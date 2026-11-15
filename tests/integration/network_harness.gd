extends Node
const Session = preload("res://app/match_session.gd")
var session: Session = Session.new()
var role: String = ""
var content: Dictionary = {}
var solution_hints: Dictionary = {}
var solution_driver: RefCounted
var test_difficulty: int = 1
var test_seed: int = 0
var initial_level: StringName = &"dock"
var level_results: Dictionary = {}
var latch_history: Dictionary = {}
var fixture_key: String = ""
var fixture_run: Dictionary = {}
var port: int = 7777
var report_path: String = ""
var scenario: String = "session"
var started: int = 0
var planner_stage: int = 0
var planner_objective: int = -1
var terminal_seen: int = 0
var last_progress: int = 0
var voted_sector: String = ""
var loaded_generations: Array[int] = []
var report: Dictionary = {"ok":false,"begins":0,"application_sizes":[]}
func _ready() -> void:
	get_tree().multiplayer_poll = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--role="): role = argument.trim_prefix("--role=")
		elif argument.begins_with("--port="): port = int(argument.trim_prefix("--port="))
		elif argument.begins_with("--scenario="): scenario = argument.trim_prefix("--scenario=")
		elif argument.begins_with("--difficulty="): test_difficulty = int(argument.trim_prefix("--difficulty="))
		elif argument.begins_with("--level="): initial_level=StringName(argument.trim_prefix("--level="))
		elif argument.begins_with("--seed="): test_seed = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--report="): report_path = argument.trim_prefix("--report=")
	if scenario == "boot":
		set_physics_process(false)
		var app: Node = load("res://scenes/app.tscn").instantiate(); add_child(app)
		await get_tree().process_frame
		var boot_ok: bool = app.assets.dock != null and app.assets.get_texture(&"title") != null and app.assets.fonts.has("bold") and app.lan_ui != null and app.state.current == app.State.Screen.MENU
		report["ok"] = boot_ok; report["boot_ready"] = boot_ok
		report["progress"]=app.progress_store.data.duplicate(true); report["progress_warning"]=app.progress_store.warning
		app.queue_free(); await get_tree().process_frame
		_finish(0 if boot_ok else 1); return
	var build: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://build_manifest.json"))
	content = preload("res://tools/validate_content.gd").load_content()
	if not content.ok: report["error"] = content.message; _finish(1); return
	solution_hints = JSON.parse_string(FileAccess.get_file_as_string("res://tools/map_solution_hints.json"))
	session.configure(build)
	session.progress.path="user://harness_%s_%d_progress.json" % [role,port]
	var initial_index: int=LevelCatalog.current().index_of(initial_level)
	if initial_index>0:session.progress.data.completed=[String(LevelCatalog.current().ids()[initial_index-1])]
	session.transport.bind_ip = "127.0.0.1"; session.discovery.bind_ip = "127.0.0.1"; session.discovery.discovery_port = port+1
	session.phase_changed.connect(func(value: String) -> void: print("PHASE ",role," ",value))
	session.failed.connect(func(code: int,message: String) -> void:
		if not report.ok:
			report["error"] = message; report["code"] = code
			print("HARNESS ERROR ",role," ",code," ",message)
			_finish.call_deferred(1))
	session.load_requested.connect(func(_sector: int,_map: StringName,generation: int) -> void: loaded_generations.append(generation))
	session.countdown_started.connect(func(snapshot: GameSnapshot) -> void: report["begins"] += 1; report["begin_tick"] = snapshot.tick)
	var result: GameTypes.Result = session.host({"port":port,"name":"Host","room":"Harness","difficulty":test_difficulty if scenario=="expedition" else 0,"seed":test_seed,"level_id":String(initial_level)}) if role=="host" else session.join("127.0.0.1",port,"Client")
	if not result.ok: report["error"] = result.message; _finish(1); return
	started = Time.get_ticks_msec()
func _physics_process(_delta: float) -> void:
	session.poll()
	var commands: Array[InputCommand] = []
	if scenario == "expedition" and session.state == "PLAYING":
		for target: int in session.next_input_ticks(): commands.append(_plan(target))
	session.fixed_update(commands)
	if scenario == "expedition":
		if session.snapshot!=null: latch_history[str(session.snapshot.sector_index)] = int(latch_history.get(str(session.snapshot.sector_index),0))|session.snapshot.latched_mask
		if session.snapshot != null and Time.get_ticks_msec()-last_progress>10000:
			last_progress = Time.get_ticks_msec()
			print("EXPEDITION ",role," ",session.state," sector=",session.sector_index," tick=",session.snapshot.tick," objective=",session.snapshot.objective_index," charge=",session.snapshot.charges," players=",session.snapshot.players[0].position,"/",session.snapshot.players[1].position," target=",session.last_target_tick," lead=",session.network_clock.lead)
		if session.state=="RESULTS" and session.snapshot.phase==GameTypes.MatchPhase.WON and session.result_confirmed:
			var level: StringName=session.snapshot.level_id
			level_results[String(level)]={"score":session.snapshot.score,"ticks":session.snapshot.sector_tick,"integrity":session.snapshot.integrity,"saved":session.progress.completed(level)}
			if LevelCatalog.current().next_id(level)!=&"" and initial_level==&"dock":
				var key: String=str(session.match_id)
				if key!=voted_sector:voted_sector=key;session.vote(0,true)
			elif terminal_seen==0: _record_terminal()
		elif session.state=="RESULTS" and session.snapshot.phase==GameTypes.MatchPhase.FAILED and terminal_seen==0: _record_terminal()
		if terminal_seen>0 and Time.get_ticks_msec()-terminal_seen>(2000 if role=="host" else 1500): _finish(0 if report.ok else 1); return
	if session.state == "LOBBY" and session.approved:
		var slot: int = 0 if role=="host" else 1
		if (session.lobby.ready_mask & (1 << slot)) == 0: session.set_ready(true)
		if role=="host" and session.lobby.can_start(): session.request_start()
	while not loaded_generations.is_empty(): session.loaded(loaded_generations.pop_front())
	if session.state == "PLAYING" and scenario != "expedition":
		report["ok"] = true; report["session_id"] = session.session_id; report["match_id"] = session.match_id
		report["engine"] = session.manifest.engine_build_id; report["content_hash"] = session.manifest.content_sha256
		report["application_sizes"] = session.transport.application_sizes.duplicate()
		# Both peers finish only after observing the final snapshot; do not close the host early.
		if role == "client" or Time.get_ticks_msec()-started>5500: _finish(0)
	if scenario != "expedition" and report.ok and role=="host" and Time.get_ticks_msec()-started>5500: _finish(0)
	if Time.get_ticks_msec()-started>(1600000 if scenario=="expedition" else 20000): _finish(1)
func _record_terminal() -> void:
	terminal_seen=Time.get_ticks_msec();report["phase"]=session.snapshot.phase;report["ok"]=session.result_confirmed and session.snapshot.phase==GameTypes.MatchPhase.WON
	report["levels"]=level_results.duplicate(true);report["latches_by_sector"]=latch_history.duplicate();report["score"]=session.snapshot.score;report["integrity"]=session.snapshot.integrity
	report["tick"]=session.snapshot.tick;report["sector"]=session.snapshot.sector_index;report["session_id"]=session.session_id;report["match_id"]=session.match_id
	report["client_has_simulation"]=role=="client" and session.simulation!=null;report["content_hash"]=session.manifest.content_sha256
	report["application_sizes"]=session.transport.application_sizes.duplicate()

func _finish(code: int) -> void:
	set_physics_process(false)
	if report_path != "":
		var file: FileAccess = FileAccess.open(report_path,FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report,"\t")); file.close()
	print(JSON.stringify(report)); session.leave(8,false); get_tree().quit(code)

func _plan(target: int) -> InputCommand:
	var s: GameSnapshot = session.snapshot
	var id: StringName = preload("res://tools/validate_content.gd").map_ids()[s.sector_index]
	var variant: int = posmod(session.lobby.seed+17*s.sector_index,3)
	var key: String = "%s/%d/%d" % [id,variant,session.lobby.difficulty]
	if key != fixture_key:
		fixture_key = key
		solution_driver = preload("res://tools/solution_driver.gd").new(); solution_driver.configure(content.maps[id],solution_hints[String(id)],session.lobby.difficulty,variant)
	var commands: Array[InputCommand] = solution_driver.commands(s,target)
	return commands[0 if role=="host" else 1]
