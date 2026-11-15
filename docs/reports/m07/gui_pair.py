import subprocess,time,os,json
from pathlib import Path
G='/home/pablo/.local/bin/godot';folder=Path('docs/reports/m07');pairs=[]
for role in ['host','client']:
 log=open(folder/('gui-'+role+'.log'),'w')
 cmd=[G,'--path','.','--display-driver','x11','/tmp/m07_gui_harness.tscn','--']+(['--host'] if role=='host' else [])
 p=subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT);pairs.append((p,log,cmd));time.sleep(.8)
time.sleep(6)
for role in ['host','client']:
 env=dict(os.environ,LUMEN_TITLE='LUMEN LINK '+role.upper()+' M07')
 subprocess.run(['python3','/tmp/m07_capture_'+role+'.py','capture'],env=env,check=True)
records=[]
for p,log,cmd in pairs:
 try:code=p.wait(timeout=25)
 except subprocess.TimeoutExpired:p.terminate();code=p.wait()
 log.close();records.append({'command':cmd,'exit_code':code})
folder.joinpath('gui.commands.json').write_text(json.dumps(records,indent=2));print(records)
