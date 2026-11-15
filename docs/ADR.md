# ADR — LUMEN LINK

Specyfikacja bazowa: 1.0. Brak zmian reguł gry, architektury lub protokołu.

## ADR-0001 — 2026-11-14 — Przyrostowy bootstrap M00

Problem: AppState docelowo zwraca GameTypes.Result, ale core/game_types.gd powstaje
w M01. M00 zabrania pustych klas przyszłych systemów i referencji do nieistniejących klas.

Decyzja: M00 używa działającego lokalnego AppState.Result o polach ok/code/message/value.
Screen zawiera wyłącznie BOOT/MENU, z jedynym dozwolonym przejściem BOOT → MENU.
Kolejne ekrany i zależności będą dołączane w etapach, które je implementują.
Przy dostarczeniu GameTypes w M01 należy przełączyć wynik na GameTypes.Result,
zachowując pola i zachowanie wywołań; nie tworzyć drugiego trwałego standardu błędów.
To przejściowa implementacja przyrostu, nie zmiana docelowych kontraktów §16–17.

Alternatywy: przedwczesne dodanie core (wykracza poza M00) albo brak działającego API (odrzucone).
Pliki: app/app_state.gd, app/app_root.gd, tests/integration/test_boot.gd.
Testy: B01 waliduje legalne/nielegalne przejścia, Result i boot rzeczywistej sceny.
Wpływ na protokół: brak; sieć nie istnieje, kontrakt VERSION=1 bez zmian.

## ADR-0002 — 2026-11-14 — Domknięcie M01

AppState.Result jest teraz aliasem GameTypes.Result (domknięcie ADR-0001).
DTO RenderFrame przechowuje tablicę RefCounted do czasu dostarczenia PlayerState w M02;
nie referencjonuje nieistniejącej klasy. Docelowe API pozostaje zgodne z §16.
Walidator wymaga tylko dock i nie traktuje identyfikatora background_asset jako ścieżki
pliku: assety zostaną dostarczone w M11, garden/reactor w M10, zgodnie z planem.
GameConfig sprawdza dokładny startowy kontrakt 1.0, włącznie z bilansem i kluczami;
przyszła przyjęta zmiana balansu aktualizuje równocześnie dane, wzorzec walidacji i dokumenty.
Brak zmian wire, protokołu i reguł gry. Testy C01, K01/K02, regresja B01.

## ADR-0003 — 2026-11-15 — Przyrost ruchu M02

Dodano rzeczywiste PlayerState, komendy, snapshoty i symulację ruchu.
RenderFrame.players nadal zawiera RefCounted, do których trafiają wyłącznie kopie
PlayerState; unikamy cyklu ładowania GameTypes ↔ WorldState.
To decyzja implementacyjna bez zmiany kontraktu danych i własności.
Wcześniej nieużywany MatchPhase w GameTypes uporządkowano zgodnie z §19.4:
COUNTDOWN=0, PLAYING=1, INTERMISSION=2, WON=3, FAILED=4. LOBBY/LOADING są
wyłącznie wartościami lokalnymi. Nie ma wdrożonego kodeka ani zmiany wire.

Fixture uruchamia się tylko w debug i przyjmuje dwie komendy wspólną ścieżką.
InputRouter.configure przyjmuje opcjonalny player_slot do izolacji wejścia debug.
Podgląd ruchu i drona nie wymagają przyszłego AssetCatalog — docelowe wstrzykiwanie
assetów i dodatkowe API widoku/audio dojdą w etapach, które je dostarczą.
Brak fikcyjnych implementacji hazardów/ładowania/przekaźników.

Testy M01–M03, K01, I01, S03 i B01/B02; raporty reports/m02/.

## ADR-0004 — 2026-11-15 — M03/M04 i czas ścieżki kolizji

Problem: swept test ruchomej wiązki wymaga czasu każdego odcinka slide, a nie
tylko jego końców. MoveResult rozszerzono o segment_times:Array[Vector2],
znormalizowane przedziały czasu w ticku. CollisionWorld zachowuje też odcinek
postoju po zatrzymaniu. HazardSystem używa względnego ruchu na tych przedziałach.
Alternatywa proporcji długości odrzucona: po slide zmienia się prędkość.
Zaktualizowano MASTER_SPEC/CODE_CONTRACTS. To metadane lokalne, nie wire;
VERSION pozostaje 1. Blueprint źródłowy zachowano bez zmian.

M03: LinkSystem, ObjectiveSystem, widok przewodu, sockety, pingi, postęp i przyczyny.
M04: HazardSystem, integrity/stun/immunity, extraction, terminalny wynik i restart
dock w debug. Sukces dock daje INTERMISSION zgodnie z kontraktem ekspedycji;
WON jest zarezerwowane dla sektora 2. Nie przeskakujemy do nieistniejącego garden.
F2 resetuje sektor. HazardSystem.hits ma opcjonalne przedziały czasu dla ścieżek.
Testy i ograniczenia: PROJECT_STATUS oraz reports/m04/.

## ADR-0005 — 2026-11-15 — Lokalna ekspedycja M05

Problem: brak garden/reactor do M10 i brak MatchSession do etapu sieciowego.
Decyzja zgodna z M05: offline fixture dock ×3 jest sterowany przez AppRoot i AppState;
nie tworzymy zastępczej klasy sesji ani nie nazywamy tego wydaniem gry.
AppState.session_active jest lokalną bramką fixture, nie modelem przyszłej sesji LAN.
Przejście loading/countdown/playing wymaga tej bramki. Escape w grze jest nakładką.

SceneRouter.configure otrzymuje opcjonalny AssetCatalog; AssetCatalog udostępnia tylko
rzeczywiście istniejący dock i scenę world. Wczytanie sceny przez threaded_request/get
następuje z poll, bez blokującego oczekiwania na worker. clear unieważnia generation;
nie ma callbacku starego ładowania, który mógłby ponownie aktywować scenę.
Budowanie DTO i walidacja małego JSON przy boot pozostają synchroniczne.
Usługi przetrwają zmianę świata, cleanup usuwa tylko sektor. Symulacja reset_sector
przenosi integrity/score/completed_beacons_total/tick/event_id, zeruje historię sektora.
Odliczanie zwiększa globalny tick, nie sector_tick ani zegar sektora.

Rekordy developerskiego dock ×3 są w debug_records.json; produkcyjne records.json
pozostaje odrębne. Ustawienia schema1 odpowiadają polom SettingsData; bindings
obsługują obecnie walidowane primitive key/button, edytor remap dojdzie w M12.
Nie ma wcześniejszego opublikowanego formatu do migracji; obce wersje zachowuje .bak.
Zapis tmp+flush+rename. Nieudany submit wycofuje zmianę rekordów w pamięci.
Log ma 500 linii w buforze, 2 MiB ×3 na dysku, sanitizację znaków kontrolnych.

Dodatkowa poprawka integracyjna: WorldView.configure przyjmuje opcjonalne difficulty
oraz variant, by wizualizacja hazardów powtórzonego dock odpowiadała symulacji.
Bez zmiany reguł gry ani wire/protocol1. Testy PS01/F01 i smoke GUI w reports/m05/.

## ADR-0006 — 2026-11-15 — M06: jawny kodek i adapter transportu

Wdrożono wszystkie 17 schematów wire 1. SnapshotBody=107 B, PlayerRecord=35 B,
header=22 B. Golden Ping i snapshot powstały niezależnie przez Python struct,
nie przez porównanie dwóch wywołań tego samego kodeka. UTF8 sprawdzane przed
konwersją; bounded cursor, liczniki i enumy przed alokacją. GDScript przechowuje
u64 echo jako nieprzezroczysty wzorzec bitów int64 (wysoki bit daje liczbę ujemną);
wszystkie 64 bity round-tripują, lokalne Time.get_ticks_usec pozostaje dodatnie.
Doprecyzowano value zdarzeń źródłowych DASH/HIT/BEACON zgodnie z istniejącym §19.
Bez zmiany wire/protocol1 i reguł rozgrywki.

SceneMultiplayer ma lokalny root_path=/root, object decoding i server relay wyłączone.
Transport ma 3 kanały, ręczne poll; callbacki C++ tylko odkładają dane/lifecycle.
Aplikacyjne callbacks są emitowane po powrocie z api.poll. Bezpośredni cleanup
podczas poll powodował crash w pierwszym teście timeout/leave — usunięto reentrancy.
Nie pobieramy host po disconnect; flush następuje tylko przy aktywnym ENet peer.
Queue max128, drain64, kontrolny overflow kończy sesję, dane niecritical są odrzucane
w pierwszej kolejności. Guard rozdziela role, stany, generacje i token buckets.

Manifest: uporządkowane ścieżki w data/core/net/app (w tym UID), u32LE długość
ścieżki/u32LE długość pliku, następnie ścieżka UTF8 i bajty. Manifest nie obejmuje
samego siebie. Source boot sprawdza aktualny hash, każda paczka sprawdza engine
version/build i schema/protocol. Eksport zawiera manifest wygenerowany przed buildem.
Revision unversioned, bo przekazany katalog nie jest repo Git.

Smoke Linux używa oficjalnych 4.5.2 templates, tymczasowego projektu/presetu i osobnego
artefaktu poza repo. Nie wprowadzono produkcyjnego export_presets ani workflow M15.
Pomiary datagramów wykonano lokalnym przekaźnikiem UDP z parserem komend ENet;
nie mylono liczby bajtów send_bytes z rozmiarem datagramu. Szczegóły w raportach.

## ADR-0007 — 2026-11-15 — M07: lobby i bariera, bez gameplayu M08

MatchSession jest właścicielem transportu, discovery, lobby, identyfikatorów i bariery.
Host startuje dopiero po Hello/Welcome, zgodnym hashu i dwóch ready bieżącej revision.
Zmiana seed/trudności zeruje ready. LoadSector/Loaded/Begin wiąże match, sector i lokalną
generation; SceneRouter.active_generation dodatkowo chroni most ładowania AppRoot.
Zakończenie odliczania potwierdza reliable SessionState; nie polegamy na ostatnim
unreliable snapshotcie. M07 zatrzymuje hosta w READY, nie symuluje rozgrywki przez LAN.
Publiczne API networking/predykcji z kolejnych milestone nie jest zastępowane stubami.

Host ma własną Simulation tylko dla początkowego countdown; gość jej nie tworzy.
Na tym etapie sieciowy start dotyczy pierwszego dock (map_id0); pełny gameplay M08,
mapy M10. Lokalny debug M05 pozostaje odrębnym narzędziem.
Handshake8 s, load15 s, heartbeat500 ms, banner1 s, zerwanie3 s. Cancel/timeout
ładowania wraca do lobby i czyści ready. Gość używa istniejącego Leave(LOAD_FAILED)
jako prośby o abort bariery, host odpowiada istniejącym nonfatal Error i LobbyState;
nie dodaje to typu wire. Zanik odpowiedzi podczas abort zamyka sesję w ograniczonym czasie.
Reject ma okno flush200 ms. Stare Loaded nie aktywują scen.

Discovery: probe64 B z nonce, reply<=160 B, źródłowy IP/port UDP, TTL3 s, skan10 s,
max2 odpowiedzi/s/IP i20/s globalnie; lista klienta max64. Serwer bind7778, skaner bind0.
Dodatkowe opcje bind_ip/broadcast służą do ograniczenia automatycznych testów do loopback;
normalne UI korzysta z broadcastu i ręcznego IPv4. Brak UPnP, DNS i zmian zapory.
UI M07 używa bazowego theme. Finalne ekrany i dopracowanie należą do M12.

## ADR-0008 — 2026-11-15 — M08: jedna symulacja hosta i pełna wyprawa LAN

MatchSession.fixed_update jest wywoływane dokładnie raz na physics tick (60 Hz).
poll obsługuje tylko transport, discovery i timeouty. HostReplication przechowuje
kopie komend per slot/target tick, ignoruje duplikaty i stare ticki, odrzuca przyszłość
powyżej 12 ticków i skoki serialu powyżej 64. Brak komendy utrzymuje osie 6 ticków,
potem neutralizuje; seriale pozostają, więc akcja nie jest ponawiana.
Tylko host tworzy i wykonuje Simulation. Klient wysyła InputBatch co 2 ticki,
z historią do 6 komend; host wysyła pełny snapshot co 2 ticki. Eventy idą reliable
z deduplikacją po ID; SessionState reliable potwierdza zmianę fazy i głosy.
Wire pozostaje w wersji 1, bez nowych schematów pakietów.

Przed M09 klient wyświetla ostatni autorytatywny snapshot bez predykcji. Target tick
rośnie od snapshot.tick+4, maksymalnie do snapshot.tick+8; snapshot starszy niż250 ms
wstrzymuje tworzenie kolejnych komend. Host dopuszcza do +12 na granicy kolejki.
Nie jest to finalna synchronizacja czasu ani model strat pakietów z M09.

Ekspedycja używa debug dock×3 i istniejącego reset_sector: wspólne integrity, score,
globalny tick i ID zdarzeń. Każdy kolejny sektor przechodzi LoadSector/Loaded/Begin.
Rematch uzgadnia seed, nadaje nowy match_id i resetuje kolejki/seriale. Głosy NEXT,
REMATCH i LOBBY mają osobne maski, więc różne wybory graczy nie uruchomią przejścia.
Wyniki po stronie AppRoot zapisują rekord zawartości debug. Escape/focus neutralizuje
lokalne wejście; sieć i symulacja nadal działają. M09 nie został rozpoczęty.

## ADR-0009 — 2026-11-15 — M09: lokalna predykcja i kontrolowany replay

NetworkClock mierzy RTT przez monotoniczne Ping/Pong, oblicza lead
clamp(ceil(RTT_ms×60/2000)+2,2,8). Koryguje estymatę najwyżej0,25 tick/fixed
update, przy odchyleniu>12 resetuje ją ze snapshotu. Target tick nigdy się nie
cofa; jeden fixed update generuje od0 do3 komend. Każda jest próbkowana przez
InputRouter; dalsze próbki zawierają te same seriale, więc krawędź nie dubluje akcji.

ClientPrediction kopiuje pełny PlayerState, wykonuje timery, dash i wspólny Movement.
Nie tworzy Simulation, nie wywołuje hazardów, celów ani przełączenia socketu.
Snapshot.tick jest granicą rozliczenia; last_received_tick hosta nią nie jest.
Replay usuwa komendy≤T, odtwarza późniejsze, neutralizuje luki z zachowaniem
seriali; limit256/luka>12 wymusza powrót do ostatniego stanu autorytatywnego.
W fazie innej niż PLAYING historia jest czyszczona. Smoothing jest wyłącznie
wizualny: do2 px bez offsetu,2..48 px exponential80 ms, większy błąd/nowy sektor snap.
Nie dodajemy spekulatywnego audio przed M13; potwierdzone Events deduplikuje ID.

SnapshotBuffer mieści32 kopie, sortuje ticki, ignoruje duplikaty i czyści sektor.
Partner: estymowany host tick−6, liniowa pozycja/prędkość, wcześniejsze stany
 dyskretne. Brak późniejszej próbki: extrapolate≤6 tick ze statycznymi kolizjami.
Własny dron i harmonogram hazardów są prezentowane dla predicted tick; przewód
używa renderowanych końców, lecz charge/kolor ładowania pozostają autorytatywne.
Przewidywany dash wygasza przewód od razu. Host interpoluje między fixed stanami.
Po250 ms bez snapshotu klient zamraża obraz i nie generuje nowych komend;
heartbeat pozostaje aktywny. Po1 s bez wiadomości banner, po3 s cleanup sesji.
Wire1 oraz rozmiary pakietów pozostają bez zmian. M10 nie rozpoczęto.

M09: dodatkowa granica bezpieczeństwa target tick to ostatni snapshot.tick+12.
Gdy host chwilowo zwalnia, estymata zegara nie daje prawa wysłać komendy poza
jego okno przyszłości. Klient pomija generowanie, nie cofa numeracji. Przypadek
wykryty w smoke GUI ma osobną regresję z zatrzymanym tickiem hosta.

## ADR-0010 — 2026-11-15 — M10: trzy mapy i dowód rozwiązania wejściem

Kampania ma stałą kolejność dock → garden → reactor. Wczytano dokładne ściany,
beacony, sockety i hazardy z §7.1, bez zmian pozycji ani reguł balansu. Wariant
pozostaje (seed+17×sector)%3, kolejność celów cykliczna, offset hazardów37×v
z dotychczasowym skalowaniem offsetów RELAXED. Mapy nie są generowane ani przesyłane.
Wire1 już przewiduje map_id0..2; host wysyła map_id=sector i klient sprawdza zgodność
mapy, sektora i wariantu przed LoadSector/Loaded/Begin. Wspólna scena world.tscn
przyjmuje zwalidowaną definicję wybranej mapy; static collision predykcji i widok
korzystają z tej samej definicji. SceneRouter.show otrzymał opcjonalny map_id.

Walidator wymaga wszystkich trzech map i sprawdza schemat, bezpieczne obszary,
8-unit flood-fill od obu spawnów do wszystkich socketów i wyjścia. To nie dowodzi
rozwiązania przewodu. Osobne zapisane wejścia w JSON pokrywają wszystkie18
kombinacji; runner odtwarza je produkcyjną Simulation i składa6 pełnych kampanii.
Fixture koduje RLE osi obu dronów, akcje mają serial0, żadnej mutacji świata.
Narzędzie offline wyznacza statycznie bezpieczne końce przewodu i drogi, następnie
naprawdę wykonuje ruch, hazardy, ładowanie300tick i ekstrakcję120tick. Nie jest botem
wydania i nie jest podłączone do normalnego AppRoot. Test ENet używa tych samych
wejść zamiast dawnego planera znającego wyłącznie dock.

Wszystkie18 tras automatycznych kończą się bez obrażeń, ale planner zna mapę i omija
całe obszary hazardów. Nie wyciągamy z tego wniosku o zrozumiałości lub łatwości dla
człowieka, nie zwiększamy trudności bez obserwacji. Nowe duety0/5 i manualne18
konfiguracji pozostają NOT RUN/PENDING w tests/manual/playtest_matrix.md.
Wymagane4/5 duetów z pierwszym celem w90s musi zostać odebrane przed bramką jakości.
Finalny art i podpowiedzi/menu należą do M11/M12. M11 nie został rozpoczęty.

M10 smoke natywny wykazał, że powtórna walidacja flood-fill trzech map na głównym
wątku po Begin może opóźnić heartbeat. Validator przechowuje więc wyłącznie fakt
poprawnej walidacji, kluczowany SHA-256 tekstu gameplay.json oraz danej mapy.
Zmiana danych unieważnia wynik. Każde load_content ponownie czyta/parsuje źródła
i zwraca świeże MapDefinition; nie cache'uje obiektów Simulation ani mutable map.
Regresja modyfikuje zwrócony garden i potwierdza niezależność następnego wczytania.
Pomiar jednego biegu: cold422524µs, warm4497µs. To lokalny pomiar walidacji, nie
benchmark FPS. Powtórzony test GUI nie wykazał już timeoutu startu.

Test ENet M10 korzysta z nagrania, a po jego zakończeniu może domknąć podejście do
wyjścia wejściem sterowanym snapshotem. Odtwarzanie bez sprzężenia zwrotnego może
po pominięciu komendy zostawić drona poza strefą; nie oznacza to braku rozwiązania
mapy. Korekta nie zmienia świata, charge ani warunków ekstrakcji. Izolowane replay
C02 pozostają dokładnym odtworzeniem zapisanych wejść, bez takiej korekty.

## ADR-0011 — 2026-11-15 — M11a/b: własne wektory i prezentacja niezależna od świata

Wszystkie obrazy z §8.3 są własnymi SVG, poza deterministycznym grain128² RGB8.
Autorowanie tools/art_sources.py, wypiek tools/asset_bake.gd seed110011.
Fonty Atkinson Hyperlegible Regular/Bold pobrano niezmienione z oficjalnego google/fonts,
przypięto commit i SHA-256 w SOURCE.json, dołączono pełną OFL1.1. Brak runtime download.
AssetCatalog tworzy40 współdzielonych regionów AtlasTexture z padding2/filter_clip.
Duże atlasy i tła mają mipmaps, źródła SVG są importowane w skali1.

DroneView ma Node Visual i prawdziwe klipy AnimationLibrary. Root pozostaje na pozycji
renderowanej; lean, bob i stretch dotyczą dzieci. CameraRig zmienia wyłącznie offset
renderowania, max3px/0.16s, defaultshake50%, reduced motion/0 wyłącza efekt.
HUD przeniesiono do CanvasLayer10, niezależnej od Camera2D; znika z ukrytym światem.
WorldView używa jawnych warstw §20; active hazard jest nad ścianą i dronem, przewód
nad hazardem. Stan ładowania i geometria fizyczna nadal pochodzą z hosta.

LinkView używa Line2D3/8/16px i markera blokady; Low pomija szerokie halo.
Trzy canvas shadery Compatibility mają najwyżej2 próbki, bez bloom/Forward+.
Shaderdevice obsługuje charge i stan telegraph/active emiterów. FxPool ma128 opisów
zdarzeń i PackedArrays320/160 cząstek. Dedup ID i player/dash_serial obejmuje
predykowany i potwierdzony dash. Najstarszy nadmiar dekoracji nie wpływa na core.
Do rysowania zostaje16/8 najnowszych pierścieni; segmenty i kolory są batchowane,
unikamy per-ring draw calls, COW zagnieżdżonych PackedArrays i wielokrotnego skanowania
całej puli dla każdej cząstki. FX starzeje się także pod ukrytym debug menu.

Przed Loaded/COUNTDOWN WorldView rysuje trzy shadery, rzeczywiste halo i pierścień/
cząstki FX przez dwa natywne frame_post_draw pod nieprzezroczystą zasłoną loading.
Po rozgrzaniu usuwa dekoracje i sprawdza generation. Headless nie udaje GPU warmup.
NativeQA używa SubViewport1280×720 i readbacku GPU, zapisuje kolor/L8 oraz krótkie
metryki. Pomiar drawcalls nie jest benchmarkiem10min ani gwarancją60FPS; M15 pozostaje
bramką wydajności. Wysoki stress może przekroczyć16.7ms mimo spełnienia≤150drawcalls.
M10 nowe duety pozostają PENDING. Nie rozpoczęto kompletnego UI M12 ani audio M13.

## ADR-0012 — wnęki celów wymagające zagięcia światła

Na prośbę użytkownika zastąpiono geometrię M10 na trzech mapach. Trzy zamknięte
strony wnęki i ograniczenie odległości od końca przewodu wykluczają proste
zasilanie. Właściwy socket daje powrotną trasę przez otwór. Nie zmieniono
LinkSystem, ObjectiveSystem ani protokołu. Zachowano 3 cele/sockety i warianty.
Zastąpiono SWEEP pulsami w przestrzeni między wnękami; balans wymaga nowych
playtestów. Pomniejszono urządzenia/ring ładowania dla czytelności wnęk.
Fixture RLE dopuszcza dodatkowe dwa pola seriali anchor (stary format nadal
czytelny). Szczegóły i certyfikat: [RELAY_MAP_DESIGN](RELAY_MAP_DESIGN.md).

## ADR-0013 — M11c: pola stabilizacji, stała progresja i protokół2

Użytkownik zlecił usunięcie dziewięciu identycznych wnęk. Zastosowano optyczny
kanał/narożnik w doku i dwuramienne układy z jawnymi parami pól na dalszych
celach. Bez globalnego zakazu nakładania dronów i bez testu minimalnego kąta.
Rule per objective w schema2:0/1/2 pary; radius44, centra≥160, role zamienne.
Jedyna nowa mechanika: pola i zatrzask150. Maska ma3 bity w WorldState i pełnym
SnapshotBody108; wire protocol2, PlayerRecord35 i limit1000 niezmienione.
Kolejność celów0→1→2; seed/variant tylko przesuwa sprawdzone fazy.
Nie zwiększono czasu ładowania, obrażeń ani nie zmieniono ruchu/zrywu.
Offsety reaktora0/30 zastąpiły zbyt odległe fazy, żeby wspólne okna miały
pojemność na postęp po unikach. Regresja1136PASS sprzed ostatniej korekty brzegów oraz niezależny model78okien
nie zastępują ludzkiej oceny. Pełne współrzędne/rozwiązania i zakres dowodów:
[M11C_POZIOMY_I_WSPOLPRACA](M11C_POZIOMY_I_WSPOLPRACA.md).

Sekwencyjny import assetów jest ustawieniem edytora, które omija zaobserwowany
crash Godota4.5.2 przy wielowątkowym imporcie fontów. Nie ogranicza ticków gry.
Historyczne raporty wnęk zachowano, bieżący raport rozgrywki zaktualizowano.

M11c — zamknięcie implementacji: ostatnia korekta obejść zmieniła Garden S2 na(1056,512), jego drugą parę na(776,192)/(944,624) i blok na[936,208,96,152]; Reactor kończy na parze(768,304)/(1168,512) z blokiem[784,448,48,96]. Na polecenie użytkownika nie kontynuowano końcowych testów; ręczną ocenę przejmuje użytkownik. Nie nadano końcowej geometrii wyniku wcześniejszej pełnej regresji.

M11c — końcowy odbiór po wznowieniu: pełna regresja1146PASS/0FAIL/19 suites na końcowych danych;6 kampanii offline,pełne LAN Normal/Relaxed,24 przypadki siatki brzegów pól(3382821 par),świeże eksporty Linux/Windows oraz Linux boot/ENet/native zakończone. Ludzki playtest, fizyczny LAN2komputerów, runtimeWindows i M15 pozostają NOT RUN. Wyniki wcześniejszych przerw nie zastępują tych końcowych logów.

## Dziewięć poziomów: katalog, wynik poziomu i zapis

Po M11c dodano katalog stabilnych ID i sześć map schema3. Zastępujemy trzysektorową ekspedycję z przenoszeniem zdrowia/punktów pojedynczymi wynikami poziomów, nowym match_id przy każdej mapie i wspólną decyzją obu osób o dalszej akcji. Wybór, kontynuacja i następnik pochodzą z katalogu; format sieci ogranicza katalog do64 wpisów. Zapis przechowuje ID, nie ordinale ani wyliczone blokady. Historyczne rekordy kampanii pozostają nietknięte i nie stanowią dowodu ukończenia poziomów. Gość zapisuje zwycięstwo dopiero po reliable SessionState. Protokół3 zawiera level_id i maski nowych przeszkód w każdym snapshotcie. Pełne menu/ustawienia M12 ma korzystać z istniejących LevelSelectPresenter i ProgressStore.
