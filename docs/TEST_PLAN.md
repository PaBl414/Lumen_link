# TEST_PLAN — kontrakt 1.0

Źródło: [MASTER_SPEC.md](MASTER_SPEC.md), specyfikacja 1.0 (14 listopada 2026).
Poniższe rozdziały zachowują pełną treść źródła. Opisują wymagania docelowe; stan implementacji podaje [PROJECT_STATUS.md](PROJECT_STATUS.md).

Powiązanie M00: B01 → import i boot dostępnej scenes/app.tscn; runner → normalny exit 0 i wymuszony exit 1; GUI → menu oraz Exit. Dowody: reports/m00/. Pozostałe przypadki nie są implementowane w M00.

## 22. Testowanie i QA

### 22.1 Runner i polecenia

`godot --headless --editor --path . --import` przygotowuje import i klasy. `godot --headless --path . --script tests/test_runner.gd -- --suite=unit` uruchamia unit. Integration uruchamia się z `--suite=integration`; scenariusze wymagające dwóch procesów uruchamiają harness jako osobną scenę z `-- --role=host/client --scenario=...`. Nazwa executable `godot` oznacza przypięty4.5.2, wrapper sprawdza `--version`.

Runner raportuje `passed,failed,skipped,duration_ms`, nazwy przypadków i rzeczywisty exit code. Skip nie jest pass. Błąd parsowania dowolnego wymaganego skryptu kończy test. Jednostki mają stałe seedy. Test audio/render nie może być uznany za wizualnie odsłuchany tylko dlatego, że scena działała headless.

### 22.2 Konkretne przypadki

| ID / plik | Przypadek | Oczekiwany wynik |
|---|---|---|
| C01 test_content | spawny w ścianie,32+ walls,9hazards,brak background | każdy błąd ma path i opis; start mapy zablokowany |
| C02 test_content | wszystkie3 mapy×3 warianty×2trudności | schema i safety zones poprawne, reachable socket/exit |
| M01 test_movement |600tick ruchu diagonalnego bez ścian | długość velocity≤240+epsilon; brak√2 boost |
| M02 test_movement | dash od postoju przez10tick | dokładnie120units bez ściany;11tick już NORMAL |
| M03 test_movement | dash serial powtórzony100razy | jeden zryw; ponowny dopiero nowy serial i cooldown0 |
| K01 test_collision | dash w ścianę i diagonal w narożnik | brak przejścia, slajd zgodnie znormalną, odchyłka≤0,02 |
| K02 test_collision | dwie ściany o tym samym czasie kontaktu | stałe tie-break niezależne od kolejności tablicy |
| L01 test_link | długość55,56,720,721 | inactive,active,active,inactive przy pozostałych warunkach |
| L02 test_link | socket zmienia łamaną; jeden odcinek zasłonięty | poprawna trasa, OCCLUDED; zero charge |
| L03 test_link | beacon przecięty w20units od gracza | brak ładowania; przy48unit ładowanie |
| O01 test_objectives |300tick poprawnego przewodu | beacon complete; następny nie dostaje charge w tym samym ticku |
| O02 test_objectives | charge100, brak zasilania30+10tick |100 przez30tick, potem95 |
| O03 test_objectives | exit120tick oba wewnątrz;119tick | sukces tylko120; wyjście jednego resetuje extract_ticks0 |
| H01 test_hazards | brzeg telegraph/active i wszystkie offsety | dokładne fazy z §6, obrażenie tylko active |
| H02 test_hazards | dwa trafienia w jednym ticku | integrity−1, oba stun12/invuln90 |
| H03 test_hazards | zryw przez pulse i zwykły ruch przez pulse | dash bez trafienia, normal z trafieniem; swept path nie tuneluje |
| S01 test_simulation | hazard zabija i exit kończy w tym samym ticku | FAILED ma pierwszeństwo |
| S02 test_simulation | extract kończy przyremaining1 | sukces i premia remaining1/60=0 |
| S03 test_simulation | snapshot zmodyfikowany po capture | WorldState bez zmian; brak aliasu players/charges |
| I01 test_input | menu,focus loss,remap capture | neutral axis, brak przypadkowych nowych seriali |
| P01 test_protocol | literal Ping z §19 |30 B, echo1000, typ12, wartości header zgodne |
| P02 test_protocol | każda wiadomość round-trip + trailingbytes | round-trip zgodny; trailing bytes odrzucane |
| P03 test_protocol | truncacja na każdej granicy,NaN,Infinity,bad enum,big count | brak crash i brak częściowej mutacji |
| P04 test_protocol | sequence wrap FFFFFFFF→0; stare match/sector | poprawne newer, stare generacje ignorowane |
| PR01 test_prediction | spokojny ruch i60 Hz input/30 Hz snapshot | po reconcile błąd core≤0,1unit, historia≤256 |
| PR02 test_prediction | host odrzuca dash i zgłasza stun | klient przyjmuje pełen stan; brak ponownego dash z tego serialu |
| PR03 test_prediction | straty20%,duplikaty10%,reorder20%,RTT100±30 ms | brak podwójnego kosztu/akcji; po2s czystej sieci stan zgodny |
| PS01 test_persistence | malformed,unknownschema,readonly folder | defaults albo zapis w pamięci; brak utraty działającej sesji |
| B01 test_boot | czysty import i brak assetu | boot działa albo precyzyjny błąd przed Lobby |
| N01 test_network | localhost dwa realne procesy ENet | connect≤2s,ready i Begin, zgodny session/match/hash |
| N02 test_network | Windows host/Linux client i odwrotnie bez internetu | pełna ekspedycja i rewanż, zero zewnętrznych połączeń |
| N03 test_network | utrata snapshotów500 ms | brak crash, freeze po250 ms, powrót po nowym snapshot |
| N04 test_network | kill host/client | partner kończy w≤3,5s, port zwalnia, można hostować ponownie |
| N05 test_network | zajęty7777,brakbroadcast,trzeci klient | czytelne błędy, directIP działa przy dostępnym gameport |
| N06 test_network | ten sam pakiet InputBatch30razy | brak31-krotnego ruchu; najwyżej jeden step/tick |
| F01 test_flow | loading timeout i late Loaded | Lobby gotowość0; spóźnione Loaded ignorowany |
| F02 test_flow |30pełnych rematch/leave cycles | signal count stały, brak obiektów starej sceny, limit RAM |
| V01 test_presentation | wszystkie stany w 720p,1080p,ultrawide | brak clippingu, ta sama widoczna przestrzeń |
| U01 test_ui | pełna nawigacja keyboard/pad bez myszy | wszystkie akcje dostępne, focus nigdy nie ginie |
| U02 test_ui | ui_scale1,3/reduced motion/colorfilter | tekst mieści się, sygnały widoczne bez rozróżniania barw |
| A01 test_audio | predicted dash i event tego samego serialu | jeden dźwięk; przy pełnej puli hit priorytet zachowany |
| A02 test_audio |30min loop i zmiany głośności | brak klików,przesteru i narastających instancji; odsłuch manualny |

### 22.3 Testy sieci pod obciążeniem

Profile: LAN nominal RTT<20 ms/loss0, Wi-Fi RTT50±20 ms/loss2%, stres RTT100±30 ms/loss10%, awaria loss100% przez4s. W stresie gra ma pozostać ukończalna, bez rozjazdu integrity/beaconów i bez zakleszczenia; nie obiecywać braku widocznych korekcji. Fixture input plus log hosta jest prawdą odniesienia, nie porównanie renderowanych pozycji w różnych czasach.

FaultLink testuje aplikacyjne opóźnienia, reorder i utratę danych. Realne zachowanie ENet reliable i fragmentacji trzeba sprawdzić przy ograniczeniu sieci na maszynie testowej lub zewnętrznym proxy UDP; aplikacyjny drop po ENet nie testuje jego retransmisji. Do wyniku dopisać użyte narzędzie i parametry; brak takiego środowiska pozostawia test pending.

### 22.4 Odbiór release

Windows10/11 x64 z obsługiwanym sterownikiem OpenGL; Linux x86_64 minimum jedna stabilna dystrybucja oraz Arch jako dodatkowy test. Weryfikacja na czystym koncie bez Godota i bez narzędzi developerskich. Rozpakowanie do ścieżki ze spacjami i polskimi znakami, brak praw zapisu przy executable, zapis do user://. Na Linux executable bit w archiwum tar.gz; na Windows zip. Obie paczki zawierają licencje, README i wspólny content manifest. Nie obiecywać podpisu cyfrowego ani braku systemowego ostrzeżenia dla niepodpisanego pliku.

