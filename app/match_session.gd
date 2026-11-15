class_name MatchSession
extends RefCounted
const P = preload("res://net/protocol.gd")
const Codec = preload("res://net/packet_codec.gd")
const Guard = preload("res://net/message_guard.gd")
const Transport = preload("res://net/net_transport.gd")
const Replication = preload("res://net/host_replication.gd")
const Lobby = preload("res://net/lobby_state.gd")
const Discovery = preload("res://net/lan_discovery.gd")
signal events_ready(events: Array[GameEvent])
signal lobby_changed()
signal phase_changed(phase: String)
signal failed(code: int,message: String)
signal load_requested(sector: int,map_id: StringName,generation: int)
signal countdown_started(snapshot: GameSnapshot)
signal level_completed(level_id: StringName,difficulty: int,score: int,time_ticks: int)
var progress: ProgressStore = ProgressStore.new()
var result_confirmed: bool = false
var confirmed_match: int = 0
var replication: Replication = Replication.new()
var network_clock: NetworkClock = NetworkClock.new()
var prediction: ClientPrediction = ClientPrediction.new()
var snapshot_buffer: SnapshotBuffer = SnapshotBuffer.new()
var previous_snapshot: GameSnapshot
var frozen_frame: GameTypes.RenderFrame
var snapshots_frozen: bool = false
var receive_map: MapDefinition
var receive_config: GameConfig
var ignored_packets: int = 0
var vote_mask: int = 0
var votes_by_kind: Dictionary = {0:0,1:0,2:0}
var next_seed: int = 0
var client_history: Array[InputCommand] = []
var last_target_tick: int = 0
var last_event_id: int = 0
var last_snapshot_ms: int = 0
var _input_send_counter: int = 0
var _next_sector: bool = false
var role: String = ""
var state: String = "IDLE"
var transport: Transport = Transport.new()
var discovery: Discovery = Discovery.new()
var lobby: Lobby = Lobby.new()
var guard: Guard = Guard.new()
var manifest: Dictionary = {}
var session_id: int = 0
var match_id: int = 0
var previous_match_id: int = 0
var sector_index: int = 0
var connected_peer: int = 0
var approved: bool = false
var local_name: String = "Gracz"
var sequences: Dictionary = {}
var generation: int = 0
var local_loaded: bool = false
var remote_loaded: bool = false
var deadline: int = 0
var last_received: int = 0
var last_ping: int = 0
var outstanding: Dictionary = {}
var rejection_deadline: int = 0
var weak_connection: bool = false
var simulation: Simulation
var snapshot: GameSnapshot
var discovery_warning: String = ""
var _load_message: Dictionary = {}
var _load_aborting: bool = false
var _last_poll: int = 0
var _countdown_accumulator: float = 0.0

func configure(build: Dictionary,save: ProgressStore = null) -> void:
	if save != null: progress = save
	manifest = build.duplicate(true) if preload("res://tools/build_manifest.gd").valid(build) else {}
func _wire() -> void:
	transport.connected.connect(_connected)
	transport.disconnected.connect(_disconnected)
	transport.packet.connect(_packet)
	transport.failed.connect(_transport_failed)
func _result(ok: bool,code: int = 0) -> GameTypes.Result:
	return GameTypes.Result.new(ok,code,"" if ok else P.text(code))
func host(options: Dictionary) -> GameTypes.Result:
	leave(8,false)
	if manifest.is_empty(): return _result(false,1)
	local_name = options.get("name","Host")
	lobby = Lobby.new(); lobby.names[0] = local_name; lobby.room = options.get("room","LUMEN LINK")
	var selected: StringName = StringName(options.get("level_id",StringName(progress.data.last_selected.level_id)))
	if not progress.unlocked(selected): return _result(false,10)
	lobby.set_options(options.get("difficulty",0),options.get("seed",0),selected)
	progress.select_level(lobby.level_id,lobby.difficulty)
	if local_name.is_empty() or lobby.room.is_empty() or not Codec.new().encode(4,{},lobby.payload()).ok: return _result(false,4)
	var error: Error = transport.start_host(options.get("port",7777))
	if error != OK: return _result(false,9)
	role = "host"; session_id = _identifier(); _wire(); _set_state("LOBBY")
	var advertised: GameTypes.Result = discovery.start_host({"room":lobby.room,"port":options.get("port",7777),"engine":manifest.engine_version,"occupied":false})
	discovery_warning = "" if advertised.ok else advertised.message
	return _result(true)
func join(ip: String,port: int,name: String) -> GameTypes.Result:
	leave(8,false)
	if manifest.is_empty(): return _result(false,1)
	if not P.ipv4(ip): return GameTypes.Result.new(false,4,"Wpisz dosłowny adres IPv4.")
	local_name = name
	if name.is_empty() or not Codec.new().encode(1,{},_hello()).ok: return _result(false,4)
	var error: Error = transport.start_client(ip,port)
	if error != OK: return _result(false,5)
	role = "client"; _wire(); deadline = Time.get_ticks_msec()+8000
	_set_state("CONNECTING"); return _result(true)
func _identifier() -> int:
	var id: int = 0
	while id == 0: id = randi() & 0xffffffff
	return id
func _hello() -> Dictionary:
	return {"engine":manifest.get("engine_version",""),"engine_build":manifest.get("engine_build_id",""),"content_hash":String(manifest.get("content_sha256","")).hex_decode(),"name":local_name}
func _set_state(value: String) -> void:
	state = value; phase_changed.emit(state)
func _connected(id: int) -> void:
	connected_peer = id; last_received = Time.get_ticks_msec()
	if role == "host":
		deadline = last_received+8000
		discovery.room["occupied"] = true
		_set_state("HANDSHAKE")
	else: _send(1,_hello())
func _transport_failed(code: int) -> void:
	_fail(code)
func _disconnected(_id: int) -> void:
	if state not in ["IDLE","REJECTING"]: _fail(8)
func _send(type: int,payload: Dictionary) -> bool:
	if connected_peer == 0: return false
	var sequence: int = sequences.get(type,0); sequences[type] = (sequence+1)&0xffffffff
	var sid: int = 0 if type == 1 else session_id
	var mid: int = 0 if type in [1,2,3,4,5] else match_id
	var packet: GameTypes.Result = Codec.new().encode(type,{"session_id":sid,"match_id":mid,"sequence":sequence},payload)
	if not packet.ok: _fail(4); return false
	var error: Error = transport.send(connected_peer,packet.value,P.mode(type),P.channel(type))
	if error != OK: _fail(8); return false
	return true
func _reject(code: int) -> void:
	_send(3,{"code":code}); rejection_deadline = Time.get_ticks_msec()+200; _set_state("REJECTING")
func _packet(id: int,bytes: PackedByteArray) -> void:
	if id != connected_peer or state == "REJECTING": return
	var now: int = Time.get_ticks_msec()
	if role == "host" and state == "HANDSHAKE" and bytes.size()>=22 and bytes.slice(0,4)==PackedByteArray([76,77,76,75]) and bytes.decode_u16(4)!=P.VERSION:
		_reject(1); return
	var decoded: GameTypes.Result = Codec.new().decode(bytes)
	if not decoded.ok:
		if guard.record_invalid(id,now): _fail(4)
		return
	var msg: Codec.DecodedMessage = decoded.value
	if state == "LOADING" and msg.type in [9,10,11,17]: return
	# Ignore stale load acknowledgements; they cannot mutate a newer load generation.
	if msg.type == 7 and (msg.match_id != match_id or msg.payload.sector != sector_index): return
	var accepted: GameTypes.Result = guard.accept(id,msg,{"is_host":role=="host","state":state,"session_id":session_id,"match_id":match_id,"sector":sector_index,"approved":approved,"packet_size":bytes.size()},now)
	if not accepted.ok:
		ignored_packets += 1
		if accepted.value is Dictionary and accepted.value.get("disconnect",false): _fail(accepted.code)
		return
	if role=="client" and msg.type in [8,10,17]:
		if receive_map==null or not msg.payload.snapshot.validate(receive_map,receive_config).ok:
			if guard.record_invalid(id,now): _fail(4)
			return
	if msg.type == 13 and not outstanding.has(msg.payload.echo_us): return
	last_received = now; weak_connection = false
	var data: Dictionary = msg.payload
	match msg.type:
		1:
			if data.name.is_empty(): _reject(4); return
			if data.engine != manifest.engine_version or data.engine_build != manifest.engine_build_id: _reject(1); return
			if data.content_hash.hex_encode() != manifest.content_sha256: _reject(2); return
			approved = true; lobby.names[1] = data.name; deadline = 0
			_send(2,{"slot":1,"host_name":local_name}); _set_state("LOBBY"); _publish_lobby()
		2:
			if msg.session_id == 0: _fail(4); return
			session_id = msg.session_id; approved = true; deadline = 0; lobby.names[0] = data.host_name; _set_state("LOBBY")
		3: _fail(data.code)
		4:
			if state in ["RESULTS","INTERMISSION"]:
				match_id = 0; snapshot = null; generation += 1; client_history.clear(); _set_state("LOBBY")
			if data.revision == lobby.revision or P.newer(data.revision,lobby.revision): lobby.apply(data); progress.select_level(lobby.level_id,lobby.difficulty,true); lobby_changed.emit()
		5:
			if data.revision == lobby.revision: lobby.set_ready(1,data.ready == 1)
			_publish_lobby()
		6:
			if state not in ["LOBBY","LOADING","INTERMISSION","RESULTS"] or msg.match_id == 0 or LevelCatalog.current().index_of(StringName(data.level_id)) != data.sector: _fail(10); return
			if data.content_hash.hex_encode() != manifest.content_sha256: _fail(2); return
			if data.variant != posmod(data.seed+17*data.sector,3): _fail(4); return
			if msg.match_id == confirmed_match: return
			match_id = msg.match_id; sector_index = data.sector; _load_message = data.duplicate(true)
			lobby.seed = data.seed; lobby.difficulty = data.difficulty; lobby.level_id = StringName(data.level_id)
			_begin_load()
		7:
			if data.content_hash.hex_encode() != manifest.content_sha256: _fail(2); return
			remote_loaded = true; _try_begin()
		8:
			if not local_loaded or data.snapshot.sector_index != sector_index: return
			snapshot = data.snapshot.copy(); deadline = 0; vote_mask = 0
			client_history.clear(); last_target_tick = snapshot.tick; last_event_id = snapshot.last_event_id; last_snapshot_ms = now
			_prepare_client_view()
			_set_state("COUNTDOWN"); countdown_started.emit(snapshot.copy())
		9:
			# Legitimate in-flight inputs may arrive after the final host tick.
			# Guard still validates identity, sector, sequence and rate; terminal state is immutable.
			if state not in ["COUNTDOWN","PLAYING"]: return
			var queued: GameTypes.Result = replication.enqueue(1,data.commands,simulation.world.tick)
			if not queued.ok and guard.record_invalid(id,now): _fail(4)
		10:
			if state not in ["COUNTDOWN","PLAYING","INTERMISSION","RESULTS"]: return
			if snapshot == null or P.newer(data.snapshot.tick,snapshot.tick):
				snapshot = data.snapshot.copy(); last_snapshot_ms = now
				_receive_snapshot()
				_apply_snapshot_phase()
		11:
			var accepted_events: Array[GameEvent] = []
			for event: GameEvent in data.events:
				if event.id>last_event_id:
					last_event_id = event.id; accepted_events.append(event.copy())
			if not accepted_events.is_empty(): events_ready.emit(accepted_events)
		14: _resolve_vote(1,data.kind,data.value == 1)
		17:
			if state not in ["COUNTDOWN","PLAYING","INTERMISSION","RESULTS"]: return
			if snapshot == null or data.snapshot.tick == snapshot.tick or P.newer(data.snapshot.tick,snapshot.tick):
				snapshot = data.snapshot.copy(); last_snapshot_ms = now; vote_mask = data.vote_mask; next_seed = data.next_seed
				_receive_snapshot()
				_apply_snapshot_phase(); _confirm_result(); phase_changed.emit(state)
		12: _send(13,{"echo_us":data.echo_us,"host_tick":snapshot.tick if snapshot != null else 0})
		13:
			if not outstanding.has(data.echo_us): return
			if role == "client" and snapshot != null: network_clock.on_pong(data.echo_us,Time.get_ticks_usec(),data.host_tick)
			outstanding.erase(data.echo_us)
		15:
			if data.reason == 6 and state == "LOADING" and role == "host": _load_failed()
			else: _fail(8)
		16:
			if data.fatal == 1: _fail(data.code)
			else:
				generation += 1; match_id = 0; local_loaded = false; remote_loaded = false; deadline = 0; _load_aborting = false
				lobby.ready_mask = 0; _set_state("LOBBY"); failed.emit(data.code,P.text(data.code))
func _publish_lobby() -> void:
	if approved: _send(4,lobby.payload())
	lobby_changed.emit()
func set_ready(value: bool) -> void:
	if state != "LOBBY" or not approved: return
	if role == "host": lobby.set_ready(0,value); _publish_lobby()
	else: _send(5,{"revision":lobby.revision,"ready":int(value)})
func set_options(difficulty: int,seed: int,level_id: StringName = lobby.level_id) -> void:
	if role != "host" or state != "LOBBY": return
	if not progress.unlocked(level_id): return
	lobby.set_options(difficulty,seed,level_id); progress.select_level(level_id,difficulty); _publish_lobby()
func request_start() -> GameTypes.Result:
	if role != "host" or state != "LOBBY" or not approved or not lobby.can_start(): return _result(false,10)
	var old: int = previous_match_id
	match_id = _identifier()
	while match_id == old: match_id = _identifier()
	previous_match_id = match_id
	if not progress.unlocked(lobby.level_id): return _result(false,10)
	sector_index = LevelCatalog.current().index_of(lobby.level_id); _next_sector = false; vote_mask = 0; next_seed = lobby.seed
	_load_message = {"sector":sector_index,"level_id":String(lobby.level_id),"variant":posmod(lobby.seed+17*sector_index,3),"difficulty":lobby.difficulty,"seed":lobby.seed,"content_hash":String(manifest.content_sha256).hex_decode()}
	_send(6,_load_message); _begin_load(); return _result(true)
func _begin_load() -> void:
	var received_content: Dictionary = preload("res://tools/validate_content.gd").load_content()
	if not received_content.ok: _fail(6); return
	receive_map = received_content.maps[preload("res://tools/validate_content.gd").map_ids()[sector_index]]; receive_config = received_content.config
	result_confirmed = false
	generation += 1; votes_by_kind = {0:0,1:0,2:0}; local_loaded = false; remote_loaded = false; _load_aborting = false; deadline = Time.get_ticks_msec()+15000
	_set_state("LOADING"); load_requested.emit(sector_index,lobby.level_id,generation)
func loaded(load_generation: int) -> void:
	if state != "LOADING" or load_generation != generation or _load_aborting: return
	local_loaded = true
	if role == "client": _send(7,{"sector":sector_index,"content_hash":String(manifest.content_sha256).hex_decode()})
	else: _try_begin()
func _try_begin() -> void:
	if not local_loaded or not remote_loaded or state != "LOADING": return
	var content: Dictionary = preload("res://tools/validate_content.gd").load_content()
	if not content.ok: _load_failed(); return
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	simulation = Simulation.new(); simulation.initialize(config,content.maps[lobby.level_id],lobby.seed+17*sector_index,lobby.difficulty)
	simulation.start_countdown(); replication.reset(); vote_mask = 0
	snapshot = simulation.snapshot(); previous_snapshot = null; deadline = 0; last_event_id = snapshot.last_event_id
	_last_poll = Time.get_ticks_msec(); _countdown_accumulator = 0
	_send(8,{"snapshot":snapshot}); _set_state("COUNTDOWN"); countdown_started.emit(snapshot.copy())
func _load_failed() -> void:
	if role == "host": _send(16,{"code":6,"fatal":0})
	else:
		if _load_aborting: _fail(6); return
		_send(15,{"reason":6}); _load_aborting = true; generation += 1
		deadline = Time.get_ticks_msec()+3000
		return
	generation += 1; match_id = 0; local_loaded = false; remote_loaded = false; deadline = 0; lobby.ready_mask = 0
	_set_state("LOBBY"); _publish_lobby(); failed.emit(6,P.text(6))
func cancel() -> void:
	if state == "LOADING": _load_failed()
	else: leave()
func poll(now: int = -1) -> void:
	if now < 0: now = Time.get_ticks_msec()
	transport.poll()
	if state == "IDLE": return
	discovery.poll(now)
	if state == "REJECTING":
		if now>=rejection_deadline: _fail(1)
		return
	if deadline>0 and now>=deadline:
		if state == "LOADING": _load_failed()
		else: _fail(5)
		return
	if approved:
		weak_connection = now-last_received>1000
		if now-last_received>3000:
			leave(8,false); failed.emit(8,"Połączenie zostało przerwane."); return
		if now-last_ping>=500:
			var echo: int = Time.get_ticks_usec(); outstanding[echo] = now; last_ping = now
			_send(12,{"echo_us":echo})
		for echo: Variant in outstanding.keys():
			if now-int(outstanding[echo])>3000: outstanding.erase(echo)
func _fail(code: int) -> void:
	leave(code,false); failed.emit(code,P.text(code))
func leave(reason: int = 8,notify: bool = true) -> void:
	if notify and approved and connected_peer != 0:
		_send(15,{"reason":reason})
	generation += 1; approved = false; connected_peer = 0; deadline = 0; session_id = 0; match_id = 0
	transport.close(); discovery.stop(); guard.reset(); sequences.clear(); outstanding.clear()
	for signal_name: String in ["connected","disconnected","packet","failed"]:
		for connection: Dictionary in transport.get_signal_connection_list(signal_name): transport.disconnect(signal_name,connection.callable)
	receive_map = null; receive_config = null
	prediction.reset(); snapshot_buffer.reset(); network_clock = NetworkClock.new(); previous_snapshot = null; frozen_frame = null; snapshots_frozen = false
	simulation = null; snapshot = null; lobby = Lobby.new(); role = ""; weak_connection = false
	replication.reset(); client_history.clear(); last_target_tick = 0; last_event_id = 0; vote_mask = 0; _input_send_counter = 0
	_set_state("IDLE")

func _apply_snapshot_phase() -> void:
	var phase: String = {0:"COUNTDOWN",1:"PLAYING",2:"INTERMISSION",3:"RESULTS",4:"RESULTS"}.get(snapshot.phase,"")
	if phase != "" and phase != state: _set_state(phase)

func _prepare_client_view() -> void:
	var content: Dictionary = preload("res://tools/validate_content.gd").load_content()
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	prediction.reset(); prediction.configure(config,content.maps[preload("res://tools/validate_content.gd").map_ids()[sector_index]])
	snapshot_buffer.reset(); snapshot_buffer.collision.configure(content.maps[preload("res://tools/validate_content.gd").map_ids()[sector_index]])
	network_clock.reset(snapshot.tick); frozen_frame = null; snapshots_frozen = false
	_receive_snapshot()

func _receive_snapshot() -> void:
	network_clock.observe(snapshot.tick); snapshot_buffer.insert(snapshot)
	if network_clock.resync_required: prediction.reset(); network_clock.resync_required = false
	if snapshot.phase != GameTypes.MatchPhase.PLAYING: prediction.pending.clear()
	prediction.reconcile(snapshot,1)
	snapshots_frozen = false
	if snapshot.phase == GameTypes.MatchPhase.PLAYING and state == "COUNTDOWN":
		network_clock.last_command_tick = maxi(network_clock.last_command_tick,snapshot.tick)

func next_input_ticks(limit: int = 3) -> Array[int]:
	var result: Array[int] = []
	if snapshot == null or state != "PLAYING": return result
	if role == "host": result.append(simulation.world.tick+1); return result
	if Time.get_ticks_msec()-last_snapshot_ms>250: return result
	return network_clock.next_command_ticks(limit,snapshot.tick+12)

func next_input_tick() -> int:
	var ticks: Array[int] = next_input_ticks(1)
	return ticks[0] if not ticks.is_empty() else -1

func fixed_update(local_commands: Array[InputCommand]) -> void:
	if state not in ["COUNTDOWN","PLAYING"] or not approved: return
	if role == "client":
		network_clock.advance(1.0/60.0)
		for command: InputCommand in local_commands:
			if command.tick<=last_target_tick or command.tick>int(ceil(network_clock.estimated_tick))+12: continue
			last_target_tick = command.tick; client_history.append(command.copy()); prediction.push(command)
			while client_history.size()>6: client_history.pop_front()
		_input_send_counter += 1
		if _input_send_counter%2 == 0 and not client_history.is_empty(): _send(9,{"sector":sector_index,"commands":client_history})
		return
	for command: InputCommand in local_commands:
		var queued: GameTypes.Result = replication.enqueue(0,[command],simulation.world.tick)
		if not queued.ok: failed.emit(4,queued.message); return
	previous_snapshot = snapshot.copy()
	var old_phase: int = simulation.world.phase
	var events: Array[GameEvent] = simulation.step(replication.commands_for(simulation.world.tick+1))
	snapshot = replication.capture(simulation)
	for event: GameEvent in events: replication.pending_events.append(event.copy())
	if replication.pending_events.size()>256: _fail(7); return
	if not events.is_empty(): events_ready.emit(events)
	var outgoing: Array[GameEvent] = replication.drain_events(8)
	if not outgoing.is_empty(): _send(11,{"events":outgoing})
	if snapshot.tick%2 == 0: _send(10,{"snapshot":snapshot})
	_apply_snapshot_phase()
	if old_phase != snapshot.phase:
		_confirm_result(); _publish_state()

func render_frame(alpha: float = 1.0,delta: float = 0.0) -> GameTypes.RenderFrame:
	var frame: GameTypes.RenderFrame = GameTypes.RenderFrame.new()
	if snapshot == null: return frame
	snapshots_frozen = role == "client" and Time.get_ticks_msec()-last_snapshot_ms>250
	if snapshots_frozen and frozen_frame != null: return frozen_frame
	for slot: int in range(2):
		var player: WorldState.PlayerState = snapshot.players[slot].copy()
		if role == "client" and prediction.player != null:
			player = prediction.present(delta) if slot == 1 else snapshot_buffer.sample(network_clock.estimated_tick-6,slot)
		elif previous_snapshot != null and previous_snapshot.sector_index == snapshot.sector_index:
			player.position = previous_snapshot.players[slot].position.lerp(player.position,clampf(alpha,0,1))
		frame.players.append(player)
	for field: String in ["integrity","complete_mask","objective_index","active_socket","link_status","phase","remaining_ticks","score"]: frame.set(field,snapshot.get(field))
	frame.charges = snapshot.charges.duplicate()
	frame.tick_float = prediction.predicted_tick if role == "client" and prediction.player != null else snapshot.tick
	frozen_frame = frame
	return frame

func _publish_state() -> void:
	_send(17,{"snapshot":snapshot,"vote_mask":vote_mask,"next_seed":next_seed})
	phase_changed.emit(state)

func _confirm_result() -> void:
	if snapshot == null or snapshot.phase != GameTypes.MatchPhase.WON or confirmed_match == match_id: return
	if receive_map == null or not snapshot.validate(receive_map,receive_config).ok: return
	confirmed_match = match_id; result_confirmed = true
	# Called on host transition or accepted RELIABLE SessionState only, never Snapshot.
	progress.accept_completion(snapshot.level_id,lobby.difficulty,snapshot.score,maxi(1,snapshot.sector_tick))
	level_completed.emit(snapshot.level_id,lobby.difficulty,snapshot.score,maxi(1,snapshot.sector_tick))

func vote(kind: int,value: bool) -> void:
	if snapshot != null and snapshot.phase == GameTypes.MatchPhase.WON and not result_confirmed: return
	if role == "host": _resolve_vote(0,kind,value)
	else: _send(14,{"kind":kind,"value":int(value)})
func _resolve_vote(slot: int,kind: int,value: bool) -> void:
	if state != "RESULTS": return
	if kind == 0 and (not result_confirmed or LevelCatalog.current().next_id(lobby.level_id) == &""): return
	# LOBBY is a shared return; NEXT and REMATCH have separate legal phases.
	if kind not in [0,1,2]: return
	if value:
		for key: int in votes_by_kind: votes_by_kind[key] &= ~(1 << slot)
		votes_by_kind[kind] |= 1 << slot
	else: votes_by_kind[kind] &= ~(1 << slot)
	vote_mask = votes_by_kind[kind]
	_publish_state()
	if vote_mask != 3: return
	if kind == P.VoteKind.LOBBY:
		# A final reliable state acknowledges the return before match_id is reset.
		match_id = 0; lobby.ready_mask = 0; simulation = null; snapshot = null; replication.reset()
		_set_state("LOBBY"); _publish_lobby(); return
	if kind == P.VoteKind.REMATCH:
		lobby.seed = next_seed; lobby.ready_mask = 3
		state = "LOBBY"; request_start(); return
	lobby.level_id = LevelCatalog.current().next_id(lobby.level_id)
	lobby.ready_mask = 3; state = "LOBBY"; request_start()

func set_next_seed(value: int) -> void:
	if role != "host" or state != "RESULTS" or value<0 or value>0xffffffff: return
	next_seed = value; votes_by_kind[1] = 0; vote_mask = 0; _publish_state()
