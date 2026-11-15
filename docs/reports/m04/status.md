# PROJECT_STATUS — LUMEN LINK

Data 2026-11-15. Implementacja M03 i M04 ukończona. Odbiór obu: **PENDING** —
nie przeprowadzono wymaganego playtestu dwóch osób. Ostatni w pełni odebrany etap:
M02. Następny etap kodowy M05, nierozpoczęty. Brak commita (katalog bez Git).

## Wdrożone funkcje

M03: geometria prostej/łamanej przez jeden socket; długości 56–720,
blokowanie ścianami z paddingiem 3, priorytet busy/short/long/occluded,
trafienie beaconu w odległości <=25 i co najmniej 48 od obu końców trasy.
Socket w zasięgu 44, remis niższe ID, cooldown 30 i naprzemienny priorytet slotów.
Charge 300, grace 30, decay co drugi tick, jeden przyrost na tick niezależnie
od liczby trafiających segmentów, zatrzaśnięcie i kolejny cel od następnego ticka.
Widok przewodu, przyczyny braku zasilania, progress, sockety, komunikat zasięgu.
Pingi mają cooldown 60, czas życia 90, numer slotu i po jednym markerze na gracza.

M04: PULSE i SWEEP, cykle NORMAL/RELAXED i offsety wariantów, telegraph całego
obszaru sweep, kierunek odwracany co cykl, geometria aktywna w czasie symulacji.
Pulse testuje zaokrąglony prostokąt, nie duży kwadrat. Sweep używa względnego
ruchu każdego odcinka ścieżki po slide i jego czasu (segment_times, ADR-0004).
Globalny koszt obrażeń max 1/30 ticków, stun/immunity obu trafionych,
dash/immunity wykluczają trafienie. Obrażenia są przed zwycięstwem.
Ewakuacja 120 ticków obu graczy, limit czasu, sukces dokładnie w ostatnim ticku,
wynik i premia sektora naliczane raz, terminalne stany zamrażają symulację.
Sukces dock = INTERMISSION, zgodnie z ekspedycją; WON dotyczy sektora 2.
F2 resetuje lokalny sektor, brak przejścia do niezaimplementowanego garden.

## Pliki i API

Nowe: core/link_system.gd, core/objective_system.gd, core/hazard_system.gd,
presentation/link_view.gd, tests/unit/test_link.gd, test_objectives.gd,
test_hazards.gd (ostatnie trzy w tests/unit/).
Zmienione: core/simulation.gd, core/game_types.gd, core/collision_world.gd,
presentation/world_view.gd, app/app_root.gd, app/input_router.gd,
scenes/world.tscn, scenes/app.tscn, tests/test_runner.gd, README.md,
docs/MASTER_SPEC.md, CODE_CONTRACTS.md, ADR.md i PROJECT_STATUS.md.
Istniejące WorldState i GameSnapshot z M02 już zawierały wymagane pola;
nie dodawano do nich pustych ani powielonych danych.

API: LinkSystem.evaluate/find_socket/hits_beacon;
ObjectiveSystem.step/finish_sector/final_score;
HazardSystem.phase_at/hits/apply; Simulation._consume_actions/_advance_timers/_resolve_phase;
LinkView.present; WorldView.present_snapshot. MoveResult.segment_times opisuje
przedziały czasu segmentów. Zmiana kontraktu lokalnego udokumentowana w ADR-0004,
MASTER_SPEC i CODE_CONTRACTS. Blueprint źródłowy bez zmian, wire bez zmian.

## Weryfikacja

Godot 4.5.2 Standard 6ce3de25a. W poniższych poleceniach `godot` oznacza
/home/pablo/.local/bin/godot. Logi i pełne komendy: reports/m04/commands.json.

| Polecenie | Exit | Wynik |
|---|---:|---|
| `godot --headless --editor --path . --import` | 0 | PASS, import.log |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | PASS, 175 asercji, 9 suites, all.log |
| Ten sam runner z `--self-test-failure` | 1 | PASS wykrywania celowego błędu, self-failure.log |
| `godot --headless --path . --script tools/validate_content.gd` | 0 | PASS, validator.log |
| `godot --path . --display-driver x11` | 0 | PASS smoke okna, gui.log/world.png |

L01–L03: długości brzegowe, endpoint48, occlusion/busy, zasięg, jednoczesne E
obu slotów i cooldown. O01–O02: 300 ticków, następny cel nie ładuje w tym samym
ticku, grace/decay. H01/H03: granice telegraph/active, okresy relaxed,
swept pulse i zaokrąglony narożnik. H02: trafienie obu, pojedynczy koszt i dwa stun.
O03/S01/S02: ostatni tick extraction, śmierć przed extraction, brak ponownego score.
Regresje M00–M02 nadal przechodzą.

Dodatkowo test pełnej trasy dock w RELAXED: oba sloty sterowane InputCommand,
bez teleportów i mutowania integrity/charge; wszystkie trzy cele i ewakuacja
przy aktywnych hazardach, wynik INTERMISSION. Pierwszą trasę poprawiono:
koniec przewodu był zbyt blisko pierwszego beaconu po niedokładnym zatrzymaniu.
Nie zmieniano reguł ani balansu, poprawiono wyłącznie docelową pozycję trasy.

GUI: rzeczywisty Compatibility/OpenGL, Intel HD 520, Linux/XWayland;
przewód, cele, sockety, hazard i HUD obejrzane na screenshotach.
To nie jest playtest dwóch ludzi ani dowód jakości sterowania/gry w duecie.

## Ograniczenia i bramki

NOT RUN: wymagany playtest dock przez dwie osoby, pełne ręczne zwycięstwo/porażka
oraz ocena czytelności zapowiedzi/ładujących się celów. Dlatego M03/M04 nie są
jeszcze odebrane mimo ukończonej implementacji i przechodzących testów.
Nie deklarowano odbioru M04 na bazie nieodebranego M03; prace kodowe obu
wykonano zgodnie z łącznym zleceniem użytkownika, bramki pozostają jawne.
Windows, LAN, fizyczny pad i pełna ekspedycja: NOT RUN, kolejne etapy.
Grafika nadal DEVELOPER ART, fixture tylko debug, brak publikacji/eksportu.

Sterowanie: F2 start/reset, P1 WASD/Spacja/E/Q, P2 IJKL/Shift/U/O,
Escape menu (gra nadal trwa; wejście neutralne), F1 podgląd geometrii.
