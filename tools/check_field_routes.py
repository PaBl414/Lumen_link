"""Independent field-boundary geometry search; grid sampling is not a continuous proof."""
import json,math
from pathlib import Path

def blocked(a,b,wall,pad):
 x,y,w,h=wall;x-=pad;y-=pad;w+=2*pad;h+=2*pad;t0=0;t1=1
 for q,d,lo,hi in [(a[0],b[0]-a[0],x,x+w),(a[1],b[1]-a[1],y,y+h)]:
  if abs(d)<1e-9:
   if q<lo or q>hi:return False
  else:
   u,v=(lo-q)/d,(hi-q)/d
   t0=max(t0,min(u,v));t1=min(t1,max(u,v))
   if t0>t1:return False
 return True

def hits(a,b,s,goal,walls):
 pts=[a,b] if s is None else [a,s,b];lengths=[math.dist(x,y) for x,y in zip(pts,pts[1:])];total=sum(lengths)
 if total<56 or total>720:return False
 if any(blocked(x,y,w['rect'],3) for x,y in zip(pts,pts[1:]) for w in walls):return False
 along=0
 for x,y,L in zip(pts,pts[1:],lengths):
  if L==0:continue
  t=max(0,min(1,((goal[0]-x[0])*(y[0]-x[0])+(goal[1]-x[1])*(y[1]-x[1]))/L**2));q=(x[0]+t*(y[0]-x[0]),x[1]+t*(y[1]-x[1]));d=along+t*L
  if math.dist(q,goal)<=25 and d>=48 and total-d>=48:return True
  along+=L
 return False
results=[]
hints=json.loads(Path('tools/map_solution_hints.json').read_text())
for name in ['dock','garden','reactor']:
 m=json.loads(Path(f'data/maps/{name}.json').read_text())
 for i,obj in enumerate(m['objectives']):
  for k,pair in enumerate(obj['stabilization']):
   clouds=[]
   for p in pair:
    cloud=[(p[0]+x,p[1]+y) for x in range(-44,45,4) for y in range(-44,45,4) if x*x+y*y<=44**2 and not any(blocked((p[0]+x,p[1]+y),(p[0]+x,p[1]+y),w['rect'],12) for w in m['walls'])];clouds.append(cloud)
   desired=hints[name][i]['stages'][k]['socket']
   if desired<0:continue
   for socket in [-1]+[x['id'] for x in m['sockets'] if x['id']!=desired]:
    found=None
    for a in clouds[0]:
     for b in clouds[1]:
      if hits(a,b,None if socket<0 else m['sockets'][socket]['position'],m['beacons'][i]['position'],m['walls']):found=(a,b);break
     if found:break
    results.append(dict(map=name,goal=i,stage=k,desired=desired,other=socket,bypass=found,pairs=len(clouds[0])*len(clouds[1])))
    print(json.dumps(results[-1]),flush=True)

report=dict(grid_step=4,cases=len(results),pairs=sum(x["pairs"] for x in results),results=results,passed=not any(x["bypass"] for x in results))
Path("docs/reports/m11c/field-routes.json").write_text(json.dumps(report,indent=2)+"\n")
raise SystemExit(0 if report["passed"] else 1)
