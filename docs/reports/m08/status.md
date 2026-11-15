# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-15. **M08 ukończone; odbiór techniczny Linux/localhost: PASS**.
M09 nie został rozpoczęty. Katalog bez Git; code_revision to `unversioned`.
Dokładny hash źródeł zawiera [build_manifest.json](../build_manifest.json).
Historia M06/M07: [raport M06](reports/m06/REPORT.md), [status M07](reports/m07/status.md).

## Zakres i działanie

Pełna ekspedycja developerska **dock ×3 przez LAN**: dwa drony, ruch/zryw,
przekaźniki, przewód, cele i zagrożenia, odliczanie każdego sektora, intermission,
wspólny wynik, rekord debug oraz rewanż lub wspólny powrót do lobby.
Garden/reactor pozostają zakresem M10; grafika jest oznaczona DEVELOPER ART.

**Tylko host posiada Simulation** i wykonuje jeden krok na physics tick 60 Hz.
Gość wysyła InputBatch30 Hz z historią do sześciu komend, host pełne Snapshot30 Hz.
HostReplication kolejkuje kopie komend według slotu i target tick. Duplikat ticku
nie zastępuje komendy, stare ticki są pomijane, przyszłość >12 odrzucana atomowo.
Seriale akcji są uint16 z dopuszczonym krokiem do64. Brak wejścia utrzymuje osie
przez6 ticków, potem neutralizuje, zachowując seriale bez ponowienia akcji.

Reliable Events są deduplikowane po ID, SessionState potwierdza fazy i głosy.
Kolejne sektory używają bariery LoadSector/Loaded/Begin. Integrity, score, tick i ID
zdarzeń przechodzą między sektorami; rewanż nadaje nowy match_id i czyści kolejki.
Oddzielne maski głosów zapobiegają startowi przy różnych wyborach graczy.
Host może ustawić seed następnego rewanżu. Wire pozostaje w wersji1.

Przed M09 gość wyświetla ostatni snapshot, bez predykcji. Kontrolowany target tick
zaczyna od snapshot.tick+4, rośnie najwyżej do +8; po250 ms bez nowego snapshotu
próbkowanie zostaje wstrzymane. Ta implementacja nie zastępuje zegara/predykcji M09.
Escape i utrata focusu neutralizują wejście, lecz gra i sieć nadal pracują.
Lokalne narzędzie F2 z M05 pozostaje dostępne osobno.

## Pliki i API

Nowe: `net/host_replication.gd` i jego UID.
Zmiany: `app/match_session.gd`, `app/app_root.gd`, `app/app_state.gd`,
`net/message_guard.gd`, `core/simulation.gd`, `presentation/world_view.gd`,
`ui/lobby_presenter.gd`, `tools/build_manifest.gd`, `build_manifest.json`,
`tests/integration/test_network.gd`, `test_session.gd`, `network_harness.gd`,
README oraz dokumentacja kontraktów/protokołu/ADR/statusu i raporty.

API: HostReplication.enqueue/commands_for/capture/drain_events/reset;
MatchSession.fixed_update/next_input_tick/render_frame/vote/set_next_seed,
sygnał events_ready. `poll()` obsługuje transport/timeouty; caller wywołuje
`fixed_update()` dokładnie raz/60 Hz. RenderFrame zawiera kopie, gość nie tworzy świata.

## Weryfikacja wykonana

Godot4.5.2 Standard official, Linux x86_64, Compatibility, Intel HD520.
Polecenia poniżej wykonano z katalogu projektu, używając `~/.local/bin/godot`.
Surowe logi i JSON: [reports/m08](reports/m08/).

| Polecenie / test | Exit | Wynik i dowód |
|---|---:|---|
| `godot --headless --editor --path . --import --quit` | 0 | import bez błędów skryptów; import.log |
| `godot --headless --path . --script tools/build_manifest.gd -- --write` | 0 | aktualny manifest; manifest-write.log |
| `godot --headless --path . --script tools/build_manifest.gd -- --check` | 0 | Manifest PASS; manifest-check.log |
| `godot --headless --path . --script tools/validate_content.gd` | 0 | dock PASS; content.log |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | **512 PASS, 0 FAIL**, 14 suites; all.log |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all --self-test-failure` | 1 | jeden zamierzony błąd runnera; self-test.log |
| Dwa procesy headless ENet, `--scenario=expedition` | 0 / 0 | pełna wyprawa zwykłymi InputCommand; expedition-{host,client}.json |
| Dwa natywne okna GUI X11, OpenGL | 0 / 0 | PLAYING, ruch/zryw obu slotów, Escape otwiera/zamyka menu, opuszczenie; gui.commands.json, logi i PNG |

Testy obejmują N06: ten sam zakodowany InputBatch30 razy przez rzeczywisty ENet,
jeden dash gościa; dodatkowo duplikaty kolejek obu slotów, jeden krok/tick,
jeden dash na slot i równoczesny socket z priorytetem wynikającym z parzystości ticku.
S01 LAN: śmiertelny hazard i kończąca ekstrakcja w tym samym ticku daje FAILED
oraz integrity0 także u gościa. Próba wysłania przez klienta Snapshot ze zmienionymi
score/charge/integrity nie modyfikuje hosta. Gość nie posiada Simulation.
Dziesięć kolejnych rewanżów na jednym połączeniu: nowe match_id, zgodny wynik,
reset kolejek i brak klientowej Simulation; mieszane głosy nie startują gry.
Weryfikowany jest również wspólny powrót do lobby i usunięcie świata/gotowości.

Testy S01 i10 rewanżów używają jawnych fixture hosta, aby doprowadzić do końca rundy;
nie są dziesięcioma pełnymi wyprawami. Osobny test dwóch procesów przechodzi
wszystkie trzy sektory wyłącznie komendami wejścia, bez teleportu, ręcznego
ładowania celów, dopisywania wyniku ani zmiany integrity. Planner steruje każdym
lokalnym slotem na podstawie autorytatywnego snapshotu. W końcowym teście oba procesy uzgodniły score **17620**, integrity **4**,
sektor2 (trzeci), tick **6363** i ten sam match/session. Hash testu:
`5a06c81d4eed67078a658f4ec175e6fdbdd75ec5230a67f0e089e12fb38e6370`. Dokładne polecenia i exit zawiera process.commands.json. GUI używa prawdziwego AppRoot i SceneRouter;
automatyzuje intencje lobby, a ruch/menu wysyła jako zdarzenia klawiatury X11.
Źródła pomocników GUI zachowano jako pliki `.txt` w raporcie.

W all.log/self-test.log komunikat `Couldn't create an ENet host` jest oczekiwany
w negatywnym teście zajętego portu. Brak SCRIPT ERROR, wycieków i crashy.
Po zamknięciu hosta GUI gość poprawnie pokazuje „Partner opuścił grę”.

## Pozostałe bramki

N02 wykonany w dostępnym zakresie Linux↔Linux/loopback. **Windows↔Linux w obu
kierunkach i dwa fizyczne komputery w LAN: NOT RUN**, pozostają oddzielną bramką
wydania. Testy procesowe nie dowodzą zachowania Wi-Fi ani zapory Windows.
Duetowy playtest M03/M04: NOT RUN, oddzielna bramka jakości. Licencja projektu
nadal wymaga decyzji (LICENSE). Nie rozpoczęto M09, M10 ani pakowania wydania.
