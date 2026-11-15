# NETWORK_PROTOCOL — protokół gry 3 (dziewięć poziomów)

Aktualny kontrakt: `net/protocol.gd`, `net/packet_codec.gd`, `app/match_session.gd`.
Wersja3 dodaje stabilny wybór poziomu i pełny stan przeszkód. SnapshotBody ma113+L B,
gdzie L to liczba bajtów ID (1–32), zatem maksymalnie145 B. Nagłówek22 B,
PlayerRecord35 B, limit1000 B i discovery version1 pozostają bez zmian.
Starsze protokoły1/2 są odrzucane w handshake. Historyczny format2: reports/m11c/NETWORK_PROTOCOL_V2.md.

## 18. Architektura LAN

### 18.1 Połączenie i discovery

ENet host: UDP7777, `create_server(port,1,3)`. Klient: `create_client(ip,port,3)`. Domyślny port można zmienić. API ma wyłączone object decoding i server relay. Ustawienie `refuse_new_connections` po zajęciu slotu ogranicza kolejne próby. Transport może odrzucić trzeciego klienta przed aplikacyjnym handshake; komunikat u niego brzmi „Nie udało się połączyć — pokój może być zajęty”, a nie zmyślone precyzyjne potwierdzenie „Pokój pełny”.

Używać `SceneMultiplayer.send_bytes` i `peer_packet`, nie RPC i nie automatycznej replikacji scen [S5]. Dzięki temu protokół aplikacji ma jedno miejsce walidacji. `SceneTree.multiplayer_poll=false`, `MultiplayerAPI.poll` wywoływane jawnie [S8]. Wymagany prototyp tego adaptera w M06; jeśli dany eksport nie przechodzi testu, poprawić adapter przed gameplay networking.

Discovery: host wiąże osobny UDP7778; klient wiąże port0 i raz/s przez10s wysyła probe na255.255.255.255:7778 oraz dostępne broadcasty interfejsów, jeśli da się je uzyskać bez zależności. P0 gwarantuje ograniczony broadcast i ręczny IPv4; enumeracja kierunkowych broadcastów to P1. Host odpowiada unicastem na **adres i port odebranego datagramu**, nie na adres zapisany przez nadawcę w treści. Host na tym samym komputerze może odpowiedzieć na dodatkowy probe127.0.0.1. Discovery nie używa stałego portu po stronie szukającej, więc lokalny test obu instancji nie koliduje.

Nie obsługujemy routowanego discovery przez VLAN ani mDNS. Ręczne połączenie po osiągalnym IPv4 może działać między podsieciami. Nie włączać UPnP, port forwarding ani automatycznych zmian zapory. UI podpowiada dopuszczenie aplikacji do prywatnej sieci oraz UDP7777 i7778; jeśli discovery zablokowane, IP nadal może działać.

### 18.2 Autorytet

Host: pozycje końcowe obu dronów, kolizje, przyjęcie dash/socket, czas, obrażenia, charge, zwycięstwo, score i next sector. Gość: zbiera wejście, przewiduje własny ruch i zryw, interpoluje partnera i przedstawia potwierdzony stan urządzeń. Lokalne efekty UI i audio nie są autorytetem.

Host również korzysta z InputRouter i standardowego InputCommand; własna komenda jest dla najbliższego ticka bez transportu. Nie dodawać sztucznego input laga hosta. Gra jest kooperacyjna, więc nie wymaga antycheatowego wyrównania rywalizacji.

### 18.3 Lobby i start

Handshake8s. Po Hello/Welcome host publikuje LobbyState. Ready działa dopiero po zgodności wersji i hasha. Zmiana poziomu/seed/trudności zwiększa revision i zeruje readiness obu. Start hosta weryfikuje aktualny revision, dwie gotowości i stan Lobby.

Host tworzy match_id i wysyła LoadSector. Obie strony ładują lokalne zasoby. Klient odpowiada Loaded z content hash i sector_index; host lokalnie oznacza loaded. Dopiero po obu gotowościach wysyła Begin zawierający pełny snapshot w COUNTDOWN, phase_remaining180. W hostowej symulacji countdown trwa3s i ignoruje ruch. Snapshoty nadal płyną, więc klient nie potrzebuje idealnego zegara systemowego, aby zobaczyć start.

Każdy poziom kończy się WON albo FAILED i stanem RESULTS; INTERMISSION=2 pozostaje zarezerwowany w enum, ale bieżący przepływ go nie używa. Wynik WON jest spójny tylko przy objective_index3, complete_mask7, charges[300,300,300], extract_ticks120 i integrity>0. Host zapisuje go raz na match_id. Gość zapisuje dopiero po reliable SessionState(17), nigdy po Snapshot(10), nawet jeżeli pokazał już wynik. Zgubienie unreliable pakietu nie usuwa zatrzasków ani stanu przeszkód. Zgubienie reliable wyniku jest naprawiane retransmisją ENet; do jego akceptacji gość nie może zagłosować za następną mapą.

NEXT jest legalny po potwierdzonym WON, gdy katalog zawiera następnik. REMATCH i LOBBY są legalne w RESULTS (również po porażce). Obaj gracze muszą wybrać tę samą akcję; nowy głos usuwa poprzedni głos tej osoby. Następny poziom i powtórka tworzą świeży match_id, tick0, stan celów i integralność właściwą dla trudności. Żaden wynik ani zdrowie nie są przenoszone. LOBBY zeruje match_id i obie gotowości. Stabilne ID katalogu służy do wyboru mapy; sector_index jest tylko bieżącym porządkiem katalogu i ma zakres0..63, nie jest identyfikatorem zapisu. Obie strony mają identyczny katalog sprawdzony hashem.

Host może wybrać tylko lokalnie odblokowany ID; gość akceptuje wybór gospodarza niezależnie od własnych blokad. Gotowość wymaga aktualnej revision. Przy wejściu do poziomu variant=(seed+17*sector_index)%3; map_id w postaci liczby z protokołu2 został usunięty.

### 18.4 Utrata połączenia

Heartbeat Ping co500 ms, niezależnie od gameplayu. Brak poprawnych pakietów1s: banner „Słabe połączenie”. Brak3s: sesja zostaje przerwana u obu po własnym timeout; host nie kontynuuje sam. Brak snapshotu>250 ms zatrzymuje predykcję gameplayu i pokazuje oczekiwanie, ale transport nadal działa. ENet może wykryć rozłączenie wcześniej; wtedy bez czekania przejdź do błędu.

Nie ma reconnect do trwającego meczu w P0. Przycisk Ponów wraca do łączenia/lobby i wymaga nowej ekspedycji. Nie ma migracji hosta. Bezpieczny wynik zakończonej gry pozostaje zapisany; trwającej rozgrywki nie zapisywać jako zwycięstwa.

## 19. Protokół i synchronizacja

### 19.1 Transport, kanały i sekwencje

| Kanał | Tryb | Dane |
|---|---|---|
| 0 | RELIABLE | handshake, lobby, barriers, wydarzenia, głosy, wynik, Leave |
| 1 | UNRELIABLE_ORDERED | InputBatch; stały schemat i mała długość |
| 2 | UNRELIABLE_ORDERED | Snapshot, Ping/Pong; mają osobne sequence per message type |

Nie zakładać porządku między kanałami ani między typami. Wspólny ordered kanał2 może odrzucić starszy snapshot po nowszym pongu; to akceptowalne przy pełnych snapshotach30 Hz. Jeśli testy wykazują niekorzystną interakcję, Ping/Pong przenieść do RELIABLE0 i bump protocol version, zamiast cicho zmieniać kanały. Brak własnego retransmitowania snapshotów. Wiarygodność i retransmisję reliable zapewnia ENet, nie implementować drugiego TCP.

Sekwencja pakietu rośnie osobno dla typu i nadawcy. Nowsza: `d=(a-b)&0xffffffff`, `0<d<0x80000000`. Input command tick jest niezależny od sequence pakietu. Nie stosować licznika pakietów do replay wejścia.

### 19.2 Nagłówek binarny

Little endian, brak alignment padding. Wszystkie długości sprawdzane przed odczytem. Maksymalny application packet1000 B; jest to ograniczenie zawartości `send_bytes`, nie gwarancja identycznej wielkości datagramu po narzutach ENet/Godot/IP. M06 mierzy realny rozmiar i fragmentację.

| Offset | Typ | Pole |
|---:|---|---|
| 0 | 4×u8 | ASCII `LMLK`:4C4D4C4 B |
| 4 | u16 | protocol_version=3 |
| 6 | u8 | message_type |
| 7 | u8 | flags=0, inne odrzucane |
| 8 | u32 | session_id,0 dla Hello |
| 12 | u32 | match_id,0 poza meczem |
| 16 | u32 | sequence |
| 20 | u16 | payload_length; musi być packet_size−22 |
| 22 | bytes | payload |

UTF8 string koduje się jako u8 liczba bajtów, potem dokładnie te bajty; limity dotyczą jednocześnie znaków i bajtów. Nazwa gracza≤20 znaków i≤64 B; pokój≤24 i≤80 B. Odrzucić niepoprawny UTF8, NUL i kontrolne znaki. Nie normalizować błędnego UTF8 w milczeniu. W kodzie u16/u32 są zwykłymi Godot int, ale przed kodowaniem sprawdza się zakres.

### 19.3 Pełna tabela komunikatów

H=host, C=client, B=obie strony. Wszystkie błędy formatowania oznaczają drop i violation count; poważne błędy handshake kończą połączenie po reliable Reject, jeśli istnieje działający transport.

| ID / nazwa | Kierunek, kanał | Payload w kolejności wire | Walidacja i efekt / odpowiedź |
|---|---|---|---|
| 1 Hello | C→H,0R | engine:String≤32 B, engine_build:String≤64 B, content_hash:32 B, name:String≤64 B | tylko nowy peer, session=match=0; zgodność wersji/hash→Welcome+LobbyState, inaczej Reject |
| 2 Welcome | H→C,0R | slot:u8=1, host_name:String≤64 B | przydział session_id z header; tylko Connecting; następny LobbyState |
| 3 Reject | H→C,0R | code:u16 | znany enum; pokaż właściwy komunikat i zamknij po flush200 ms |
| 4 LobbyState | H→C,0R | revision:u32,ready_mask:u8, difficulty:u8,seed:u32,level_id:String≤32 B,room:String≤80 B,name0:String≤64 B,name1:String≤64 B | ready mask0..3; difficulty0/1; aktualniejszy revision; match0 |
| 5 SetReady | C→H,0R | revision:u32,ready:u8 | ready0/1, revision zgodny; aktualizuje tylko slot1; odpowiedź LobbyState nawet przy starej revision |
| 6 LoadSector | H→C,0R | sector:u8,level_id:String≤32 B,variant:u8,difficulty:u8,seed:u32,content_hash:32 B | level_id zgodny z katalogiem i jego sector0..63; wariant wyliczony zseed; nowy mecz lub dozwolony next; zacznij load |
| 7 Loaded | C→H,0R | sector:u8,content_hash:32 B | tylko oczekiwany sector/match; zgodny hash; obaj loaded→Begin |
| 8 Begin | H→C,0R | SnapshotBody(113+L B) | tylko Loading, phase COUNTDOWN i sector zgodny; zresetuj clock/bufory, podłącz widok |
| 9 InputBatch | C→H,1UO | sector:u8,count:u8, count×InputRecord12 B | count1..6, rosnące ticki, map/match/slot powiązane zpeer; kolejkuj tylko przyszłość w COUNTDOWN/PLAYING; w RESULTS/INTERMISSION poprawne pakiety w locie są walidowane i odrzucane bez symulacji; odpowiedź Snapshot |
| 10 Snapshot | H→C,2UO | SnapshotBody(113+L B) | only host; tick rosnący, sector oczekiwany; wczytaj stan i reconcile |
| 11 Events | H→C,0R | count:u8, count×EventRecord21 B | count1..8; event ID monotonic/dedup, tick≤latest estimate+12; event z przyszłości chwilowo buforuj |
| 12 Ping | B→B,2UO | echo_us:u64 | zaakceptowany peer; odpowiedź Pong z dokładnym echo; max4/s |
| 13 Pong | B→B,2UO | echo_us:u64,host_tick:u32 | echo musi odpowiadać outstanding ping; klient używa host_tick, host tylkoRTT; nie ufaj czasowi gościa |
| 14 Vote | C→H,0R | kind:u8,value:u8 | kind NEXT=0,REMATCH=1,LOBBY=2; value0/1; legalna phase; host local intent tym samym resolverem; odpowiedź SessionState |
| 15 Leave | B→B,0R | reason:u16 | dopuszczalny stan sesji; cleanup i modal; brak obowiązkowego ack |
| 16 Error | H→C,0R | code:u16,fatal:u8 | fatal0/1; tylko znany kod; fatal→Menu po close, nonfatal zostaje w bezpiecznym stanie |
| 17 SessionState | H→C,0R | SnapshotBody(113+L B),vote_mask:u8,next_seed:u32 | reliable potwierdzenie phase change/wyniku/głosów; dwa bity vote; nie cofaj nowszego ticka od Snapshot |

Host zmienia seed rewanżu przez lokalny resolver, publikuje `next_seed` w SessionState, zeruje oba rematch votes. Nie ma wire StartRequest, bo Start jest przyciskiem tylko hosta. Nie ma osobnej wiadomości Damage ani Win: trwałe wartości zawsze w snapshot i SessionState.

`InputRecord12 B`: tick:u32, axis_x:i8,axis_y:i8,dash_serial:u16,anchor_serial:u16,ping_serial:u16. Axis−128 zabronione; po dekodowaniu długość osi normalizowana. `sector` w InputBatch usuwa możliwość potraktowania komendy starej mapy jako ruchu na nowej.

`EventRecord21 B`: id:u32,tick:u32,type:u8,player_id:u8,object_id:u8,value:u16,x:f32,y:f32. player_id0/1/255; value przy DASH=dash_serial, HIT=integrity po koszcie, BEACON=ID celu, reszta0. Wartości pozycji skończone i w granicach mapy z marginesem64. SessionState obsługuje końce również bez Events. Markery Q są krótkotrwałymi efektami od Events; ich brak po spóźnionym dostarczeniu nie wpływa na postęp i nie wymaga rozszerzania SnapshotBody.

### 19.4 SnapshotBody — 113+L B

| Offset | Typ | Pole |
|---:|---|---|
| 0 | u32 | tick |
| 4 | u32 | sector_tick |
| 8 | u16 | remaining_ticks |
| 10 | u16 | phase_remaining |
| 12 | u8 | integrity |
| 13 | u8 | sector_index |
| 14 | u8 | phase: COUNTDOWN=0,PLAYING=1,INTERMISSION=2,WON=3,FAILED=4 |
| 15 | u8 | objective_index0..3 |
| 16 | i8 | active_socket:−1,0,1,2 |
| 17 | u8 | link_status: ACTIVE=0,TOO_SHORT=1,TOO_LONG=2,OCCLUDED=3,PLAYER_BUSY=4,SHUTTERED=5,JAMMED=6 |
| 18 | 3×u16 | charge każdego beaconu według ID0..2 |
| 24 | u16 | extract_ticks0..120 |
| 26 | u8 | socket_cooldown0..30 |
| 27 | u8 | damage_cooldown0..30 |
| 28 | u32 | score |
| 32 | u8 | complete_mask,3bity |
| 33 | u32 | last_event_id |
| 37 | u8 | latched_mask0..7; bitID oznacza zatrzaśnięte150 dwufazowego celu |
| 38 | u8 | L=liczba bajtów level_id (1..32) |
| 39 | L×u8 | ASCII stabilne level_id; a–z, potem a–z/0–9/_ |
| 39+L | u16 | obstacle_active_mask, bit obstacle.id |
| 41+L | u16 | obstacle_warning_mask, bity rozłączne z active |
| 43+L | PlayerRecord35 B | slot0 |
| 78+L | PlayerRecord35 B | slot1 |

PlayerRecord: position.x/y:f32 (8 B),velocity.x/y:f32 (8),facing.x/y:f32 (8),mode:u8,dash_ticks:u8,stun_ticks:u8,invulnerable_ticks:u8,dash_cooldown:u8 (5),consumed_dash/anchor/ping:u16 (6). Suma35 B. Facing jednostkowy z tolerancją0,01; velocity≤721; timers zakresami config. Snapshot powstaje po ticku, więc `snapshot.tick` jest jednocześnie granicą przetworzonych komend. Nie potrzebuje osobnego „ack ostatniego odebranego pakietu”. Utracone komendy do tego ticka są zamkniętą przeszłością.

Snapshot zapisuje stabilne ID, latched_mask i obie maski przeszkód, sprawdzane względem załadowanej mapy (≤16 przeszkód, brak nieistniejących bitów). Harmonogramy przeszkód są deterministycznymi danymi mapy, a ich tick ustala host. Snapshot nie zapisuje historii decay ani ścian; zawiera cały stan potrzebny klientowi w ramach już załadowanej mapy. Nie jest formatem save game i nie służy do migracji hosta.

Wektor testowy: Ping w sesji1,meczu2,sequence3,echo_us=1000 ma nagłówek `4c 4d 4c 4b 03 00 0c 00 01 00 00 00 02 00 00 00 03 00 00 00 08 00` i payload `e8 03 00 00 00 00 00 00`. Wielkość30 B. Kodek musi round-tripować ten literal, nie porównywać dwóch identycznie błędnych encoderów.

### 19.5 Schemat discovery

Osobny datagram≤256 B, bez ENet. Probe: magic `LMDQ`4 B, version:u16, nonce:u32, padding do64 B samymi zerami. Reply: magic `LMDR`,version:u16,nonce:u32,game_port:u16,occupied:u8,engine:String≤32 B,room:String≤80 B. Limit odpowiedzi160 B. Reply przyjmowany tylko dla nonce z ostatnich3s; IP pobierany z datagramu. Host odpowiada max2/s dla IP i max20/s globalnie. Pokój pełny może być pokazany jako disabled. Discovery nie przesyła hasha; prawdziwa zgodność weryfikowana w Hello.

### 19.6 Komendy, jitter i niepowtarzanie akcji

Klient generuje jedną komendę na lokalny przewidywany tick60 Hz. Co2 ticki wysyła sześć ostatnich komend (na początku mniej). Host przechowuje je wg target tick. Odrzuca tick≤current albo >current+12. Brak komendy na najbliższy tick: powtarza tylko ostatnie osie maksymalnie6 ticków, potem daje zero; nie uruchamia ponownie akcji.

Naciśnięcie zwiększa serial odpowiedniej akcji modulo65536. Kolejne komendy zawierają aktualny serial aż do następnego naciśnięcia. Host uznaje nową akcję, jeśli modularna różnica względem consumed w1..64. Wykonuje najwyżej jedną danego rodzaju na tick; konsumuje najnowszy serial również przy odrzuceniu przez cooldown/stun. Dzięki temu zagubiona krawędź wróci w następnym pakiecie, a duplicate nie wykona dash drugi raz. Różnica>64 jest naruszeniem protokołu. Do rewanżu seriale resetują się do0 po nowym match_id; przy nowym sektorze także obie strony zerują je w Begin.

Hostowa komenda local trafia na current+1; gość utrzymuje lead `clamp(ceil(RTT_ms×60/2000)+2,2,8)` względem estymowanego host tick. RTT jest mierzony Ping/Pong z monotonicznego zegara, nie czasem UTC.

`NetworkClock` koryguje estimate łagodnie (max0,25tick/frame), a po odchyleniu>12tick wymaga resetu z najnowszego snapshotu. Nie cofa target_tick: gdy zbyt daleko przed hostem, pomija generowanie nowej komendy; gdy spóźniony, generuje max3 w danym fixed update. Krawędzie akcji przenosi tylko do pierwszej nowej komendy, kolejne zawierają ten sam serial. Starsze timestampy nie dają prawa symulowania dodatkowych kroków po stronie hosta.

### 19.7 Predykcja i reconciliation

1. Klient kopiuje stan własnego gracza z Begin.
2. Dla każdej przyszłej komendy wykonuje timery, lokalne przyjęcie dash i wspólny Movement. Nie wywołuje HazardSystem, ObjectiveSystem ani przełączenia socketu.
3. Po Snapshot T zastępuje predicted PlayerState **pełnym** stanem własnego drona z T, w tym timers, facing, mode i consumed serials.
4. Usuwa pending komendy≤T, po czym odtwarza wszystkie późniejsze w porządku ticków. Jeśli brakuje ticka, tworzy komendę neutralną z ostatnimi serialami. Max256 replay; przekroczenie lub luka>12 wymaga resync i wyzerowania historii, bez nieograniczonej pętli.
5. Różnicę między starym obrazem a nowym predicted transform przechowuje jako czysto wizualny offset. Error≤2 px: brak smoothing;2–48 px: exponential decay z czasem0,08s;>48 px albo różny sector: natychmiastowy snap. Collider zawsze korzysta z poprawionego stanu.
6. Gdy host odrzucił dash, jego cooldown i consumed serial zapobiegają samoczynnemu ponownemu odtworzeniu. Spekulatywny dźwięk dash nie jest odtwarzany drugi raz po potwierdzeniu.

Czysta predykcja ruchu może chwilowo pokazać dash, który host odrzuci po trafieniu. To jawna granica projektu; korekcja ma być czytelna i krótka. Nie implementować pełnego rollbacku wszystkich zagrożeń i beacona.

### 19.8 Interpolacja i prezentacja czasu

Zdalny dron: bufor32 snapshotów, render time = estimated_host_tick−6 (100 ms). Interpolacja linear pos i velocity; stany dyskretne z wcześniejszej próbki. Przy braku kolejnej próbki extrapolate velocity≤6tick, z kolizjami statycznymi, potem freeze. Przy zmianie sector natychmiast clear.

Własny dron jest renderowany z predicted tick. Zagrożenia mają znany harmonogram i są rysowane dla predicted tick lokalnego gracza, aby warning odpowiadał temu, co może za chwilę zrobić. Zdalny partner jest celowo nieco opóźniony. Wyświetlany przewód używa aktualnych renderowanych końców, natomiast jego kolor „ładuje” i postęp pochodzą wyłącznie ze snapshotu. Przy własnym przewidywanym dash przewód wygaszamy wizualnie od razu. Nie liczymy lokalnie charge ze skorygowanej geometrii.

Host renderuje między poprzednim i bieżącym stanem fixed update z `Engine.get_physics_interpolation_fraction`; nie włącza dodatkowo automatycznej interpolacji tych samych Node. Animacja nie podwaja interpolation.

### 19.9 Dokładne zachowanie błędów

| Sytuacja | Zachowanie techniczne | Komunikat / ekran |
|---|---|---|
| Port zajęty | create_server error, zamknij częściowe sockety | „Port jest zajęty. Wybierz inny.” HostForm |
| Niepoprawny IP | odrzuć przed ENet | błąd przy polu, bez spinnera |
| Brak odpowiedzi8s | close, wyczyść outstanding | „Nie udało się połączyć. Sprawdź IP i sieć.” JoinForm |
| Niezgodny protocol/engine/content | Reject konkretny kod, close | „Obie osoby potrzebują tej samej wersji gry.” |
| Load>15s | reliable Error, powrót Lobby i readiness0 | „Nie udało się załadować sektora.” |
| Duplicate/out-of-order | ignore, licznik diagnostyki | brak popupu |
| 1s bez wiadomości | banner, ping wciąż działa | „Słabe połączenie” |
| 3s bez wiadomości | przerwanie meczu, cleanup | „Połączenie zostało przerwane.” Menu |
| Host/client zamknął grę | Leave jeśli możliwe; partner kończy sesję | „Partner opuścił grę.” Menu |
| 3 wadliwe wiadomości/10s | disconnect tego peer | „Odebrano nieprawidłowe dane.” |
| Discovery nie działa | po5s pokazuje pomoc, scan do10s | „Wpisz adres IP gospodarza.” |
| Dodatkowy gość | odmowa ENet lub Reject FULL jeśli dotrze | ogólna odmowa jeśli brak handshake |
| Zapis ustawień nie działa | zachowaj w pamięci, log | „Ustawienia działają, ale nie zostały zapisane.” |

## 23. Bezpieczeństwo i niezawodność

Granica zaufania to każdy pakiet, nawet w domu. Nie ma kont, szyfrowania ani ochrony przeciw podsłuchowi w nieufnej sieci; gra nie wysyła sekretów. LAN nie jest dowodem zaufanego nadawcy. session_id chroni przed mieszaniem sesji, nie kryptograficznie przed napastnikiem.

Tylko whitelist typów i stanów. Żadnego `str_to_var`, `bytes_to_var`, `load` ani `ResourceLoader` ze ścieżką podaną w pakiecie. `allow_object_decoding=false`. Długość pakietu sprawdzana przed decode, liczniki przed alokacją. Payload nigdy nie tworzy nieograniczonej tablicy.

Limity: jeden gość; incoming queue max128pakietów; drain max64/tick; max120 pakietów/s per peer (burst60), max64 KiB/s application payload (burst32 KiB), InputBatch max60/s, Ready/Vote max5/s, Ping max4/s. Rate excess przez2s albo3malformed/10s kończy połączenie. Queue overflow odrzuca najstarszy niecritical snapshot/input; reliable kontrolny overflow kończy sesję z kodem OVERLOAD, bo nie można milcząco zgubić bariery. Nie pozwalać na blokujące DNS: P0 direct address to literalIPv4.

Kody błędów: VERSION_MISMATCH1,CONTENT_MISMATCH2,FULL3,BAD_PACKET4,TIMEOUT5,LOAD_FAILED6,OVERLOAD7,PEER_LEFT8,PORT_IN_USE9,INVALID_STATE10. User text pochodzi z lokalnej tabeli, nie z dowolnego remote string.

Zamknięcie portów, odłączenie sygnałów, zerowanie kolejki i stop audio są idempotentne. Wyjście z lobby nie usuwa settings ani records. Logi rotują, nie rejestrują pełnych pakietów, nie odczytują danych poza katalogiem gry i user://.


## Obecna implementacja ruchu i trwałego etapu

Simulation hosta60Hz; InputBatch i Snapshot30Hz. NetworkClock steruje lead2..8, komendami monotonicznymi i granicą ostatni snapshot.tick+12. ClientPrediction odtwarza pełny PlayerState wyłącznie gościa, zachowując tylko przyszłe komendy (historia≤256, luka≤12). SnapshotBuffer przechowuje32 próbki, partner tick−6, ekstrapolacja≤6 ticków z kolizją statyczną. Nie ma drugiej Simulation u gościa. RenderFrame zawiera kopie i nie modyfikuje autorytatywnego świata. Zamrożenie po250ms bez snapshotu, heartbeat500ms, ostrzeżenie1s, rozłączenie3s.

latched_mask przy offset37 jest częścią każdego snapshotu. Kodek wymaga0..7 i charge≥150 dla ustawionych bitów. GameSnapshot.validate dodatkowo sprawdza typ celu i zgodność150 z bitem, socket z liczbą urządzeń mapy, stabilny ID, maski przeszkód i spójne zwycięstwo. Kolejność celów0→1→2, variant wpływa tylko na fazy. Pola i harmonogramy są statycznymi danymi zgodnymi przez content hash; zajęcie rozstrzyga host. Nie zależymy od zdarzenia wizualnego dla zatrzasku ani zapisu zwycięstwa.

## Testy wersji3

`tools/protocol_vectors.py` niezależnie składa Ping i snapshot dock (L4, body117 B, packet139 B). Testy round-trip obejmują17 typów, odcięcie każdego bajtu, NaN/Infinity, zakresy, UTF8,32-bajtowy ID i sector63, zmianę kolejności katalogu oraz pełne maski przeszkód. Scenariusze ENet sprawdzają revision, gościa z lokalną blokadą, dwie zgodne decyzje, utratę reliable wyniku i odzyskanie zatrzasku ze snapshotu. Trwały wynik nie zależy od EventRecord.
