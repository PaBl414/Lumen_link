"""Authoring only. Adds six explicit layouts; leaves the original three JSON maps unchanged."""
import json
from pathlib import Path

def stage(ends,socket=-1,operator=0,escape=None,centers=None):return dict(ends=ends,socket=socket,operator=operator,escape=escape or ends,centers=centers or ends)
def goal(hint,stages,fields=True):return dict(hint=hint,stages=stages,fields=fields)
def pulse(x,y,offset=0):return dict(type='PULSE',a=[x,y],radius=48,phase_offset=offset)
def sweep(x,y1,y2,travel,offset=0):return dict(type='SWEEP',a=[x,y1],b=[x,y2],travel=[travel,0],phase_offset=offset)
def gate(kind,rect,normal=(360,90,60),relaxed=(420,120,45),offset=0):return dict(type=kind,rect=rect,normal=list(normal),relaxed=list(relaxed),phase_offset=offset)
levels={
'switchyard':dict(theme='dock',walls=[[272,224,128,96],[816,144,96,80],[512,336,112,48],[944,352,128,24],[496,136,64,112],[1104,144,24,80]],beacons=[[496,448],[880,288],[1040,528]],sockets=[[176,448],[352,448],[752,288]],hazards=[pulse(352,448),sweep(688,432,600,96,90)],obstacles=[],goals=[
 goal('Dwie trasy: lewy zaczep omija puls, środkowy skraca dojście. Wybierzcie wspólnie.',[stage([[176,208],[624,448]],1,escape=[[176,208],[624,528]])]),
 goal('Nowa przegroda: północny dron prowadzi pionowe ramię, wschodni poziome.',[stage([[752,144],[1040,288]],2)]),
 goal('Odłączcie zaczep. Po 150 oboje obróćcie ustawienie i przywróćcie przewód.',[stage([[848,528],[1168,528]]),stage([[944,432],[1136,624]])])]),
'service_channels':dict(theme='dock',walls=[[224,352,832,48],[352,584,112,40],[784,440,64,40],[944,584,64,40],[432,128,80,48],[704,224,96,64],[1008,128,48,96]],beacons=[[112,400],[400,480],[976,480]],sockets=[[176,432],[1120,432]],hazards=[sweep(336,144,272,160),pulse(448,528,100),pulse(1120,224,30)],obstacles=[],goals=[
 goal('Rozdzielcie drogi: jeden nad przegrodą, drugi pod nią. Spotykacie się przewodem.',[stage([[112,240],[112,560]])]),
 goal('Dolny dron pokonuje pulsy, górny omija ruchomą barierę. Zsynchronizujcie ramiona przy lewym zaczepie.',[stage([[176,208],[624,528]],0,escape=[[112,208],[624,624]])]),
 goal('Przejdźcie różnymi korytarzami na prawo. Po 150 przestawcie oba końce, zachowując prawy zaczep.',[stage([[1120,144],[832,528]],1,escape=[[1200,144],[912,528]]),stage([[1120,304],[688,576]],1,escape=[[1200,304],[688,656]])])]),
'observatory':dict(theme='garden',walls=[[720,136,112,48],[880,384,64,64],[480,320,96,80],[1056,144,48,96],[576,536,96,48]],beacons=[[336,240],[784,240],[944,512]],sockets=[[656,240],[912,336],[1056,600]],hazards=[pulse(944,600,60)],obstacles=[gate('SHUTTER',[320,184,24,112],(360,90,90),(420,120,60)),gate('SHUTTER',[840,208,24,48],(420,90,90),(480,120,60)),gate('SHUTTER',[704,184,32,24],(420,90,90),(480,120,60),300),gate('SHUTTER',[896,464,32,80],(360,90,90),(420,120,60),120)],goals=[
 goal('Przesłona nie rani i nie blokuje dronów. Żółta zapowiedź poprzedza zamknięcie przewodu.',[stage([[208,240],[464,240]])],False),
 goal('Porównajcie oba zaczepy: przesłony zamykają inne ramiona w różnych momentach.',[stage([[656,144],[1008,240]],0)]),
 goal('Połowa zachowana: przesuńcie oboje końce orbity i odzyskajcie otwarte okno.',[stage([[720,336],[1168,600]],2,escape=[[720,336],[1168,504]]),stage([[608,248],[944,600]],2,escape=[[608,248],[848,600]])])]),
'interference':dict(theme='reactor',walls=[[656,208,128,144],[976,208,112,144],[304,320,144,48],[400,128,48,48],[656,576,112,40],[1120,144,48,96]],beacons=[[336,240],[720,448],[960,528]],sockets=[[592,448],[928,528]],hazards=[pulse(832,592,90)],obstacles=[gate('JAM',[160,192,96,96],(330,90,90),(420,120,60),240),gate('JAM',[920,400,112,96],(330,90,90),(420,120,60)),gate('SHUTTER',[784,416,24,64],(360,90,60),(420,120,45),120),gate('JAM',[880,272,96,96],(330,90,90),(420,120,60)),gate('JAM',[992,480,96,96],(330,90,90),(420,120,60),240)],goals=[
 goal('Strefa nie rani: opuśćcie jej obrys, a przewód wróci po zakończeniu zakłócenia.',[stage([[208,240],[464,240]],escape=[[112,240],[464,240]])]),
 goal('Zaczep za narożnikiem. Tym razem wschodnie stanowisko musi wycofać się ze strefy.',[stage([[592,208],[976,448]],0,escape=[[592,208],[1104,448]])]),
 goal('Po 150 górny dron przechodzi ponad strefę, drugi opuszcza wschodni kraniec. Sama wiązka może przejść przez zakłócenia.',[stage([[928,320],[1168,528]],1,escape=[[848,320],[1168,448]]),stage([[928,144],[1040,528]],1,escape=[[928,144],[1168,528]])])]),
'aux_core':dict(theme='reactor',walls=[[448,136,48,112],[696,144,144,192],[976,224,80,64],[512,432,112,48],[752,536,64,32],[1136,160,48,112]],beacons=[[304,320],[784,400],[1056,480]],sockets=[[624,384],[912,512],[1056,368]],hazards=[pulse(624,176),pulse(1040,384,30),pulse(848,624,90),sweep(880,432,600,144,60)],obstacles=[gate('SHUTTER',[272,272,64,24]),gate('JAM',[256,448,96,96]),gate('JAM',[888,256,64,96],offset=120),gate('SHUTTER',[1040,432,32,96],(390,90,60),(480,120,45))],goals=[
 goal('Po 150 obróćcie przewód z poziomego w pionowy. Sprawdźcie zapowiedź strefy przy dolnym polu.',[stage([[144,320],[464,320]]),stage([[304,144],[304,496]],escape=[[304,144],[400,496]])]),
 goal('Najpierw środkowy zaczep. Po 150 zmieńcie go na dolny; wycofajcie się z pulsu i odtwórzcie ramiona.',[stage([[624,176],[1040,384]],0,escape=[[528,176],[1136,384]]),stage([[560,256],[848,624]],1,1,escape=[[560,256],[848,528]])]),
 goal('Krótka droga przecina ruchomą barierę. Zachowajcie 150, potem przełączcie dolny zaczep na górny.',[stage([[912,304],[1200,448]],1,escape=[[816,304],[1200,544]]),stage([[848,400],[1056,624]],2,1,escape=[[848,400],[1168,624]])])]),
'station_heart':dict(theme='reactor',walls=[[256,368,64,80],[432,192,80,96],[640,176,112,64],[832,128,48,152],[592,480,96,48],[912,640,96,24],[1056,224,64,80]],beacons=[[384,400],[768,432],[1040,480]],sockets=[[384,320],[768,320],[1056,528]],hazards=[sweep(96,128,240,128),pulse(384,624,90),pulse(768,592,30),sweep(880,368,560,144,90),pulse(1168,416,90)],obstacles=[gate('JAM',[160,272,96,96]),gate('JAM',[512,272,96,96],offset=180),gate('SHUTTER',[368,416,32,48],(330,90,60),(420,120,45)),gate('SHUTTER',[752,432,32,64]),gate('SHUTTER',[1024,448,64,24],(420,90,60),(480,120,45),240),gate('JAM',[736,100,96,96],offset=120)],goals=[
 goal('Po 150 oboje zmieńcie pola. Dolna część lewego pola chroni przed SWEEP; drugi dron wycofuje się z PULSE.',[stage([[208,320],[384,496]],0,escape=[[112,320],[384,496]]),stage([[112,272],[384,624]],0,escape=[[112,304],[480,624]],centers=[[112,240],[384,624]])]),
 goal('Po 150 drugi gracz przełącza zaczep. W nowych polach skróćcie ramiona: limit całej trasy to 720.',[stage([[560,320],[768,592]],1,escape=[[464,320],[864,592]]),stage([[640,384],[840,608]],2,1,escape=[[640,384],[840,656]],centers=[[624,384],[864,624]])]),
 goal('Ostatni obwód: zachowajcie 150, zmieńcie zaczep i obie strony. Po wyłączeniu strefy wspólnie do wyjścia.',[stage([[944,192],[1168,416]],2,escape=[[944,192],[1168,320]]),stage([[784,144],[1176,560]],1,0,escape=[[688,144],[1176,656]])])]),
}
hints_path=Path('tools/map_solution_hints.json');hints=json.loads(hints_path.read_text())
for name,l in levels.items():
 objectives=[dict(id=i,hint=g['hint'],stabilization=[s['centers'] for s in g['stages']] if g['fields'] else []) for i,g in enumerate(l['goals'])]
 m=dict(schema_version=3,id=name,bounds=[32,88,1216,600],spawns=[[112,592],[176,592]],walls=[dict(id=i,rect=r) for i,r in enumerate(l['walls'])],beacons=[dict(id=i,position=p) for i,p in enumerate(l['beacons'])],sockets=[dict(id=i,position=p) for i,p in enumerate(l['sockets'])],exit=dict(position=[1168,592],radius=64),hazards=[dict(id=i,**h) for i,h in enumerate(l['hazards'])],background_asset=l['theme']+'_background',objectives=objectives,obstacles=[dict(id=i,**o) for i,o in enumerate(l['obstacles'])])
 Path(f'data/maps/{name}.json').write_text(json.dumps(m,indent=2)+'\n')
 hints[name]=[dict(stages=[{k:v for k,v in s.items() if k!='centers'} for s in g['stages']]) for g in l['goals']]
hints_path.write_text(json.dumps(hints,indent=2)+'\n')
