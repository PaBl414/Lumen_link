import subprocess,socket,threading,time,json,struct
from pathlib import Path
G='/home/pablo/.local/bin/godot';root=Path('/home/pablo/lan_game');out=root/'docs/reports/m07'
proxy=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);proxy.bind(('127.0.0.1',22992));proxy.settimeout(.1)
stop=False;client_address=None;measure=[];types=[];parse_errors=0
sizes={1:8,2:48,3:44,4:8,5:4,10:12,11:16}
def parse(data):
 global parse_errors
 if len(data)<2:return
 pos=4 if struct.unpack('!H',data[:2])[0]&0x8000 else 2
 while pos+4<=len(data):
  cmd=data[pos]&15;types.append(cmd)
  if cmd in sizes:pos+=sizes[cmd]
  elif cmd in [6,7,8,9,12]:
   offset=4 if cmd==6 else 6
   if pos+offset+2>len(data):parse_errors+=1;return
   n=struct.unpack('!H',data[pos+offset:pos+offset+2])[0]
   pos+=(6 if cmd==6 else 24 if cmd in [8,12] else 8)+n
  else:parse_errors+=1;return
 if pos!=len(data):parse_errors+=1
def relay():
 global client_address
 while not stop:
  try:data,addr=proxy.recvfrom(65535)
  except socket.timeout:continue
  if addr[1]==22991:
   if client_address:proxy.sendto(data,client_address)
  else:
   client_address=addr;proxy.sendto(data,('127.0.0.1',22991))
  measure.append(len(data));parse(data)
th=threading.Thread(target=relay);th.start()
files=[]
def launch(role,port):
 log=open(out/f'process-{role}.log','w');files.append(log)
 cmd=[G,'--headless','--path',str(root),'tests/integration/network_harness.tscn','--',f'--role={role}',f'--port={port}',f'--report={out}/process-{role}.json']
 return subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT),cmd
host,hcmd=launch('host',22991);time.sleep(.7);guest,gcmd=launch('client',22992)
try:
 gc=guest.wait(timeout=25);hc=host.wait(timeout=25)
finally:
 stop=True;th.join();proxy.close()
 for f in files:f.close()
 for p in [guest,host]:
  if p.poll() is None:p.terminate()
summary={'commands':[hcmd,gcmd],'exit_codes':[hc,gc],'udp_datagrams':len(measure),'max_udp_payload':max(measure,default=0),'udp_payload_sizes':sorted(set(measure)),'enet_command_types':sorted(set(types)),'enet_fragment_commands':sum(t in [8,12] for t in types),'enet_parse_errors':parse_errors,'loopback_mtu':int(Path('/sys/class/net/lo/mtu').read_text()),'measurement':'Transparent loopback UDP relay; actual ENet datagrams, including Godot/ENet overhead; IPv4 overhead adds 28 bytes.'}
(out/'processes-and-datagrams.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary))
