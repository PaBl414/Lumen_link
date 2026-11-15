"""Cross-process progress/recovery/reset + actual composition-root boot; isolated user folder."""
import json,os,subprocess,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[1];out=root/'docs/reports/levels9'
g=os.environ.get('GODOT',str(Path.home()/'.local/bin/godot'));results=[]
with tempfile.TemporaryDirectory(prefix='lumen-progress-restart-') as temporary:
 env=dict(os.environ,XDG_DATA_HOME=temporary)
 def fixture(action):
  command=[g,'--headless','--path',str(root),'--script','tools/check_progress_process.gd','--',f'--isolated={temporary}',f'--action={action}']
  p=subprocess.run(command,env=env,capture_output=True,text=True,timeout=30)
  assert p.returncode==0,(p.stdout,p.stderr)
  return next(json.loads(line) for line in p.stdout.splitlines() if line.startswith('{'))
 def boot(label):
  path=Path(temporary)/f'{label}.json'
  command=[g,'--headless','--path',str(root),'res://tests/integration/network_harness.tscn','--','--scenario=boot',f'--report={path}']
  p=subprocess.run(command,env=env,capture_output=True,text=True,timeout=30)
  (out/f'progress-boot-{label}.log').write_text(p.stdout+p.stderr)
  assert p.returncode==0,(p.stdout,p.stderr)
  return json.loads(path.read_text())
 data=fixture('write');path=Path(data['path'])
 legacy=path.parent/'debug_records.json'
 raw=json.dumps({'schema_version':1,'records':[{'seed':42,'difficulty':0,'score':9999,'duration_ticks':10000,'integrity':6,'date_utc':'2026-11-15T00:00:00Z'}]})
 legacy.write_text(raw)
 loaded=boot('restart');assert loaded['progress']['completed']==['dock','garden']
 assert loaded['progress']['records']['garden']['relaxed']['best_score']==200
 assert legacy.read_text()==raw;results.append('restart actual AppRoot: two stable IDs and difficulty records; legacy unchanged')
 path.write_text('{corrupt')
 recovered=boot('recovery');assert recovered['progress']['completed']==['dock'] and recovered['progress_warning']
 assert legacy.read_text()==raw;results.append('corrupt primary: actual AppRoot restores previous valid backup and warning')
 assert fixture('cancel_reset')['data']['completed']==['dock'];results.append('cancelled reset preserves history')
 fixture('reset');reset=boot('reset');assert reset['progress']['completed']==[]
 path.write_text('{corrupt')
 assert fixture('read')['data']['completed']==[];assert legacy.read_text()==raw
 results.append('confirmed reset survives restart and backup recovery; legacy unchanged')
(out/'progress-restart.json').write_text(json.dumps({'ok':True,'cases':results},indent=2)+'\n')
print(json.dumps({'ok':True,'cases':results}))
