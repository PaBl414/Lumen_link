import json,struct
from pathlib import Path
root=Path(__file__).resolve().parents[4];out=root/'docs/reports/levels9'
def read(path):return json.loads(path.read_text())
def suite(name):
 rows=[]
 for line in (out/name).read_text().splitlines():
  try:
   value=json.loads(line)
   if 'cases' in value and 'passed' in value:rows.append(value)
  except json.JSONDecodeError:pass
 assert rows and rows[-1]['failed']==0,name
 return {key:value for key,value in rows[-1].items() if key!='cases'}
manifest=read(root/'build_manifest.json');catalog=read(root/'data/levels.json')['levels'];ids=[e['id'] for e in catalog]
full=suite('all-final.log');late=suite('late-inputs-after.log');network=suite('network-final.log');focused=suite('final-focused.log')
fixtures=[]
for id in ids:
 data=read(root/f'tests/fixtures/{id}_success.json');assert data['map']==id and len(data['runs'])==6 and all(r['ok'] for r in data['runs'])
 assert {(r['variant'],r['difficulty']) for r in data['runs']}=={(v,d) for v in range(3) for d in range(2)}
 fixtures.extend(data['runs'])
lan={};disk={}
for difficulty,label,port in [(0,'normal',25900),(1,'relaxed',25932)]:
 folder=out/f'lan-{label}';processes=read(folder/'lan-processes.json');assert processes['ok']
 reports=[read(folder/f'lan-d{difficulty}-{role}.json') for role in ['host','client']]
 assert all(r['ok'] and r['phase']==3 and r['begins']==9 and sorted(r['levels'])==sorted(ids) and all(x['saved'] for x in r['levels'].values()) for r in reports)
 assert reports[0]['levels']==reports[1]['levels'] and not reports[1]['client_has_simulation']
 lan[label]={'ok':True,'exit_codes':[r['exit_code'] for r in processes['results']],'levels':reports[0]['levels'],'final_score':reports[0]['score'],'final_integrity':reports[0]['integrity'],'content_hash':reports[0]['content_hash'],'latches':reports[0]['latches_by_sector'],'report_directory':str(folder.relative_to(root))}
 for role in ['host','client']:
  path=Path.home()/f'.local/share/godot/app_userdata/LUMEN LINK/harness_{role}_{port}_progress.json';data=read(path)
  assert data['schema_version']==1 and sorted(data['completed'])==sorted(ids)
  for id in ids:
   row=data['records'][id][label];result=reports[0]['levels'][id]
   assert row['best_score']==result['score'] and row['best_time_ticks']==result['ticks']
  (out/f'disk-{label}-{role}.json').write_text(json.dumps(data,indent=2)+'\n');disk[f'{label}-{role}']=True
exports=read(out/'export.commands.json');assert all(row['exit_code']==0 for row in exports)
progress=read(out/'progress-restart.json');assert progress['ok']
images={p.name:list(struct.unpack('>II',p.read_bytes()[16:24])) for p in out.glob('*.png')};assert len(images)==12 and all(size==[1280,720] for size in images.values())
assert 'Manifest PASS' in (out/'manifest-check.log').read_text()
summary={'build':manifest,'catalog':catalog,'full_regression':full,'terminal_input_regression':late,'fresh_network_protocol_tests':network,'focused_runtime_ui_and_heart_tests':focused,'completion_fixtures':{'count':len(fixtures),'levels':9,'difficulties':2,'variants':3,'ok':True,'max_ticks':max(r['ticks'] for r in fixtures)},'lan':lan,'disk_after_process_exit':disk,'progress_restart':progress,'export_commands':exports,'native_images':images,'original_maps':read(out/'original-maps.json'),'not_run':['human playtest / fun and subjective difficulty','LAN on two physical computers','Windows runtime','full performance/release benchmark'],'ordering_note':'The23-suite full regression used final map geometry; the subsequently added terminal-input fix was verified separately by4 focused regressions,145 fresh protocol/LAN assertions and the complete Relaxed campaign. Normal campaign used the same final maps before this guard-only fix.'}
(out/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n')
status=f'''# PROJECT_STATUS — LUMEN LINK

**Rozszerzenie do9 poziomów ukończone.** M00–M11c pozostają wykonane. M12a jest częściowo wykonany: katalog, wybór/podgląd poziomów, trudność, odblokowania, kontynuacja, rekordy i trwały zapis. Pełne menu/ustawienia M12, audio M13 i wydanie/odbiór M14–M15 nadal wymagają dalszej pracy.

## Zmiany i poziomy

Jeden uporządkowany katalog stabilnych ID: `data/levels.json`. Przepływ/UI/sieć/zapis nie zakładają trzech map; limit64 to limit formatu. Dock, Garden i Reactor zachowują identyczne dane względem końcowego generatora M11c (original-maps.json). Sześć nowych map ma po trzy cele i wspólną ewakuację:

| Poziom | Zadanie obu graczy |
|---|---|
|4. Rozdzielnia|Wybór między dłuższą bezpieczną trasą a krótszym ramieniem/przejściem przy PULSE, potem inny narożnik i odłączenie zaczepu.|
|5. Kanały serwisowe|Osobne drogi nad/pod długą przegrodą, inne zagrożenia po obu stronach i synchronizacja przy zaczepach.|
|6. Obserwatorium|Bezpieczna nauka przesłony, wybór otwartego ramienia między dwoma zaczepami i dwa etapy orbity.|
|7. Komora zakłóceń|Opuszczanie JAM kolejno przez różnych graczy, powrót do stanowisk i odbudowa wiązki.|
|8. Rdzeń pomocniczy|Trzy dwufazowe zadania, przełączanie zaczepów i wybór krótkiego ryzykownego albo zewnętrznego dojścia.|
|9. Serce stacji|Trzy dwufazowe obwody, zmiany obu końców i operatora zaczepu, PULSE/SWEEP/SHUTTER/JAM, potem ewakuacja. Dolna część lewego pola pierwszego celu daje czytelne schronienie przed SWEEP.|

Przesłona optyczna w aktywnej fazie blokuje oba odcinki przewodu, przepuszcza drony i nie rani. JAM wyłącza całą parę po kontakcie collidera dowolnego drona; odporność/zryw nie anulują zakłócenia. Oba typy mają dane cykli i faz hosta, obrys, zapowiedź i komunikat. Pełny snapshot protokołu3 zawiera stabilne ID, zatrzaski150 i maski przeszkód. Znacznik blokady wypada na rzeczywistym zablokowanym odcinku.

Ruch240, zryw720/10 ticków/cooldown90, wspólne zdrowie, limit przewodu720, geometria kolizji i ładowanie300 pozostają zachowane. Każdy poziom zaczyna się od integralności6/9, czasu i wyniku0; punkty i zdrowie nie przechodzą między mapami. Dalej/powtórka/wybór wymagają dwóch zgodnych głosów.

## Wybór i zapis

Ekran wyboru pokazuje numer/nazwę, rzeczywisty podgląd, blokadę/ukończenie i rekordy Normal/Relaxed. Ten sam selektor działa w menu i lobby hosta. Host zmienia mapę/trudność/seed, zerując obie gotowości. Gość widzi wybór przed gotowością i może wejść do mapy odblokowanej przez hosta.

`user://progress.json`, schema1: ukończenia po ID, rekordy według trudności i ostatni wybór. Odblokowania wyliczane z katalogu; pierwsza mapa dostępna od razu, ukończenie otwiera następnik. Kontynuuj wybiera pierwszy nieukończony; po całej kampanii zostaje wybór z informacją o ukończeniu. Zapis po każdym zaakceptowanym zwycięstwie, atomowe zastąpienie, `.bak` poprzedniej poprawnej generacji, odzyskiwanie, walidacja, ochrona nowszego schematu, reset z potwierdzeniem i komunikat IO z zachowaniem postępu w pamięci.

Gość zapisuje dopiero reliable wynik hosta; sam snapshot WON, porażka ani rozłączenie przed potwierdzeniem nie zaliczają mapy. Stare records.json/debug_records.json są zachowaną historią kampanii i nie stanowią dowodu ukończenia poziomów. M12 musi rozwijać LevelSelectPresenter i ProgressStore, bez drugiego ekranu lub konkurencyjnego magazynu.

## Faktycznie wykonana weryfikacja

| Zakres | Wynik / dowód |
|---|---|
| Pełna regresja końcowych map | **{full['passed']}PASS /0FAIL /0SKIP**,{full['suite_count']} zestawy,{full['duration_ms']}ms — reports/levels9/all-final.log |
| Ukończalność bez teleportów |54 konfiguracje(9×2 trudności×3 fazy),6 pełnych kampanii i przejście aplikacji; rzeczywiste InputCommand/RLE. Aktualne nagrania w tests/fixtures; ostatnie6 finału w heart-recordings-final.log.|
| Spóźnione wejścia po wyniku |Regresja przed poprawką wykazała rozłączenie; po poprawce **{late['passed']}PASS**. Host nadal sprawdza tożsamość/sekwencję/limity, ale nie symuluje wejść po końcu.|
| Świeże testy protokołu/LAN po poprawce |**{network['passed']}PASS /0FAIL** — network-final.log; wybór/ready, gość z lokalną blokadą, reliable potwierdzenie, odzyskanie zatrzasku i reset.|
| Końcowe testy runtime/UI/finału |**{focused['passed']}PASS /0FAIL** — final-focused.log |
| Pełne LAN Normal |9/9,WON,exit0/0,identyczne wyniki obu ról; finał{lan['normal']['final_score']}pkt,integralność{lan['normal']['final_integrity']} — lan-normal/ |
| Pełne LAN Relaxed |9/9,WON,exit0/0,identyczne wyniki obu ról; finał{lan['relaxed']['final_score']}pkt,integralność{lan['relaxed']['final_integrity']} — lan-relaxed/ |
| Pliki po zamknięciu procesów |4 pliki testowe mają9 ukończeń i rekordy zgodne z wynikami; disk-*.json |
| Restart/recovery/reset |4 scenariusze w osobnych procesach i rzeczywistej AppRoot, historyczny plik bez zmian — progress-restart.json |
| Kolejność katalogu |Test odwróconego katalogu zachowuje rekordy/ukończenia po ID; wire ładuje ID z nowym ordinalem.|
| Prezentacja |12 natywnych zrzutów1280×720: selektor świeży/ukończony,9 map i schronienie finału. Sprawdzono nowe mapy i selektor. To kontrola techniczna, nie playtest.|
| Eksporty |Import, Linux x86_64, Windows x86_64 debug, Linux boot oraz ENet host/gość: wszystkie exit0 — export.commands.json |
| Manifest |PASS — manifest-check.log |

Pełna regresja23 zestawów obejmuje końcową geometrię; po jej starcie dodano poprawkę spóźnionych wejść. Tę zmianę sprawdzono oddzielną regresją4 przypadków,145 testami i pełną kampanią Relaxed. Kampania Normal przeszła na tych samych końcowych mapach przed samą poprawką guardu. Nie sumujemy zachodzących na siebie zestawów jako nowych niezależnych testów. Błąd zajętego portu w pełnej regresji jest oczekiwanym testem negatywnym; brak SCRIPT ERROR/Parse Error. Historyczne nieudane próby i przerwane przebiegi są w attempts/; summary.json zawiera wyłącznie wskazane końcowe dowody.

## Pozostaje dla ludzi

Playtest frajdy, intuicyjności i odczuwalnej trudności: **NOT RUN**. LAN testowano dwoma procesami Linux/loopback, nie dwoma fizycznymi komputerami. Runtime Windows: NOT RUN (wykonano eksport). Pełny benchmark60FPS i odbiór wydania: NOT RUN. Nagrania dowodzą istnienia rozwiązań, nie braku każdego możliwego skrótu w przestrzeni ciągłej. Fixtures techniczne przygotowujące wynik/latch nie są przedstawiane jako przejście mapy.

## Uruchomienie i materiały

Godot4.5.2 Standard → Wybierz poziom / LAN → Kontynuuj albo Zagraj wybrany poziom → pokój/gotowość/start. WASD/Spacja/E/Q; lokalny test F2: drugi gracz IJKL/Shift/U/O. Escape pokazuje menu bez pauzowania hosta.

Eksporty developerskie poza repo: `~/.local/share/lumen-tools/levels9-smoke/linux/` i `windows/` (oddzielne PCK). Nie są wydaniem dystrybucyjnym. [Poziomy/rozwiązania](LEVELS9.md) · [Zapis i wybór](PROGRESS.md) · [Odbiór ręczny](LEVELS9_MANUAL.md) · [Protokół](NETWORK_PROTOCOL.md) · [Wyniki](reports/levels9/summary.json).

Build `{manifest['build_label']}`, protocol3, schema zapisu1, code_revision=unversioned.
Content SHA-256: `{manifest['content_sha256']}`.
Historia M11c: reports/m11c/PROJECT_STATUS_FINAL.md.
'''
(root/'docs/PROJECT_STATUS.md').write_text(status)
print(json.dumps({'ok':True,'regression':full['passed'],'normal_levels':len(lan['normal']['levels']),'relaxed_levels':len(lan['relaxed']['levels']),'disk_checks':len(disk)},ensure_ascii=False))
