import subprocess,time,os,json
from pathlib import Path
folder=Path('docs/reports/m07');g='/home/pablo/.local/bin/godot'
log=open(folder/'gui-menu.log','w');cmd=[g,'--path','.','--display-driver','x11','/tmp/m07_gui_harness.tscn','--','--menu']
p=subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT);time.sleep(7)
env=dict(os.environ,LUMEN_TITLE='LUMEN LINK CLIENT M07')
# Focus also makes the native compositor publish a current backing surface.
subprocess.run(['python3','/tmp/m07_capture_menu.py','focus'],env=env,capture_output=True)
time.sleep(.3)
shot=subprocess.run(['python3','/tmp/m07_capture_menu.py','capture'],env=env,capture_output=True,text=True)
code=p.wait(timeout=15);log.close();folder.joinpath('gui-menu.command.json').write_text(json.dumps(dict(command=cmd,exit_code=code,capture_exit_code=shot.returncode),indent=2));print(code,shot.returncode)
