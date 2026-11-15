# CODE_CONTRACTS — kontrakt 1.0

Źródło: [MASTER_SPEC.md](MASTER_SPEC.md), specyfikacja 1.0 (14 listopada 2026).
Poniższe rozdziały zachowują pełną treść źródła. Opisują wymagania docelowe; stan implementacji podaje [PROJECT_STATUS.md](PROJECT_STATUS.md).

## 16. Blueprint plik po pliku

### 16.1 Konwencje kontraktów

Wszystkie `.gd` są w GDScript. Nazwy klasy PascalCase, pliki i metody snake_case. Klasy core i DTO dziedziczą `RefCounted`, konfiguracje są konstruowane z walidowanego JSON. Nie używać `Dictionary` jako uniwersalnego modelu świata. Słowniki dozwolone na granicy JSON, do mapowania ID i w krótkotrwałych modelach UI. W tabelach `Result` oznacza `GameTypes.Result`, a `Frame` oznacza `GameTypes.RenderFrame` — są to konkretne klasy z `core/game_types.gd`, nie nieistniejące generyki.

Błędy oczekiwane zwracają `Result(ok:bool, code:int, message:String, value:Variant)`. Błędy sieci mają kod z Protocol.ErrorCode, lokalne z GameTypes.ErrorCode. Nie używać wyjątków jako modelu API GDScript. Konfigurację sprawdza się przed meczem; w pętli ticka nie ma logowania każdego poprawnego przypadku. Sygnały emitowane po ukończeniu mutacji, nie w jej środku.

Wszystkie poniższe API są normatywnymi **sygnaturami projektu**, nie cytatami API silnika. Sol ma zaimplementować je w tych plikach. Godot nie gwarantuje read-only DTO: immutable oznacza własność i zakaz modyfikacji po publikacji, wymuszany kopiami i testami aliasingu.

### 16.2 Core: dane i symulacja

| Plik / klasa | Pola i publiczne API | Algorytmy, granice, test |
|---|---|---|
| core/game_types.gd / GameTypes | enum PlayerMode, MatchPhase, LinkStatus, Difficulty, ErrorCode; klasy Result, MoveResult, LinkResult, RenderFrame, SettingsData, RecordData | Result bez Node; MoveResult: position,velocity,segments:Array[Vector4],segment_times:Array[Vector2] (początek/koniec odcinka jako ułamek ticka; ADR-0004); RenderFrame: tick_float,players,beacons,link,hazards,integrity; test_content sprawdza zakres enum |
| core/game_config.gd / GameConfig | stałe dt, speed, dash_ticks, timers; `static from_json(data:Dictionary)->Result`; `validate()->Result` | immutable po walidacji; odrzuca NaN, ujemne timery, różny tickrate; test_content |
| core/map_definition.gd / MapDefinition | id:StringName, bounds:Rect2, walls:Array[Rect2], spawns:Array[Vector2], beacons,sockets:Array[Vector2], hazards:Array[HazardDef], exit_position:Vector2; `static from_json(data:Dictionary)->Result`; `validate(config:GameConfig)->Result` | HazardDef zagnieżdżona: id,type,a,b,travel,radius,offset; walidacja limitów, kolizji spawn i bezpiecznych stref; test_content |
| core/input_command.gd / InputCommand | tick:int, axis_x:int,axis_y:int, dash_serial:int,anchor_serial:int,ping_serial:int; `axis()->Vector2`; `copy()->InputCommand`; `static neutral(tick:int)->InputCommand` | oś i8, normalizacja; seriale u16; neutral przy timeout zachowuje ostatnie skonsumowane seriale poprzez jawne przepisanie w sesji; test_input |
| core/world_state.gd / WorldState | tick,sector_tick,remaining_ticks,phase_remaining,phase,sector_index,integrity,objective_index,active_socket,link_status,charges:PackedInt32Array,extract_ticks,socket_cooldown,damage_cooldown,score,complete_mask,last_event_id; players:Array[PlayerState]; last_power_ticks:PackedInt32Array; difficulty:int,variant:int,objective_order:PackedInt32Array,last_ping_ticks:PackedInt32Array,completed_beacons_total:int | PlayerState: position,velocity,facing:Vector2; mode,dash_ticks,stun_ticks,invulnerable_ticks,dash_cooldown; consumed_serials:Vector3i; `reset(map:MapDefinition,config:GameConfig,carry_integrity:int)->void`; mutuje wyłącznie Simulation; test_simulation |
| core/game_snapshot.gd / GameSnapshot | opublikowane kopie pól wire z §19; `static capture(world:WorldState)->GameSnapshot`; `copy()->GameSnapshot`; `validate(map:MapDefinition,config:GameConfig)->Result` | bez last_power_ticks, bo nie służy odtwarzaniu hostowej symulacji; wystarcza do bieżącego renderowania i predykcji drona; test aliasingu i kodeka |
| core/game_event.gd / GameEvent | id,tick,type,player_id,object_id,value,position; EventType: DASH,SOCKET,HIT,BEACON,PING,SECTOR_END,MATCH_END; `copy()->GameEvent` | Systemy tworzą eventy z id=0; po zakończeniu ticka Simulation nadaje kolejne ID i aktualizuje last_event_id. ID rośnie w meczu; object_id=255 gdy brak; nie steruje trwałym stanem; test_simulation |
| core/collision_world.gd / CollisionWorld | walls:Array[Rect2],bounds:Rect2; `configure(map:MapDefinition)->void`; `move(position:Vector2,velocity:Vector2,dt:float)->GameTypes.MoveResult`; `blocks_segment(a:Vector2,b:Vector2,padding:float)->bool` | prywatne `_sweep_aabb`, `_first_hit`, `_depenetrate_tiny`; deterministyczne tie-break, limit3 slide; test_collision |
| core/movement.gd / Movement | bez stanu; `static step(player:WorldState.PlayerState,command:InputCommand,collision:CollisionWorld,config:GameConfig)->GameTypes.MoveResult` | używa już zaktualizowanych timerów/akcji; współdzielona kinematyka; `static begin_dash(...) -> bool`; test_movement |
| core/link_system.gd / LinkSystem | `evaluate(players:Array[WorldState.PlayerState],socket_id:int,map:MapDefinition,collision:CollisionWorld)->GameTypes.LinkResult`; `find_socket(position:Vector2,map:MapDefinition)->int`; `hits_beacon(link:GameTypes.LinkResult,center:Vector2)->bool` | LinkResult: points:Array[Vector2],length:float,status:int; punkty kopiowane; najbliższy segment i długości wzdłuż trasy; test_link |
| core/hazard_system.gd / HazardSystem | `phase_at(def:MapDefinition.HazardDef,tick:int,difficulty:int,variant:int)->Dictionary`; `hits(def:MapDefinition.HazardDef,path:Array[Vector4],tick:int,difficulty:int,variant:int)->bool`; `apply(world:WorldState,paths:Array,map:MapDefinition,config:GameConfig,events:Array[GameEvent])->void` | phase_at zwraca ograniczony model view, nie mutuje; apply koszt max 1/30tick, oba stun; test_hazards |
| core/objective_system.gd / ObjectiveSystem | `step(world:WorldState,link:GameTypes.LinkResult,map:MapDefinition,config:GameConfig,events:Array[GameEvent])->void`; `finish_sector(world:WorldState)->void`; `final_score(world:WorldState)->int` | ładowanie, decay, cel następny tick, ekstrakcja; finish_sector jednokrotne; test_objectives |
| core/simulation.gd / Simulation | world:WorldState,config:GameConfig,map:MapDefinition,collision:CollisionWorld,seed:int,difficulty:int,variant:int; `initialize(config:GameConfig,map:MapDefinition,seed:int,difficulty:int)->void`; `step(commands:Array[InputCommand])->Array[GameEvent]`; `snapshot()->GameSnapshot`; `reset_sector(map:MapDefinition,sector_index:int)->void` | exact2 commands; prywatne `_advance_timers`, `_consume_actions`, `_resolve_phase`; nie przyjmuje delta z render; test_simulation |

`HazardSystem.phase_at` jest wyjątkiem dotyczącym małego słownika na granicy prezentacji; w implementacji finalnej może wypełniać istniejący słownik, bez alokacji co tick dla każdego hazardu. W `apply(paths:Array)` tablica ma dokładnie dwa elementy typu Array[Vector4], walidowane raz przez Simulation; nie opierać się na zagnieżdżonych typed arrays niewspieranych przez wybraną wersję GDScript.

### 16.3 App i usługi

| Plik / klasa | Pola, API i zdarzenia | Życie, błędy, test |
|---|---|---|
| app/app_state.gd / AppState | enum Screen; current,return_to:int; `transition(next:int)->Result`; `allows(next:int)->bool` | tabela przejść §14; zakaz Playing bez sesji; test_flow |
| app/app_root.gd / AppRoot : Node | settings,assets,session,router,ui,audio,diagnostics; `_ready`, `_physics_process(delta)`, `_process(delta)`; `dispatch(intent:StringName,payload:Dictionary)->void`; `shutdown()->void` | composition root; `_notification` obsługuje focus i WM close; start w Boot; test_boot |
| app/scene_router.gd / SceneRouter : RefCounted | container:Node,active:Node,pending_generation:int; `configure(container:Node)->void`; `show(scene_id:StringName)->Result`; `clear()->void`; signal scene_ready(scene_id) | ładowanie przez AssetCatalog, generacja unieważnia zakończony stary load; aktualizacja drzewa tylko główny wątek; test_flow |
| app/input_router.gd / InputRouter : RefCounted | seriale,enabled,last_axis; `configure(settings:GameTypes.SettingsData)->void`; `sample(target_tick:int)->InputCommand`; `set_enabled(value:bool)->void`; `clear()->void` | sample raz per command tick, edge input zbierane z `_unhandled_input` przez `feed(event:InputEvent)->void`; test_input |
| app/match_session.gd / MatchSession : RefCounted | role,session_id,match_id,phase,transport,lobby,simulation,prediction,clock; `host(options:Dictionary)->Result`; `join(ip:String,port:int,name:String)->Result`; `set_ready(value:bool)->void`; `request_start()->Result`; `vote(kind:int,value:bool)->void`; `fixed_update(local_commands:Array[InputCommand])->void`; `render_frame(alpha:float)->GameTypes.RenderFrame`; `leave(reason:int)->void` | signals lobby_changed,phase_changed,failed(code,message),events_ready(events); wyłącznie ta klasa mapuje peer ID na0/1; test_session/network |
| services/asset_catalog.gd / AssetCatalog | packed_scenes,textures,audio,fonts:Dictionary; `load_boot()->Result`; `begin_sector(map_id:StringName)->void`; `poll_loading()->Result`; `get_scene(id:StringName)->PackedScene`; `get_texture(id:StringName)->Texture2D`; `get_audio(id:StringName)->AudioStream`; `release_sector()->void` | ResourceLoader threaded load, pobranie dopiero po loaded; jeden egzemplarz atlasu, null→jawny błąd; test_content/presentation |
| services/settings_store.gd / SettingsStore | path,user settings; `load_settings()->GameTypes.SettingsData`; `save_settings(data:GameTypes.SettingsData)->Result`; `validate(data:Dictionary)->Result` | tmp+rename, version1, malformed→defaults+ostrzeżenie; test_persistence |
| services/records_store.gd / RecordsStore | records:Array[GameTypes.RecordData]; `load_records()->void`; `submit(record:GameTypes.RecordData)->Result`; `best(difficulty:int)->GameTypes.RecordData` | max100, sort score desc then time asc; brak danych→null; test_persistence |
| services/log_service.gd / LogService | ring:PackedStringArray,max_lines=500; `write(level:int,code:StringName,message:String)->void`; `flush()->Result` | log max2 MiB×3; bez wpisywania pakietów/raw nazw z kontrolnymi znakami; test_persistence |
| services/diagnostics.gd / Diagnostics | próbki frame/physics/rtt/bandwidth/alloc count; `sample_frame(ms:float)->void`; `sample_tick(ms:float)->void`; `report()->Dictionary`; `reset()->void` | okno300 próbek; zapis tylko po benchmark/wyjściu; HUD debug F3 tylko debug build; test_perf przez benchmark |

### 16.4 Sieć

| Plik / klasa | API / stan | Ważne zachowanie i test |
|---|---|---|
| net/protocol.gd / Protocol | VERSION=1,MAX_PACKET_BYTES=1000; MessageType,ErrorCode,Channel,VoteKind; statyczne mapowanie typu do kanału i limitu | same stałe; Hello schema i wersje przypięte; test_protocol |
| net/packet_codec.gd / PacketCodec | `encode(type:int,header:Dictionary,payload:Variant)->Result`; `decode(bytes:PackedByteArray)->Result`; `_write_snapshot`, `_read_snapshot`, `_read_string` | result.value=DecodedMessage(type,session_id,match_id,sequence,payload) jako klasa zagnieżdżona; bounded cursor, little endian; bez bytes_to_var; test_protocol |
| net/message_guard.gd / MessageGuard | ostatnie seq per peer/type,token buckets,invalid_count; `accept(peer_id:int,msg:PacketCodec.DecodedMessage,context:Dictionary,now_ms:int)->Result`; `reset()->void` | chronologia stanów i roli, pełne sprawdzenie długości przed decode payload; limity §23; test_protocol |
| net/net_transport.gd / NetTransport | peer:ENetMultiplayerPeer,api:SceneMultiplayer,connected_peer:int; `start_host(port:int)->Error`; `start_client(ip:String,port:int)->Error`; `poll()->void`; `send(peer_id:int,bytes:PackedByteArray,mode:int,channel:int)->Error`; `close()->void` | signals packet(peer_id,bytes),connected(peer_id),disconnected(peer_id),failed(code); api.allow_object_decoding=false; test_network |
| net/lan_discovery.gd / LanDiscovery | udp:PacketPeerUDP,entries:Dictionary,last_probe_ms; `start_host(room:Dictionary)->Result`; `start_scan()->Result`; `poll(now_ms:int)->void`; `stop()->void`; signal results_changed(entries) | UDP7778, scan ephemeral port, TTL3s, żadnych NodePath z sieci; test_network |
| net/lobby_state.gd / LobbyState | revision:int,ready_mask:int,names:Array[String],difficulty,seed; `set_ready(slot:int,value:bool)->void`; `set_options(difficulty:int,seed:int)->void`; `can_start()->bool` | zmiana options zeruje ready_mask; signal zastępuje sesja; test_session |
| net/host_replication.gd / HostReplication | inputs po tickach per slot,held_axes,last_received_tick,pending_events; `enqueue(slot:int,commands:Array[InputCommand],current_tick:int)->Result`; `commands_for(tick:int)->Array[InputCommand]`; `capture(simulation:Simulation)->GameSnapshot`; `drain_events(max_count:int)->Array[GameEvent]`; `reset()->void` | przyszłe ticki≤12, przeszłe ignorowane, neutral po6 brakach; test_network/prediction |
| net/client_prediction.gd / ClientPrediction | player:WorldState.PlayerState,pending:Array[InputCommand],last_authority_tick:int,visual_offset:Vector2; `configure(map:MapDefinition,config:GameConfig,slot:int)->void`; `push(command:InputCommand)->void`; `reconcile(snapshot:GameSnapshot)->void`; `present(delta:float)->WorldState.PlayerState`; `reset()->void` | ring256, tylko Movement i własne cooldowny, kopiowanie przy reset, brak zgadywania damage/socket; test_prediction |
| net/snapshot_buffer.gd / SnapshotBuffer | snapshots:Array[GameSnapshot],capacity=32; `insert(snapshot:GameSnapshot)->bool`; `sample(render_tick:float)->GameTypes.RenderFrame`; `clear()->void` | ominięcie starych i duplikatów, interp pos/vel tylko; enum i charge z najbliższego wcześniejszego; test_prediction |
| net/network_clock.gd / NetworkClock | rtt_ms:float,estimated_tick:float,lead_ticks:int,last_echo:int; `on_pong(echo_us:int,server_tick:int,now_us:int)->void`; `advance(delta:float)->void`; `next_command_ticks(last_tick:int)->PackedInt32Array`; `reset(tick:int)->void` | RTT EWMA0,1, lead clamp2..8; max3 nowe ticki/fixed update, nie cofa ticków; test_prediction |

### 16.5 Prezentacja, UI, audio i narzędzia

| Plik / klasa | Publiczna granica i stan | Reguły, błędy, powiązany test |
|---|---|---|
| presentation/world_view.gd / WorldView : Node2D | `configure(map:MapDefinition,assets:AssetCatalog)->void`; `present(frame:GameTypes.RenderFrame,delta:float)->void`; `reset()->void`; drony,urządzenia,hazardy | brak Simulation i Input; pooling beaconów; test_presentation |
| presentation/drone_view.gd / DroneView : Node2D | `configure(slot:int,assets:AssetCatalog)->void`; `present(player:WorldState.PlayerState,delta:float)->void`; `play_event(event:GameEvent)->void` | root.position z modelu, child transform z animacji; nie podwaja korekcji; test_presentation |
| presentation/link_view.gd / LinkView : Node2D | `present(points:PackedVector2Array,status:int,charge:float)->void`; `set_reduced_motion(value:bool)->void` | trzy Line2D i materiał współdzielony poza parametrami instancji; efekty bez geometrii collision; test_presentation |
| presentation/fx_pool.gd / FxPool : Node2D | `emit_event(event:GameEvent)->void`; `update_effects(delta:float)->void`; `clear()->void`; capacity128/320particles | najstarsze dekoracyjne wygaszane; event dedup id; test_presentation |
| presentation/camera_rig.gd / CameraRig : Camera2D | `configure(shake_scale:float)->void`; `impulse(amplitude:float,duration:float)->void`; `_process(delta)` | bazowe centrum640,360, zoom1; shake tylko offset, clamp3 px; test_presentation |
| presentation/audio_director.gd / AudioDirector : Node | `configure(assets:AssetCatalog,settings:GameTypes.SettingsData)->void`; `play_event(event:GameEvent)->void`; `update_frame(frame:GameTypes.RenderFrame)->void`; `set_mix(settings:GameTypes.SettingsData)->void`; `stop_session()->void` | dedup(id) i speculative dash(player,serial); crossfade i pula; test_audio |
| ui/ui_root.gd / UIRoot : CanvasLayer | `show_screen(screen:int,model:Dictionary)->void`; `show_error(code:int,text:String)->void`; `show_overlay(id:StringName)->void`; signal intent(action,payload) | jedyna droga UI→AppRoot, focus trap modal; test_ui |
| ui/menu_presenter.gd / MenuPresenter : Control | `bind(model:Dictionary)->void`; `set_rooms(rooms:Array)->void`; `set_busy(value:bool)->void`; signal intent | host/join/discovery/credits, sanitizacja nazw, ip parser; test_ui |
| ui/lobby_presenter.gd / LobbyPresenter : Control | `present(lobby:LobbyState,role:int)->void`; `present_loading(progress:float,remote_loaded:bool)->void`; signal intent | host-only options/start, jeden listener na button; test_ui/session |
| ui/hud_presenter.gd / HudPresenter : Control | `present(frame:GameTypes.RenderFrame,network:Dictionary)->void`; `show_hint(id:StringName)->void` | refresh tekstu gdy wartość się zmieni, czas ceil(remaining/60); test_ui |
| ui/settings_presenter.gd / SettingsPresenter : Control | `open(settings:GameTypes.SettingsData)->void`; `capture_binding(action:StringName)->void`; `cancel_capture()->void`; signal intent | kontrolki lokalne, timeout potwierdzenia obrazu; test_ui/persistence |
| ui/results_presenter.gd / ResultsPresenter : Control | `present(snapshot:GameSnapshot,votes:int)->void`; signal intent | wynik z snapshot, animacja może się pominąć, zero wyliczeń punktów po stronie UI; test_ui |
| tools/asset_bake.gd | SceneTree `_initialize`; CLI `--out`, generuje grain i opcjonalne autorskie dźwięki | deterministyczny seed; nie uruchamia się u użytkownika; test_content waliduje rezultat |
| tools/validate_content.gd | SceneTree `_initialize`; waliduje mapy, manifest, licencje i regiony atlasów; exit0/1 | wymusza limity, brak plików→1; test_content |
| tools/build_manifest.gd | SceneTree `_initialize`; `--write` lub `--check`; oblicza hash | uporządkowane ścieżki i bajty; opis §17; bez data/time w hashu |
| tests/test_assert.gd / TestAssert | `equal`, `near`, `is_true`, `fails`, `summary`; licznik błędów | nie używa jedynie silnikowego assert; działa release/headless |
| tests/test_runner.gd | SceneTree; `--suite=unit/integration/all`, jawna lista suites | każdy suite `run(t:TestAssert)->void`; output JSON i exit1 przy błędzie/skrypcie niezaładowanym |
| tests/integration/network_harness.gd | Node; CLI role,port,scenario,report; uruchamia dwie realne aplikacje przez wrapper lub niezależnie | auto input tylko debug, timeout30s; testuje realny ENet oddzielnie od fault_link |
| tests/integration/fault_link.gd / FaultLink | `send(packet,now)`, `receive_due(now)`; seed,loss,duplicate,reorder,latency,jitter | izolowana podmiana wysyłki testowej, nie udaje pełnej emulacji ENet; scenariusze reliable mają opóźnienie, a retransmisję bada realny test sieci |
| tests/perf/benchmark.gd | Node;60s warmup+600s próbek, zapis JSON/CSV, exit | pełna scena i maxFX, nie headless dla GPU |

`export.sh` i `export.ps1` mają równoważne kroki import→content→tests→manifest check→dwa eksporty→hash paczek. Nie pobierają automatycznie toolchain bez jawnej komendy setup. README opisuje instalację wskazanego silnika i templates. LICENSE: kod MIT, własna grafika/audio CC-BY4.0 lub inna jawnie zatwierdzona licencja autora; dopóki autor nie zdecyduje o publikacji, dokumentacja nie udziela za niego licencji. Pierwszy milestone zapisuje w LICENSE **„All rights reserved — licensing decision pending”** zamiast samodzielnie publikować kod na MIT. THIRD_PARTY_NOTICES zawiera licencje silnika i fontu.

`data/audio_bank.json` ma schema_version1 i słownik entries: każde ID z §10 mapuje na {path:String,bus:StringName,priority:int0..10,max_voices:int1..24,loop:bool,gain_db:float,spatial:bool}. Ścieżki muszą wskazywać lokalne assets/audio; walidator sprawdza obecność i zgodność loop z formatem. Ustawienia pętli OGG zapisuje się w imporcie; przy WAV w AudioStreamWAV. Buses i połączenia są konfiguracją `project.godot` oraz tworzonego banku audio, nie danymi z sieci.

`GameTypes.SettingsData` ma typy wynikające ze schematu §17.1: bool dla przełączników, float dla suwaków, int dla limitu FPS, String dla IP, Dictionary dla walidowanych bindingów. `GameTypes.RecordData`: seed:int,difficulty:int,score:int,duration_ticks:int,integrity:int,date_utc:String. `GameTypes.RenderFrame` zawiera kopie dwóch PlayerState, charges:PackedInt32Array, complete_mask:int, objective_index:int, active_socket:int, link_status:int, integrity:int, phase:int, remaining_ticks:int, score:int oraz transient modele hazardów i przewodu. Nie przekazuje mutowalnego hostowego WorldState.

### 16.6 Pliki testowe i kontrakty wejścia/wyjścia

Wszystkie `tests/unit/test_*.gd` i `tests/integration/test_*.gd` implementują `run(t:TestAssert)->void`, a test wymagający idle frames udostępnia asynchroniczne `run_async(t:TestAssert)->void`, jawnie awaitowane przez runner. Runner wykrywa metodę przez `has_method`; brak obu to błąd suite, nie skip. Suites nie wywołują `quit` samodzielnie. Nazwy przypadków i oczekiwane wyniki są w §22. Integracja nie otwiera portów poza127.0.0.1, chyba że scenariusz jawnie oznaczono `lan_manual`.

JSON fixtures: `protocol_vectors` ma pary hex/decoded oraz błędne pakiety; `*_success` ma seed, map_id, komendy dwóch slotów i oczekiwane eventy/phase. Fixture nie zawiera teleportów i nie modyfikuje integrity, aby wymusić sukces. `valid_map` jest małą legalną mapą z wyłączonymi hazardami wyłącznie w testach; `invalid_map` nakłada spawn na ścianę.

## 17. Specyfikacje klas, danych i algorytmów

### 17.1 Schemat konfiguracji

`data/gameplay.json` ma `schema_version:1`, `simulation_hz:60`, `snapshot_hz:30`, `input_hz:30`, `movement:{speed:240,acceleration:1800,deceleration:2400,half_size:12}`, `dash:{speed:720,duration_ticks:10,cooldown_ticks:90}`, `link:{min_length:56,max_length:720,width:6,socket_radius:44,socket_cooldown:30}`, `objective:{charge_ticks:300,grace_ticks:30,decay_period_ticks:2,extract_ticks:120}`, `damage:{stun_ticks:12,invulnerable_ticks:90,global_cooldown:30}`, `difficulties` z parametrami NORMAL/RELAXED §5–6. Całość ładowana przed uruchomieniem lobby.

Parametry `difficulty`, `variant` i `objective_order` w WorldState są ustawiane przy initialize/reset_sector i nie zmieniają się podczas sektora. Klient wylicza je z LoadSector i zweryfikowanych danych. `last_ping_ticks` jest wyłącznie hostową historią ograniczenia markerów.

Map JSON ma `schema_version`, `id`, `bounds:[x,y,w,h]`, `spawns:[[x,y],[x,y]]`, `walls:[{id,rect}]`, `beacons:[{id,position}]`, `sockets:[{id,position}]`, `exit:{position,radius}`, `hazards:[{id,type,a,b,travel,radius,phase_offset}]`, `background_asset`. Typy PULSE pomijają b/travel, SWEEP pomija radius. Nieznane klucze są błędem podczas walidacji produkcyjnego contentu. ID wall0..31, beacon0..2, socket0..2, hazard0..7. Limit ścian32, hazardów8, całkowita długość JSON mapy≤64 KiB.

Settings JSON `schema_version:1`: volumes0..1,fullscreen bool,fps_limit60/120/0,vsync bool,ui_scale1/1.15/1.3,shake0..1,reduced_motion bool,color_accessibility bool,hints bool,bindings dictionary,last_ip string. Starsze wersje migruje się jawnie; nowszą ignoruje z ostrzeżeniem i zachowaniem pliku `.bak`. Rekordy mają osobny schema1, max100 wpisów.

### 17.2 Własność, identyfikatory i hash

| Dane | Właściciel | Zmienność / czas życia | Replikacja |
|---|---|---|---|
| GameConfig, MapDefinition | Asset/config service | immutable od load do shutdown | tylko content hash i ID |
| WorldState | Simulation hosta | mutable przez mecz | projekcja GameSnapshot |
| PlayerState hosta | WorldState | mutable co tick | snapshot |
| PlayerState predicted | ClientPrediction | prywatna kopia gościa | nigdy do hosta |
| GameSnapshot | producent, potem odbiorca | po publikacji immutable; bufor32 | host→client |
| InputCommand | InputRouter, potem kolejki | immutable po sample; ring256 | client→host |
| GameEvent | Simulation | immutable, cache256 | host→client |
| RenderFrame | session/view | transient, można reuse po zakończeniu frame | nie |
| Settings/records | lokalne services | mutable tylko UI/save | nie |
| Assety | AssetCatalog | współdzielone Resources | nie |

Slot gracza to0 albo1; peer ID ENet nie jest slotem. Host to peer1/slot0; gość dostaje losowy ENet peer ID, sesja mapuje go do slot1. session_id: losowy niezerowy u32 przy hostowaniu; match_id: losowy niezerowy u32 na każdą ekspedycję/rewanż, inny od poprzedniego. Nie są sekretami ani tokenami uwierzytelniającymi. sector_index0..2 jest częścią snapshotu; spóźniony pakiet z innego sektora jest odrzucany.

`build_manifest.json`: schema1, protocol1, engine_version, engine_build_id, content_sha256, code_revision, build_label. `engine_build_id` oznacza wspólny hash commita oficjalnego silnika, bez nazwy platformy; nie porównuje się pełnej ścieżki executable ani platformowego suffixu. Content hash obejmuje uporządkowane bajtowo ścieżki i bajty `data/**`, `core/**`, `net/**`, `app/**`; każdy wpis ma długość ścieżki i pliku przed bajtami, żeby uniknąć niejednoznacznej konkatenacji. Nie obejmuje samego manifestu, logów, platformowych importów ani grafik/audio. Manifest budowany z jednego commita dla obu OS. Różne zasoby wizualne nie wpływają na symulację, ale paczki release mają ten sam kompletny content i osobne SHA256 archiwów. `code_revision` jest metadanymi, nie jedyną kontrolą zgodności.

### 17.3 Startup i zamknięcie

```text
boot:
  sprawdź engine_version/build_id z manifestem
  wczytaj settings lub defaults
  otwórz log i sprawdź wszystkie dane gry
  przygotuj font, theme, menu i bank UI audio
  skonfiguruj InputRouter i AudioDirector
  wyłącz automatyczny multiplayer_poll w SceneTree
  pokaż Menu, nie otwieraj socketów

shutdown:
  ustaw flagę closing (kolejne wywołanie nic nie robi)
  zablokuj wejście i anuluj aktywną generację loading
  wyślij Leave, jeśli połączenie działa
  poll do maksymalnie200ms bez blokowania głównego wątku
  close transport i discovery; odłącz signals
  stop audio; usuń WorldView, wyczyść bufory
  zapisz settings/records i log (błąd nie blokuje wyjścia)
  quit
```

Nie czekać na ack zamknięcia bez końca. Przy brutalnym zabiciu procesu partner sam wykrywa timeout.

### 17.4 Ruch i przewód — pseudokod

```text
player_tick(command):
  dekrementuj timery (wykonywane raz przez simulation/prediction)
  porównaj dash_serial i anchor_serial z consumed_serials
  skonsumuj nowe seriale nawet gdy cooldown odmawia akcji
  jeśli nowy dash i mode NORMAL i cooldown==0:
      mode=DASH; dash_ticks=10; cooldown=90
      facing=nonzero(command.axis) albo last_facing
  jeśli mode STUN: velocity=zero
  inaczej jeśli DASH: velocity=facing*720
  inaczej: velocity=move_toward(velocity,desired,accel_or_brake/60)
  result=collision.move(position,velocity,1/60)
  zapisz result.position, result.velocity i odcinki toru

link_hits(beacon):
  jeśli status != ACTIVE: false
  accumulated=0
  dla segmentu [a,b] o długości L:
      wyznacz najbliższy punkt q na [a,b]
      along=accumulated+distance(a,q)
      jeśli distance(q,beacon)<=25 i 48<=along<=total_length-48:
          true
      accumulated+=L
  false
```

Timer dash ustawiony na10 jest aktywny w ticku przyjęcia i w kolejnych9. Na początku następnego po tych10 spada do0 i przełącza mode NORMAL. Tę samą kolejność musi stosować predykcja. Anchor jest autorytatywną akcją Simulation, nie Movement.

### 17.5 Pętla aplikacji i threading

`AppRoot._physics_process` jest jedynym sterownikiem fixed update. Najpierw `transport.poll()`, następnie queue drain i session state, sample komend, Simulation albo Prediction, a na końcu sieciowa wysyłka. `MatchSession.fixed_update` otrzymuje tablicę lokalnych komend: host ma dokładnie jedną, gość od zera do trzech według NetworkClock. Sesja hosta buduje następnie dokładnie dwuelementową tablicę dla `Simulation.step`; komendy gościa nie powodują dodatkowych kroków hosta. `AppRoot._process(delta)` aktualizuje NetworkClock, render frame, UI i audio. Nie uruchamia symulacji ani nie odbiera input actions drugi raz.

Callbacks sieciowe wykonują się podczas `poll`; dodają DTO do bounded queue. Drain zachodzi po powrocie z poll. Discovery poll jest nieblokujący; max32 datagramy/frame. Asset loading może korzystać z wątków silnika, ale tworzenie Node i przypisywanie Resources wykonuje główny wątek. Brak własnych worker threads w P0.

Silnik może doganiać physics do4 kroków na klatkę. Jeśli host przez >500 ms nie wyrabia z60 Hz, pokazuje „Host działa zbyt wolno”; zegar gry zwalnia razem z tickami, nie odejmuje ukrytego czasu ściennego. Benchmark ma wykazać, że na sprzęcie bazowym ten stan nie występuje. Nie przenosić symulacji do `_process`, aby ukryć problem.

### 17.6 Kontrakty integracyjne

| Granica | Format i timing | Własność i błąd |
|---|---|---|
| UI→AppRoot | intent StringName + walidowane primitive payload, main thread | intencja nie zmienia świata; nieznana nazwa log+ignore |
| Input→Session | InputCommand dla jednego target_tick | immutable; duplicate tick ignorowany |
| Session→Simulation | Array dokładnie2 komend, raz/tick | mutable world tylko wewnątrz; nieprawidłowa długość to błąd programowania/test failure |
| Simulation→Replication | snapshot + events po skończonym ticku | głęboko skopiowane pola mutable; brak Node/Resource |
| Transport→Codec→Guard | PackedByteArray≤1000, peer_id poza pakietem | odrzucenie przed routingiem, żadnych wyjątków z zewnętrznej treści |
| Session→View | RenderFrame raz na render | view może przechować do następnego frame, nie modyfikuje snapshot |
| Events→Audio/FX | id,tick,type,serial w value gdy dash | dedup przed odtworzeniem; przepełnienie dekoracji nie wpływa na sim |
| Services→UI | Result dla save/load i defaults | błąd zapisu pokazuje ostrzeżenie, nie kończy meczu |
| SceneRouter→Session | sector_loaded(generation,sector_index) jako wywołanie sesji po scene_ready | stara generation ignorowana; żaden stary load nie uruchamia nowego meczu |


## Implementacja M08

HostReplication.enqueue(slot, commands, current_tick) waliduje cały batch przed
zmianą kolejki. commands_for(tick) zwraca dokładnie dwie kopie komend.
MatchSession.fixed_update(local_commands) jest wywoływane raz/60 Hz, niezależnie
od poll(); render_frame() zwraca kopie aktualnego stanu. vote(kind,value) jest
rozstrzygane wyłącznie przez hosta. next_input_tick() zwraca -1, gdy nie wolno
próbkować wejścia. Klient nie posiada Simulation ani lokalnego świata autorytatywnego.

## Implementacja M09

NetworkClock.on_pong/advance/next_command_ticks steruje lead2..8 i monotonicznymi
komendami (max3/fixed update). AppRoot używa MatchSession.next_input_ticks().
ClientPrediction.push/reconcile/present/reset odtwarza pełny PlayerState z granicą
snapshot.tick, zachowuje wyłącznie przyszłe komendy, ogranicza historię do256
oraz lukę do12. SnapshotBuffer.insert/sample:32 próbek, remote tick−6,
extrapolate≤6 tick ze statyczną kolizją. Predykcja dotyczy wyłącznie ruchu gościa,
bez drugiej Simulation. RenderFrame to kopie; WorldView nie zmienia świata.
Zamrożenie klienta po250 ms bez snapshotu, wznowienie po nowym stanie;
heartbeat500 ms, ostrzeżenie1 s, rozłączenie3 s. Wire1 bez zmian schematów.

M09: dodatkowa granica bezpieczeństwa target tick to ostatni snapshot.tick+12.
Gdy host chwilowo zwalnia, estymata zegara nie daje prawa wysłać komendy poza
jego okno przyszłości. Klient pomija generowanie, nie cofa numeracji. Przypadek
wykryty w smoke GUI ma osobną regresję z zatrzymanym tickiem hosta.

## Implementacja M10

Mapy kampanii to dock/garden/reactor, map_id0/1/2 zgodny z sector_index.
LoadSector wariant musi odpowiadać (seed+17×sector)%3; brak zmiany wire1.
AssetCatalog.maps i map_for_sector(index) udostępniają trzy zwalidowane definicje.
SceneRouter.show(scene_id,map_id=&"dock") zachowuje domyślne API; produkcyjna
kampania jawnie wybiera mapę sektora. MatchSession, ClientPrediction i WorldView
używają tej samej geometrii lokalnej. Simulation.reset_sector zachowuje integrity,
score, globalny tick i event IDs, resetując stan sektora/seriale.
Testowe pliki sukcesu zawierają rzeczywiste RLE InputCommand obu slotów,18 tras;
nie są wejściem normalnej gry. Flood-fill nie zastępuje replay ani playtestu duetu.

## Implementacja M11a/b

AssetCatalog ładuje lokalne tekstury/fonty i tworzy współdzielone AtlasTexture.
WorldView.configure(...,catalog=null) przyjmuje katalog; play_event kopiuje event,
nie mutuje Simulation/Snapshot. FxPool.emit_event/update_effects/clear ma limity
128/320 lub160 i bounded dedup512. DroneView.present/play_event dotyczy wyłącznie
Visual, CameraRig.impulse wyłącznie render offset; HUD jest w CanvasLayer10.
prewarm/finish_warmup obejmują shadery i właściwe prymitywy FX, w natywnym AppRoot
przed Loaded. Generation po await uniemożliwia start anulowanego ładowania.
Low/reduced motion nie usuwają geometrii i informacji o niebezpieczeństwie.

### Nagrania po przebudowie map

`*_success.json` RLE: `[ticks,x0,y0,x1,y1,anchor0,anchor1]`. Serial utrzymuje się
między klatkami; odtwarzacz przyjmuje też starsze 5 pól z zerowymi akcjami.
Planer autora korzysta z `tools/map_solution_hints.json`, gra nie ładuje tego pliku.
Geometria użytkownika zastępuje historyczne współrzędne map M10.

## M11c — aktualne rozszerzenie kontraktów

`MapDefinition.ObjectiveDef`: hint:String, stabilization:Array[PackedVector2Array],
0/1/2 pary. `objective_rule(id)` daje zwykły cel dla starych fixture schema1.
Map schema2 wymaga3 uporządkowanych reguł,1..3 socketów. Cele zawsze0→1→2.
`ObjectiveSystem.active_pair(state,map,id)` wybiera parę po masce;
`fields_satisfied` rozpatruje oba przyporządkowania i NORMAL, radius44;
`message` jest wspólne dla HUD lokalnego i LAN. `step` stosuje zwykły przewód
i latch150 z podłogą zaniku. WorldState.reset zeruje latched_mask.
GameSnapshot.SCALARS/capture/copy i PacketCodec przenoszą maskę:u8, offset37,
SnapshotBody108 B, protokół2. Walidacja mapy sprawdza semantykę zatrzasku.
`CollisionWorld.first_block(a,b,padding)->Vector2` zwraca kontakt lub INF;
LinkResult zawiera blocked_point/blocked_segment dla prezentacji, bez nowego wire pola.
Fixture RLE schema2 ma9 pól, dodane dash0/dash1 po anchor0/anchor1. Starsze5/7
pól nadal czytelne. Generator uruchamia prawdziwą Simulation i zapisuje tylko sukcesy.
