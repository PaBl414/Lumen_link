# M03 — rozpoczęty, odbiór PENDING

Dodano core/link_system.gd i core/objective_system.gd oraz integrację z core/simulation.gd.
Implementacja robocza: geometria przewodu, wybór socketu, cooldown, ładowanie i decay.
Nie ukończono prezentacji przewodu/postępu, dedykowanych testów L01–L03/O01–O02,
zdarzeń socketu, komunikatu poza zasięgiem ani testu gry duetem. M03 nie jest odebrany.
Ostatni odebrany etap: M02. Nie rozpoczęto M04.
Regresja: `/home/pablo/.local/bin/godot --headless --path . --script tests/test_runner.gd -- --suite=all`
exit 0, 143 PASS, 0 failed; docs/reports/m03/regression.log. To testy wcześniejszych
etapów, nie dowód poprawności wszystkich nowych reguł M03.

Poniżej zachowany raport odebranego M02:

# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-15. Kontrakt 1.0. Etap: **M02 — Ruch dwóch dronów i zryw**.
Kod ukończony; odbiór M02: **PASS**.
Ostatni odebrany etap: M02. Następny: M03, nierozpoczęty.
Bieżący commit: brak (katalog bez Git). Raporty historyczne: reports/m00/status.md,
reports/m01/status.md. To nie jest kompletna gra ani release candidate.

## Pliki i działające moduły

Utworzono wszystkie 15 plików z Promptu M02:

- core/input_command.gd, core/world_state.gd, core/game_snapshot.gd,
  core/game_event.gd, core/movement.gd, core/simulation.gd.
- app/input_router.gd.
- presentation/world_view.gd, presentation/drone_view.gd, presentation/camera_rig.gd.
- scenes/world.tscn, scenes/drone.tscn.
- tests/unit/test_movement.gd, tests/unit/test_input.gd, tests/unit/test_simulation.gd.

Zmieniono app/app_root.gd, scenes/app.tscn, tests/test_runner.gd oraz
core/game_types.gd (kolejność MatchPhase zgodna z normatywnym §19.4),
tests/integration/test_boot.gd (regresja fixture/focus/menu), README.md,
docs/ADR.md i niniejszy status. Dodatkowo Godot generuje .gd.uid i importy;
raporty w docs/reports/m02/.

API: InputCommand.axis/copy/neutral; InputRouter.configure/feed/sample/clear/set_enabled;
WorldState.PlayerState.copy/reset; Movement.begin_dash/step; Simulation.initialize/step/snapshot;
GameSnapshot.capture/copy/validate; GameEvent.copy; WorldView.configure/present;
DroneView.configure/present. CameraRig ustawia centrum (640,360) i zoom=1.
Przyszłe systemy gameplayu i AssetCatalog nie są zastępowane stubami.

AppRoot posiada pojedynczą debug Simulation; tylko ona i Movement mutują stan gry.
Oba sloty korzystają z InputCommand i tych samych reguł ruchu/kolizji. Tick 60 Hz,
próbkowanie komend 30 Hz (komenda podtrzymana przez dwa ticki), render korzysta z
interpolacji dwóch snapshotów i prywatnych kopii PlayerState. Kierunek i pozycja
rysunku nie definiują kolizji. Drony przenikają przez siebie.

Przyspieszenie 1800, hamowanie 2400, limit ruchu 240 units/s; zryw 720 units/s
przez dokładnie 10 ticków, cooldown 90 od przyjęcia. Zryw od postoju pokonuje
120 units na wolnej drodze. Po zrywie clamp 240, potem normalny ruch/hamowanie.
Nowy serial w cooldown/stun jest konsumowany bez kolejki. Powtórki/stare seriale
nie uruchamiają kolejnego zrywu; obsługiwany wrap u16. Stun blokuje ruch;
liczniki zmniejszają się w stałym ticku. Samo zadawanie obrażeń dojdzie w M04.

Zryw emituje GameEvent z kolejnym ID. Snapshot kopiuje pola wire, players/charges,
nie eksportuje historii hosta; jego zmiana nie mutuje WorldState.

## Testowanie i dowody

Godot 4.5.2 Standard, build 6ce3de25a, /home/pablo/.local/bin/godot.
Linux/X11 przez XWayland, Compatibility OpenGL/Mesa Intel HD 520.
W tabeli `godot` oznacza tę pełną ścieżkę.

| Polecenie / sprawdzenie | Exit | Wynik / dowód |
|---|---:|---|
| `godot --headless --editor --path . --import` | 0 | PASS, reports/m02/import.log |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | PASS: 143 asercje, 6 suites, 0 failed; all.log, commands.json |
| Ten sam runner z `--self-test-failure` | 1 | PASS detekcji celowego błędu; self-failure.log |
| `godot --headless --path . --script tools/validate_content.gd` | 0 | PASS; validator.log |
| GUI: `godot --path . --display-driver x11 --disable-vsync --max-fps 30` | 0 | PASS, ruch/zryw obu slotów, menu i Exit; start/move/dash/menu-30.png |
| To samo z `--max-fps 60` | 0 | PASS, oględziny przy FPS=60; move/dash/menu-60.png |
| To samo z `--max-fps 120` | 0 | PASS, oględziny przy FPS=120; move/dash/menu-120.png |

Ścieżki raportów odnoszą się do [reports/m02/](reports/m02/).
M01–M03: 600 ticków diagonalnych, przyspieszanie/hamowanie, 120-unit zryw,
10/11 tick, cooldown, ponowienie serialu, krawędź w cooldown, przenikanie dronów,
kolizja z dock, stun/consumption. K01/K02 i C01 z M01 nadal przechodzą.
I01: menu/focus loss/resume, held/echo, odrzucenie niepobranego impulsu, analog deadzone,
kopie komend, normalizacja. B02: uruchomienie fixture, dwa widoki, ukrycie widoku,
blokada wejścia i przywrócenie focusu po menu. S03: kopie snapshotu i charges,
serialwrap, odrzucenie starego serialu, wymóg dwóch komend, blokada błędnej mapy.

GUI sterowane zdarzeniami X11 z oględzinami screenshotów; nie jest to playtest duetu.
Pełne komendy i exitcodes: gui.commands.json. Licznik na screenshotach pokazywał
30/60/120 FPS; to smoke bieżącej sceny, nie benchmark ani gwarancja wydajności.
Sekwencja: focus → F2 → W/I → Spacja/Shift → Escape → Enter (press/release).
Pierwsze próby harnessu poprawiono: poczekanie na okno, nadanie focusu oraz pełne
naciśnięcie/zwolnienie Enter. Próby bez focusu poprawnie nie poruszały dronami;
timeout harnessu nie był uznawany za PASS. Wstępny runner uruchomiony podczas
importu ponowiono po zakończeniu rejestracji klas; końcowe logi bez błędów.

## Obsługa i ograniczenia

F2 lub przycisk: developerski test ruchu/reset. P1: WASD/strzałki lub pad, Spacja/dolny
przycisk — dash. P2: IJKL, Shift — dash. Drugi slot i fixture wyłącznie debug.
F1 zachowuje podgląd geometrii M01. Escape przełącza menu; symulacja trwa,
wejście w menu/focus loss jest zerowane. Powrót wymaga nowego naciśnięcia.
Developer art jest jawnie oznaczone; różne sylwetki i kolory dronów.

Nie ma sesji LAN, przewodu, celów, hazardów, wyników ani finalnych assetów.
Garden/reactor pending do M10. Fizyczny pad, Windows i test dwóch komputerów:
NOT RUN, poza zakresem odbioru M02. Pełna walidacja pakietów/snapshotów dla
niezaufanej sieci dojdzie z protokołem; obecna walidacja obsługuje lokalny przyrost.
M03 nie został rozpoczęty. Brak publikacji, eksportu i wysyłki zewnętrznej.
