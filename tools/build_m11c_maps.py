"""Authoring only: explicit M11c layouts and one solution per goal. Not runtime logic."""
import argparse
import json
from pathlib import Path

def pulse(x, y, offset=0):
    return dict(type='PULSE', a=[x,y], radius=48, phase_offset=offset)

def sweep(x, y1, y2, travel, offset=0):
    return dict(type='SWEEP', a=[x,y1], b=[x,y2], travel=[travel,0], phase_offset=offset)

def stage(ends, socket=-1, operator=0, escape=None):
    return dict(ends=ends, socket=socket, operator=operator, escape=escape or ends)

def goal(hint, stages, fields=False):
    return dict(hint=hint, stages=stages, fields=fields)

LAYOUTS = {
 'dock':dict(
  walls=[[344,296,24,184],[400,272,32,24],[432,180,392,132],[368,344,64,136],[432,328,392,152]],
  beacons=[[208,440],[416,320],[992,552]], sockets=[[384,320]],
  hazards=[pulse(896,552)],
  goals=[
   goal('Ustawcie się po obu stronach celu. Jasny przewód ładuje cel przez 5 s.',[stage([[112,440],[304,440]])]),
   goal('Zaczep przy narożniku: jeden dron nad kanałem, drugi po jego prawej stronie. Limit przewodu 720.',[stage([[384,192],[904,320]],0)]),
   goal('Odłączcie poprzedni zaczep. Zajmijcie różne pola; wycofajcie się przed czerwonym pulsem i wróćcie.',[stage([[896,552],[1120,552]],escape=[[896,648],[1120,648]])],True),
  ]),
 'garden':dict(
  walls=[[600,224,112,160],[936,208,96,152]],
  beacons=[[256,256],[672,448],[944,384]], sockets=[[544,448],[880,384],[1056,512]],
  hazards=[sweep(480,152,296,128,0),pulse(1056,432,100)],
  goals=[
   goal('Dwa etapy: po zatrzaśnięciu 150 przejdźcie na drugą parę. Pierwsza połowa pozostaje.',[stage([[112,256],[400,256]]),stage([[160,176],[352,336]])],True),
   goal('Przewód za przegrodą. Żółta linia zapowiada SWEEP: opuśćcie stanowisko, a potem wróćcie.',[stage([[544,224],[800,448]],0,escape=[[448,224],[800,528]])],True),
   goal('Po 150 zmieńcie zaczep. Krótka droga przecina puls; obejście prowadzi prawą stroną.',[stage([[880,224],[1104,384]],1,escape=[[800,224],[1168,384]]),stage([[776,192],[944,624]],2,1,escape=[[776,192],[944,624]])],True),
  ]),
 'reactor':dict(
  walls=[[272,192,112,192],[744,136,144,120],[784,448,48,96]],
  beacons=[[336,448],[800,320],[928,496]], sockets=[[208,448],[672,320],[1008,592]],
  hazards=[sweep(144,144,272,128,0),pulse(672,160,0),pulse(1008,320,30),pulse(672,480,0),pulse(1168,320,30),pulse(768,304,0),sweep(944,464,624,96,90)],
  goals=[
   goal('Rozdzielcie się wokół bloku. Zaczep prowadzi oba ramiona; SWEEP przecina północne stanowisko.',[stage([[208,208],[448,448]],0,escape=[[112,208],[448,528]])],True),
   goal('Po 150 oboje zmieńcie pola. Pulsy naciskają naprzemiennie: bezpieczne miejsca są obok stanowisk.',[stage([[672,160],[1008,320]],1,escape=[[576,160],[1008,416]]),stage([[672,480],[1168,320]],1,escape=[[576,480],[1168,224]])],True),
   goal('Finał: zachowajcie 150, przełączcie zaczep i odbudujcie trasę. Omińcie SWEEP, potem wspólne wyjście.',[stage([[672,480],[1056,584]],1,escape=[[576,480],[1120,584]]),stage([[768,304],[1168,512]],2,1,escape=[[672,304],[1168,592]])],True),
  ]),
}

def write(name):
    layout=LAYOUTS[name]
    objectives=[dict(id=i,hint=g['hint'],stabilization=[s['ends'] for s in g['stages']] if g['fields'] else []) for i,g in enumerate(layout['goals'])]
    data=dict(schema_version=2,id=name,bounds=[32,88,1216,600],spawns=[[112,592],[176,592]],
      walls=[dict(id=i,rect=r) for i,r in enumerate(layout['walls'])],
      beacons=[dict(id=i,position=p) for i,p in enumerate(layout['beacons'])],
      sockets=[dict(id=i,position=p) for i,p in enumerate(layout['sockets'])],
      exit=dict(position=[1168,592],radius=64),
      hazards=[dict(id=i,**h) for i,h in enumerate(layout['hazards'])],background_asset=name+'_background',objectives=objectives)
    Path(f'data/maps/{name}.json').write_text(json.dumps(data,indent=2)+'\n')
    path=Path('tools/map_solution_hints.json'); hints=json.loads(path.read_text())
    hints[name]=[dict(stages=g['stages']) for g in layout['goals']]
    path.write_text(json.dumps(hints,indent=2)+'\n')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--map',choices=list(LAYOUTS)+['all'],default='all')
    chosen=parser.parse_args().map
    for name in LAYOUTS if chosen=='all' else [chosen]: write(name)
