# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-15. **M05 — Cykl ekspedycji i lokalny zapis: ukończony, odbiór techniczny PASS**.
Bieżący commit: brak (katalog bez Git). Następny: M06, nierozpoczęty.
Playtest dwóch osób M03/M04 pozostaje NOT RUN jako osobna bramka jakości;
zgodnie z poleceniem użytkownika nie blokował pracy nad M05.
Nie jest to wydanie gry: M05 zawiera wyłącznie developerską ekspedycję dock ×3.
Raport wcześniejszego stanu: reports/m04/status.md.

## Wdrożone funkcje

AppRoot przetrwa całą ekspedycję i posiada SettingsStore, RecordsStore, LogService,
AssetCatalog oraz SceneRouter. Zmienia się tylko world w WorldContainer.
Przepływ: Menu → Loading → Countdown → Playing → Intermission → Loading
(dwa razy), następnie Results po WON/FAILED. Obaj lokalni gracze potwierdzają
Dalej/rematch (1/2 lub dwa przyciski); jedno potwierdzenie nie wystarcza.
F2 jest developerskim resetem całej ekspedycji, Escape anuluje loading.
Menu podczas gry nie zatrzymuje symulacji; wyłącza input i przywraca focus.

SceneRouter.show uruchamia ładowanie sceny przez ResourceLoader threaded API.
poll pobiera scenę dopiero po THREAD_LOAD_LOADED. clear unieważnia generation,
usuwa bieżący world, czyści referencje sektora i blokuje aktywację starego load.
Anulowanie nie czeka synchronicznie na worker; UI pozostaje aktywne.
Boot waliduje mały JSON synchronicznie; nie twierdzimy, że całość startu jest asynchroniczna.

Simulation.reset_sector zachowuje integrity, score, ukończone beacony, globalny tick
oraz ID zdarzeń. Zeruje lokalny tick, drony, timery, cele i historię wejścia.
Wariant/kolejność celów zależą od seed oraz sector_index, mimo powtórzonego dock.
Odliczanie 180 ticków zwiększa tylko globalny tick; czas sektora nie maleje.
Po 3 sektorach naliczany jest WON i jednorazowa premia integrity. Czas rekordu
jest sumą sector_tick, bez loading/countdown/intermission. Wynik pochodzi z Simulation.

SettingsStore: schema1, walidacja typów/zakresów i bindingów, defaults przy braku
lub błędzie pliku, ostrzeżenie i backup .bak dla danych niezgodnych.
RecordsStore: walidacja, kopie, max100, sort score malejąco/czas rosnąco,
oddzielne trudności, submit z wycofaniem pamięci przy błędzie zapisu.
Oba używają tmp+flush+rename; błędy są jawne, nie kończą gry.
LogService: 500 linii w buforze, sanitizacja znaków kontrolnych, 2 MiB ×3 i rotacja.
Zapis wyłącznie do user://, bez sieci. Ostrzeżenia boot/save są wyświetlane.

Pliki użytkownika: settings.json, debug_records.json i lumen.log (z .1/.2).
Rekordy dock ×3 nie trafiają do produkcyjnego records.json. Sam edytor ustawień,
pełne remapowanie i finalny interfejs należą do M12.

## Pliki / API

Utworzono wszystkie 7 plików M05:
app/scene_router.gd; services/settings_store.gd; services/records_store.gd;
services/log_service.gd; services/asset_catalog.gd;
tests/unit/test_persistence.gd; tests/integration/test_flow.gd.

Zmieniono: app/app_root.gd, app/app_state.gd, core/simulation.gd, scenes/app.tscn,
tests/test_runner.gd; dodatkowo tests/integration/test_boot.gd (async fixture),
presentation/world_view.gd (wariant/difficulty widoku), README.md,
docs/ADR.md i PROJECT_STATUS.md. Identyfikatory .gd.uid generuje Godot.

API: SceneRouter.configure/show/poll/clear i scene_ready;
AssetCatalog.load_boot/begin_sector/poll_loading/get_scene/get_texture/get_audio/release_sector;
SettingsStore.load_settings/save_settings/validate/atomic_write;
RecordsStore.load_records/submit/best; LogService.write/flush;
Simulation.reset_sector/start_countdown; AppState.allows/transition.
Opcjonalna zależność katalogu w SceneRouter.configure oraz parametry widoku
są opisane w ADR-0005. Wersja wire nadal 1, brak wdrożonej sieci.
Nie powstały zastępcze MatchSession, UI presenters ani inne moduły z kolejnych etapów.

## Testy i dowody

Godot 4.5.2 Standard, 6ce3de25a, /home/pablo/.local/bin/godot.
Linux/XWayland; rzeczywisty Compatibility/OpenGL, Mesa Intel HD 520.
Pełne komendy i exitcodes: reports/m05/commands.json.

| Polecenie / test | Exit | Wynik i dowód |
|---|---:|---|
| `godot --headless --editor --path . --import` | 0 | PASS, import.log |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | PASS, 245 asercji, 11 suites, 0 failed/skipped; all.log |
| Ten sam runner z `--self-test-failure` | 1 | PASS detekcji celowego błędu; self-failure.log |
| `godot --headless --path . --script tools/validate_content.gd` | 0 | PASS dock; validator.log |
| `godot --path . --display-driver x11` | 0 | PASS menu → ładowanie/odliczanie → gra → menu → Exit; gui.log, menu.png/playing.png |
| Renderowany harness wyniku | 0 | PASS, naturalna gałąź przegranej po skróceniu timera w teście; gui-results-final.log/results-final.png |

Ostatni harness jest wyłącznie testowy: kod do wglądu w
reports/m05/gui_results_harness.gd.txt; nie ma go w produkcyjnej ścieżce aplikacji.
Komendy GUI: reports/m05/gui.commands.json. Screenshoty obejrzano; poprawiono
kontrast panelu wyników. Wynik normalnego scenariusza sukcesu nie był wymuszany.

F01: pełna lokalna ekspedycja w RELAXED, wszystkie 3 warianty dock i 9 beaconów,
ruchem obu dronów przez InputCommand, przy aktywnych hazardach, bez teleportów
ani zmiany integrity/charge. Test używa Simulation do szybkiego odtwarzania wejść,
a AppRoot do przejść loading/countdown/intermission/results. Sprawdza oba głosy,
carry integrity/score/tick, zgodność wariantu widoku, jeden rekord, czas bez countdown,
niezmienny wynik, dwa restarty (z wyników i przez F2), jeden world/listener oraz cleanup.
Anulowany load ma nową generation i nie odtwarza sceny po powrocie do menu.

PS01: brak/corrupt/nowsza wersja settings, backup, poprawny roundtrip, NaN,
ostatni ui_cancel, atomowy rename bez pozostałego tmp, kopia best, trudności,
sort/tie-break, cap100 zapis/odczyt, save error i rollback, uszkodzone rekordy,
log ring/flush i trzy pliki rotacji. Wszystkie regresje M00–M04 nadal przechodzą.

Wstępne testy wykryły: JSON odczytuje liczby jako float (poprawiono walidację
list enumów), oraz błędne traktowanie zakończonego threaded load jako busy
(poprawiono poll). Zawieszoną pierwszą próbę zakończono i powtórzono po poprawce;
nie traktowano jej jako PASS. Końcowe logi nie zawierają błędów silnika/skryptów.

## Ograniczenia

Garden/reactor: pending M10, finalne assety/UI: późniejsze etapy. Wydajność pełnej
gry, Windows, fizyczny pad, dwa komputery/LAN: NOT RUN. Nie są odbiorem lokalnego M05.
Playtest duetem z M03/M04 pozostaje NOT RUN. Nie ma publikacji ani eksportu.
M06 nie został rozpoczęty.
