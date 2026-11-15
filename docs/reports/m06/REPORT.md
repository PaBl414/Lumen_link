# M06 — protokół i transport

Data: 2026-11-15. Godot 4.5.2 Standard, build 6ce3de25aa58466e14ef354703ba8d9791a417da.
Kod wdrożony, odbiór techniczny Linux/localhost PASS. Końcowa weryfikacja: wspólny raport ../m07/commands.json i ../m07/all.log.

Utworzono wszystkie 12 plików M06: net/protocol.gd, packet_codec.gd,
message_guard.gd, net_transport.gd, lobby_state.gd; tools/build_manifest.gd;
build_manifest.json; tests/unit/test_protocol.gd; tests/fixtures/protocol_vectors.json;
tests/integration/network_harness.gd/.tscn i test_network.gd.
Zmieniono AppRoot, runner oraz wartości źródłowych zdarzeń DASH/HIT/BEACON w core,
aby odpowiadały istniejącemu kontraktowi wire. Wspólne zmiany integracyjne M07 opisuje PROJECT_STATUS.

Kodek obsługuje 17 komunikatów, header22, SnapshotBody107, PlayerRecord35,
InputRecord12 i EventRecord21. Bounded cursor i wszystkie limity długości/liczników,
ścisły UTF8 (przed konwersją), kontrolne znaki, finite f32, enumy i zakresy liczb.
Golden Ping30 B i snapshot107 powstały niezależnie przez Python struct.
Testy obejmują każdy typ, roundtrip, trailing bytes i truncację na każdym bajcie,
NaN/Inf, nielegalny enum/count/axis, UTF8/NUL, sequence wrap i stare identyfikatory,
rate Ping4/s i rzeczywisty DASH z serialem w value. u64 jest zachowany bitowo przez
signed Godot int64; test ffffffffffffffff nie jest ograniczony do małych timestampów.

Transport to prawdziwy ENet/SceneMultiplayer, bez RPC/synchronizera. 3 kanały,
manual poll, lokalny root_path=/root, object decoding i server relay wyłączone.
Callbacki lifecycle i pakiety są kolejkowane; aplikacyjne sygnały dopiero po api.poll.
Queue128, drain64, niecritical drop i kontrolny OVERLOAD. Guard sprawdza kierunek,
stan, session/match/sector, modularne seq, limity pakietów/bajtów i typów.
Tylko literal IPv4, max1 gość. Zajęty port jest jawnym błędem; close→rebind przechodzi.
Trzeci klient nie zostaje przyjęty. Oczekiwany komunikat silnika „Couldn't create
an ENet host” w all.log pochodzi z negatywnego testu zajętego portu, nie z awarii suite.

Pierwszy prototyp ujawnił konieczność ustawienia root_path oraz nieistniejące
peer.is_server (zastąpione get_unique_id==1). Test timeout/leave wykrył też crash przy
zamknięciu peer w trakcie native poll; obsługa lifecycle została przeniesiona poza
poll i zabezpieczona przed reentrancy. Końcowe testy tej samej reprodukcji przechodzą.

## Dwa procesy i datagramy

../m07/processes-and-datagrams.json zawiera pełne komendy, exitcodes oraz pomiary
transparentnego przekaźnika UDP na loopback; skrypt: measure_datagrams.py.
../m07/process-host.json i process-client.json potwierdzają Hello/Welcome,
zgodny session/match/hash, Begin i snapshoty do końca countdown.
Mierzono UDP payload wraz z narzutem Godot/ENet, a nie tylko send_bytes.
Parser komend ENet raportuje zero SEND_FRAGMENT/SEND_UNRELIABLE_FRAGMENT;
max datagramu 145 B, +28 B IPv4/UDP, poniżej MTU loopback. To pomiar lokalnego
scenariusza, nie deklaracja rozmiaru wszystkich możliwych datagramów na każdej sieci.
Nie wymagał raw capture ani uprawnień administratora.

## Smoke eksportowy

Zainstalowano oficjalne Linux x86_64 export templates 4.5.2 poza repo.
export_smoke.py odtwarza tymczasowy projekt/preset, import i eksport Linux debug.
Brak produkcyjnego export_presets.cfg i pipeline M15; ten artefakt zawiera harness
testowy i nie jest wydaniem gry. Niczego nie opublikowano.

export.commands.json i export-*.log: eksport, boot ze sprawdzeniem realnego AppRoot
(assets.dock/UI/MENU, nie tylko kod procesu), następnie dwa procesy wyeksportowanego
binary wymieniające dane przez ENet. export-host.json i export-client.json mają
zgodne identyfikatory i hash. export-boot.json potwierdza boot_ready=true.
Artefakt pozostaje w /home/pablo/.local/share/lumen-tools/m06-smoke/.

Windows, fizyczna para komputerów i cross-OS: NOT RUN — dostępne środowisko to Linux.
Nie zastępujemy tego localhostem; bramki wydania pozostają otwarte.
