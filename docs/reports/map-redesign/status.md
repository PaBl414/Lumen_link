# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-15. **M11a i M11b: implementacja, C01/V01 i przegląd natywny PASS.**
M12 nie rozpoczęto. M10 testy nowych duetów pozostają PENDING (0/5).
Katalog bez Git, code_revision=`unversioned`; content SHA-256:
`0039c9be838c29b25db3a6e014b368759cfd5e141595a91b4480637fabf72871`.
Historia: [M10](reports/m10/status.md); decyzje: [ADR-0011](ADR.md).

## Aktualizacja — mapy wymagające zagięcia przewodu

Na prośbę użytkownika zastąpiono układy dock/garden/reactor: dziewięć wnęk
z celami i przekaźnikami. Prosty przewód nie może zasilać tych celów; wynika
to z geometrii, bez zmiany reguł LinkSystem/ObjectiveSystem. Zmiana zaczepu
oraz ustawienia obu dronów pozwala doprowadzić światło przez kolejne otwory.
Pomniejszono urządzenia i pierścień postępu dla czytelności wnęk. Zagrożenia
na drogach między nimi są teraz PULSE; SWEEP usunięto z tych trzech map.

Bieżący pełny zestaw: **1119 PASS / 0 FAIL**, 17 suites, exit0, 97357ms.
18 nagrań ukończenia i 6 pełnych kampanii PASS. Certyfikat geometrii9 wnęk
oraz próby bez anchor: zero ładunku na wszystkich mapach. Walidacja map,
assetów i manifestu PASS. Natywny renderer OpenGL: 9 podglądów, bez błędów.
Testy z ludźmi NOT RUN; nie deklarujemy potwierdzonej trudności/zrozumiałości.
Starszy eksport M11 ma wcześniejsze mapy — bieżący stan uruchamiać z projektu.

[Projekt i dowód geometryczny](RELAY_MAP_DESIGN.md) ·
[Wyniki](reports/map-redesign/summary.json) ·
[Podgląd](reports/map-redesign/dock-1.png).
Poniższe wyniki M11 opisują wcześniejszy odbiór grafiki i wydajności.

## M11a — dostarczona grafika i font

Dwanaście assetów graficznych z §8.3: dwa drony, sensor, station/devices atlas,
grain, particle, trzy tła, icons i title. SVG to własne źródła o docelowej palecie:
ceramiczne obudowy, optyczne soczewki, mięta/miedź, rury/dok, liście/garden,
pierścienie/reactor. Zastąpiono rysunki developerskie w normalnym WorldView.
Drony odróżnia sylwetka okrągła/romb z wycięciem, nie tylko kolor.

Atkinson Hyperlegible Regular/Bold pobrano niezmienione z oficjalnego google/fonts,
commit `95f4904fc8bcf26d3420fe315560c96417c6dec7`. Pełna OFL1.1 w assets/fonts/OFL.txt;
URLs, SHA-256 i rozmiary w SOURCE.json. Font działa lokalnie, bez runtime download.
Źródła własne i licencje: [ASSET_MANIFEST](ASSET_MANIFEST.md), THIRD_PARTY_NOTICES.md.
Nie ustalano nowej licencji całego projektu i nie publikowano paczki.

AssetCatalog ładuje wspólne tekstury, tworzy40 AtlasTexture (16station/8devices/16icons)
z padding2/filter_clip. W icons pozostaje16 celowo pustych komórek. SVG import1:1,
duże atlasy/tła mają mipmaps, świat filtruje linear+mipmaps. Walidator sprawdza
wymiary, viewBox, brak zewnętrznych zależności, integer regiony i ich marginesy,
polskie znaki fontu, OFL oraz sumy źródeł fontu. W eksporcie sprawdza też font.data,
gdy importer zastąpił surowy TTF zasobem FontFile.

## M11b — animacje, warstwy, shadery i FX

Pięć rzeczywistych klipów AnimationLibrary: idle1.8s/move0.5s/dash0.167s/hit0.2s/
celebrate1s. Bob±1.5px, lean≤8°, squash0.96×1.04, dash stretch1.18 w osi ruchu,
flash0.08s, stun2px/0.12s, obrys odporności4Hz bez ukrywania sylwetki. DashAxis
obraca oś skali, Art obraca się przeciwnie, więc pionowy dash nie obraca korpusu.
Celebrate jest jednorazowe i ma pierwszeństwo po wygranej nawet przy zamrożonym
PlayerMode.DASH. Root drona pozostaje przy pozycji renderowanej; collider nie skaluje się.

Przewód ma rdzeń3px i halo8/16px; Low jedno halo. Shader dostaje ciągłe UV Line2D.
Nieaktywność jest kreskowana, ściana ma marker X; ładowanie nadal wynika z hosta.
Warstwy §20: teksturowane tło/podłoga/ściany, telegraph, urządzenia, drony,
active hazard nad ścianami i dronami, link, FX. HUD w CanvasLayer10 nie drży z kamerą.

Trzy canvas shadery Compatibility: link przepływ, device charge/telegraph emiterów,
background subtelny grain. Do2 próbek tekstury, bez bloom/Forward+/dynamicznych cieni.
FxPool:128 obiektów, PackedArrays320 drobin High /160 Low, bounded dedup512 oraz
player/dash_serial. Potwierdzenie dash nie powtarza spekulatywnego FX. Pierścień
beacon24→92px/0.4s i20 drobin; hit i socket mają własne wskazanie. Rysowane16/8
najnowszych dekoracyjnych pierścieni, segmenty batchowane zamiast osobnego draw_arc.
Stary nadmiar dekoracji nie zmienia stanu urządzeń ani fizyki. FX wygasa także przy
ukrytym świecie. CameraRig: max3px/0.16s, default shake50%, wyłączenie przy0/reduced motion.
Reduced motion usuwa bob/lean/stretch, rozrzut, przepływ i shake, zachowując informacje.

WorldView.prewarm rysuje trzy materiały, rzeczywiste Line2D, pierścień i cząstki FX
przez dwa frame_post_draw pod pełną zasłoną loading. Dopiero potem AppRoot wysyła
Loaded/startuje countdown; po await sprawdza generation. Headless pomija oczekiwanie
na GPU i nie jest przedstawiany jako test shader warmup. Materiały są przygotowane
przed grą, a nie przy pierwszym dash.

## Pliki i API

Nowe: wszystkie assets/art/*.svg/grain.png/atlas_regions.json i assets/ui/*.svg z planu;
assets/fonts/Regular/Bold/OFL.txt/SOURCE.json; tools/art_sources.py, tools/asset_bake.gd;
presentation/fx_pool.gd; shaders/{link,device,background}.gdshader;
tests/integration/test_presentation.gd oraz presentation_preview.gd/.tscn, UID i import settings.
Zmiany: services/asset_catalog.gd, tools/validate_content.gd, presentation/world_view.gd,
drone_view.gd, link_view.gd, camera_rig.gd, scenes/world.tscn, drone.tscn, app.tscn,
app/app_root.gd, core/game_types.gd (default shake0.5), tests/test_runner.gd,
tests/integration/network_harness.gd (silniejszy export boot sentinel),
tools/build_manifest.gd, manifest, README i docs/notice/status.

API: DroneView.present/play_event/set_reduced_motion; FxPool.emit_event/update_effects/
clear/set_quality/set_reduced_motion; CameraRig.impulse; LinkView.present/set_quality/
set_reduced_motion; WorldView.play_event/prewarm/finish_warmup/apply_settings.
Dane map, reguły, Simulation60Hz, input/snapshot30Hz i wire1 pozostają bez zmian.

## Wykonane sprawdzenia

Godot4.5.2 Standard official, Linux x86_64, Compatibility/OpenGL, Intel HD520.
`godot` to `/home/pablo/.local/bin/godot`. Logi i obrazy: [reports/m11](reports/m11/).

| Polecenie / test | Exit | Wynik |
|---|---:|---|
| `python3 tools/art_sources.py` | 0 | źródła wektorów/regionów, deterministyczny autor |
| `godot --headless --path . --script tools/asset_bake.gd` | 0 | bake.log, grain128² seed110011 |
| `godot --headless --editor --path . --import --quit` | 0 | import.log |
| `godot --headless --path . --script tools/validate_content.gd` | 0 | content.log:3 mapy + art/font/license PASS |
| `godot --headless --path . --script tools/build_manifest.gd -- --write/--check` (osobne wywołania) | 0 | manifest-write.log / manifest-check.log |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | **1019 PASS,0 FAIL**,16 suites; all.log |
| runner `--suite=integration --self-test-failure` | 1 | dokładnie1 zamierzony błąd runnera; self-test.log |
| `godot --path . --display-driver x11 --max-fps 60 tests/integration/presentation_preview.tscn` | 0 | render.log / render-metrics.json, rzeczywisty GPU readback720p |
| dwa natywne AppRoot/LAN, cap60 | 0/0 | gui.commands.json, ruch/zryw, Escape/resume i poprawne opuszczenie |
| Linux debug export (tymczasowy preset poza repo) | 0 | export-import.log, export-linux.log |
| eksport: headless boot oraz dwa procesy ENet | 0 /0/0 | export.commands.json, boot_ready z prawdziwą teksturą title i fontem bold |
| eksport: native OpenGL, F2 i scena z grafiką | 0 | export-native.commands.json / export-native.png |

C01/V01: wszystkie PlayerMode/LinkStatus, durations klipów, oś pionowego dash,
jednorazowa celebration, pełny katalog i padding, dedup, High320/Low160,128 obiektów,
reduced motion i shake0, niezależny collider/HUD, cleanup i wygasanie ukrytych FX.
Zachowane pełne regresje M10:18 success fixtures i6 kampanii, M09 predykcja/faults,
M08 replay pakietu i10 rewanżów. Nie powtarzano fizycznego Windows/LAN ani całego
M09 procesu SIGKILL/loss — raporty historyczne pozostają osobno.

Przegląd natywny: asset-board, dock/garden/reactor, active-link, dash-stun, occluded,
high/low stress, reduced-motion, każdy w kolorze i L8. Obejrzano sylwetki, numerację,
postęp, padding i kontrast ostrzeżeń bez koloru. Obrazy map bazują na rzeczywistej
Simulation i wejściu fixture; dodatkowe przypadki mode/link/FX są jawnie wizualnymi
fixture Snapshot i nie stanowią dowodu zwycięstwa lub playtestu ludzi.

W krótkiej próbie: ≤68 draw calls (max stress67, limit150), High peak320 drobin,
Low peak160, reduced motion0. Pierwszy dash po prewarm: max18.336ms, bez osobnego
skoku kompilacji>50ms. Odczyt GPU/PNG wykonywany poza oknem pomiaru pierwszego dash.
P95 max stress High20.777ms/Low21.803ms w tym biegu: **nie jest to dowód60FPS**.
Budżet GPU8ms, frame pacing, RAM i długi release benchmark pozostają bramką M15.
Nie ma pełnoekranowego bloom ani przezroczystych efektów zasłaniających całe pole;
przewód i cząstki są ograniczone powierzchnią/liczbą, najstarsze pierścienie pomijane.

Native/export smoke jest developerską paczką lokalną poza repo, nie wydaniem ani
publikacją. Font/OFL/JSON są zapakowane; tekstury działają przez remapy importera.
Pomocniki GUI/exportu i ich polecenia zachowano jako `.txt`/JSON w raporcie.
W all.log/self-test.log `Couldn't create an ENet host` jest oczekiwanym negatywnym
testem zajętego portu; finalne logi nie zawierają SCRIPT ERROR/shader errors/crashy.
Wyjście hosta na końcu GUI daje oczekiwane „Partner opuścił grę”.

## Pozostałe bramki

M10 manualnie18 konfiguracji i nowe duety0/5: nadal PENDING/NOT RUN, patrz
[macierz](../tests/manual/playtest_matrix.md). Windows↔Linux, dwa fizyczne komputery,
odbiór60FPS/GPU8ms na release oraz inne GPU pozostają niewykonane jako oddzielne bramki.
Licencja projektu nadal wymaga decyzji. M12 kompletne menu i M13 audio nie rozpoczęto;
M11 nie oznacza ukończenia całej gry.
