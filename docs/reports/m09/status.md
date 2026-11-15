# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-15. **M09 ukończone; odbiór techniczny Linux/localhost: PASS**.
M10 nie został rozpoczęty. Katalog bez Git; code_revision=`unversioned`.
Content SHA-256: `2e740732b7ec30b8b61df9823d9765b4fdadac35141660f178f9c33965abb158`.
Historia: [M08](reports/m08/status.md), [ADR-0009](ADR.md).

## Zakres

Gość przewiduje własny ruch od razu, bez drugiej Simulation. Host pozostaje jedynym
właścicielem świata, charge, obrażeń, celów i wyniku. Simulation60 Hz,
InputBatch/Snapshot30 Hz, wire1 bez zmiany schematów ani rozmiarów.

NetworkClock mierzy RTT monotonicznym Ping/Pong; lead=clamp(ceil(RTT×60/2000)+2,2,8).
Estymata korygowana najwyżej0,25 tick/update; drift>12 resetuje ją ze snapshotu.
Target ticks są monotoniczne, od0 do3 na fixed update, z twardą granicą
ostatni snapshot.tick+12. Przy zwalniającym hoście klient pomija generowanie,
zamiast wysyłać komendy poza dozwolone okno. Catch-up nie mnoży krawędzi
akcji: kolejne komendy zawierają aktualne seriale InputRouter.

ClientPrediction odtwarza timery, dash i wspólny Movement ze statycznymi kolizjami.
Korekta zastępuje **pełny PlayerState**, w tym facing/mode/seriale/timery. Granicą
replay jest snapshot.tick, a nie ostatni odebrany przez hosta input. Historia≤256,
luka>12 wymusza resync do ostatniego stanu autorytatywnego. Luki neutralne zachowują
seriale; host odrzucający dash konsumuje serial, więc akcja nie startuje ponownie.
Fazy poza PLAYING czyszczą historię. Smoothing jest wyłącznie wizualny: ≤2px brak,
2..48px decay80ms, >48px/nowy sektor snap. Nie dodano spekulatywnego audio przed M13.

SnapshotBuffer:32 kopie, uporządkowane ticki, dedup, clear po zmianie sektora.
Partner renderowany dla estimated_host_tick−6; interpolacja pozycji/prędkości,
stany dyskretne z wcześniejszej próbki. Extrapolate≤6tick ze statyczną kolizją,
potem freeze. Host interpoluje poprzedni/bieżący stan fixed update przez fraction
silnika. Własny dron/hazardy używają predicted tick. Końce przewodu są renderowane,
lecz jego postęp i kolor ładowania pochodzą ze snapshotu; dash wizualnie go wygasza.

Po250ms bez snapshotu obraz i generowanie komend są wstrzymane. Nowy snapshot
wznawia prezentację; menu i heartbeat działają nadal. Po1s bez wiadomości banner,
po3s cleanup i komunikat zerwania. Wyjście partnera zachowuje komunikat opuszczenia.
Ekspedycja dock×3, wspólny wynik, rewanże i lokalny debug F2 pozostają dostępne.

## Pliki i API

Nowe: `net/client_prediction.gd`, `net/snapshot_buffer.gd`, `net/network_clock.gd`,
`tests/unit/test_prediction.gd`, `tests/integration/fault_link.gd` i UID.
Dodatkowe rzeczywiste testy: `tests/integration/fault_harness.gd`,
`fault_harness.tscn`, `run_fault_processes.py`.
Zmiany: `app/match_session.gd`, `app/app_root.gd`, `net/host_replication.gd`,
`presentation/world_view.gd`, `ui/lobby_presenter.gd`, `tests/integration/test_network.gd`,
`test_session.gd`, `network_harness.gd`, `tests/test_runner.gd`,
`tools/build_manifest.gd`, manifest, README i docs kontraktów/protokołu/ADR/statusu.

API: ClientPrediction.configure/push/reconcile/present/reset;
SnapshotBuffer.insert/sample/reset; NetworkClock.on_pong/observe/advance/next_command_ticks;
MatchSession.next_input_ticks/render_frame(alpha,delta). AppRoot pobiera wszystkie
komendy (max3), zamiast pojedynczego target tick. Brak modułów M10 i dalszych etapów.

## Wykonane testy

Godot4.5.2 Standard official, Linux x86_64, Compatibility, Intel HD520.
`godot` w poniższych poleceniach to `/home/pablo/.local/bin/godot`.
Dowody: [reports/m09](reports/m09/).

| Polecenie / sprawdzenie | Exit | Rezultat |
|---|---:|---|
| `godot --headless --editor --path . --import --quit` | 0 | import.log; brak błędów skryptów |
| `godot --headless --path . --script tools/build_manifest.gd -- --write` | 0 | manifest-write.log, etykieta M09-dev |
| `godot --headless --path . --script tools/build_manifest.gd -- --check` | 0 | manifest-check.log, hash zgodny |
| `godot --headless --path . --script tools/validate_content.gd` | 0 | content.log, dock PASS |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | **804 PASS,0 FAIL**,15 suites, all.log |
| ten sam runner z `--self-test-failure` | 1 | dokładnie1 zamierzony błąd, self-test.log |
| `python3 tests/integration/run_fault_processes.py` | 0 | realny ENet/UDP loss, N03 i N04; fault-processes.json |
| dwa procesy `network_harness.tscn -- --scenario=expedition` | 0/0 | pełne dock×3, score17620, integrity4, tick6277; expedition-{host,client}.json |
| dwa natywne okna X11/OpenGL, cap60FPS, AppRoot i SceneRouter | 0/0 | ruch/zryw obu ról, przewód, menu Escape, resume/leave; gui.commands.json, PNG i logi |

PR01: zgodny core ruchu, timerów i ograniczona historia przy60Hz/30Hz.
PR02: host odrzuca dash i narzuca stun/cooldown/invulnerability/facing/consumed serial;
klient przyjmuje całość bez drugiego dash. Sprawdzone smoothing80ms, snap>48px,
bounded resync, monotoniczne ticks, lead i limit3, bufor32/interpolacja/extrapolacja.
PR03 FaultLink: seeded loss20%,duplicate10%,reorder20%, bazowy RTT100±30ms;
po2s czystej sieci pozycja/timery/seriale zgodne, jeden dash.
Test regresji WorldView sprawdza faktyczny RenderFrame i renderowane końce przewodu.
Dodatkowa regresja zatrzymanego hosta potwierdza cap snapshot.tick+12 i pomijanie
komend zamiast rozłączenia przy chwilowym spowolnieniu.

Oddzielny realny ENet: transparentny przekaźnik UDP na loopback, ustalone parametry
20% loss/10% duplicate/20% reorder i50±15ms opóźnienia w każdą stronę. Zakłócenia
włączane po zestawieniu sesji i wejściu obu ról do PLAYING; dodatkowo pełny blackout500ms.
W końcowym biegu:84 zgubione datagramy,38 duplikatów,75 dodatkowo opóźnionych,
22 zgubione w blackout. Gość zamroził obraz17 fixed updates i wznowił go. Końcowe
pozycje host snapshot / guest snapshot / guest prediction identyczne: (448,592).
Dash obu stron liczony1, duplikaty Events0; ponad2s czystej sieci przed końcem.
ENet może ponawiać reliable datagramy, więc parametry to losowanie na datagramach,
a nie założenie takiego samego procentu utraconych wiadomości aplikacyjnych.

N03: dodatkowo rzeczywista sesja bez odbioru snapshotów przez~520ms, stabilny frozen
transform i wznowienie po nowym stanie. N04: SIGKILL hosta oraz gościa w osobnych
sesjach, partner zakończył odpowiednio w3,103s i3,185s (≤3,5s); ponowne bind portów
udane. SIGKILL ofiary exit−9 jest zamierzony; partner exit0. Dokładne polecenia i czasy
zawiera fault-processes.json. Końcowe opuszczenie peer w teście loss to oczekiwany teardown.

Test pełnej wyprawy używa wyłącznie InputCommand, bez teleportacji ani dopisywania
charge/integrity/score. Obie role uzgodniły snapshot i hash, klient bez Simulation.
Zachowane regresje M08: replay tego samego pakietu30 razy, jednoczesne dash/socket,
S01 śmierć przed ekstrakcją,10 rewanżów, brak możliwości zmiany score/charge/integrity
przez gościa. Tylko testy końca rundy/rewanżów stosują jawne fixture hosta.

W all.log i self-test.log `Couldn't create an ENet host` jest oczekiwanym wynikiem
negatywnego testu zajętego portu. Finalne logi nie mają SCRIPT ERROR/crashy/wycieków.
Źródła pomocników GUI zachowane jako `.txt`; wejścia wysyłane przez X11, lobby
uruchamiane intencjami AppRoot. Obserwacja GUI potwierdza responsywność jakościowo;
nie jest pomiarem opóźnienia fotodiodą ani benchmarkiem FPS.

## Pozostałe bramki

Windows↔Linux, dwa fizyczne komputery LAN/Wi-Fi: **NOT RUN**, oddzielna bramka wydania.
Duetowy playtest M03/M04 nadal NOT RUN. Docelowe mapy M10, art M11, finalne UI M12
 i audio M13 pozostają przyszłymi etapami. Licencja projektu wymaga decyzji.
Ten etap nie oznacza ukończenia całej gry. Następny milestone: M10.
