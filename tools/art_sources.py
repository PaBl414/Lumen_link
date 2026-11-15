"""Original LUMEN LINK vector artwork. Offline authoring; no third-party graphics."""
from pathlib import Path
import math,json
ART=Path('assets/art');UI=Path('assets/ui');ART.mkdir(parents=True,exist_ok=True);UI.mkdir(parents=True,exist_ok=True)
P='#dce8de';D='#101b2b';S='#344a58';M='#66e0c2';C='#ffbe78';R='#f07178';G='#e9f6bf'
def svg(path,w,h,body):path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n')
def circ(x,y,r,fill,stroke='none',sw=1):return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def rect(x,y,w,h,fill,rx=0,stroke='none',sw=1):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def path(d,fill='none',stroke=P,sw=2):return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>'
# Porcelain chassis, recessed sensor and two mechanical stabilizers; core spans40px.
a=path('M12 21 Q5 23 7 35 L13 39 M51 21 Q59 23 57 35 L51 39',S,M,2)
a+=circ(32,34,21,D)+circ(32,31,20,P,S,2)+path('M17 26 Q20 14 32 14',stroke='#ffffff',sw=2)
a+=path('M15 36 Q32 46 49 36',stroke='#9db3b1',sw=2)+path('M22 14 L26 10 L38 10 L42 14',S,M,2)
a+=rect(20,23,24,15,D,7)+circ(22,43,2,M)+circ(42,43,2,M)+path('M15 30 L18 30 M46 30 L49 30',stroke=M,sw=2)
svg(ART/'drone_a.svg',64,64,a)
b=path('M32 10 Q35 10 38 13 L53 28 Q57 32 53 36 L41 49 L35 46 L32 51 L26 49 L11 36 Q7 32 11 28 L26 13 Q29 10 32 10',P,S,2)
b+=path('M14 30 L8 25 L5 30 L10 35 M50 30 L56 25 L59 30 L54 35',S,C,2)
b+=path('M19 24 L30 14 L34 14 M17 37 L27 46 M39 44 L47 36',stroke='#ffffff',sw=2)
b+=rect(20,23,24,15,D,6)+path('M27 44 L32 40 L37 44',stroke=C,sw=3)+circ(32,18,2,C)
svg(ART/'drone_b.svg',64,64,b)
svg(ART/'sensor.svg',16,16,circ(8,8,6,D)+circ(8,8,4,'#ffffff')+circ(6.5,6.5,1.5,'#ffffff'))
# Sixteen tile designs: interlocking ceramic modules, ribs, small fasteners and inlaid circuits.
tiles='';regions={}
for i in range(16):
 x=(i%4)*256;y=(i//4)*256
 tile=rect(2,2,252,252,S if i>=12 else '#1c303b',16,'#405b66',2)
 tile+=path('M18 60 L18 28 Q18 18 28 18 L60 18 M196 18 L228 18 Q238 18 238 28 L238 60 M18 196 L18 228 Q18 238 28 238 L60 238 M196 238 L228 238 Q238 238 238 228 L238 196',stroke='#58717a' if i>=12 else '#29444e',sw=2)
 for px,py in [(12,12),(244,12),(12,244),(244,244)]:tile+=circ(px,py,2,'#8da3a5' if i>=12 else '#3c5962')
 if i>=12:
  tile+=rect(30,28,196,200,'#405b66',12,'#789098',2)+rect(38,32,180,8,'#9aafaf',4)
  tile+=path('M48 56 L48 206 M208 56 L208 206',stroke='#263e4a',sw=3)
  for n in range(5):tile+=rect(70,70+n*25,116,7,'#29434e',3)
  tile+=circ(128,210,5,C)+path('M100 210 L113 210 M143 210 L156 210',stroke='#6b8790',sw=2)
 else:
  if i%4==0:tile+=path('M128 2 L128 68 L146 86 L146 170 L128 188 L128 254',stroke='#2e4e56',sw=2)+circ(146,128,7,'#1c303b','#3d6268',2)
  elif i%4==1:
   for n in range(4):tile+=rect(64,64+n*36,128,2,'#27414b',1)
  elif i%4==2:tile+=path('M28 128 L76 128 L104 100 L152 100 L180 128 L228 128',stroke='#38525a',sw=2)+circ(128,100,5,'#3c6768')
  else:tile+=circ(128,128,54,'none','#29434e',2)+circ(128,128,44,'none','#263e48',1)+path('M128 70 L128 90 M128 166 L128 186 M70 128 L90 128 M166 128 L186 128',stroke='#3b5961',sw=2)
 tiles+=f'<g transform="translate({x} {y})">{tile}</g>'
 regions[f'station_{i:02}']={'atlas':'station_atlas','rect':[x+2,y+2,252,252]}
svg(ART/'station_atlas.svg',1024,1024,tiles)
# Devices are a coherent eight-cell family; lighting is separate from the ceramic shell.
devices=''
for i in range(8):
 body='';on=i%2==1;color=M if i<4 else G
 if i<2:
  body=circ(64,68,42,D)+circ(64,64,40,S,'#789596',2)
  for angle in range(0,360,60):body+=f'<g transform="rotate({angle} 64 64)">'+rect(59,20,10,20,P,4)+rect(62,22,4,12,G if on else '#59777d',2)+'</g>'
  body+=circ(64,64,27,D,P,2)+circ(64,64,18,G if on else '#344a58')+path('M54 64 L61 71 L75 55',stroke=D if on else '#8ea5a3',sw=3)
 elif i<4:
  body=path('M64 23 L100 44 L100 84 L64 105 L28 84 L28 44 Z',S,'#8da3a5',3)
  body+=path('M64 30 L93 47 M35 49 L35 79 M64 97 L92 81',stroke=P,sw=2)+circ(64,64,23,D,M if on else '#6c858a',3)
  body+=path('M52 54 L64 64 L76 54 M64 64 L64 79',stroke=M if on else '#65818a',sw=4)
 else:
  if i<6:
   body=circ(64,64,48,D,S,4)+circ(64,64,42,'none',G if on else '#6b8289',4)
   for angle in range(0,360,45):body+=f'<g transform="rotate({angle} 64 64)">'+rect(61,12,6,16,P,2)+'</g>'
   body+=path('M48 47 L65 47 L65 39 L84 64 L65 89 L65 81 L48 81 Z',G if on else '#45616b','none')
  elif i==6:
   body=circ(64,64,36,D,P,3)+circ(64,64,26,S,R,3)+path('M64 30 L64 48 M64 80 L64 98 M30 64 L48 64 M80 64 L98 64',stroke=P,sw=5)+circ(64,64,12,R)
  else:
   body=rect(25,28,78,72,S,12,P,3)+rect(36,42,56,16,D,4)+path('M40 70 L64 83 L88 70 M40 83 L64 96 L88 83',stroke=C,sw=4)
 devices+=f'<g transform="translate({i%4*128} {i//4*128})">{body}</g>'
 regions[['beacon_off','beacon_on','socket_off','socket_on','exit_off','exit_on','pulse','sweep'][i]]={'atlas':'devices','rect':[i%4*128+2,i//4*128+2,124,124]}
svg(ART/'devices.svg',512,256,devices)
# Original simple pictograms: first16 cells populated, remaining16 intentionally transparent.
icons=[('move','M14 32 L50 32 M32 14 L32 50 M14 32 L21 25 M14 32 L21 39 M50 32 L43 25 M50 32 L43 39 M32 14 L25 21 M32 14 L39 21 M32 50 L25 43 M32 50 L39 43'),('dash','M36 10 L18 35 L30 35 L26 54 L48 27 L35 27 Z'),('socket','M32 12 L49 22 L49 42 L32 52 L15 42 L15 22 Z M23 25 L32 32 L41 25 M32 32 L32 43'),('ping','M32 52 L32 24 M19 24 Q32 10 45 24 M12 16 Q32 -1 52 16'),('ready','M15 33 L27 45 L50 18'),('host','M10 30 L32 12 L54 30 M17 27 L17 50 L47 50 L47 27 M27 50 L27 36 L37 36 L37 50'),('join','M38 13 L51 13 L51 51 L38 51 M10 32 L40 32 M30 22 L40 32 L30 42'),('back','M42 15 L24 32 L42 49'),('sound','M13 26 L23 26 L34 16 L34 48 L23 38 L13 38 Z M43 22 Q54 32 43 42'),('settings','M27 10 L37 10 L40 19 L49 22 L54 31 L48 39 L47 49 L37 52 L30 47 L20 49 L13 40 L17 31 L13 21 L22 17 Z M25 32 A7 7 0 1 0 39 32 A7 7 0 1 0 25 32'),('warning','M32 10 L55 51 L9 51 Z M32 23 L32 36 M32 44 L32 45'),('heart','M32 51 C-2 29 13 8 32 24 C51 8 66 29 32 51 Z'),('star','M32 9 L39 24 L55 26 L43 38 L46 54 L32 46 L18 54 L21 38 L9 26 L25 24 Z'),('clock','M32 11 A21 21 0 1 0 32 53 A21 21 0 1 0 32 11 M32 20 L32 33 L42 39'),('link','M24 40 L17 47 C7 57 0 43 10 34 L24 20 C35 9 47 21 38 30 M40 24 L47 17 C57 7 64 21 54 30 L40 44 C29 55 17 43 26 34 M23 41 L41 23'),('exit','M26 13 L13 13 L13 51 L26 51 M30 32 L54 32 M43 21 L54 32 L43 43')]
body=''
for i,(name,d) in enumerate(icons):
 x=i%8*64;y=i//8*64;body+=f'<g transform="translate({x} {y})">{path(d,stroke=P,sw=3)}</g>';regions['icon_'+name]={'atlas':'icons','rect':[x+2,y+2,60,60]}
svg(UI/'icons.svg',512,256,body)
# A bespoke stroked wordmark, without embedded fonts or external text resources.
glyphs={'L':'M0 0 L0 48 L30 48','U':'M0 0 L0 35 Q0 48 15 48 Q30 48 30 35 L30 0','M':'M0 48 L0 0 L15 22 L30 0 L30 48','E':'M30 0 L0 0 L0 48 L30 48 M0 24 L24 24','N':'M0 48 L0 0 L30 48 L30 0','I':'M0 0 L30 0 M15 0 L15 48 M0 48 L30 48','K':'M0 0 L0 48 M30 0 L0 27 L30 48'}
body=circ(65,80,35,'none',M,4)+path('M36 102 L94 58 M36 58 L94 102',stroke=C,sw=3)+circ(65,80,8,G)
x=130
for ch in 'LUMEN LINK':
 if ch==' ':x+=20;continue
 body+=f'<g transform="translate({x} 56)">{path(glyphs[ch],stroke=P,sw=4)}</g>';x+=47
body+=path('M132 125 L291 125 M333 125 L553 125',stroke='#45616b',sw=1)+circ(312,125,3,M)
svg(UI/'title.svg',640,160,body)
# Three authored environmental compositions. Floor detail never claims collider geometry.
for name,accent in [('dock','#375c6a'),('garden','#345e54'),('reactor','#725448')]:
 body=rect(0,0,1280,720,D)
 body+=path('M32 76 L1248 76 M32 700 L1248 700',stroke=accent,sw=2)
 for x in range(48,1260,128):body+=rect(x,72,48,3,accent,1)+rect(x+16,697,32,3,accent,1)
 if name=='dock':
  for x,y,w in [(80,18,370),(754,28,432),(480,650,448)]:
   body+=rect(x,y,w,18,'#1f3542',9,accent,2)+path(f'M{x+16} {y+5} L{x+w-16} {y+5}',stroke='#486977',sw=2)
   for cx in range(x+30,x+w-10,64):body+=rect(cx,y-4,7,26,'#52666b',2)+rect(cx+1,y+2,5,4,C,1)
  body+=path('M20 126 L20 630 M1260 126 L1260 630',stroke='#345362',sw=6)
 elif name=='garden':
  for x,flip in [(18,1),(1262,-1)]:
   body+=path(f'M{x} 650 C{x+flip*36} 530 {x-flip*20} 320 {x+flip*10} 112',stroke='#426a5a',sw=3)
   for y in range(150,650,76):
    body+=path(f'M{x} {y+30} Q{x+flip*64} {y-20} {x+flip*20} {y-40} Q{x-flip*8} {y-20} {x} {y+30}',fill='#24483f',stroke='#497563',sw=1)
  for x in [380,620,860]:body+=path(f'M{x} 36 Q{x+26} 4 {x+62} 30 Q{x+26} 55 {x} 36',fill='#24483f',stroke=accent)
 else:
  for cx,cy in [(1240,365),(40,365)]:
   for r in [100,122,146,174]:body+=circ(cx,cy,r,'none',accent,2)
   for angle in range(0,360,30):
    a=math.radians(angle);x1=cx+130*math.cos(a);y1=cy+130*math.sin(a);x2=cx+156*math.cos(a);y2=cy+156*math.sin(a)
    body+=path(f'M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}',stroke='#98735c',sw=3)
  body+=path('M440 36 L840 36 M480 47 L800 47',stroke=accent,sw=4)
 # The floor is a connected station surface, with quiet circuit channels and small edge labels.
 body+=rect(32,88,1216,600,'#162934',18,accent,2)
 for y in range(112,680,64):body+=path(f'M48 {y} L1232 {y}',stroke='#203a45',sw=1)
 for x in range(64,1240,64):body+=path(f'M{x} 104 L{x} 672',stroke='#203a45',sw=1)
 for x in range(64,1240,128):
  for y in range(112,680,128):body+=path(f'M{x-4} {y} L{x+4} {y} M{x} {y-4} L{x} {y+4}',stroke='#2b4650',sw=1)
 body+=path('M72 520 L72 504 L232 504 L232 520 M1072 672 L1072 660 L1232 660 L1232 672',stroke=accent,sw=2)
 svg(ART/(name+'_bg.svg'),1280,720,body)
svg(ART/'particle.svg',16,16,path('M8 1 L11 5 L15 8 L11 11 L8 15 L5 11 L1 8 L5 5 Z',P,'none')+circ(8,8,2,'#ffffff'))
(ART/'atlas_regions.json').write_text(json.dumps({'schema_version':1,'padding':2,'regions':regions},indent=2)+'\n')
print('Original SVGs and atlas regions written')
