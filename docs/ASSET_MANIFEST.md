# ASSET_MANIFEST — kontrakt 1.0

Źródło: [MASTER_SPEC.md](MASTER_SPEC.md), specyfikacja 1.0 (14 listopada 2026).
Poniższe rozdziały zachowują pełną treść źródła. Opisują wymagania docelowe; stan implementacji podaje [PROJECT_STATUS.md](PROJECT_STATUS.md).

Stan M11a/b: wszystkie wymagane assety graficzne i fonty z §8.3 dostarczone i używane.
Grafika SVG jest własna, grain PNG jest deterministycznie wypiekany przez asset_bake.gd.
Fonty pochodzą z oficjalnego repozytorium Google Fonts, z niezmienioną OFL1.1.
Audio z §10 pozostaje NOT IMPLEMENTED do M13; nie jest częścią odbioru M11.
Rejestr dostarczonych plików i dowody renderowania znajdują się poniżej.

## 8. Kierunek artystyczny i produkcja assetów

### 8.1 Styl

Precyzyjna grafika 2D z miękkimi, lekko ilustracyjnymi kształtami. Stacja przypomina połączenie ceramiki i starego przyrządu optycznego. Bez realistycznych tekstur i bez stylistyki wojskowego HUD. Dron A ma okrągłą sylwetkę i dwa krótkie stabilizatory; B jest zaokrąglonym rombem z wycięciem. Rozróżnienie działa również w skali szarości.

Paleta: tło `#101B2 B`, panel `#1C2C3C`, powierzchnia `#344A58`, porcelana `#DCE8DE`, światło A `#66E0C2`, światło B `#FFBE78`, aktywny przewód `#E9F6BF`, zagrożenie `#F07178`, telegraph `#F4D27A`, tekst `#F2F5EF`, tekst wtórny `#B3C2C6`. Czerwony nigdy nie jest jedynym sygnałem obrażeń: dodaj obrys, ikonę i animację.

Dron: rdzeń 40×40 w ramce 64×64; collider 24×24 jest zaznaczany delikatnym cieniem centralnym. 65% jasny korpus, 20% kolor identyfikacji, 15% ciemne detale. „Twarz” to pojedynczy sensor, bez konieczności animowania kończyn.

### 8.2 Animacje i efekty

Dron ma wektorowy korpus i osobny sensor; animacje transformacjami: idle bob ±1,5 px/1,8 s; move lean max8° i squash 0,96×1,04; dash stretch 1,18 w osi ruchu przez 0,07 s; hit flash 0,08 s; stun drganie 2 px/0,12 s; odporność obrys pulsujący 4 Hz, bez ukrywania sylwetki.

Nie potrzeba klatek sprite sheet dla dronów: to **docelowy styl animacji części**, a nie placeholder. Wymagane klipy AnimationLibrary: `idle` 1,8 s loop, `move` 0,5 s loop, `dash` 0,167 s, `hit` 0,2 s, `celebrate` 1 s. Stan gry wyzwala klipy, nigdy odwrotnie. Efekty charge i hazard wynikają z parametrów shaderów.

Przewód ma linię rdzenia 3 px i dwie szersze, półprzezroczyste warstwy 8/16 px. Brak pełnoekranowego bloom. Przy zerwaniu przez ścianę rysuje się przerywany przebieg i znacznik blokady. Zakończenie beaconu: pierścień rozszerzający się 24→92 px przez 0,4 s, 20 drobin, zmiana dekoracyjnych kabli sektora.

Screen shake tylko lokalny, renderingowy: trafienie max3 px, 0,16 s; beacon max1,5 px, 0,1 s. Domyślnie 50%, możliwość 0%. Brak zatrzymywania hostowej symulacji dla hit-stop. Wizualne spowolnienie efektu trafienia może trwać 40 ms, lecz nie zmienia drona ani wejścia.

### 8.3 Manifest assetów

Wszystkie ścieżki względem katalogu projektu. SVG importowane do rastra przez Godot w skali 1. Dla SVG wymagane poprawne `viewBox`; bez zewnętrznych obrazów, fontów i skryptów. Grafika źródłowa jest własna. Font dostarczony z licencją OFL; nie pobierać go podczas uruchamiania gry.

| ID / ścieżka | Format i wymiary | Cel i animacja | Alpha / zależności |
|---|---|---|---|
| `drone_a`: assets/art/drone_a.svg | SVG 64×64 | korpus A, transformacje klipów | tak; drone.tscn |
| `drone_b`: assets/art/drone_b.svg | SVG 64×64 | korpus B | tak; drone.tscn |
| `sensor`: assets/art/sensor.svg | SVG 16×16 | osobna pozycja sensora 0–2 px | tak |
| `station_atlas`: assets/art/station_atlas.svg | SVG 1024×1024 | 16 kafli 256×256; ceramiczna podłoga/ściana | tak; atlas_regions.json |
| `devices`: assets/art/devices.svg | SVG 512×256 | osiem komórek128×128: beacon off/on, socket off/on, exit off/on, pulse, sweep emitter | tak; atlas_regions.json |
| `icons`: assets/ui/icons.svg | SVG 512×256 | 32 komórki64×64, pierwsze16: ruch,zryw,socket,ping,ready,host,join,back,sound,settings,warning,heart,star,clock,link,exit | tak; pozostałe przezroczyste |
| `title`: assets/ui/title.svg | SVG 640×160 | własny logotyp typograficzny wektorowy | tak |
| `grain`: assets/art/grain.png | PNG 128×128 | subtelna ziarnistość tła, bez animacji | nie; shader opcjonalny |
| `particle`: assets/art/particle.svg | SVG 16×16 | drobina; jeden wspólny materiał | tak |
| `font`: assets/fonts/AtkinsonHyperlegible-Regular.ttf | TTF | UI z polskimi znakami | licencja assets/fonts/OFL.txt |
| `font_bold`: assets/fonts/AtkinsonHyperlegible-Bold.ttf | TTF | nagłówki i wynik | ta sama licencja |
| `dock_bg`: assets/art/dock_bg.svg | SVG 1280×720 | dalekie rury, dok, spokojny granat | nie; mapa dock |
| `garden_bg`: assets/art/garden_bg.svg | SVG 1280×720 | roślinne ornamenty, mięta | nie |
| `reactor_bg`: assets/art/reactor_bg.svg | SVG 1280×720 | miedziane pierścienie, cieplejszy kontrast | nie |

`assets/art/atlas_regions.json`: mapowanie ID na całkowite `x,y,w,h`, margines bezpieczeństwa 2 px wewnątrz komórek. `AssetCatalog` tworzy współdzielone AtlasTexture podczas bootu. Żadne assety nie są ładowane z sieci.

Pipeline: szkic proporcji → SVG w edytorze wektorowym → import i podgląd w 720p → test w skali szarości → dopiero detale. Tła mogą być proceduralnie komponowane z własnych kształtów; seedy dekoracji nie wpływają na symulację. Narzędzia generatywne tylko do inspiracji lub dekoracyjnych teł, nigdy do kolizji, napisów, masek i atlasów wymagających dokładnych regionów. P0 nie wymaga ich użycia.

## 10. Audio

Buses: `Master → Music`, `Master → SFX`, `Master → UI`, `Master → Ambience`. Master domyślnie0,8; Music0,5; SFX0,8; UI0,7; Ambience0,4. Slider0–1 mapowany przez `linear_to_db`, zero wycisza bus. Wszystkie ustawienia zapisują się lokalnie.

Muzyka: własna, oszczędna synteza, 96 BPM. Jeden utwór 80 s (32 takty4/4) w trzech zgodnych długością stemach: base, pulse, resolve. Start wspólny lokalnie przy starcie sektora; miks zmienia się płynnie250 ms zgodnie z postępem. Nie synchronizować audio sample-by-sample przez LAN. W P0 można wygenerować utwór offline przy użyciu `tools/asset_bake.gd`, ale musi mieć kompozycję, zmianę harmonii co8 taktów i ręcznie sprawdzony loop; przypadkowe tony nie przechodzą odbioru.

| Asset / ścieżka w assets/audio/ | Format | Trigger | Reguła |
|---|---|---|---|
| music_base.ogg; music_pulse.ogg; music_resolve.ogg | OGG48kHz stereo,80s każdy | start i postęp sektora | wspólny czas startu, loop bez kliknięcia |
| ambience.ogg | OGG48kHz stereo,20s | wejście na mapę | cicho, loop, fade300 ms |
| move.wav | WAV48kHz16-bit mono,1s loop | prędkość>20 | cichy silnik, pitch0,95–1,05, niezależne instancje |
| dash.wav | WAV48kHz16-bit mono,0,18s | przyjęty/predykowany zryw | deduplikacja po player+dash_serial |
| socket.wav | WAV mono,0,2s | przyjęcie socketu | autorytatywne zdarzenie |
| charge.wav | WAV mono,1s loop | aktywne ładowanie | pitch zależy od charge, nie tworzyć instancji co tick |
| beacon.wav | WAV mono,0,65s | ukończenie celu | priorytet8 |
| hit.wav | WAV mono,0,25s | trafienie | priorytet10, kompresja bez przesterowania |
| telegraph.wav | WAV mono,0,15s | start telegraph | priorytet6, max2/100 ms |
| ping.wav | WAV mono,0,18s | ping partnera | priorytet4 |
| ui_focus.wav; ui_accept.wav; ui_back.wav | WAV mono,0,05/0,1/0,1s | UI | debounce focus40 ms |
| victory.wav; defeat.wav | WAV stereo,1,5s/1s | wynik | przerwanie charge i wygaszenie ambience |

Maksymalnie24 głosy SFX,2 ciągłe silniki,1 charge,3 music,1 ambience. Pula AudioStreamPlayer2D dla efektów świata, UI bez panoramy. Panorama delikatna: zakres stereo ograniczony do0,5. Przy pełnej puli odrzuć najniższy priorytet albo najstarszy efekt tego samego typu. Dźwięk zagrożenia nigdy nie jest jedynym ostrzeżeniem.

Zdarzenia symulacji są jedynym źródłem hit/beacon/socket/result. Pojawienie się zmiany w snapshot może odtworzyć wizualny stan nawet po utracie eventu, ale nie musi odtwarzać dawnego dźwięku. Network snapshot nie jest zegarem odtwarzania sampli.


## Dostarczone M11a — źródła i sumy

Grafika: własna, bez zewnętrznych obrazów/napisów/fontów w SVG; odtwarzalny generator
`tools/art_sources.py`. Grain: własny generator Godot `tools/asset_bake.gd`, seed110011.
Font: [oficjalna dystrybucja Google Fonts](https://github.com/google/fonts/tree/95f4904fc8bcf26d3420fe315560c96417c6dec7/ofl/atkinsonhyperlegible),
OFL1.1, niezmodyfikowane pliki; licencja i dokładne URLs w assets/fonts/OFL.txt/SOURCE.json.
Licencja całego projektu nadal wymaga decyzji; THIRD_PARTY_NOTICES.md zachowuje rozdział praw.

| Plik | Wymiary / typ | SHA-256 |
|---|---|---|
| `assets/art/devices.svg` | 512×256 SVG | `911752a8f09f3d3feeaf3ff45d143286574447bf5082050795bdf4f6912c2bb2` |
| `assets/art/dock_bg.svg` | 1280×720 SVG | `4628915766828c661639eeabcb7c7016ce45de4eb8fc1203cf319c47d67feab0` |
| `assets/art/drone_a.svg` | 64×64 SVG | `e0f5e8bf7a201763f04996377056c1c659d8a7709bd0b66dc4d3845dac279792` |
| `assets/art/drone_b.svg` | 64×64 SVG | `3edf411de682424ba0a4d5951ba6117a75ca96a590257204122ca4113b9bd509` |
| `assets/art/garden_bg.svg` | 1280×720 SVG | `8783a8860ce0cfc8ceef5b5891cb60dfb44ccdeaec5917fa02a226e00e5e3173` |
| `assets/art/grain.png` | 128×128 RGB8 PNG | `b282fc75874b4d5a4c61a7d8fcfcd0be88ca78d5178e3778983cda59864bbf39` |
| `assets/art/particle.svg` | 16×16 SVG | `6bbfd7bfa429272fbc67d70e11cb8ec9089465e44bdc7e85e6edd7c5403da105` |
| `assets/art/reactor_bg.svg` | 1280×720 SVG | `75f57e2953748a68054411219c8bbb74eb2a29d9f57893db1c1086ab6c3a8f52` |
| `assets/art/sensor.svg` | 16×16 SVG | `0ec375ba44d8051c6c28e49035c91739a6359d40288843c753812d09e95e4c6d` |
| `assets/art/station_atlas.svg` | 1024×1024 SVG | `1b8f5e9473a2a08e3368298166302fcb2cf34bbb5a36c07a24cce62ed98531c2` |
| `assets/fonts/AtkinsonHyperlegible-Bold.ttf` | TTF / OFL1.1 | `5a3b0c8cc8ca545155150b4512a1fa248298df121c50d6557e651e61fbdab92f` |
| `assets/fonts/AtkinsonHyperlegible-Regular.ttf` | TTF / OFL1.1 | `7fb917c89019896d0b52ee84b7cbb3304c18cb90b19a62f5e32712bd23e97669` |
| `assets/ui/icons.svg` | 512×256 SVG | `919ae16615e3d0145933dff638d4ead15ca2a5c7db054a30d07b6dae0c736ddf` |
| `assets/ui/title.svg` | 640×160 SVG | `c7e24a05de75d6947003ac681a684c13044406515c2e7d636e34f0dc4e7e45e1` |

Atlasy: station1024²/16komórek256², devices512×256/8komórek128², icons512×256/32komórki64²
(pierwsze16 wypełnione). Każdy region ma2px marginesu. AtlasTexture.filter_clip=true;
SVG importowane w skali1, duże atlasy/tła mają mipmaps, świat filtruje linear+mipmaps.
Wspólne źródła są współdzielone, materiały per beacon/emitter mają tylko własne uniformy.
Nie dodano bitmapowych zdjęć ani generatywnych dekoracji. Tła są autorskimi kompozycjami
rur, liści i pierścieni, a nie geometrią kolizji.

## Odbiór M11b

idle1.8s/move0.5s/dash0.167s/hit0.2s/celebrate1s w AnimationLibrary; ruch części
Visual nie zmienia collidera. Bob1.5px, lean8°, squash0.96×1.04, stretch1.18,
flash0.08s, stun2px/0.12s, outline4Hz. HUD w CanvasLayer10, świat na warstwach §20.
Przewód3/8/16px z wygaszaniem podczas dash i markerem blokady. Trzy proste canvas
shadery Compatibility, bez bloom. FX128 obiektów /320 drobin high lub160 low.
Najnowsze dekoracyjne pierścienie:16 high /8 low; stary nadmiar pomijany w rysowaniu,
stan celów/hazardów pozostaje widoczny. Segmenty pierścieni batchowane, drobiny
w PackedArrays bez słowników na cząstkę. Reduced motion wyłącza bob/lean/stretch,
rozrzut, animację przepływu i shake, zachowując kontury, ostrzeżenia oraz postęp.

Dowody: docs/reports/m11/ — asset-board i trzy mapy w kolorze i skali szarości,
active-link/dash-stun/occluded/high-stress/low-stress/reduced-motion, dokładnie1280×720.
Obrazy pochodzą z natywnego Compatibility/OpenGL, a nie z headless ani makiety.
Grayscale jest konwersją readbacku GPU do L8 wyłącznie do kontroli kontrastu.
Metryki krótkich prób zawiera render-metrics.json; nie są dziesięciominutowym
benchmarkiem release M15 ani gwarancją60FPS. Manualny odbiór nowych duetów M10
pozostaje PENDING i nie jest zastępowany tym przeglądem artu.
