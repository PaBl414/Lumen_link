extends Node
var session: MatchSession = MatchSession.new()
var role: String = "host"
var port: int = 28991
var report_path: String
var scenario: String = "loss"
var started: int
var playing_since: int = 0
var connected: bool = false
var ready_sent: bool = false
var frozen_count: int = 0
var recovered: bool = false
var dashes: int = 0
var event_ids: Dictionary = {}
var duplicate_events: int = 0
var max_prediction_error: float = 0
var last_error: int = 0
var last_report: int = 0
var last_valid_snapshot: GameSnapshot
func _ready() -> void:
	get_tree().multiplayer_poll = false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="): role = arg.trim_prefix("--role=")
		elif arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--scenario="): scenario = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--report="): report_path = arg.trim_prefix("--report=")
	session.configure(JSON.parse_string(FileAccess.get_file_as_string("res://build_manifest.json")))
	session.transport.bind_ip = "127.0.0.1"; session.discovery.bind_ip = "127.0.0.1"; session.discovery.discovery_port = port+100
	session.load_requested.connect(func(_sector: int,_map: StringName,generation: int) -> void: session.loaded(generation))
	session.failed.connect(func(code: int,message: String) -> void: last_error = code; print("FAIL ",role," ",message))
	session.phase_changed.connect(func(phase: String) -> void: print(role," ",phase," ready=",session.lobby.ready_mask," rev=",session.lobby.revision))
	session.events_ready.connect(func(events: Array[GameEvent]) -> void:
		for event: GameEvent in events:
			if event_ids.has(event.id): duplicate_events += 1
			event_ids[event.id] = true
			if event.type == GameEvent.EventType.DASH and event.player_id == 1: dashes += 1)
	var result: GameTypes.Result = session.host({"port":port,"name":"Host","difficulty":1}) if role=="host" else session.join("127.0.0.1",port,"Guest")
	started = Time.get_ticks_msec()
	if not result.ok: last_error = result.code; _finish(1)
func _physics_process(_delta: float) -> void:
	session.poll()
	if session.approved: connected = true
	if session.state == "LOBBY" and session.approved:
		var slot: int = 0 if role=="host" else 1
		if not ready_sent and session.lobby.names[1] != "":
			ready_sent = true; session.set_ready(true)
		if role=="host" and session.lobby.can_start(): session.request_start()
	var commands: Array[InputCommand] = []
	if session.state == "PLAYING":
		if playing_since==0: playing_since = Time.get_ticks_msec()
		for tick: int in session.next_input_ticks():
			var command: InputCommand = InputCommand.new(); command.tick = tick
			command.axis_x = 127 if Time.get_ticks_msec()-playing_since<1000 else 0
			command.dash_serial = 1 if role=="client" and Time.get_ticks_msec()-playing_since>500 else 0
			commands.append(command)
	session.fixed_update(commands)
	if session.snapshot != null:
		session.render_frame(1,1.0/60)
		if session.snapshots_frozen: frozen_count += 1
		elif frozen_count>0: recovered = true
	if Time.get_ticks_msec()-last_report>100:
		last_report = Time.get_ticks_msec(); _write()
	if connected and session.state=="IDLE":
		_finish(0 if scenario=="kill" or (playing_since>0 and Time.get_ticks_msec()-started>23000) else 1); return
	if scenario=="loss" and Time.get_ticks_msec()-started>(24000 if role=="client" else 26000): _finish(0 if playing_since>0 else 1)
	if Time.get_ticks_msec()-started>35000: _finish(1)
func _write() -> void:
	var data: Dictionary = {"state":session.state,"role":role,"elapsed_ms":Time.get_ticks_msec()-started,"playing":playing_since>0,"frozen_count":frozen_count,"recovered":recovered,"dashes":dashes,"duplicate_events":duplicate_events,"last_error":last_error,"ignored":session.ignored_packets,"content_hash":session.manifest.content_sha256}
	if session.snapshot != null: last_valid_snapshot = session.snapshot.copy()
	if last_valid_snapshot != null:
		data["tick"] = last_valid_snapshot.tick; data["position"] = [last_valid_snapshot.players[1].position.x,last_valid_snapshot.players[1].position.y]
	if session.prediction.player != null:
		data["predicted_position"] = [session.prediction.player.position.x,session.prediction.player.position.y]
		data["pending"] = session.prediction.pending.size(); data["rtt_ms"] = session.network_clock.rtt_ms; data["lead"] = session.network_clock.lead
	var file: FileAccess = FileAccess.open(report_path,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(data)); file.close()
func _finish(code: int) -> void:
	_write(); session.leave(8,false); get_tree().quit(code)
