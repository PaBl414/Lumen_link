# IMPLEMENTATION_PLAN — kontrakt 1.0

Źródło: [MASTER_SPEC.md](MASTER_SPEC.md), specyfikacja 1.0 (14 listopada 2026).
Poniższe rozdziały zachowują pełną treść źródła. Opisują wymagania docelowe; stan implementacji podaje [PROJECT_STATUS.md](PROJECT_STATUS.md).

## 26. Kompletny plan implementacji

### 26.1 Zasady etapowania

Każdy milestone jest oddzielnym przyrostem. Po nim projekt ma się importować i uruchamiać; od M03 istnieje grywalna zagadka, od M04 pełny sektor, od M08 pełna sesja LAN. Elementy robocze są dopuszczalne w milestone technicznym, ale muszą być oznaczone w PROJECT_STATUS jako pending i zastąpione przed odbiorem P0.

Każda pozycja poniżej podaje cel, zależność, dokładne pliki, API, kolejność, integrację, testy, kryterium, stan końcowy i typowy błąd. Wspólna decyzja techniczna: stos, własność stanu, dane i sygnatury są ustalone w §12–19. Nie podejmować ich ponownie przy każdym promptcie.

Zawsze dodatkowo aktualizuje się `docs/PROJECT_STATUS.md`; jeśli zmienił się kontrakt, również odpowiedni dokument oraz `docs/ADR.md`. Te trzy zasady dotyczą każdego etapu i nie są ukrytym zakresem refaktoryzacji. Test runner rejestruje wyłącznie testy już istniejące; planowany test nie może być pustą funkcją raportującą PASS.

### M00 — Uruchamialny fundament

**Cel i wymagany stan wejściowy:** Uruchamialny fundament. Poprzedni odbiór: puste repozytorium i przekazany kompletny blueprint; zero niezapisanych konfliktujących zmian. Kontrakty: §12–17.

**Utwórz:** `project.godot`, `.gitignore`, `.editorconfig`, `README.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, `docs/MASTER_SPEC.md`, `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/NETWORK_PROTOCOL.md`, `docs/CODE_CONTRACTS.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/PROJECT_STATUS.md`, `docs/ASSET_MANIFEST.md`, `docs/TEST_PLAN.md`, `docs/RELEASE_CHECKLIST.md`, `docs/ADR.md`, `app/app_root.gd`, `app/app_state.gd`, `scenes/app.tscn`, `tests/test_runner.gd`, `tests/test_assert.gd`, `tests/integration/test_boot.gd`.

**Zmień:** brak istniejących plików poza dokumentacją statusu.

**Klasy/metody:** AppRoot._ready/shutdown, AppState.transition/allows, TestAssert.equal/near/is_true/fails/summary, TestRunner suite dispatcher.

**Kolejność implementacji:**

1. Skopiuj pełny przekazany dokument do MASTER_SPEC i przygotuj dokumenty kontraktów według mapowania z §27.1.
2. Ustaw Compatibility, viewport1280×720, fixed60 Hz i wejścia; utwórz realną scenę z menu startowym i przyciskiem zamknięcia.
3. Dodaj działający runner, test boot oraz test celowo błędny uruchamiany wyłącznie flagą --self-test-failure.
4. Zapisz wersję narzędzi i stan etapu; nie dodawaj nieużywanych pustych klas przyszłych systemów.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §12–17 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** Import headless; zwykły boot GUI i Exit; B01 dla dostępnej sceny; runner self-test musi zwrócić1, normalny0.

**Kryterium odbioru i stan końcowy:** Projekt startuje z czystego importu; menu reaguje; runner wykrywa błąd; żadna nieistniejąca klasa nie jest referencją runtime.

**Pułapka:** Nie generuj jednocześnie całej gry ani pustych metod z pass udających ukończone moduły.

### M01 — Dane mapy i geometria kolizji

**Cel i wymagany stan wejściowy:** Dane mapy i geometria kolizji. Poprzedni odbiór: M00; zero niezapisanych konfliktujących zmian. Kontrakty: §6.1–6.2, §7, §16.2, §17.1.

**Utwórz:** `core/game_types.gd`, `core/game_config.gd`, `core/map_definition.gd`, `core/collision_world.gd`, `data/gameplay.json`, `data/maps/dock.json`, `tools/validate_content.gd`, `tests/unit/test_content.gd`, `tests/unit/test_collision.gd`, `tests/fixtures/valid_map.json`, `tests/fixtures/invalid_map.json`.

**Zmień:** `app/app_root.gd`, `tests/test_runner.gd`.

**Klasy/metody:** GameTypes DTO; GameConfig.from_json/validate; MapDefinition.from_json/validate; CollisionWorld.configure/move/blocks_segment; content validator CLI.

**Kolejność implementacji:**

1. Utwórz walidowane typy i dokładny layout dock.
2. Zaimplementuj swept AABB, tie-break, slide i test odcinka ze ścianą.
3. Dodaj diagnostyczny podgląd geometrii dock do uruchamialnej sceny.
4. Walidator na tym etapie wymaga istniejącego dock; garden/reactor są jawnie pending do M10.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §6.1–6.2, §7, §16.2, §17.1 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** C01 na istniejącej zawartości; K01/K02; granice mapy; NaN i overlap spawn; zwykłe menu nadal działa.

**Kryterium odbioru i stan końcowy:** Geometria przechodzi testy brzegowe; błędna mapa nie uruchamia sesji; żaden test nie wymaga jeszcze brakującej mapy.

**Pułapka:** Nie używaj RigidBody2D ani dwóch niezależnych źródeł kolizji.

### M02 — Ruch dwóch dronów i zryw

**Cel i wymagany stan wejściowy:** Ruch dwóch dronów i zryw. Poprzedni odbiór: M01; zero niezapisanych konfliktujących zmian. Kontrakty: §6.1–6.2, §16–17.

**Utwórz:** `core/input_command.gd`, `core/world_state.gd`, `core/game_snapshot.gd`, `core/game_event.gd`, `core/movement.gd`, `core/simulation.gd`, `app/input_router.gd`, `presentation/world_view.gd`, `presentation/drone_view.gd`, `presentation/camera_rig.gd`, `scenes/world.tscn`, `scenes/drone.tscn`, `tests/unit/test_movement.gd`, `tests/unit/test_input.gd`, `tests/unit/test_simulation.gd`.

**Zmień:** `app/app_root.gd`, `scenes/app.tscn`, `tests/test_runner.gd`.

**Klasy/metody:** InputRouter.feed/sample/clear; InputCommand.axis/copy; Movement.begin_dash/step; Simulation.initialize/step/snapshot; GameSnapshot.capture/copy; WorldView.present.

**Kolejność implementacji:**

1. Podłącz jedną ścieżkę InputCommand do obu slotów w developerskim trybie testowym.
2. Zaimplementuj60 Hz ruch, hamowanie, dash10tick/cooldown90 i kolizje.
3. Dodaj snapshot copy oraz render między tickami; tymczasowy rysunek ma jawny status developer art.
4. Włącz developerskie sterowanie drugim slotem tylko dla debug; blokuj input przy menu/focus loss.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §6.1–6.2, §16–17 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** M01–M03,K01,I01,S03; ręczny ruch i zryw przy30/60/120renderFPS.

**Kryterium odbioru i stan końcowy:** Dwa drony poruszają się niezależnie bez diagonal boost i tunelowania; długi dash ma120units; snapshot nie mutuje hosta.

**Pułapka:** Nie wiąż prędkości z render delta i nie mieszaj animacji z colliderem.

### M03 — Pierwsza grywalna zagadka przewodu

**Cel i wymagany stan wejściowy:** Pierwsza grywalna zagadka przewodu. Poprzedni odbiór: M02; zero niezapisanych konfliktujących zmian. Kontrakty: §6.3–6.4, §17.4.

**Utwórz:** `core/link_system.gd`, `core/objective_system.gd`, `presentation/link_view.gd`, `tests/unit/test_link.gd`, `tests/unit/test_objectives.gd`.

**Zmień:** `core/simulation.gd`, `core/world_state.gd`, `presentation/world_view.gd`, `scenes/world.tscn`, `tests/test_runner.gd`.

**Klasy/metody:** LinkSystem.evaluate/find_socket/hits_beacon; ObjectiveSystem.step; Simulation._consume_actions.

**Kolejność implementacji:**

1. Dodaj jeden aktywny socket i jego globalny cooldown.
2. Wylicz prostą/łamaną, długości, blokowanie i odległość trafienia beacona.
3. Zaimplementuj charge300, grace30, decay co 2 ticki oraz kolejne cele.
4. Pokaż przyczynę nieaktywnego przewodu i postęp; zagraj duetem w pierwszy dock.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §6.3–6.4, §17.4 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** L01–L03,O01–O02; jednoczesne E obu graczy; beacon trafiony przez oba segmenty nie ładuje się2×.

**Kryterium odbioru i stan końcowy:** Gracze mogą świadomie uruchomić trzy beacony; dash przerywa przewód, charge zachowuje zasady; brak zależności od sieci.

**Pułapka:** Nie uznawaj dotknięcia celu końcówką za poprawne przeciągnięcie światła.

### M04 — Zagrożenia, ewakuacja i wynik sektora

**Cel i wymagany stan wejściowy:** Zagrożenia, ewakuacja i wynik sektora. Poprzedni odbiór: M03; zero niezapisanych konfliktujących zmian. Kontrakty: §5–6.5–6.7, §17.4.

**Utwórz:** `core/hazard_system.gd`, `tests/unit/test_hazards.gd`.

**Zmień:** `core/simulation.gd`, `core/objective_system.gd`, `core/world_state.gd`, `core/game_snapshot.gd`, `presentation/world_view.gd`, `tests/unit/test_simulation.gd`, `tests/unit/test_objectives.gd`, `tests/test_runner.gd`.

**Klasy/metody:** HazardSystem.phase_at/hits/apply; ObjectiveSystem.finish_sector/final_score; Simulation._advance_timers/_resolve_phase.

**Kolejność implementacji:**

1. Dodaj oba cykle hazardów i matematyczne swept tests.
2. Wprowadź globalne integrity, stun, immunity i koszt max 1/30tick.
3. Zaimplementuj extraction120tick, timer i rozstrzygnięcie ostatniego ticka.
4. Dodaj pełen cykl start → play → won/failed → restart jednego sektora debug.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §5–6.5–6.7, §17.4 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** H01–H03,O03,S01–S02; wszystkie cykle RELAXED sumują się do zadanego period.

**Kryterium odbioru i stan końcowy:** Jeden sektor jest kompletną wygrywalną/przegrywalną grą zczytelnymi zagrożeniami i poprawnym wynikiem.

**Pułapka:** Nie zadawaj podwójnych obrażeń duetowi i nie naliczaj premii sektora wielokrotnie.

### M05 — Cykl ekspedycji i lokalny zapis

**Cel i wymagany stan wejściowy:** Cykl ekspedycji i lokalny zapis. Poprzedni odbiór: M04; zero niezapisanych konfliktujących zmian. Kontrakty: §5, §9, §13, §17.3.

**Utwórz:** `app/scene_router.gd`, `services/settings_store.gd`, `services/records_store.gd`, `services/log_service.gd`, `services/asset_catalog.gd`, `tests/unit/test_persistence.gd`, `tests/integration/test_flow.gd`.

**Zmień:** `app/app_root.gd`, `app/app_state.gd`, `core/simulation.gd`, `scenes/app.tscn`, `tests/test_runner.gd`.

**Klasy/metody:** SceneRouter.show/clear; SettingsStore.load_settings/save_settings; RecordsStore.submit/best; AssetCatalog.load_boot/begin_sector/poll_loading; LogService.write/flush.

**Kolejność implementacji:**

1. Zbuduj przejścia loading/countdown/intermission/results bez gubienia AppRoot.
2. W developerskim scenariuszu użyj dock trzy razy i wyraźnie oznacz brak map M10; nie opublikuj tego jako content release.
3. Dodaj zachowanie integrity i score oraz atomowy zapis rekordów/settings.
4. Zweryfikuj cleanup i anulowanie asynchronicznego load przez generation.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §5, §9, §13, §17.3 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** PS01,F01 w wersji lokalnej;3 sektory debug i 2 restarty; brak podwojonych sygnałów.

**Kryterium odbioru i stan końcowy:** Cała lokalna ekspedycja kończy się prawidłowym wynikiem; loading nie blokuje UI; zapis ma fallback.

**Pułapka:** Nie niszcz sesyjnych usług przy każdej zmianie WorldView.

### M06 — Zamknięty protokół i realny transport

**Cel i wymagany stan wejściowy:** Zamknięty protokół i realny transport. Poprzedni odbiór: M05; zero niezapisanych konfliktujących zmian. Kontrakty: §18–19, §23.

**Utwórz:** `net/protocol.gd`, `net/packet_codec.gd`, `net/message_guard.gd`, `net/net_transport.gd`, `net/lobby_state.gd`, `tools/build_manifest.gd`, `build_manifest.json`, `tests/unit/test_protocol.gd`, `tests/fixtures/protocol_vectors.json`, `tests/integration/network_harness.gd`, `tests/integration/network_harness.tscn`, `tests/integration/test_network.gd`.

**Zmień:** `app/app_root.gd`, `tests/test_runner.gd`.

**Klasy/metody:** PacketCodec.encode/decode; MessageGuard.accept; NetTransport.start_host/start_client/poll/send/close; manifest --write/--check.

**Kolejność implementacji:**

1. Zaimplementuj wszystkie schematy wire z limitem1000 B i niezależny golden Ping.
2. Zaimplementuj SceneMultiplayer.send_bytes/peer_packet z manual poll i 3 kanałami.
3. Połącz dwie realne instancje localhost, wymień Hello/Welcome i snapshot testowy.
4. Sprawdź rzeczywiste packet sizes i brak fragmentacji, utwórz pierwszy smoke eksportowy na dostępnych OS.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §18–19, §23 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** P01–P04,N01 transport; queue/rate validation; przetestuj error port bind i close→rebind.

**Kryterium odbioru i stan końcowy:** Wire format ma jednoznaczne wymiary107 B/35 B; wadliwe bytes nie crashują; dwie instancje wymieniają dane przez ENet.

**Pułapka:** Nie zastępuj testu realnego transportu samym round-tripem kodeka ani RPC synchronizerem.

### M07 — Lobby, discovery i bariery ładowania

**Cel i wymagany stan wejściowy:** Lobby, discovery i bariery ładowania. Poprzedni odbiór: M06; zero niezapisanych konfliktujących zmian. Kontrakty: §9, §18.1–18.4, §19.3/19.5.

**Utwórz:** `app/match_session.gd`, `net/lan_discovery.gd`, `ui/ui_root.gd`, `ui/menu_presenter.gd`, `ui/lobby_presenter.gd`, `scenes/menus.tscn`, `scenes/lobby.tscn`, `tests/integration/test_session.gd`.

**Zmień:** `app/app_root.gd`, `app/scene_router.gd`, `app/app_state.gd`, `net/lobby_state.gd`, `net/message_guard.gd`, `tests/integration/test_network.gd`, `tests/test_runner.gd`.

**Klasy/metody:** MatchSession.host/join/set_ready/request_start/leave; LanDiscovery.start_host/start_scan/poll/stop; LobbyState.set_options/can_start; UIRoot.show_screen.

**Kolejność implementacji:**

1. Podłącz formularze host/join i ręczne IPv4.
2. Dodaj discovery z nonce,TTL i efemeryczny port klienta.
3. Zaimplementuj revision,ready obu i LoadSector/Loaded/Begin.
4. Dodaj timeout8/15s,Cancel i odmowę wersji/hasza; wszystkie ekrany mogą jeszcze używać bazowego theme.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §9, §18.1–18.4, §19.3/19.5 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** N01,N05,F01; oba ready wymagane; zmiana seed czyści gotowość; spóźnione Loaded nie otwiera starej sceny.

**Kryterium odbioru i stan końcowy:** Dwóch ludzi może znaleźć pokój, dołączyć i dotrzeć do tego samego countdown; single player nie startuje.

**Pułapka:** Nie wiąż discovery klienta na7778 i nie wierz adresowi wtreści datagramu.

### M08 — Autorytatywna rozgrywka LAN

**Cel i wymagany stan wejściowy:** Autorytatywna rozgrywka LAN. Poprzedni odbiór: M07; zero niezapisanych konfliktujących zmian. Kontrakty: §13.3, §18–19.1–19.6.

**Utwórz:** `net/host_replication.gd`.

**Zmień:** `app/match_session.gd`, `app/app_root.gd`, `net/message_guard.gd`, `core/simulation.gd`, `presentation/world_view.gd`, `tests/integration/test_network.gd`, `tests/integration/test_session.gd`.

**Klasy/metody:** HostReplication.enqueue/commands_for/capture/drain_events/reset; MatchSession.fixed_update/render_frame/vote.

**Kolejność implementacji:**

1. Zaimplementuj kolejki komend wg target tick i seriale krawędzi.
2. Tylko host uruchamia Simulation; client wyświetla pełne snapshoty30 Hz.
3. Podłącz eventy i SessionState oraz intermission/results/rematch.
4. Przed M09 klient używa kontrolowanego target tick z ostatniego snapshotu; jawnie oznacz brak finalnej predykcji.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §13.3, §18–19.1–19.6 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** N02 na dostępnych platformach,N06,S01 na LAN; oba sloty jednocześnie dash/socket;10 rematch.

**Kryterium odbioru i stan końcowy:** Pełna ekspedycja debug przezLAN kończy się jednym zgodnym wynikiem; client nie może sam zmienić charge/integrity.

**Pułapka:** Nie twórz drugiej autorytatywnej Simulation po stronie gościa.

### M09 — Predykcja, czas sieciowy i utrata pakietów

**Cel i wymagany stan wejściowy:** Predykcja, czas sieciowy i utrata pakietów. Poprzedni odbiór: M08; zero niezapisanych konfliktujących zmian. Kontrakty: §19.6–19.9, §23.

**Utwórz:** `net/client_prediction.gd`, `net/snapshot_buffer.gd`, `net/network_clock.gd`, `tests/unit/test_prediction.gd`, `tests/integration/fault_link.gd`.

**Zmień:** `app/match_session.gd`, `app/app_root.gd`, `net/host_replication.gd`, `presentation/world_view.gd`, `tests/integration/test_network.gd`, `tests/test_runner.gd`.

**Klasy/metody:** ClientPrediction.push/reconcile/present/reset; SnapshotBuffer.insert/sample; NetworkClock.on_pong/advance/next_command_ticks.

**Kolejność implementacji:**

1. Dodaj pomiar RTT przez ping,lead 2..8 i monotoniczne target ticks.
2. Zaimplementuj pełne odtwarzanie własnego PlayerState oraz bufor 32 snapshotów.
3. Dodaj smoothing przy progach 2/48 px, freeze 250 ms,heartbeat i disconnect 3 s.
4. Testuj FaultLink oraz oddzielnie realny ENet przy loss; dedup event i serial dash.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §19.6–19.9, §23 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** PR01–PR03,N03–N04; spóźnienia, zmiana kolejności i duplikaty; brak podwójnej akcji; po2s czystej sieci stan zgodny.

**Kryterium odbioru i stan końcowy:** Ruch gościa reaguje lokalnie; timers po korekcie zgodne; chwilowy brak pakietów nie zawiesza meczu ani menu.

**Pułapka:** Nie cofaj target tick i nie traktuj ostatniego otrzymanego input jako granicy rozliczonej symulacji.

### M10 — Docelowe mapy i balans zawartości

**Cel i wymagany stan wejściowy:** Docelowe mapy i balans zawartości. Poprzedni odbiór: M09; zero niezapisanych konfliktujących zmian. Kontrakty: §5–8, §22.2.

**Utwórz:** `data/maps/garden.json`, `data/maps/reactor.json`, `tests/fixtures/dock_success.json`, `tests/fixtures/garden_success.json`, `tests/fixtures/reactor_success.json`, `tests/manual/playtest_matrix.md`.

**Zmień:** `data/maps/dock.json`, `tools/validate_content.gd`, `services/asset_catalog.gd`, `app/match_session.gd`, `tests/unit/test_content.gd`, `tests/unit/test_simulation.gd`, `build_manifest.json`.

**Klasy/metody:** MapDefinition.validate; content flood-fill; Simulation.reset_sector; warianty seed iorder map.

**Kolejność implementacji:**

1. Wprowadź dokładne3 layouty i3 warianty z §7.
2. Usuń powtarzany dock ze scenariusza ekspedycji.
3. Zapisz rzeczywiste fixture wejścia prowadzące do sukcesu, bez cheatów.
4. Przeprowadź testy 18 konfiguracji i pierwsze testy z nowymi duetami; korekty balansu zapisuj jakoADR, zachowując scope.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §5–8, §22.2 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** C02 i success fixtures; manual matrix18kombinacji; wskaźniki zrozumienia pierwszego celu.

**Kryterium odbioru i stan końcowy:** Wszystkie3 sektory mają unikalny layout; każda kombinacja jest ukończalna lub wyraźnie oznaczona do poprawy przed bramką.

**Pułapka:** Flood-fill drogi drona nie jest dowodem, że przewód może zasilić wszystkie cele.

### M11a — Finalne assety i katalog zasobów

**Cel i wymagany stan wejściowy:** Finalne assety i katalog zasobów. Poprzedni odbiór: M10; zero niezapisanych konfliktujących zmian. Kontrakty: §8, §16.5, §20.

**Utwórz:** `assets/art/drone_a.svg`, `assets/art/drone_b.svg`, `assets/art/sensor.svg`, `assets/art/station_atlas.svg`, `assets/art/devices.svg`, `assets/art/atlas_regions.json`, `assets/art/grain.png`, `assets/art/particle.svg`, `assets/art/dock_bg.svg`, `assets/art/garden_bg.svg`, `assets/art/reactor_bg.svg`, `assets/ui/icons.svg`, `assets/ui/title.svg`, `assets/fonts/AtkinsonHyperlegible-Regular.ttf`, `assets/fonts/AtkinsonHyperlegible-Bold.ttf`, `assets/fonts/OFL.txt`, `tools/asset_bake.gd`, `tests/integration/test_presentation.gd`.

**Zmień:** `services/asset_catalog.gd`, `tools/validate_content.gd`, `docs/ASSET_MANIFEST.md`, `THIRD_PARTY_NOTICES.md`.

**Klasy/metody:** AssetCatalog.get_texture; atlasregion construction; asset_bake grain generation; license validation.

**Kolejność implementacji:**

1. Wykonaj własną grafikęSVG zgodną zmanifestem i rozróżnieniem sylwetek.
2. Pozyskaj font z jego oficjalnego źródła wraz zlicencją, zapisz lokalnie.
3. Utwórz regiony atlasów i walidację dimensions/padding; podmień developer art.
4. Obejrzyj wszystkie assety w 720p i skali szarości; popraw czytelność.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §8, §16.5, §20 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** C01 asset manifest,V01 podstawowy; rzeczywisty przegląd obrazu; pliki i licencje kompletne.

**Kryterium odbioru i stan końcowy:** Każdy wymagany asset P0 ma docelowy wygląd, poprawną alfę i udokumentowane pochodzenie.

**Pułapka:** Nie traktuj losowych gradientów i surowych prostokątów jako skończonego artu.

### M11b — Animacje, shadery i efekty

**Cel i wymagany stan wejściowy:** Animacje, shadery i efekty. Poprzedni odbiór: M11a; zero niezapisanych konfliktujących zmian. Kontrakty: §6.7, §8.2, §20.

**Utwórz:** `presentation/fx_pool.gd`, `shaders/link.gdshader`, `shaders/device.gdshader`, `shaders/background.gdshader`.

**Zmień:** `presentation/world_view.gd`, `presentation/drone_view.gd`, `presentation/link_view.gd`, `presentation/camera_rig.gd`, `scenes/world.tscn`, `scenes/drone.tscn`, `tests/integration/test_presentation.gd`.

**Klasy/metody:** DroneView.present/play_event; FxPool.emit_event/update_effects/clear; CameraRig.impulse; LinkView.present.

**Kolejność implementacji:**

1. Zbuduj animacje części drona i klipy bez wpływu na collider.
2. Dodaj trzy proste shadery, warstwy przewodu i efekty beacon/hit.
3. Zastosuj pule, low/high particles i reduced motion.
4. Rozgrzej materiały podczas loading i zweryfikuj drawcalls/overdraw.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §6.7, §8.2, §20 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** V01 i wszystkie stany PlayerMode/LinkStatus; limit 320 drobin; brak skoków przy pierwszym dash.

**Kryterium odbioru i stan końcowy:** Obraz jest spójny i czytelny, efekty nie zmieniają ticków, lowtier zachowuje wszystkie informacje.

**Pułapka:** Nie używaj bloom ani funkcji Forward+ nieobecnych w Compatibility.

### M12a — Kompletne menu, HUD i wynik

> Stan po rozszerzeniu do9 poziomów: katalog, wspólny ekran wyboru/podglądów, trudność, odblokowania, kontynuacja, rekordy poziomów, trwały zapis/backup/reset i dwugłos wyników są już wdrożone. Rozwijaj `LevelSelectPresenter`, `ProgressStore` i istniejący przepływ MatchSession; nie twórz drugiego selektora ani systemu zapisu. Ten fragment M12a jest wykonany, pełne menu/HUD/ustawienia nadal wymagają odbioru. Szczegóły: PROJECT_STATUS.md i PROGRESS.md.

**Cel i wymagany stan wejściowy:** Kompletne menu, HUD i wynik. Poprzedni odbiór: M11b; zero niezapisanych konfliktujących zmian. Kontrakty: §9.

**Utwórz:** `ui/hud_presenter.gd`, `ui/results_presenter.gd`, `ui/ui_theme.tres`, `scenes/hud.tscn`, `scenes/results.tscn`, `tests/integration/test_ui.gd`.

**Zmień:** `ui/ui_root.gd`, `ui/menu_presenter.gd`, `ui/lobby_presenter.gd`, `scenes/menus.tscn`, `scenes/lobby.tscn`, `app/app_root.gd`, `tests/test_runner.gd`.

**Klasy/metody:** HudPresenter.present/show_hint; ResultsPresenter.present; UIRoot.show_error/show_overlay; intent routing.

**Kolejność implementacji:**

1. Zastosuj docelowy theme, spacing i typografię.
2. Dokończ wszystkie ekrany sieci, HUD,intermission,results i głosowanie nad rewanżem.
3. Dodaj kontekstowe podpowiedzi i dokładne błędy z §19.9.
4. Weryfikuj flow myszy/klawiatury/pada, focus po modalach i „Gra nadal trwa”.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §9 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** U01,F01,F02; ekran wyników korzysta ze score hosta; brak wejścia gry spod nakładki.

**Kryterium odbioru i stan końcowy:** Każdy ekran z §9 ma działające akcje i stan busy/error; brak developer-only przycisków w release.

**Pułapka:** Nie wyliczaj wyniku niezależnie w ResultsPresenter.

### M12b — Ustawienia, remap i dostępność

**Cel i wymagany stan wejściowy:** Ustawienia, remap i dostępność. Poprzedni odbiór: M12a; zero niezapisanych konfliktujących zmian. Kontrakty: §5.4, §9.1, §17.1.

**Utwórz:** `ui/settings_presenter.gd`, `scenes/settings.tscn`.

**Zmień:** `ui/ui_root.gd`, `services/settings_store.gd`, `app/input_router.gd`, `presentation/camera_rig.gd`, `presentation/link_view.gd`, `ui/ui_theme.tres`, `tests/integration/test_ui.gd`, `tests/unit/test_persistence.gd`.

**Klasy/metody:** SettingsPresenter.open/capture_binding/cancel_capture; SettingsStore.validate/save_settings; InputRouter.configure.

**Kolejność implementacji:**

1. Zbuduj obraz/dźwięk/dostępność/controls z realnymi ustawieniami.
2. Dodaj przechwytywanie przypisań,zamianę konfliktów i ochronę ui_cancel.
3. Zaimplementuj przywracanie trybu okna po 10 s,ui_scale i reduced motion.
4. Sprawdź zapis atomowy i brak zapisu przy read-only; settings muszą nadal działać w pamięci.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §5.4, §9.1, §17.1 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** U02,I01,PS01;960×540 ui_scale1,3; pełny przepływ pad-only.

**Kryterium odbioru i stan końcowy:** Wszystkie opcje mają realny efekt i zachowują się po restarcie; duża typografia nie ucina akcji.

**Pułapka:** Nie pozwalaj capture klawisza uruchomić dash albo zamknąć całej aplikacji.

### M13a — Kompozycja audio i routing zdarzeń

**Cel i wymagany stan wejściowy:** Kompozycja audio i routing zdarzeń. Poprzedni odbiór: M12b; zero niezapisanych konfliktujących zmian. Kontrakty: §10, §16.5.

**Utwórz:** `presentation/audio_director.gd`, `data/audio_bank.json`, `assets/audio/music_base.ogg`, `assets/audio/music_pulse.ogg`, `assets/audio/music_resolve.ogg`, `assets/audio/ambience.ogg`, `assets/audio/move.wav`, `assets/audio/dash.wav`, `assets/audio/socket.wav`, `assets/audio/charge.wav`, `assets/audio/beacon.wav`, `assets/audio/hit.wav`, `assets/audio/telegraph.wav`, `assets/audio/ping.wav`, `assets/audio/ui_focus.wav`, `assets/audio/ui_accept.wav`, `assets/audio/ui_back.wav`, `assets/audio/victory.wav`, `assets/audio/defeat.wav`, `tests/integration/test_audio.gd`.

**Zmień:** `services/asset_catalog.gd`, `tools/asset_bake.gd`, `app/app_root.gd`, `scenes/app.tscn`, `project.godot`, `docs/ASSET_MANIFEST.md`, `tests/test_runner.gd`.

**Klasy/metody:** AudioDirector.configure/play_event/update_frame/set_mix/stop_session; audio_bank schema; asset generation offline.

**Kolejność implementacji:**

1. Przygotuj docelowe dźwięki i spójną muzykę z manifestu; odbierz je odsłuchem.
2. Utwórz buses i pule głosów,priorytety i crossfade.
3. Podłącz autorytatywne eventy oraz deduplikację przewidywanego dash; loops aktualizuj bez restartów co klatkę.
4. Zapisz pochodzenie i licencje; wszystkie audio lokalne i offline.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §10, §16.5 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** A01,A02; limit głosów,wyciszenie bus,zamknięcie sesji; realny odsłuch loopów.

**Kryterium odbioru i stan końcowy:** Każda istotna akcja ma spójny feedback; brak zdublowanego dash i klików muzyki.

**Pułapka:** Nie oznaczaj muzyki jako ukończonej po samym sprawdzeniu długości pliku.

### M13b — Game feel i odbiór duetu

**Cel i wymagany stan wejściowy:** Game feel i odbiór duetu. Poprzedni odbiór: M13a; zero niezapisanych konfliktujących zmian. Kontrakty: §6.7–10, §21.

**Utwórz:** brak nowych plików.

**Zmień:** `presentation/drone_view.gd`, `presentation/link_view.gd`, `presentation/fx_pool.gd`, `presentation/camera_rig.gd`, `presentation/audio_director.gd`, `ui/hud_presenter.gd`, `tests/manual/playtest_matrix.md`, `tests/integration/test_presentation.gd`.

**Klasy/metody:** Wartości animacji iFX; trigger timing; HUD hints; bez zmian protokołu i fizyki.

**Kolejność implementacji:**

1. Zgraj dash,charge,beacon i hit z czasami animacji/audio.
2. Sprawdź rozróżnienie własnego/zdalnego drona i przyczyn nieaktywnego przewodu.
3. Przeprowadź minimum 5 nowych duetów, jeśli dostępni; zanotuj faktyczne obserwacje.
4. Popraw czytelność i tempo w granicach§6.7; nie dodawaj nowych mechanik.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §6.7–10, §21 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** Playtest comprehension i sukcesy; U02 orazA01 po zmianach; test przy RTT50 ms.

**Kryterium odbioru i stan końcowy:** Gra daje zrozumiały feedback; zgłoszenia są zanotowane; brak obserwatorów oznacza pending, nie fikcyjne playtesty.

**Pułapka:** Nie maskuj trudności niewidzialną zmianą zasad i nie zatrzymuj Simulation dla hit-stop.

### M14a — Odporność protokołu i regresje sesji

**Cel i wymagany stan wejściowy:** Odporność protokołu i regresje sesji. Poprzedni odbiór: M13b; zero niezapisanych konfliktujących zmian. Kontrakty: §19, §22–23.

**Utwórz:** brak nowych plików.

**Zmień:** `net/message_guard.gd`, `net/packet_codec.gd`, `net/net_transport.gd`, `app/match_session.gd`, `tests/unit/test_protocol.gd`, `tests/integration/test_network.gd`, `tests/integration/test_session.gd`, `tests/integration/test_flow.gd`, `tests/integration/fault_link.gd`, `tests/manual/playtest_matrix.md`.

**Klasy/metody:** Walidacja caps/role/state; cleanup i timeout; tylko poprawki wykazane przez scenariusze.

**Kolejność implementacji:**

1. Przejdź wszystkie komunikaty przez truncację i błędne wektory danych.
2. Zbadaj nowe/stare match IDs,spóźnione Loaded,reorder i serialwrap.
3. Uruchom30 rematch,kill obu ról oraz realny ENet przy stratach.
4. Napraw wyniki z reprodukcją i testem regresji; nie zmieniaj wire bez zwiększenia wersji.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §19, §22–23 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** P01–P04,N01–N06,F01–F02,PR01–PR03; zapisane logi z rzeczywistych poleceń.

**Kryterium odbioru i stan końcowy:** Żaden znany błąd nie psuje stanu ani nie zawiesza wyjścia; nieprawidłowe dane są ograniczone caps.

**Pułapka:** Nie uznawaj testów FaultLink za test retransmisji transportu.

### M14b — Profilowanie i optymalizacja zmierzonych kosztów

**Cel i wymagany stan wejściowy:** Profilowanie i optymalizacja zmierzonych kosztów. Poprzedni odbiór: M14a; zero niezapisanych konfliktujących zmian. Kontrakty: §20–22.

**Utwórz:** `services/diagnostics.gd`, `tests/perf/benchmark.gd`, `tests/perf/benchmark.tscn`.

**Zmień:** `app/app_root.gd`, `presentation/fx_pool.gd`, `presentation/world_view.gd`, `services/asset_catalog.gd`, `tests/manual/playtest_matrix.md`.

**Klasy/metody:** Diagnostics.sample_frame/sample_tick/report; benchmark warmup60s/sample600s; pule i ograniczenie overdraw.

**Kolejność implementacji:**

1. Dodaj zbieranie p95/p99,RAM,RTT,bandwidth bez spamu wlogu.
2. Zmierz baseline i mocniejszy sprzęt, low/high oraz60/120 FPS.
3. Optymalizuj tylko zidentyfikowane koszty; porównaj ten sam scenariusz.
4. Powtórz30 rematch leaktest, zachowaj raport hardware/settings/commit.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §20–22 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** Budżety§21; pełen render benchmark, nie headless; ponowne unit tylko gdy zmieniono funkcje logiczne.

**Kryterium odbioru i stan końcowy:** Pomiary mieszczą się w budżetach albo jasno blokują release; nie ma deklaracji60 FPS bez testu.

**Pułapka:** Nie dodawajC++/ECS w miejsce prostej redukcji alokacji luboverdraw.

### M15a — Paczki Windows/Linux i powtarzalny build

**Cel i wymagany stan wejściowy:** Paczki Windows/Linux i powtarzalny build. Poprzedni odbiór: M14b; zero niezapisanych konfliktujących zmian. Kontrakty: §12, §22.4, §28.

**Utwórz:** `export_presets.cfg`, `tools/export.sh`, `tools/export.ps1`, `.github/workflows/verify.yml`, `tests/manual/release_matrix.md`.

**Zmień:** `README.md`, `THIRD_PARTY_NOTICES.md`, `build_manifest.json`, `tools/build_manifest.gd`, `docs/RELEASE_CHECKLIST.md`.

**Klasy/metody:** Exportwrappers: validate/import/test/manifest/export/package/hash; dwa presets; workflow wywołuje te same komendy.

**Kolejność implementacji:**

1. Wyklucztesty, tools i debug fixtures zrelease, zachowaj licencje i lokalne banki assetów.
2. Zbuduj Windows x64 ZIP i Linux x64 tar.gz z tego samego commita.
3. Sprawdź manifest/checksum,executability i start bez Godota.
4. Opisz instalację,LAN,firewall,sterowanie,knownlimits i brak reconnect.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §12, §22.4, §28 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** Czyste konto,ścieżka z polskimi znakami,instalacja w katalogu read-only,boot i join na obu OS; offline scan sieci.

**Kryterium odbioru i stan końcowy:** Obie paczki działają bez edytora developerskiego; nie brakuje importowanych zasobów; odpowiadają temu samemu protokołowi.

**Pułapka:** Nie publikuj ani nie wysyłaj paczek zewnętrznie bez osobnego polecenia użytkownika.

### M15b — Ostateczny odbiór wydania

**Cel i wymagany stan wejściowy:** Ostateczny odbiór wydania. Poprzedni odbiór: M15a; zero niezapisanych konfliktujących zmian. Kontrakty: §22–28.

**Utwórz:** brak nowych plików.

**Zmień:** `docs/PROJECT_STATUS.md`, `docs/RELEASE_CHECKLIST.md`, `tests/manual/release_matrix.md`, `tests/manual/playtest_matrix.md`, `README.md`.

**Klasy/metody:** Braknowychsystemów; tylko udokumentowane poprawki blokujących błędów zoddzielnym testem.

**Kolejność implementacji:**

1. Zagraj pełną ekspedycję Windows→Linux i Linux→Windows bez internetu.
2. Przejdź18wariantów,wyniki,rematch,disconnect i accessibility według matrycy.
3. Zbierz artefakty testów i rozdziel PASS/FAIL/NOTRUN.
4. Oznaczreleasecandidate dopieropo przejściu wszystkich P0; brak środowiska pozostawia precyzyjny blocker.

**Integracja i decyzje:** zachowaj jeden AppRoot, kontrakty §22–28 oraz wszystkie funkcje ukończonych etapów. Nowy moduł dołączaj dopiero, gdy jego rzeczywiste zależności są gotowe; bez martwych klas zastępczych.

**Testy:** Pełna checklista§28; finalny hash paczek i powiązanie z commitem; manualny audio/visual/playtest.

**Kryterium odbioru i stan końcowy:** Wydanie jest przyjęte tylko przy wszystkich P0 PASS; specyfikacja, status i build odpowiadają sobie.

**Pułapka:** Nie nazywaj gotowym wydaniem paczki z nieprzetestowanym LAN albo roboczą grafiką.

## 27. Sekwencyjne prompty dla GPT-6.1 Sol

### 27.1 Utrzymywanie kontekstu

Przed pierwszym promptem dołącz ten dokument. Sol zapisuje go jako `docs/MASTER_SPEC.md`. Jest to wersjonowany kontrakt bazowy, nie materiał do swobodnego skracania. Tematyczne dokumenty zawierają dokładne rozdziały oraz identyfikator wersji1.0:

| Dokument | Zakres autorytatywny |
|---|---|
| GAME_DESIGN.md | §1–10 oraz feature scope§24 |
| ARCHITECTURE.md | §11–15,§20–21 i invariants |
| NETWORK_PROTOCOL.md | §18–19,§23,pełne byte layouts i limity |
| CODE_CONTRACTS.md | §16–17,sygnatury i własność |
| IMPLEMENTATION_PLAN.md | §26–27,milestones i prompty |
| ASSET_MANIFEST.md | szczegółowe tabele§8/10,pochodzenie,licencja,status każdego assetu |
| TEST_PLAN.md | §22 wraz z powiązaniem test→wymaganie |
| RELEASE_CHECKLIST.md | §28,status kryteriów i linki do raportów |
| PROJECT_STATUS.md | bieżąca prawda o implementacji; nie zmienia reguł gry |
| ADR.md | numer,data,problem,wybrana zmiana,alternatywy,pliki,testy,wpływ na protokół |

Nie utrzymywać sprzecznych kopii kontraktu: zmiana normatywna aktualizuje MASTER_SPEC oraz odpowiadający dokument tematyczny w tym samym commicie. Przy rozbieżności Sol najpierw pokazuje konkretną różnicę i usuwa ją na podstawie ostatniego przyjętego ADR. Brak ADR oznacza obowiązywanie bazowego kontraktu 1.0. Drobne techniczne poprawki zachowujące publiczny kontrakt można robić samodzielnie; nie wymagają pytania użytkownika o każdą zmienną.

PROJECT_STATUS na końcu etapu zawiera: ostatni odebrany milestone, bieżący commit, faktycznie istniejące moduły, zmienione API, polecenia testów, exitcodes, ścieżki raportów, PASS/FAIL/NOTRUN, ograniczenia, następny milestone. Ukończony kod i odebrana funkcja są osobnymi statusami, jeśli brakowało możliwości testu manualnego.

Procedura przeciw dryfowi: przed edycją porównaj listę plików, wersję protokołu i API z kontraktem; po edycji wyszukaj zakazane zależności core→app/net/UI oraz zapisy do WorldState poza Simulation i jej systemami. Porównaj typy wire i test fixtures. Gdy wykryjesz drift, popraw w aktualnym etapie, uruchom powiązany test, zapisz ADR jeśli kontrakt rzeczywiście musiał się zmienić. Nie buduj następnych etapów na naruszeniu własności świata.

Każdy poniższy blok jest kompletnym promptem do skopiowania **wraz z dostępem do repo i jego dokumentów**. Nie trzeba kopiować wszystkich poprzednich odpowiedzi czatu. Bez dostępu do repo Sol ma poprosić o aktualne pliki wymagane przez milestone zamiast odtwarzać je z pamięci, a następnie zwrócić kompletne zmienione pliki. Pierwszy prompt wymaga załączonego blueprintu.

### Prompt M00 — Uruchamialny fundament

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M00.

B. KONTEKST
Wymagany stan repo: puste repozytorium i przekazany kompletny blueprint. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M00 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §12–17. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Uruchamialny fundament. Oczekiwany rezultat: Projekt startuje z czystego importu; menu reaguje; runner wykrywa błąd; żadna nieistniejąca klasa nie jest referencją runtime.

D. PLIKI
Utwórz: project.godot, .gitignore, .editorconfig, README.md, LICENSE, THIRD_PARTY_NOTICES.md, docs/MASTER_SPEC.md, docs/GAME_DESIGN.md, docs/ARCHITECTURE.md, docs/NETWORK_PROTOCOL.md, docs/CODE_CONTRACTS.md, docs/IMPLEMENTATION_PLAN.md, docs/PROJECT_STATUS.md, docs/ASSET_MANIFEST.md, docs/TEST_PLAN.md, docs/RELEASE_CHECKLIST.md, docs/ADR.md, app/app_root.gd, app/app_state.gd, scenes/app.tscn, tests/test_runner.gd, tests/test_assert.gd, tests/integration/test_boot.gd.
Zmień: brak poza dokumentacją.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: AppRoot._ready/shutdown, AppState.transition/allows, TestAssert.equal/near/is_true/fails/summary, TestRunner suite dispatcher.
1) Skopiuj pełny przekazany dokument do MASTER_SPEC i przygotuj dokumenty kontraktów według mapowania z §27.1.
2) Ustaw Compatibility, viewport1280×720, fixed60Hz i wejścia; utwórz realną scenę z menu startowym i przyciskiem zamknięcia.
3) Dodaj działający runner, test boot oraz test celowo błędny uruchamiany wyłącznie flagą --self-test-failure.
4) Zapisz wersję narzędzi i stan etapu; nie dodawaj nieużywanych pustych klas przyszłych systemów.
Pułapka do uniknięcia: Nie generuj jednocześnie całej gry ani pustych metod z pass udających ukończone moduły.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: Import headless; zwykły boot GUI i Exit; B01 dla dostępnej sceny; runner self-test musi zwrócić1, normalny0. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Projekt startuje z czystego importu; menu reaguje; runner wykrywa błąd; żadna nieistniejąca klasa nie jest referencją runtime. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M01 — Dane mapy i geometria kolizji

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M01.

B. KONTEKST
Wymagany stan repo: M00. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M01 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §6.1–6.2, §7, §16.2, §17.1. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Dane mapy i geometria kolizji. Oczekiwany rezultat: Geometria przechodzi testy brzegowe; błędna mapa nie uruchamia sesji; żaden test nie wymaga jeszcze brakującej mapy.

D. PLIKI
Utwórz: core/game_types.gd, core/game_config.gd, core/map_definition.gd, core/collision_world.gd, data/gameplay.json, data/maps/dock.json, tools/validate_content.gd, tests/unit/test_content.gd, tests/unit/test_collision.gd, tests/fixtures/valid_map.json, tests/fixtures/invalid_map.json.
Zmień: app/app_root.gd, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: GameTypes DTO; GameConfig.from_json/validate; MapDefinition.from_json/validate; CollisionWorld.configure/move/blocks_segment; content validator CLI.
1) Utwórz walidowane typy i dokładny layout dock.
2) Zaimplementuj swept AABB, tie-break, slide i test odcinka ze ścianą.
3) Dodaj diagnostyczny podgląd geometrii dock do uruchamialnej sceny.
4) Walidator na tym etapie wymaga istniejącego dock; garden/reactor są jawnie pending do M10.
Pułapka do uniknięcia: Nie używaj RigidBody2D ani dwóch niezależnych źródeł kolizji.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: C01 na istniejącej zawartości; K01/K02; granice mapy; NaN i overlap spawn; zwykłe menu nadal działa. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Geometria przechodzi testy brzegowe; błędna mapa nie uruchamia sesji; żaden test nie wymaga jeszcze brakującej mapy. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M02 — Ruch dwóch dronów i zryw

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M02.

B. KONTEKST
Wymagany stan repo: M01. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M02 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §6.1–6.2, §16–17. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Ruch dwóch dronów i zryw. Oczekiwany rezultat: Dwa drony poruszają się niezależnie bez diagonal boost i tunelowania; długi dash ma120units; snapshot nie mutuje hosta.

D. PLIKI
Utwórz: core/input_command.gd, core/world_state.gd, core/game_snapshot.gd, core/game_event.gd, core/movement.gd, core/simulation.gd, app/input_router.gd, presentation/world_view.gd, presentation/drone_view.gd, presentation/camera_rig.gd, scenes/world.tscn, scenes/drone.tscn, tests/unit/test_movement.gd, tests/unit/test_input.gd, tests/unit/test_simulation.gd.
Zmień: app/app_root.gd, scenes/app.tscn, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: InputRouter.feed/sample/clear; InputCommand.axis/copy; Movement.begin_dash/step; Simulation.initialize/step/snapshot; GameSnapshot.capture/copy; WorldView.present.
1) Podłącz jedną ścieżkę InputCommand do obu slotów w developerskim trybie testowym.
2) Zaimplementuj60Hz ruch, hamowanie, dash10tick/cooldown90 i kolizje.
3) Dodaj snapshot copy oraz render między tickami; tymczasowy rysunek ma jawny status developer art.
4) Włącz developerskie sterowanie drugim slotem tylko dla debug; blokuj input przy menu/focus loss.
Pułapka do uniknięcia: Nie wiąż prędkości z render delta i nie mieszaj animacji z colliderem.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: M01–M03,K01,I01,S03; ręczny ruch i zryw przy30/60/120renderFPS. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Dwa drony poruszają się niezależnie bez diagonal boost i tunelowania; długi dash ma120units; snapshot nie mutuje hosta. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M03 — Pierwsza grywalna zagadka przewodu

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M03.

B. KONTEKST
Wymagany stan repo: M02. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M03 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §6.3–6.4, §17.4. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Pierwsza grywalna zagadka przewodu. Oczekiwany rezultat: Gracze mogą świadomie uruchomić trzy beacony; dash przerywa przewód, charge zachowuje zasady; brak zależności od sieci.

D. PLIKI
Utwórz: core/link_system.gd, core/objective_system.gd, presentation/link_view.gd, tests/unit/test_link.gd, tests/unit/test_objectives.gd.
Zmień: core/simulation.gd, core/world_state.gd, presentation/world_view.gd, scenes/world.tscn, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: LinkSystem.evaluate/find_socket/hits_beacon; ObjectiveSystem.step; Simulation._consume_actions.
1) Dodaj jeden aktywny socket i jego globalny cooldown.
2) Wylicz prostą/łamaną, długości, blokowanie i odległość trafienia beacona.
3) Zaimplementuj charge300, grace30, decay co 2 ticki oraz kolejne cele.
4) Pokaż przyczynę nieaktywnego przewodu i postęp; zagraj duetem w pierwszy dock.
Pułapka do uniknięcia: Nie uznawaj dotknięcia celu końcówką za poprawne przeciągnięcie światła.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: L01–L03,O01–O02; jednoczesne E obu graczy; beacon trafiony przez oba segmenty nie ładuje się2×. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Gracze mogą świadomie uruchomić trzy beacony; dash przerywa przewód, charge zachowuje zasady; brak zależności od sieci. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M04 — Zagrożenia, ewakuacja i wynik sektora

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M04.

B. KONTEKST
Wymagany stan repo: M03. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M04 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §5–6.5–6.7, §17.4. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Zagrożenia, ewakuacja i wynik sektora. Oczekiwany rezultat: Jeden sektor jest kompletną wygrywalną/przegrywalną grą zczytelnymi zagrożeniami i poprawnym wynikiem.

D. PLIKI
Utwórz: core/hazard_system.gd, tests/unit/test_hazards.gd.
Zmień: core/simulation.gd, core/objective_system.gd, core/world_state.gd, core/game_snapshot.gd, presentation/world_view.gd, tests/unit/test_simulation.gd, tests/unit/test_objectives.gd, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: HazardSystem.phase_at/hits/apply; ObjectiveSystem.finish_sector/final_score; Simulation._advance_timers/_resolve_phase.
1) Dodaj oba cykle hazardów i matematyczne swept tests.
2) Wprowadź globalne integrity, stun, immunity i koszt max 1/30tick.
3) Zaimplementuj extraction120tick, timer i rozstrzygnięcie ostatniego ticka.
4) Dodaj pełen cykl start → play → won/failed → restart jednego sektora debug.
Pułapka do uniknięcia: Nie zadawaj podwójnych obrażeń duetowi i nie naliczaj premii sektora wielokrotnie.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: H01–H03,O03,S01–S02; wszystkie cykle RELAXED sumują się do zadanego period. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Jeden sektor jest kompletną wygrywalną/przegrywalną grą zczytelnymi zagrożeniami i poprawnym wynikiem. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M05 — Cykl ekspedycji i lokalny zapis

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M05.

B. KONTEKST
Wymagany stan repo: M04. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M05 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §5, §9, §13, §17.3. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Cykl ekspedycji i lokalny zapis. Oczekiwany rezultat: Cała lokalna ekspedycja kończy się prawidłowym wynikiem; loading nie blokuje UI; zapis ma fallback.

D. PLIKI
Utwórz: app/scene_router.gd, services/settings_store.gd, services/records_store.gd, services/log_service.gd, services/asset_catalog.gd, tests/unit/test_persistence.gd, tests/integration/test_flow.gd.
Zmień: app/app_root.gd, app/app_state.gd, core/simulation.gd, scenes/app.tscn, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: SceneRouter.show/clear; SettingsStore.load_settings/save_settings; RecordsStore.submit/best; AssetCatalog.load_boot/begin_sector/poll_loading; LogService.write/flush.
1) Zbuduj przejścia loading/countdown/intermission/results bez gubienia AppRoot.
2) W developerskim scenariuszu użyj dock trzy razy i wyraźnie oznacz brak map M10; nie opublikuj tego jako content release.
3) Dodaj zachowanie integrity i score oraz atomowy zapis rekordów/settings.
4) Zweryfikuj cleanup i anulowanie asynchronicznego load przez generation.
Pułapka do uniknięcia: Nie niszcz sesyjnych usług przy każdej zmianie WorldView.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: PS01,F01 w wersji lokalnej;3 sektory debug i 2 restarty; brak podwojonych sygnałów. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Cała lokalna ekspedycja kończy się prawidłowym wynikiem; loading nie blokuje UI; zapis ma fallback. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M06 — Zamknięty protokół i realny transport

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M06.

B. KONTEKST
Wymagany stan repo: M05. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M06 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §18–19, §23. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Zamknięty protokół i realny transport. Oczekiwany rezultat: Wire format ma jednoznaczne wymiary107B/35B; wadliwe bytes nie crashują; dwie instancje wymieniają dane przez ENet.

D. PLIKI
Utwórz: net/protocol.gd, net/packet_codec.gd, net/message_guard.gd, net/net_transport.gd, net/lobby_state.gd, tools/build_manifest.gd, build_manifest.json, tests/unit/test_protocol.gd, tests/fixtures/protocol_vectors.json, tests/integration/network_harness.gd, tests/integration/network_harness.tscn, tests/integration/test_network.gd.
Zmień: app/app_root.gd, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: PacketCodec.encode/decode; MessageGuard.accept; NetTransport.start_host/start_client/poll/send/close; manifest --write/--check.
1) Zaimplementuj wszystkie schematy wire z limitem1000B i niezależny golden Ping.
2) Zaimplementuj SceneMultiplayer.send_bytes/peer_packet z manual poll i 3 kanałami.
3) Połącz dwie realne instancje localhost, wymień Hello/Welcome i snapshot testowy.
4) Sprawdź rzeczywiste packet sizes i brak fragmentacji, utwórz pierwszy smoke eksportowy na dostępnych OS.
Pułapka do uniknięcia: Nie zastępuj testu realnego transportu samym round-tripem kodeka ani RPC synchronizerem.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: P01–P04,N01 transport; queue/rate validation; przetestuj error port bind i close→rebind. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Wire format ma jednoznaczne wymiary107B/35B; wadliwe bytes nie crashują; dwie instancje wymieniają dane przez ENet. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M07 — Lobby, discovery i bariery ładowania

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M07.

B. KONTEKST
Wymagany stan repo: M06. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M07 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §9, §18.1–18.4, §19.3/19.5. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Lobby, discovery i bariery ładowania. Oczekiwany rezultat: Dwóch ludzi może znaleźć pokój, dołączyć i dotrzeć do tego samego countdown; single player nie startuje.

D. PLIKI
Utwórz: app/match_session.gd, net/lan_discovery.gd, ui/ui_root.gd, ui/menu_presenter.gd, ui/lobby_presenter.gd, scenes/menus.tscn, scenes/lobby.tscn, tests/integration/test_session.gd.
Zmień: app/app_root.gd, app/scene_router.gd, app/app_state.gd, net/lobby_state.gd, net/message_guard.gd, tests/integration/test_network.gd, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: MatchSession.host/join/set_ready/request_start/leave; LanDiscovery.start_host/start_scan/poll/stop; LobbyState.set_options/can_start; UIRoot.show_screen.
1) Podłącz formularze host/join i ręczne IPv4.
2) Dodaj discovery z nonce,TTL i efemeryczny port klienta.
3) Zaimplementuj revision,ready obu i LoadSector/Loaded/Begin.
4) Dodaj timeout8/15s,Cancel i odmowę wersji/hasza; wszystkie ekrany mogą jeszcze używać bazowego theme.
Pułapka do uniknięcia: Nie wiąż discovery klienta na7778 i nie wierz adresowi wtreści datagramu.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: N01,N05,F01; oba ready wymagane; zmiana seed czyści gotowość; spóźnione Loaded nie otwiera starej sceny. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Dwóch ludzi może znaleźć pokój, dołączyć i dotrzeć do tego samego countdown; single player nie startuje. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M08 — Autorytatywna rozgrywka LAN

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M08.

B. KONTEKST
Wymagany stan repo: M07. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M08 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §13.3, §18–19.1–19.6. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Autorytatywna rozgrywka LAN. Oczekiwany rezultat: Pełna ekspedycja debug przezLAN kończy się jednym zgodnym wynikiem; client nie może sam zmienić charge/integrity.

D. PLIKI
Utwórz: net/host_replication.gd.
Zmień: app/match_session.gd, app/app_root.gd, net/message_guard.gd, core/simulation.gd, presentation/world_view.gd, tests/integration/test_network.gd, tests/integration/test_session.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: HostReplication.enqueue/commands_for/capture/drain_events/reset; MatchSession.fixed_update/render_frame/vote.
1) Zaimplementuj kolejki komend wg target tick i seriale krawędzi.
2) Tylko host uruchamia Simulation; client wyświetla pełne snapshoty30Hz.
3) Podłącz eventy i SessionState oraz intermission/results/rematch.
4) Przed M09 klient używa kontrolowanego target tick z ostatniego snapshotu; jawnie oznacz brak finalnej predykcji.
Pułapka do uniknięcia: Nie twórz drugiej autorytatywnej Simulation po stronie gościa.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: N02 na dostępnych platformach,N06,S01 na LAN; oba sloty jednocześnie dash/socket;10 rematch. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Pełna ekspedycja debug przezLAN kończy się jednym zgodnym wynikiem; client nie może sam zmienić charge/integrity. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M09 — Predykcja, czas sieciowy i utrata pakietów

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M09.

B. KONTEKST
Wymagany stan repo: M08. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M09 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §19.6–19.9, §23. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Predykcja, czas sieciowy i utrata pakietów. Oczekiwany rezultat: Ruch gościa reaguje lokalnie; timers po korekcie zgodne; chwilowy brak pakietów nie zawiesza meczu ani menu.

D. PLIKI
Utwórz: net/client_prediction.gd, net/snapshot_buffer.gd, net/network_clock.gd, tests/unit/test_prediction.gd, tests/integration/fault_link.gd.
Zmień: app/match_session.gd, app/app_root.gd, net/host_replication.gd, presentation/world_view.gd, tests/integration/test_network.gd, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: ClientPrediction.push/reconcile/present/reset; SnapshotBuffer.insert/sample; NetworkClock.on_pong/advance/next_command_ticks.
1) Dodaj pomiar RTT przez ping,lead 2..8 i monotoniczne target ticks.
2) Zaimplementuj pełne odtwarzanie własnego PlayerState oraz bufor 32 snapshotów.
3) Dodaj smoothing przy progach 2/48 px, freeze 250 ms,heartbeat i disconnect 3 s.
4) Testuj FaultLink oraz oddzielnie realny ENet przy loss; dedup event i serial dash.
Pułapka do uniknięcia: Nie cofaj target tick i nie traktuj ostatniego otrzymanego input jako granicy rozliczonej symulacji.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: PR01–PR03,N03–N04; spóźnienia, zmiana kolejności i duplikaty; brak podwójnej akcji; po2s czystej sieci stan zgodny. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Ruch gościa reaguje lokalnie; timers po korekcie zgodne; chwilowy brak pakietów nie zawiesza meczu ani menu. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M10 — Docelowe mapy i balans zawartości

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M10.

B. KONTEKST
Wymagany stan repo: M09. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M10 w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §5–8, §22.2. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Docelowe mapy i balans zawartości. Oczekiwany rezultat: Wszystkie3 sektory mają unikalny layout; każda kombinacja jest ukończalna lub wyraźnie oznaczona do poprawy przed bramką.

D. PLIKI
Utwórz: data/maps/garden.json, data/maps/reactor.json, tests/fixtures/dock_success.json, tests/fixtures/garden_success.json, tests/fixtures/reactor_success.json, tests/manual/playtest_matrix.md.
Zmień: data/maps/dock.json, tools/validate_content.gd, services/asset_catalog.gd, app/match_session.gd, tests/unit/test_content.gd, tests/unit/test_simulation.gd, build_manifest.json.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: MapDefinition.validate; content flood-fill; Simulation.reset_sector; warianty seed iorder map.
1) Wprowadź dokładne3 layouty i3 warianty z §7.
2) Usuń powtarzany dock ze scenariusza ekspedycji.
3) Zapisz rzeczywiste fixture wejścia prowadzące do sukcesu, bez cheatów.
4) Przeprowadź testy 18 konfiguracji i pierwsze testy z nowymi duetami; korekty balansu zapisuj jakoADR, zachowując scope.
Pułapka do uniknięcia: Flood-fill drogi drona nie jest dowodem, że przewód może zasilić wszystkie cele.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: C02 i success fixtures; manual matrix18kombinacji; wskaźniki zrozumienia pierwszego celu. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Wszystkie3 sektory mają unikalny layout; każda kombinacja jest ukończalna lub wyraźnie oznaczona do poprawy przed bramką. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M11a — Finalne assety i katalog zasobów

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M11a.

B. KONTEKST
Wymagany stan repo: M10. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M11a w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §8, §16.5, §20. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Finalne assety i katalog zasobów. Oczekiwany rezultat: Każdy wymagany asset P0 ma docelowy wygląd, poprawną alfę i udokumentowane pochodzenie.

D. PLIKI
Utwórz: assets/art/drone_a.svg, assets/art/drone_b.svg, assets/art/sensor.svg, assets/art/station_atlas.svg, assets/art/devices.svg, assets/art/atlas_regions.json, assets/art/grain.png, assets/art/particle.svg, assets/art/dock_bg.svg, assets/art/garden_bg.svg, assets/art/reactor_bg.svg, assets/ui/icons.svg, assets/ui/title.svg, assets/fonts/AtkinsonHyperlegible-Regular.ttf, assets/fonts/AtkinsonHyperlegible-Bold.ttf, assets/fonts/OFL.txt, tools/asset_bake.gd, tests/integration/test_presentation.gd.
Zmień: services/asset_catalog.gd, tools/validate_content.gd, docs/ASSET_MANIFEST.md, THIRD_PARTY_NOTICES.md.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: AssetCatalog.get_texture; atlasregion construction; asset_bake grain generation; license validation.
1) Wykonaj własną grafikęSVG zgodną zmanifestem i rozróżnieniem sylwetek.
2) Pozyskaj font z jego oficjalnego źródła wraz zlicencją, zapisz lokalnie.
3) Utwórz regiony atlasów i walidację dimensions/padding; podmień developer art.
4) Obejrzyj wszystkie assety w 720p i skali szarości; popraw czytelność.
Pułapka do uniknięcia: Nie traktuj losowych gradientów i surowych prostokątów jako skończonego artu.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: C01 asset manifest,V01 podstawowy; rzeczywisty przegląd obrazu; pliki i licencje kompletne. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Każdy wymagany asset P0 ma docelowy wygląd, poprawną alfę i udokumentowane pochodzenie. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M11b — Animacje, shadery i efekty

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M11b.

B. KONTEKST
Wymagany stan repo: M11a. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M11b w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §6.7, §8.2, §20. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Animacje, shadery i efekty. Oczekiwany rezultat: Obraz jest spójny i czytelny, efekty nie zmieniają ticków, lowtier zachowuje wszystkie informacje.

D. PLIKI
Utwórz: presentation/fx_pool.gd, shaders/link.gdshader, shaders/device.gdshader, shaders/background.gdshader.
Zmień: presentation/world_view.gd, presentation/drone_view.gd, presentation/link_view.gd, presentation/camera_rig.gd, scenes/world.tscn, scenes/drone.tscn, tests/integration/test_presentation.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: DroneView.present/play_event; FxPool.emit_event/update_effects/clear; CameraRig.impulse; LinkView.present.
1) Zbuduj animacje części drona i klipy bez wpływu na collider.
2) Dodaj trzy proste shadery, warstwy przewodu i efekty beacon/hit.
3) Zastosuj pule, low/high particles i reduced motion.
4) Rozgrzej materiały podczas loading i zweryfikuj drawcalls/overdraw.
Pułapka do uniknięcia: Nie używaj bloom ani funkcji Forward+ nieobecnych w Compatibility.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: V01 i wszystkie stany PlayerMode/LinkStatus; limit 320 drobin; brak skoków przy pierwszym dash. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Obraz jest spójny i czytelny, efekty nie zmieniają ticków, lowtier zachowuje wszystkie informacje. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M12a — Kompletne menu, HUD i wynik

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M12a.

B. KONTEKST
Wymagany stan repo: M11b. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M12a w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §9. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Kompletne menu, HUD i wynik. Oczekiwany rezultat: Każdy ekran z §9 ma działające akcje i stan busy/error; brak developer-only przycisków w release.

D. PLIKI
Utwórz: ui/hud_presenter.gd, ui/results_presenter.gd, ui/ui_theme.tres, scenes/hud.tscn, scenes/results.tscn, tests/integration/test_ui.gd.
Zmień: ui/ui_root.gd, ui/menu_presenter.gd, ui/lobby_presenter.gd, scenes/menus.tscn, scenes/lobby.tscn, app/app_root.gd, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: HudPresenter.present/show_hint; ResultsPresenter.present; UIRoot.show_error/show_overlay; intent routing.
1) Zastosuj docelowy theme, spacing i typografię.
2) Dokończ wszystkie ekrany sieci, HUD,intermission,results i głosowanie nad rewanżem.
3) Dodaj kontekstowe podpowiedzi i dokładne błędy z §19.9.
4) Weryfikuj flow myszy/klawiatury/pada, focus po modalach i „Gra nadal trwa”.
Pułapka do uniknięcia: Nie wyliczaj wyniku niezależnie w ResultsPresenter.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: U01,F01,F02; ekran wyników korzysta ze score hosta; brak wejścia gry spod nakładki. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Każdy ekran z §9 ma działające akcje i stan busy/error; brak developer-only przycisków w release. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M12b — Ustawienia, remap i dostępność

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M12b.

B. KONTEKST
Wymagany stan repo: M12a. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M12b w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §5.4, §9.1, §17.1. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Ustawienia, remap i dostępność. Oczekiwany rezultat: Wszystkie opcje mają realny efekt i zachowują się po restarcie; duża typografia nie ucina akcji.

D. PLIKI
Utwórz: ui/settings_presenter.gd, scenes/settings.tscn.
Zmień: ui/ui_root.gd, services/settings_store.gd, app/input_router.gd, presentation/camera_rig.gd, presentation/link_view.gd, ui/ui_theme.tres, tests/integration/test_ui.gd, tests/unit/test_persistence.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: SettingsPresenter.open/capture_binding/cancel_capture; SettingsStore.validate/save_settings; InputRouter.configure.
1) Zbuduj obraz/dźwięk/dostępność/controls z realnymi ustawieniami.
2) Dodaj przechwytywanie przypisań,zamianę konfliktów i ochronę ui_cancel.
3) Zaimplementuj przywracanie trybu okna po 10 s,ui_scale i reduced motion.
4) Sprawdź zapis atomowy i brak zapisu przy read-only; settings muszą nadal działać w pamięci.
Pułapka do uniknięcia: Nie pozwalaj capture klawisza uruchomić dash albo zamknąć całej aplikacji.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: U02,I01,PS01;960×540 ui_scale1,3; pełny przepływ pad-only. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Wszystkie opcje mają realny efekt i zachowują się po restarcie; duża typografia nie ucina akcji. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M13a — Kompozycja audio i routing zdarzeń

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M13a.

B. KONTEKST
Wymagany stan repo: M12b. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M13a w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §10, §16.5. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Kompozycja audio i routing zdarzeń. Oczekiwany rezultat: Każda istotna akcja ma spójny feedback; brak zdublowanego dash i klików muzyki.

D. PLIKI
Utwórz: presentation/audio_director.gd, data/audio_bank.json, assets/audio/music_base.ogg, assets/audio/music_pulse.ogg, assets/audio/music_resolve.ogg, assets/audio/ambience.ogg, assets/audio/move.wav, assets/audio/dash.wav, assets/audio/socket.wav, assets/audio/charge.wav, assets/audio/beacon.wav, assets/audio/hit.wav, assets/audio/telegraph.wav, assets/audio/ping.wav, assets/audio/ui_focus.wav, assets/audio/ui_accept.wav, assets/audio/ui_back.wav, assets/audio/victory.wav, assets/audio/defeat.wav, tests/integration/test_audio.gd.
Zmień: services/asset_catalog.gd, tools/asset_bake.gd, app/app_root.gd, scenes/app.tscn, project.godot, docs/ASSET_MANIFEST.md, tests/test_runner.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: AudioDirector.configure/play_event/update_frame/set_mix/stop_session; audio_bank schema; asset generation offline.
1) Przygotuj docelowe dźwięki i spójną muzykę z manifestu; odbierz je odsłuchem.
2) Utwórz buses i pule głosów,priorytety i crossfade.
3) Podłącz autorytatywne eventy oraz deduplikację przewidywanego dash; loops aktualizuj bez restartów co klatkę.
4) Zapisz pochodzenie i licencje; wszystkie audio lokalne i offline.
Pułapka do uniknięcia: Nie oznaczaj muzyki jako ukończonej po samym sprawdzeniu długości pliku.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: A01,A02; limit głosów,wyciszenie bus,zamknięcie sesji; realny odsłuch loopów. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Każda istotna akcja ma spójny feedback; brak zdublowanego dash i klików muzyki. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M13b — Game feel i odbiór duetu

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M13b.

B. KONTEKST
Wymagany stan repo: M13a. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M13b w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §6.7–10, §21. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Game feel i odbiór duetu. Oczekiwany rezultat: Gra daje zrozumiały feedback; zgłoszenia są zanotowane; brak obserwatorów oznacza pending, nie fikcyjne playtesty.

D. PLIKI
Utwórz: brak.
Zmień: presentation/drone_view.gd, presentation/link_view.gd, presentation/fx_pool.gd, presentation/camera_rig.gd, presentation/audio_director.gd, ui/hud_presenter.gd, tests/manual/playtest_matrix.md, tests/integration/test_presentation.gd.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: Wartości animacji iFX; trigger timing; HUD hints; bez zmian protokołu i fizyki.
1) Zgraj dash,charge,beacon i hit z czasami animacji/audio.
2) Sprawdź rozróżnienie własnego/zdalnego drona i przyczyn nieaktywnego przewodu.
3) Przeprowadź minimum 5 nowych duetów, jeśli dostępni; zanotuj faktyczne obserwacje.
4) Popraw czytelność i tempo w granicach§6.7; nie dodawaj nowych mechanik.
Pułapka do uniknięcia: Nie maskuj trudności niewidzialną zmianą zasad i nie zatrzymuj Simulation dla hit-stop.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: Playtest comprehension i sukcesy; U02 orazA01 po zmianach; test przy RTT50ms. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Gra daje zrozumiały feedback; zgłoszenia są zanotowane; brak obserwatorów oznacza pending, nie fikcyjne playtesty. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M14a — Odporność protokołu i regresje sesji

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M14a.

B. KONTEKST
Wymagany stan repo: M13b. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M14a w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §19, §22–23. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Odporność protokołu i regresje sesji. Oczekiwany rezultat: Żaden znany błąd nie psuje stanu ani nie zawiesza wyjścia; nieprawidłowe dane są ograniczone caps.

D. PLIKI
Utwórz: brak.
Zmień: net/message_guard.gd, net/packet_codec.gd, net/net_transport.gd, app/match_session.gd, tests/unit/test_protocol.gd, tests/integration/test_network.gd, tests/integration/test_session.gd, tests/integration/test_flow.gd, tests/integration/fault_link.gd, tests/manual/playtest_matrix.md.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: Walidacja caps/role/state; cleanup i timeout; tylko poprawki wykazane przez scenariusze.
1) Przejdź wszystkie komunikaty przez truncację i błędne wektory danych.
2) Zbadaj nowe/stare match IDs,spóźnione Loaded,reorder i serialwrap.
3) Uruchom30 rematch,kill obu ról oraz realny ENet przy stratach.
4) Napraw wyniki z reprodukcją i testem regresji; nie zmieniaj wire bez zwiększenia wersji.
Pułapka do uniknięcia: Nie uznawaj testów FaultLink za test retransmisji transportu.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: P01–P04,N01–N06,F01–F02,PR01–PR03; zapisane logi z rzeczywistych poleceń. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Żaden znany błąd nie psuje stanu ani nie zawiesza wyjścia; nieprawidłowe dane są ograniczone caps. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M14b — Profilowanie i optymalizacja zmierzonych kosztów

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M14b.

B. KONTEKST
Wymagany stan repo: M14a. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M14b w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §20–22. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Profilowanie i optymalizacja zmierzonych kosztów. Oczekiwany rezultat: Pomiary mieszczą się w budżetach albo jasno blokują release; nie ma deklaracji60FPS bez testu.

D. PLIKI
Utwórz: services/diagnostics.gd, tests/perf/benchmark.gd, tests/perf/benchmark.tscn.
Zmień: app/app_root.gd, presentation/fx_pool.gd, presentation/world_view.gd, services/asset_catalog.gd, tests/manual/playtest_matrix.md.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: Diagnostics.sample_frame/sample_tick/report; benchmark warmup60s/sample600s; pule i ograniczenie overdraw.
1) Dodaj zbieranie p95/p99,RAM,RTT,bandwidth bez spamu wlogu.
2) Zmierz baseline i mocniejszy sprzęt, low/high oraz60/120FPS.
3) Optymalizuj tylko zidentyfikowane koszty; porównaj ten sam scenariusz.
4) Powtórz30 rematch leaktest, zachowaj raport hardware/settings/commit.
Pułapka do uniknięcia: Nie dodawajC++/ECS w miejsce prostej redukcji alokacji luboverdraw.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: Budżety§21; pełen render benchmark, nie headless; ponowne unit tylko gdy zmieniono funkcje logiczne. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Pomiary mieszczą się w budżetach albo jasno blokują release; nie ma deklaracji60FPS bez testu. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M15a — Paczki Windows/Linux i powtarzalny build

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M15a.

B. KONTEKST
Wymagany stan repo: M14b. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M15a w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §12, §22.4, §28. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Paczki Windows/Linux i powtarzalny build. Oczekiwany rezultat: Obie paczki działają bez edytora developerskiego; nie brakuje importowanych zasobów; odpowiadają temu samemu protokołowi.

D. PLIKI
Utwórz: export_presets.cfg, tools/export.sh, tools/export.ps1, .github/workflows/verify.yml, tests/manual/release_matrix.md.
Zmień: README.md, THIRD_PARTY_NOTICES.md, build_manifest.json, tools/build_manifest.gd, docs/RELEASE_CHECKLIST.md.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: Exportwrappers: validate/import/test/manifest/export/package/hash; dwa presets; workflow wywołuje te same komendy.
1) Wyklucztesty, tools i debug fixtures zrelease, zachowaj licencje i lokalne banki assetów.
2) Zbuduj Windows x64 ZIP i Linux x64 tar.gz z tego samego commita.
3) Sprawdź manifest/checksum,executability i start bez Godota.
4) Opisz instalację,LAN,firewall,sterowanie,knownlimits i brak reconnect.
Pułapka do uniknięcia: Nie publikuj ani nie wysyłaj paczek zewnętrznie bez osobnego polecenia użytkownika.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: Czyste konto,ścieżka z polskimi znakami,instalacja w katalogu read-only,boot i join na obu OS; offline scan sieci. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Obie paczki działają bez edytora developerskiego; nie brakuje importowanych zasobów; odpowiadają temu samemu protokołowi. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

### Prompt M15b — Ostateczny odbiór wydania

```text
A. ROLA
Jesteś GPT-6.1 Sol, programistą gry LUMEN LINK. Implementujesz przyjętą architekturę Godot 4.5.2 Standard, typed GDScript, Compatibility, ENet. Wykonaj tylko milestone M15b.

B. KONTEKST
Wymagany stan repo: M15a. Przeczytaj docs/PROJECT_STATUS.md, docs/MASTER_SPEC.md, docs/ARCHITECTURE.md, docs/CODE_CONTRACTS.md, docs/NETWORK_PROTOCOL.md i opis M15b w docs/IMPLEMENTATION_PLAN.md. Szczególnie obowiązują §22–28. Jeśli to M00, utwórz te dokumenty z dołączonego kompletnego blueprintu. Host jest jedynym właścicielem WorldState; symulacja 60 Hz, snapshot/input 30 Hz, dokładnie 2 ludzi.

C. CEL
Ostateczny odbiór wydania. Oczekiwany rezultat: Wydanie jest przyjęte tylko przy wszystkich P0 PASS; specyfikacja, status i build odpowiadają sobie.

D. PLIKI
Utwórz: brak.
Zmień: docs/PROJECT_STATUS.md, docs/RELEASE_CHECKLIST.md, tests/manual/release_matrix.md, tests/manual/playtest_matrix.md, README.md.
Zawsze uaktualnij docs/PROJECT_STATUS.md. Przy udokumentowanej zmianie kontraktu uaktualnij odpowiadający dokument i docs/ADR.md.

E. WYMAGANIA
API: Braknowychsystemów; tylko udokumentowane poprawki blokujących błędów zoddzielnym testem.
1) Zagraj pełną ekspedycję Windows→Linux i Linux→Windows bez internetu.
2) Przejdź18wariantów,wyniki,rematch,disconnect i accessibility według matrycy.
3) Zbierz artefakty testów i rozdziel PASS/FAIL/NOTRUN.
4) Oznaczreleasecandidate dopieropo przejściu wszystkich P0; brak środowiska pozostawia precyzyjny blocker.
Pułapka do uniknięcia: Nie nazywaj gotowym wydaniem paczki z nieprzetestowanym LAN albo roboczą grafiką.

F. OGRANICZENIA
Czytelny typowany kod, jawna obsługa błędów, zachowanie wcześniejszych funkcji. Bez nowych zależności, niepowiązanego refaktoru, pustych stubów przedstawianych jako gotowe, usuwania funkcji i samowolnej zmiany architektury. Nie wprowadzaj systemów zkolejnych milestone. Wszystkie tworzone zasoby muszą być legalnego pochodzenia. Nie publikuj, nie wdrażaj i nie wysyłaj nic zewnętrznie.

G. TESTY
Wykonaj import/parse projektu i odpowiednie automatyczne suites oraz rzeczywisty smoke GUI, jeśli środowisko to umożliwia. Konkretne sprawdzenia: Pełna checklista§28; finalny hash paczek i powiązanie z commitem; manualny audio/visual/playtest. Zapisz polecenia,exitcode i wyniki. Nigdy nie deklaruj PASS bez wykonania. Brak sprzętu,drugiej maszyny albo możliwości GUI oznacz NOT RUN i podaj dokładny zakres brakującej weryfikacji.

H. KRYTERIUM UKOŃCZENIA
Wydanie jest przyjęte tylko przy wszystkich P0 PASS; specyfikacja, status i build odpowiadają sobie. Projekt nadal startuje; wcześniejsze odebrane funkcje działają; dokumentacja statusu odpowiada kodowi. Test wymagany przez odbiór, lecz niewykonany, pozostawia bramkę pending.

I. RAPORT
Jeżeli masz dostęp do repo, wprowadź i zweryfikuj zmiany bezpośrednio. W przeciwnym razie zwróć pełną treść każdego nowego/zmienionego pliku i dokładną ścieżkę; nie zastępuj kodu wielokropkiem. W podsumowaniu wymień utworzone pliki,zmienione pliki,wdrożone funkcje,wykonane testy,wyniki,pozostałe problemy i następny milestone. Nie twierdź, że ukończono całą grę po tym jednym etapie.
```

