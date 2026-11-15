"""Linux loopback ENet fault/kill checks; stdlib only. Run from project root."""
import heapq,json,random,socket,subprocess,threading,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/reports/m09'; OUT.mkdir(parents=True,exist_ok=True)
G=str(Path.home()/'.local/bin/godot')
def launch(role,port,scenario,prefix):
    report=OUT/f'{prefix}-{role}.json'; report.unlink(missing_ok=True)
    cmd=[G,'--headless','--path',str(ROOT),'tests/integration/fault_harness.tscn','--',f'--role={role}',f'--port={port}',f'--scenario={scenario}',f'--report={report}']
    log=open(OUT/f'{prefix}-{role}.log','w')
    return subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT),log,cmd,report
def read(path):
    try:return json.loads(path.read_text())
    except (FileNotFoundError,json.JSONDecodeError):return {}
def wait_playing(pair):
    deadline=time.monotonic()+18
    while time.monotonic()<deadline:
        if all(read(x[3]).get('playing') for x in pair):return
        time.sleep(.05)
    raise AssertionError('PLAYING timeout')
def loss_test():
    rng=random.Random(90210); sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);sock.bind(('127.0.0.1',28992));sock.settimeout(.002)
    stop=threading.Event(); fault_start=[float('inf')]; counters={'dropped':0,'duplicated':0,'reordered':0,'blackout_dropped':0,'sources':{},'forwarded':0}; start=time.monotonic()
    def relay():
        client=None; pending=[]; order=0
        while not stop.is_set():
            elapsed=time.monotonic()-fault_start[0]
            try:
                data,source=sock.recvfrom(65535)
                counters['sources'][str(source)]=counters['sources'].get(str(source),0)+1
                if source[1]==28991: destination=client
                else: client=source;destination=('127.0.0.1',28991)
                if destination:
                    # Full wire blackout500ms, after the countdown. Reliable ENet will retry.
                    if 4<=elapsed<4.5:counters['blackout_dropped']+=1
                    elif 0<=elapsed<10 and rng.random()<.2:counters['dropped']+=1
                    else:
                        delay=(.05+rng.uniform(-.015,.015)) if 0<=elapsed<10 else 0
                        if 0<=elapsed<10 and rng.random()<.2:delay+=.05;counters['reordered']+=1
                        order+=1;heapq.heappush(pending,(time.monotonic()+delay,order,data,destination))
                        if 0<=elapsed<10 and rng.random()<.1:
                            counters['duplicated']+=1;order+=1;heapq.heappush(pending,(time.monotonic()+delay+.003,order,data,destination))
            except socket.timeout:pass
            now=time.monotonic()
            while pending and pending[0][0]<=now:
                _,_,data,destination=heapq.heappop(pending);sock.sendto(data,destination);counters['forwarded']+=1
    thread=threading.Thread(target=relay);thread.start();pair=[]
    try:
        pair.append(launch('host',28991,'loss','wire-loss'));time.sleep(.7);pair.append(launch('client',28992,'loss','wire-loss'))
        wait_playing(pair);time.sleep(1);fault_start[0]=time.monotonic()
        codes=[p.wait(timeout=38) for p,_,_,_ in pair]
        results=[read(x[3]) for x in pair]; host,guest=results
        assert codes==[0,0],(codes,results)
        assert host['dashes']==guest['dashes']==1,results
        assert guest['frozen_count']>0 and guest['recovered'],results
        assert host['duplicate_events']==guest['duplicate_events']==0,results
        assert host['position']==guest['position']==guest['predicted_position'],results
        return {'commands':[x[2] for x in pair],'exit_codes':codes,'faults':counters,'results':results,'pass':True}
    finally:
        stop.set();thread.join();sock.close();(OUT/'relay-debug.json').write_text(json.dumps(counters))
        for p,log,_,_ in pair:
            if p.poll() is None:p.terminate();p.wait()
            log.close()
def kill_test(victim,port):
    pair=[launch('host',port,'kill','kill-'+victim)];time.sleep(.7);pair.append(launch('client',port,'kill','kill-'+victim))
    try:
        wait_playing(pair);index=0 if victim=='host' else 1
        started=time.monotonic();pair[index][0].kill();pair[index][0].wait()
        survivor=pair[1-index];code=survivor[0].wait(timeout=4)
        duration=time.monotonic()-started;result=read(survivor[3])
        assert code==0 and duration<=3.5 and result['state']=='IDLE',(code,duration,result)
        # Actual server bind after teardown.
        sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);sock.bind(('127.0.0.1',port));sock.close()
        return {'victim':victim,'commands':[x[2] for x in pair],'survivor_exit':code,'victim_exit':pair[index][0].returncode,'seconds':duration,'result':result,'port_rebound':True,'pass':True}
    finally:
        for p,log,_,_ in pair:
            if p.poll() is None:p.terminate();p.wait()
            log.close()
if __name__=='__main__':
    results={'wire_loss':loss_test(),'kill_host':kill_test('host',29191),'kill_client':kill_test('client',29291)}
    (OUT/'fault-processes.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(results))
