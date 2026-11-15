# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-15. **M06 i M07 ukończone; odbiór techniczny Linux/localhost: PASS**.
Bieżący commit: brak (katalog bez Git); build_manifest.json zawiera dokładny content SHA-256.
Zweryfikowany build: `7b95f1fb75c497b4528fb455f66596c43473670f3831d01acd08ff3533bc2096`.
Następny etap M08 nie został rozpoczęty. Historia M05: reports/m05/status.md.
M03/M04 playtest duetem nadal NOT RUN jako oddzielna bramka jakości, bez blokowania pracy kodowej.

## Zakres

M06: wszystkie 17 schematów wire1, jednoznaczne rozmiary 22/107/35 B,
bounded decode/encode, niezależne golden vectors, guard i rzeczywisty ENet,
manual poll, 3 kanały, kolejki/rate limits i manifest. Szczegóły i pliki:
[raport M06](reports/m06/REPORT.md).

M07: MatchSession, host/join przez literal IPv4, formularze i lobby na bazowym theme,
discovery nonce/TTL, dwa ready i revision, opcje hosta, LoadSector/Loaded/Begin,
obsługa błędów zgodności, timeout8/15 s, Cancel i cleanup. Tylko host zaczyna po
zgodności obu buildów i ready obu slotów. Samotny host nie może rozpocząć LAN.

Host używa Simulation wyłącznie do pierwszego COUNTDOWN180. Gość nie tworzy Simulation.
Stan końcowy M07 to READY po wspólnym countdown, potwierdzony reliable SessionState.
**Nie ma jeszcze sieciowego sterowania ani autorytatywnej rozgrywki — to M08.**
Lokalny developerski M05 dock×3 nadal działa osobno (F2). Pierwszy sieciowy start
korzysta z dock; garden/reactor należą do M10. Developer art pozostaje oznaczone.

## Pliki i API

Nowe M06 (12): net/protocol.gd, net/packet_codec.gd, net/message_guard.gd,
net/net_transport.gd, net/lobby_state.gd, tools/build_manifest.gd, build_manifest.json,
tests/unit/test_protocol.gd, tests/fixtures/protocol_vectors.json,
tests/integration/network_harness.gd, network_harness.tscn, test_network.gd (ostatnie w tests/integration/).
Nowe M07 (8): app/match_session.gd, net/lan_discovery.gd, ui/ui_root.gd,
ui/menu_presenter.gd, ui/lobby_presenter.gd, scenes/menus.tscn, scenes/lobby.tscn,
tests/integration/test_session.gd.

Zmiany: app/app_root.gd, app/app_state.gd, app/scene_router.gd, tests/test_runner.gd,
core/simulation.gd, core/hazard_system.gd i core/objective_system.gd (value zdarzeń
zgodne z istniejącą specyfikacją), README.md, docs/ADR.md i niniejszy status.
Dodatkowo .gd.uid, raporty i lokalne artefakty eksportowe poza repo.

API M06: Protocol.channel/mode/newer/ipv4; PacketCodec.encode/decode;
MessageGuard.accept/reset/record_invalid; NetTransport.start_host/start_client/poll/send/close;
LobbyState.set_ready/set_options/can_start; build_manifest --write/--check.
API M07: MatchSession.host/join/set_ready/set_options/request_start/loaded/poll/cancel/leave,
sygnały lobby_changed/phase_changed/load_requested/countdown_started/failed;
LanDiscovery.start_host/start_scan/poll/stop/results_changed; UIRoot.show_screen,
MenuPresenter.bind/set_rooms/set_busy, LobbyPresenter.bind/present_loading.
SceneRouter.active_generation chroni most SceneRouter → MatchSession.loaded.
Nie dodano pustych modułów replikacji/predykcji przyszłych milestone.

## Zachowanie i niezawodność

Manifest jest sprawdzany przed lobby: schema/protocol, engine version/build ID;
w source build także rzeczywisty hash data/core/net/app. Po zmianie kodu/danych
uruchom tools/build_manifest.gd --write; obaj gracze wymagają zgodnych buildów.
Sekwencje są per typ/nadawca. Stare session/match/Loaded nie zmieniają nowej gry.
Queue max128/drain64, limity global120/s,64 KiB/s i typów, malformed3/10 s,
przeciążenie sustained2 s. Nie dekodujemy obiektów, nie ładujemy ścieżek z sieci.

Transport nie emituje aplikacyjnych callbacków w środku C++ poll. Close idempotentny,
sygnały odłączane, bufory resetowane; port może zostać ponownie związany.
Handshake8 s, load15 s, Ping500 ms, banner1 s i utrata połączenia3 s.
Host czeka 200 ms po Reject. Timeout/Cancel loading czyści readiness i wraca do lobby;
gość prosi o abort istniejącym Leave(LOAD_FAILED), host odpowiada nonfatal Error.
Brak odpowiedzi podczas abort kończy sesję w ograniczonym czasie. Brak reconnect.

Discovery: host UDP7778; klient bind0, probe64 B, reply<=160 B, świeży nonce<=3 s,
adres/port odbiorcy z datagramu, nie z payload. Odpowiedzi2/s/IP i20/s globalnie,
lista max64, TTL3 s, skan10 s. Skan dopiero na żądanie użytkownika. Ręczne IP działa
bez discovery. Historia IP aktualizowana dopiero po udanym Welcome.
Automatyczne testy używają bind127.0.0.1 i probe loopback; normalne UI broadcast.
Nie zmieniamy zapory, nie stosujemy DNS/UPnP, brak usług internetowych podczas gry.

## Testy i dowody

Godot 4.5.2 Standard (6ce3de25aa58466e14ef354703ba8d9791a417da), Linux,
GUI OpenGL Compatibility/Mesa Intel HD 520, X11/XWayland.
Pełne komendy/exitcodes: reports/m07/commands.json, gui.commands.json,
processes-and-datagrams.json oraz reports/m06/export.commands.json.

| Sprawdzenie | Exit | Wynik / dowód |
|---|---:|---|
| headless editor import | 0 | PASS, m07/final-import.log |
| build_manifest --write i --check | 0 | PASS, manifest-write.log/manifest-check.log |
| runner --suite=all | 0 | PASS: 427 asercji, 14 suites, 0 failed/skipped; m07/all.log |
| runner --suite=all --self-test-failure | 1 | PASS detekcji celowego błędu; self-failure.log |
| dwa procesy ENet | 0/0 | PASS, process-host/client.json i logi |
| pomiar UDP/ENet | 0 | PASS, max UDP145 B, zero komend fragmentacji; processes-and-datagrams.json |
| dwa okna GUI host/gość | 0/0 | PASS, gui-host.png/gui-client.png i logi |
| eksport Linux debug + boot realnego AppRoot | 0 | PASS, m06/export*.log i export-boot.json |
| dwie instancje eksportu Linux | 0/0 | PASS, m06/export-host/client.json |

P01–P04: literal Ping i snapshot, każdy typ roundtrip, wszystkie truncacje/trailing,
NaN/Inf/enum/count/-128/UTF8/NUL, całe u64, serialwrap i stale ID, rate, realny DASH.
Formularz również obejrzano: gui-menu.png (7 s warmup i focus przed capture).
Screenshoty hosta i gościa wykonano w różnych chwilach; równość Begin sprawdza test.

N01/N05: rzeczywisty send_bytes/peer_packet, rebind, zajęty port, trzeci peer,
queue128/drain64 i jawny OVERLOAD. Session: oba ready, seed czyści ready,
niezgodny content odrzucony, stare local Loaded generation nie otwierają scen,
Begin dopiero po obu Loaded, countdown obu stron, handshake/load timeout,
Cancel gościa wraca obu do lobby, UDP probe/reply z efemerycznego portu i TTL.
Wszystkie wcześniejsze regresje M00–M05 nadal przechodzą.

Jedyny oczekiwany ERROR silnika w all.log pochodzi z testu zajętego portu:
„Couldn't create an ENet host”. Nie jest to FAIL. Końcowe logi nie mają SCRIPT ERROR
ani crash. Pierwsze próby wykryły i naprawiły zły root_path, nazwę native ready,
reentrant close podczas api.poll oraz pobieranie host po disconnect. Nie uznawano
nieudanych prób/harnessów za PASS. GUI używa normalnego Node/SceneTree, nie
niestandardowego MainLoop zakłócającego render. Helpery zachowane w raportach.

## Ograniczenia

Windows, dwa fizyczne komputery i prawdziwa dostawa broadcastu przez sieć/zaporę:
NOT RUN. Loopback i eksport Linux tego nie zastępują; bramki cross-OS/real-LAN wydania
pozostają pending. Playtest dwóch ludzi M03/M04: NOT RUN.

UI podstawowe, mapy docelowe M10, pełne menu M12, release packaging M15.
Artefakt smoke to build developerski z harnessami, nie wydanie. Niczego nie
opublikowano ani nie wysłano. M08 nie został rozpoczęty.
