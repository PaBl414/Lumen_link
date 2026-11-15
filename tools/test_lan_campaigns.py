"""Two independent Godot processes per difficulty, real 60 Hz ENet/input campaign.
Requires a current build manifest. No world mutations or teleports.
"""
import argparse,json,os,subprocess,time
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--difficulty',choices=['all','0','1'],default='all');parser.add_argument('--level',default='dock');parser.add_argument('--port',type=int,default=25800);parser.add_argument('--output',default='docs/reports/levels9');args=parser.parse_args()
root=Path(__file__).resolve().parents[1];out=(root/args.output).resolve();out.mkdir(parents=True,exist_ok=True)
g=os.environ.get('GODOT',str(Path.home()/'.local/bin/godot'));catalog=json.loads((root/'data/levels.json').read_text())['levels']
assert args.level in [entry['id'] for entry in catalog]
processes=[];streams=[];results=[]
try:
 for difficulty in ([0,1] if args.difficulty=='all' else [int(args.difficulty)]):
  for role in ['host','client']:
   stem=out/f'lan-d{difficulty}-{role}';stream=stem.with_suffix('.log').open('w');streams.append(stream)
   command=[g,'--headless','--path',str(root),'res://tests/integration/network_harness.tscn','--','--scenario=expedition',f'--level={args.level}',f'--role={role}',f'--difficulty={difficulty}',f'--port={args.port+2*difficulty}',f'--report={stem.with_suffix(".json")}']
   process=subprocess.Popen(command,stdout=stream,stderr=subprocess.STDOUT);processes.append((difficulty,role,process,command));time.sleep(.7)
 deadline=time.monotonic()+1650
 while time.monotonic()<deadline and any(process.poll() is None for _,_,process,_ in processes):time.sleep(1)
 for difficulty,role,process,command in processes:
  if process.poll() is None:process.kill();process.wait()
  report_path=out/f'lan-d{difficulty}-{role}.json';report=json.loads(report_path.read_text()) if report_path.exists() else {}
  expected=[entry['id'] for entry in catalog] if args.level=='dock' else [args.level]
  ok=process.returncode==0 and report.get('ok',False) and sorted(report.get('levels',{}))==sorted(expected) and all(row.get('saved',False) for row in report.get('levels',{}).values())
  results.append(dict(difficulty=difficulty,role=role,exit_code=process.returncode,ok=ok,command=command));print(json.dumps(results[-1]),flush=True)
 for difficulty in {d for d,_,_,_ in processes}:
  host=json.loads((out/f'lan-d{difficulty}-host.json').read_text());guest=json.loads((out/f'lan-d{difficulty}-client.json').read_text())
  assert host.get('levels')==guest.get('levels'), 'Authoritative results differ'
  assert not guest.get('client_has_simulation',True)
finally:
 for _,_,process,_ in processes:
  if process.poll() is None:process.terminate();process.wait()
 for stream in streams:stream.close()
(out/'lan-processes.json').write_text(json.dumps({'ok':all(row['ok'] for row in results),'results':results},indent=2)+'\n')
raise SystemExit(0 if results and all(row['ok'] for row in results) else 1)
