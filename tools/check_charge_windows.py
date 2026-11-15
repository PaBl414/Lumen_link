"""Independent timing analysis, not a movement replay or playtest.
Reserves 24 ticks before danger and 36 ticks to reacquire after danger.
Uses actual hazard phases/shape and exact grace30/decay2; four cycles maximum.
"""
import json, math, argparse
from pathlib import Path

def hit(h,p,t,d,v):
    pulse=h['type']=='PULSE'; period=([300,360] if pulse else [360,420])[d]
    off,tele,active=(([180,60,60],[240,90,30]) if pulse else ([60,90,180],[120,120,120]))[d]
    absolute=t+math.floor(h['phase_offset']*period/(300 if pulse else 360))+37*v
    q=absolute%period
    if not off+tele<=q<off+tele+active:return False
    if pulse:
        dx=max(0,abs(p[0]-h['a'][0])-12);dy=max(0,abs(p[1]-h['a'][1])-12)
        return dx*dx+dy*dy<=h['radius']**2
    progress=(q-off-tele)/(active-1)
    if (absolute//period)%2: progress=1-progress
    ax=h['a'][0]+h['travel'][0]*progress;ay=h['a'][1]+h['travel'][1]*progress
    bx=h['b'][0]+h['travel'][0]*progress;by=h['b'][1]+h['travel'][1]*progress
    # Conservative stationary square at current and previous sweep location.
    return min(ax,bx)-18<=p[0]<=max(ax,bx)+18 and min(ay,by)-18<=p[1]<=max(ay,by)+18

def analyze(data,hints,d,v):
    periods=[([300,360] if h['type']=='PULSE' else [720,840])[d] for h in data['hazards']]
    period=math.lcm(*periods) if periods else 300 # SWEEP reverses every cycle
    result=[]
    for i,goal in enumerate(hints):
        for stage,s in enumerate(goal['stages']):
            unsafe=[any(hit(h,p,t,d,v) for h in data['hazards'] for p in s['ends']) for t in range(period)]
            anticipated=[any(unsafe[(t+k)%period] for k in range(25)) for t in range(period)]
            charge=150 if stage else 0;floor=charge;threshold=300 if len(goal['stages'])==1 else (150 if not stage else 300)
            last_power=0;recovery=0;peak=charge;finished=None;longest=0;run=0
            for t in range(1,period*4+1):
                danger=anticipated[t%period]
                if danger: recovery=36
                elif recovery:recovery-=1
                good=not danger and not recovery
                run=run+1 if good else 0;longest=max(longest,run)
                if good:charge+=1;last_power=t
                elif t-last_power>30 and (t-last_power)%2==0:charge=max(floor,charge-1)
                peak=max(peak,charge)
                if charge>=threshold:finished=t;break
            result.append(dict(map=data['id'],goal=i,stage=stage,difficulty=d,variant=v,period=period,ticks_to_threshold=finished,peak=peak,required=threshold,longest_ready_window=longest,passed=finished is not None))
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',default='docs/reports/m11c/charge-windows.json');args=parser.parse_args()
    hints=json.loads(Path('tools/map_solution_hints.json').read_text());results=[]
    for name in ['dock','garden','reactor']:
        data=json.loads(Path(f'data/maps/{name}.json').read_text())
        for d in range(2):
            for v in range(3):results+=analyze(data,hints[name],d,v)
    report=dict(anticipation_ticks=24,reacquisition_ticks=36,meaning='independent stationary timing model, not full movement proof',results=results,passed=all(r['passed'] for r in results))
    Path(args.output).write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(dict(passed=report['passed'],cases=len(results),failures=[r for r in results if not r['passed']])))
    raise SystemExit(0 if report['passed'] else 1)
