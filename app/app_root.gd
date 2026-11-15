class_name AppRoot
extends Node
## Sole composition root; debug movement fixture is separate from the future LAN session.

const Catalog = preload("res://services/asset_catalog.gd")
const SceneRouting = preload("res://app/scene_router.gd")
const Settings = preload("res://services/settings_store.gd")
const Records = preload("res://services/records_store.gd")
const Logs = preload("res://services/log_service.gd")
var assets: Catalog = Catalog.new()
var progress_store: ProgressStore = ProgressStore.new()
var level_select: LevelSelectPresenter
var chosen_level: StringName = &"dock"
var chosen_difficulty: int = 0
var scene_router: SceneRouting = SceneRouting.new()
var settings_store: Settings = Settings.new()
var records_store: Records = Records.new()
var log_service: Logs = Logs.new()
var settings: GameTypes.SettingsData
var loading_new: bool = true
var pending_sector: int = 0
var votes: int = 0
var result_saved: bool = false
var expedition_ticks: int = 0
var service_warning: String = ""
var flow_panel: VBoxContainer
var flow_text: Label
var vote_buttons: Array[Button] = []
const Match = preload("res://app/match_session.gd")
const LANUI = preload("res://ui/ui_root.gd")
const NetworkProtocol = preload("res://net/protocol.gd")
var lan_session: Match = Match.new()
var lan_scan: RefCounted = preload("res://net/lan_discovery.gd").new()
var lan_ui: LANUI
var lan_active: bool = false
var lan_paused: bool = false
var lan_load_generation: int = 0
var lan_router_generation: int = -1
var lan_message: String = ""
var lan_join_ip: String = ""
var lan_was_weak: bool = false
var scan_started: int = 0
var manifest: Dictionary = {}
const State = preload("res://app/app_state.gd")

var state: State = State.new()
var closing: bool = false
var simulation: Simulation
var world_view: WorldView
var routers: Array[InputRouter] = []
var previous: GameSnapshot
var current: GameSnapshot
var commands: Array[InputCommand] = []
var fixture_active: bool = false
var focused: bool = true
var anchor_hint: String = ""
var anchor_hint_until: int = 0
var fixture_hint: Label

@onready var exit_button: Button = $Menu/Center/Panel/Margin/Content/ExitButton
@onready var status_label: Label = $Menu/Center/Panel/Margin/Content/Status


func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().multiplayer_poll = false
	var result: State.Result = state.transition(State.Screen.MENU)
	if not result.ok:
		status_label.text = result.message
		push_error(result.message)
		get_tree().quit(1)
		return
	exit_button.pressed.connect(shutdown)
	exit_button.grab_focus()
	status_label.text = "%d poziomów · lokalny zapis postępu · LAN offline" % LevelCatalog.current().count()
	records_store.path = "user://debug_records.json" if OS.is_debug_build() else "user://records.json"
	settings = settings_store.load_settings()
	records_store.load_records()
	progress_store.load_progress()
	chosen_level=StringName(progress_store.data.last_selected.level_id); chosen_difficulty=int(progress_store.data.last_selected.difficulty)
	service_warning = settings_store.warning + " " + records_store.warning + " " + progress_store.warning
	log_service.write(1,&"BOOT",service_warning)
	if not service_warning.strip_edges().is_empty(): status_label.text += "\nUwaga: "+service_warning
	scene_router.configure($WorldContainer,assets)
	scene_router.scene_ready.connect(_sector_ready)
	_build_flow_panel()
	var manifest_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://build_manifest.json"))
	if not preload("res://tools/build_manifest.gd").valid(manifest_data) or manifest_data.engine_build_id != Engine.get_version_info().hash or manifest_data.engine_version != "%d.%d.%d" % [Engine.get_version_info().major,Engine.get_version_info().minor,Engine.get_version_info().patch]:
		status_label.text = "Niezgodny manifest silnika. Uruchom tools/build_manifest.gd --write."; return
	manifest = manifest_data
	if FileAccess.file_exists("res://app/app_root.gd"):
		var actual_build: Dictionary = preload("res://tools/build_manifest.gd").calculate()
		if manifest.content_sha256 != actual_build.content_sha256:
			status_label.text = "Kod zmienił się od ostatniego manifestu. Uruchom tools/build_manifest.gd --write."; return
	lan_session.configure(manifest,progress_store)
	lan_session.level_completed.connect(_accepted_lan_result)
	lan_session.lobby_changed.connect(_lan_refresh)
	lan_session.phase_changed.connect(_lan_phase)
	lan_session.failed.connect(_lan_error)
	lan_session.load_requested.connect(_lan_load)
	lan_session.countdown_started.connect(_lan_begin)
	lan_session.events_ready.connect(_lan_events)
	lan_scan.results_changed.connect(_lan_rooms)
	lan_ui = LANUI.new(); add_child(lan_ui); lan_ui.intent.connect(_lan_intent)
	var lan_button: Button = Button.new(); lan_button.text = "Wybierz poziom / LAN"
	$Menu/Center/Panel/Margin/Content.add_child(lan_button); lan_button.pressed.connect(_open_level_select)
	level_select=LevelSelectPresenter.new(); $FlowLayer.add_child(level_select); level_select.visible=false; level_select.intent.connect(_level_intent)
	var boot: GameTypes.Result = assets.load_boot()
	if not boot.ok:
		lan_button.disabled = true
		status_label.text = boot.message
		return
	_apply_art_theme(lan_button)
	if OS.is_debug_build():
		var start: Button = Button.new()
		start.text = "Test lokalny wybranego poziomu (F2)"
		$Menu/Center/Panel/Margin/Content.add_child(start)
		start.pressed.connect(_start_fixture.bind(assets.dock))
	var preview: Node2D = Node2D.new()
	preview.name = "DockGeometry"
	preview.visible = false
	add_child(preview)
	preview.draw.connect(_draw_geometry.bind(preview, assets.dock))
	var toggle: Button = Button.new()
	toggle.text = "Podgląd geometrii dock (F1)"
	$Menu/Center/Panel/Margin/Content.add_child(toggle)
	toggle.pressed.connect(func() -> void: preview.visible = not preview.visible)


func _unhandled_key_input(event: InputEvent) -> void:
	if lan_active:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if lan_session.state in ["PLAYING","COUNTDOWN"]:
				lan_paused = not lan_paused; _lan_input_enabled(); _lan_refresh()
			else: _lan_intent(&"cancel",{})
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_1,KEY_2] and state.current in [State.Screen.INTERMISSION,State.Screen.RESULTS]:
			vote_continue(0 if event.keycode == KEY_1 else 1)
			return
		if event.keycode == KEY_ESCAPE and state.current == State.Screen.LOADING:
			cancel_loading()
			return
		if event.keycode == KEY_ESCAPE and simulation != null and state.current in [State.Screen.COUNTDOWN,State.Screen.PLAYING]:
			fixture_active = not fixture_active
			$Menu.visible = not fixture_active
			world_view.visible = fixture_active
			if not fixture_active: exit_button.grab_focus()
			for router: InputRouter in routers: router.set_enabled(_input_enabled())
			return
		if event.keycode == KEY_F2 and OS.is_debug_build():
			if assets.dock != null: _start_fixture(assets.dock)
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1 and has_node("DockGeometry"):
		$DockGeometry.visible = not $DockGeometry.visible


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = what == NOTIFICATION_APPLICATION_FOCUS_IN
		for router: InputRouter in routers: router.set_enabled(_input_enabled())
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown()


func shutdown() -> void:
	if closing:
		return
	closing = true
	exit_button.disabled = true
	for router: InputRouter in routers: router.set_enabled(false)
	lan_session.leave(); lan_scan.stop()
	scene_router.clear()
	if settings != null:
		var saved: GameTypes.Result = settings_store.save_settings(settings)
		if not saved.ok: log_service.write(2,&"SAVE_SETTINGS",saved.message)
	log_service.write(1,&"SHUTDOWN","Local services stopped")
	var flushed: GameTypes.Result = log_service.flush()
	if not flushed.ok: push_warning(flushed.message)
	get_tree().quit(0)


func _draw_geometry(canvas: Node2D, map: RefCounted) -> void:
	canvas.draw_rect(map.bounds, Color(0.05, 0.1, 0.16))
	for wall: Rect2 in map.walls:
		canvas.draw_rect(wall, Color(0.4, 0.5, 0.6))
	for point: Vector2 in map.beacons:
		canvas.draw_circle(point, 22, Color(0.9, 0.6, 0.3))
	for point: Vector2 in map.sockets:
		canvas.draw_circle(point, 12, Color(0.3, 0.9, 0.7))
	for point: Vector2 in map.spawns:
		canvas.draw_rect(Rect2(point - Vector2(12, 12), Vector2(24, 24)), Color(0.6, 0.9, 1))
	canvas.draw_arc(map.exit_position, 64, 0, TAU, 64, Color(0.3, 1, 0.5), 3)
	for h: RefCounted in map.hazards:
		if h.type == "PULSE": canvas.draw_arc(h.a, h.radius, 0, TAU, 48, Color(1, 0.3, 0.3), 2)
		else:
			canvas.draw_line(h.a, h.b, Color(1, 0.3, 0.3), 10)
			canvas.draw_line(h.a + h.travel, h.b + h.travel, Color(1, 0.3, 0.3, 0.4), 10)


func _start_fixture(_map: MapDefinition) -> void:
	if not OS.is_debug_build() or assets.dock == null or lan_active: return
	loading_new = true; pending_sector = LevelCatalog.current().index_of(chosen_level); result_saved = false; expedition_ticks = 0
	_begin_loading()

func _begin_loading() -> void:
	if closing: return
	state.session_active = true
	if state.current != State.Screen.LOADING:
		var changed: State.Result = state.transition(State.Screen.LOADING)
		if not changed.ok: service_warning = changed.message; return
	fixture_active = false
	for router: InputRouter in routers: router.set_enabled(false)
	world_view = null; current = null; previous = null
	$Menu.visible = false; $DockGeometry.visible = false
	flow_panel.visible = true; flow_text.text = "Ładowanie… Esc: anuluj\nKatalog poziomów: %d map" % LevelCatalog.current().count()
	for button: Button in vote_buttons: button.visible = false
	var shown: GameTypes.Result = scene_router.show(&"world",assets.map_ids()[lan_session.sector_index if lan_active else pending_sector])
	if not shown.ok: _loading_failed(shown.message)

func _sector_ready(_scene_id: StringName) -> void:
	if lan_active:
		_lan_scene_ready(); return
	if state.current != State.Screen.LOADING or closing: return
	if loading_new:
		simulation = Simulation.new()
		simulation.initialize(assets.config,assets.map_for_sector(pending_sector),0,chosen_difficulty)
	else:
		simulation.reset_sector(assets.map_for_sector(pending_sector),pending_sector)
	if simulation.world == null: _loading_failed("Invalid sector"); return
	simulation.start_countdown()
	world_view = scene_router.active as WorldView
	world_view.configure(assets.map_for_sector(pending_sector),simulation.difficulty,simulation.variant,assets)
	var loaded_generation: int = scene_router.active_generation
	await _warm_world(world_view)
	if loaded_generation!=scene_router.active_generation or state.current!=State.Screen.LOADING: return
	fixture_hint = Label.new(); fixture_hint.add_theme_font_size_override("font_size",13)
	fixture_hint.size = Vector2(1216,80); fixture_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fixture_hint.position = Vector2(32,8); world_view.get_node("HUD").add_child(fixture_hint); fixture_hint.add_theme_font_override("font",assets.fonts.ui)
	routers.clear(); commands.clear()
	for slot: int in range(2):
		var input: InputRouter = InputRouter.new(); input.configure(settings,slot)
		routers.append(input); commands.append(input.sample(simulation.world.tick+1))
	current = simulation.snapshot(); previous = current.copy()
	votes = 0; fixture_active = true; flow_panel.visible = false
	state.transition(State.Screen.COUNTDOWN)

func cancel_loading() -> void:
	$FlowLayer/Backdrop.visible = false
	if state.current != State.Screen.LOADING: return
	scene_router.clear(); simulation = null; world_view = null; current = null; previous = null
	state.transition(State.Screen.MENU); state.session_active = false
	flow_panel.visible = false; $Menu.visible = true; exit_button.grab_focus()

func _loading_failed(message: String) -> void:
	service_warning = message; log_service.write(2,&"LOAD",message)
	cancel_loading(); status_label.text = message

func _input_enabled() -> bool:
	if lan_active: return focused and not lan_paused and lan_session.state == "PLAYING"
	return fixture_active and focused and state.current == State.Screen.PLAYING

func _build_flow_panel() -> void:
	flow_panel = $FlowLayer/Panel
	flow_text = flow_panel.get_node("Text")
	for slot: int in range(2):
		var button: Button = Button.new(); button.text = "P%d: potwierdź (%d)" % [slot+1,slot+1]
		flow_panel.add_child(button); button.pressed.connect(vote_continue.bind(slot)); vote_buttons.append(button)
	var leave: Button = Button.new(); leave.text = "Wróć do menu"
	flow_panel.add_child(leave); leave.pressed.connect(_leave_expedition)
	flow_panel.visible = false

func _leave_expedition() -> void:
	if state.current == State.Screen.LOADING: cancel_loading(); return
	scene_router.clear(); simulation = null; world_view = null; current = null; previous = null
	for router: InputRouter in routers: router.set_enabled(false)
	routers.clear(); commands.clear(); fixture_active = false
	if state.current != State.Screen.MENU: state.transition(State.Screen.MENU)
	state.session_active = false; flow_panel.visible = false; $Menu.visible = true; exit_button.grab_focus()

func vote_continue(slot: int) -> void:
	if state.current not in [State.Screen.INTERMISSION,State.Screen.RESULTS] or slot not in [0,1]: return
	votes |= 1 << slot
	vote_buttons[slot].text = "P%d: gotowy" % (slot+1)
	if votes != 3: return
	if state.current == State.Screen.RESULTS:
		var next: StringName=LevelCatalog.current().next_id(chosen_level)
		if current.phase==GameTypes.MatchPhase.WON and next!=&"": chosen_level=next
		_start_fixture(assets.dock)
	else:
		pending_sector = simulation.world.sector_index+1; loading_new = false
		_begin_loading()

func _end_sector() -> void:
	expedition_ticks += current.sector_tick
	fixture_active = false
	for router: InputRouter in routers: router.set_enabled(false)
	var intermission: bool = current.phase == GameTypes.MatchPhase.INTERMISSION
	state.transition(State.Screen.INTERMISSION if intermission else State.Screen.RESULTS)
	votes = 0; flow_panel.visible = true
	for slot: int in range(2):
		vote_buttons[slot].visible = true; vote_buttons[slot].text = "P%d: potwierdź (%d)" % [slot+1,slot+1]
	vote_buttons[0].grab_focus()
	var label: String = "Sektor ukończony — obaj potwierdźcie Dalej" if intermission else ("Poziom ukończony" if current.phase == GameTypes.MatchPhase.WON else "Ekspedycja nieudana")
	flow_text.text = "%s\nKatalog poziomów \nPoziom %d/%d · integrity %d · wynik %d" % [label,current.sector_index+1,LevelCatalog.current().count(),current.integrity,current.score]
	if current.phase==GameTypes.MatchPhase.WON and not result_saved:
		result_saved=true
		progress_store.accept_completion(current.level_id,simulation.difficulty,current.score,maxi(1,current.sector_tick))
		service_warning=progress_store.warning

	if not service_warning.strip_edges().is_empty(): flow_text.text += "\nUwaga: "+service_warning

func _input(event: InputEvent) -> void:
	for router: InputRouter in routers: router.feed(event)

func _physics_process(_delta: float) -> void:
	if lan_active:
		lan_session.poll()
		var local: Array[InputCommand] = []
		for target: int in lan_session.next_input_ticks():
			if not routers.is_empty(): local.append(routers[0].sample(target))
		lan_session.fixed_update(local)
		return
	if simulation == null or state.current not in [State.Screen.COUNTDOWN,State.Screen.PLAYING]: return
	previous = current
	# Commands sampled at 30 Hz and held for two 60 Hz simulation ticks.
	if simulation.world.tick % 2 == 0:
		for slot: int in range(2):
			var command: InputCommand = routers[slot].sample(simulation.world.tick+1)
			if command.anchor_serial != commands[slot].anchor_serial and preload("res://core/link_system.gd").new().find_socket(current.players[slot].position,simulation.map) < 0:
				anchor_hint = "P%d: podejdź bliżej przekaźnika" % (slot+1); anchor_hint_until = current.tick+45
			commands[slot] = command
	# A menu/focus change must neutralize even the held half of a command pair.
	for slot: int in range(2):
		if not routers[slot].enabled: commands[slot] = routers[slot].sample(simulation.world.tick + 1)
	var events: Array[GameEvent] = simulation.step(commands)
	for event: GameEvent in events:
		world_view.play_event(event)
	current = simulation.snapshot()

	if state.current == State.Screen.COUNTDOWN and current.phase == GameTypes.MatchPhase.PLAYING:
		state.transition(State.Screen.PLAYING)
		for router: InputRouter in routers: router.set_enabled(_input_enabled())
	if current.phase in [GameTypes.MatchPhase.INTERMISSION,GameTypes.MatchPhase.WON,GameTypes.MatchPhase.FAILED]: _end_sector()

func _process(delta: float) -> void:
	if flow_panel != null: $FlowLayer/Backdrop.visible = flow_panel.visible
	if scene_router.pending:
		var loaded: GameTypes.Result = scene_router.poll()
		if not loaded.ok and loaded.code != ERR_BUSY:
			if lan_active: _lan_error(6,loaded.message); lan_session.cancel()
			else: _loading_failed(loaded.message)
	if lan_active:
		lan_scan.poll(Time.get_ticks_msec())
		_render_network(delta)
		return
	if world_view == null or current == null: return
	var frame: GameTypes.RenderFrame = GameTypes.RenderFrame.new()
	var alpha: float = Engine.get_physics_interpolation_fraction()
	for slot: int in range(2):
		var p: WorldState.PlayerState = current.players[slot].copy()
		p.position = previous.players[slot].position.lerp(p.position, alpha)
		frame.players.append(p)
	world_view.present(frame, delta)
	world_view.present_snapshot(current)
	fixture_hint.text = "Test lokalny · P1 WASD/Spacja · P2 IJKL/Shift · Esc menu\nFPS %d · tick %d · P1 %s [%d] · P2 %s [%d]" % [Engine.get_frames_per_second(), current.tick, current.players[0].position, current.players[0].mode, current.players[1].position, current.players[1].mode]
	fixture_hint.text += " · poziom %d/%d · odliczanie %d" % [current.sector_index+1,LevelCatalog.current().count(),int(ceil(current.phase_remaining/60.0))]
	fixture_hint.text += "\nPrzewód: %s · cele %d/3 · integrity %d · czas %d · wynik %d · faza %d · F2 restart" % [["Aktywny","Odsuńcie się","Za daleko","Ściana","Dron zajęty","Przesłona","Zakłócenia"][current.link_status],current.objective_index,current.integrity,int(ceil(current.remaining_ticks/60.0)),current.score,current.phase]
	if current.tick < anchor_hint_until: fixture_hint.text += "\n"+anchor_hint
	fixture_hint.text += "\n"+ObjectiveSystem.message(current,simulation.map)
	fixture_hint.text += "\nE / U: przekaźnik · Q / O: ping · " + ["Odliczanie","Gra","Sektor ukończony — F2 restart","Zwycięstwo — F2 restart","Porażka — F2 restart"][mini(current.phase,4)]

func _exit_tree() -> void:
	# Also invalidate in-flight work when a test or parent frees AppRoot.
	lan_session.leave(8,false); lan_scan.stop(); scene_router.clear()

func _open_lan() -> void:
	if assets.dock == null or not has_node("DockGeometry"): return
	lan_message = ""; scan_started = 0
	if simulation != null: _leave_expedition()
	lan_active = true; $Menu.visible = false; $DockGeometry.visible = false
	state.transition(State.Screen.JOIN_FORM)
	lan_ui.show_screen(0,{"message":"Wybierz Utwórz albo wpisz IPv4 gospodarza.\n"+progress_store.warning})
	lan_ui.menu.difficulty.select(chosen_difficulty)
	if NetworkProtocol.ipv4(settings.last_ip): lan_ui.menu.ip.text = settings.last_ip
	lan_ui.menu.player_name.grab_focus()

func _lan_intent(action: StringName,data: Dictionary) -> void:
	match action:
		&"host":
			lan_message = ""; scan_started = 0
			lan_scan.stop(); state.transition(State.Screen.HOST_FORM)
			var result: GameTypes.Result = lan_session.host(data.merged({"level_id":String(chosen_level)},true))
			if not result.ok: lan_ui.show_error(result.code,result.message)
		&"join":
			lan_message = ""; scan_started = 0
			lan_scan.stop()
			if state.current == State.Screen.HOST_FORM: state.transition(State.Screen.JOIN_FORM)
			var result: GameTypes.Result = lan_session.join(data.ip,data.port,data.name)
			if result.ok: lan_join_ip = data.ip
			if not result.ok: lan_ui.show_error(result.code,result.message)
		&"scan":
			var result: GameTypes.Result = lan_scan.start_scan(); scan_started = Time.get_ticks_msec()
			lan_ui.show_screen(0,{"message":"Skan LAN (10 s). Możesz też wpisać IP." if result.ok else result.message})
		&"select_level":
			if lan_session.role=="host" and lan_session.state=="LOBBY":
				lan_ui.visible=false; level_select.visible=true; level_select.bind(progress_store)
		&"ready":
			var slot: int = 0 if lan_session.role == "host" else 1
			lan_session.set_ready((lan_session.lobby.ready_mask & (1 << slot)) == 0)
		&"options":
			if lan_session.state == "RESULTS": lan_session.set_next_seed(data.seed)
			else: lan_session.set_options(data.difficulty,data.seed,StringName(data.get("level_id",lan_session.lobby.level_id)))
		&"next": lan_session.vote(0,true)
		&"rematch": lan_session.vote(1,true)
		&"lobby": lan_session.vote(2,true)
		&"start":
			var result: GameTypes.Result = lan_session.request_start()
			if not result.ok: _lan_error(result.code,result.message)
		&"cancel":
			if lan_session.state == "LOADING":
				scene_router.clear(); world_view = null; current = null; lan_session.cancel()
			else: _close_lan()
		&"back": _close_lan()
func _close_lan() -> void:
	lan_session.leave(); lan_scan.stop(); scene_router.clear()
	world_view = null; current = null; previous = null
	level_select.visible=false
	lan_active = false; routers.clear(); lan_paused = false; scan_started = 0; lan_ui.visible = false; flow_panel.visible = false
	if state.current != State.Screen.MENU: state.transition(State.Screen.MENU)
	state.session_active = false; $Menu.visible = true; exit_button.grab_focus()
func _lan_rooms(entries: Array) -> void:
	if lan_ui != null: lan_ui.menu.set_rooms(entries)
func _lan_refresh() -> void:
	if not lan_active: return
	var info: String = lan_message
	if not progress_store.warning.is_empty() and not progress_store.warning in info: info += "\n"+progress_store.warning
	if lan_session.role == "host":
		var ips: Array[String] = []
		for ip: String in IP.get_local_addresses():
			if NetworkProtocol.ipv4(ip) and not ip.begins_with("127."): ips.append(ip)
		info += " IP hosta: "+", ".join(ips)+"\n"+lan_session.discovery_warning
	if lan_session.weak_connection: info += "\nSłabe połączenie"
	lan_ui.show_screen(1,{"lobby":lan_session.lobby,"role":lan_session.role,"state":lan_session.state,"approved":lan_session.approved,"message":info,"snapshot":lan_session.snapshot,"votes":lan_session.vote_mask,"next_seed":lan_session.next_seed,"confirmed":lan_session.result_confirmed,"progress":progress_store})
	if level_select.visible or (lan_session.state in ["PLAYING","COUNTDOWN"] and not lan_paused): lan_ui.visible = false
func _lan_phase(phase: String) -> void:
	if not lan_active or closing: return
	match phase:
		"CONNECTING":
			state.transition(State.Screen.CONNECTING)
			lan_ui.show_screen(0,{"busy":true,"message":"Łączenie… limit 8 sekund. Anuluj, aby zamknąć połączenie."})
		"LOBBY":
			var returned: bool=state.current==State.Screen.RESULTS
			if lan_session.role == "client" and lan_session.approved and NetworkProtocol.ipv4(lan_join_ip): settings.last_ip = lan_join_ip
			state.session_active = true
			if state.current != State.Screen.LOBBY: state.transition(State.Screen.LOBBY)
			if scene_router.pending or world_view != null:
				scene_router.clear(); world_view = null; current = null
			_lan_refresh()
			if returned and lan_session.role=="host":
				lan_ui.visible=false;level_select.visible=true;level_select.bind(progress_store)
		"PLAYING":
			if state.current != State.Screen.PLAYING: state.transition(State.Screen.PLAYING)
			_lan_input_enabled(); _lan_refresh()
		"INTERMISSION","RESULTS":
			var target: int = State.Screen.INTERMISSION if phase == "INTERMISSION" else State.Screen.RESULTS
			if state.current != target:
				state.transition(target)
				pass # Only reliable result confirmation may persist completion.
			_lan_input_enabled(); _lan_refresh()
		"HANDSHAKE","LOADING","COUNTDOWN": _lan_refresh()
func _lan_error(code: int,message: String) -> void:
	lan_was_weak = false
	lan_message = message
	log_service.write(2,&"LAN",message)
	if lan_session.state == "LOBBY": _lan_refresh(); return
	if lan_session.state == "IDLE":
		for router: InputRouter in routers: router.set_enabled(false)
		state.session_active = false
		scene_router.clear(); world_view = null; current = null; previous = null
		if state.current != State.Screen.MENU: state.transition(State.Screen.MENU)
		state.transition(State.Screen.JOIN_FORM)
		lan_ui.show_error(code,message)
func _lan_load(_sector: int,_map: StringName,generation: int) -> void:
	lan_load_generation = generation; state.session_active = true
	state.transition(State.Screen.LOADING); world_view = null; current = null
	flow_panel.visible = false
	var result: GameTypes.Result = scene_router.show(&"world",assets.map_ids()[lan_session.sector_index if lan_active else pending_sector])
	lan_router_generation = scene_router.pending_generation
	if not result.ok: _lan_error(6,result.message); lan_session.cancel()
func _lan_scene_ready() -> void:
	if lan_load_generation != lan_session.generation or lan_router_generation != scene_router.active_generation: return
	if lan_session.state != "LOADING": scene_router.clear(); return
	world_view = scene_router.active as WorldView
	world_view.configure(assets.map_for_sector(lan_session.sector_index),lan_session.lobby.difficulty,posmod(lan_session.lobby.seed+17*lan_session.sector_index,3),assets)
	var loaded_generation: int = lan_load_generation
	await _warm_world(world_view)
	if loaded_generation!=lan_session.generation or lan_session.state!="LOADING": return
	fixture_hint = Label.new(); fixture_hint.position = Vector2(32,10); fixture_hint.add_theme_font_size_override("font_size",14); fixture_hint.size = Vector2(1216,80); fixture_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; world_view.get_node("HUD").add_child(fixture_hint); fixture_hint.add_theme_font_override("font",assets.fonts.ui)
	lan_session.loaded(lan_load_generation)
func _lan_begin(value: GameSnapshot) -> void:
	current = value.copy(); previous = current.copy()
	state.transition(State.Screen.COUNTDOWN)
	routers.clear()
	var input: InputRouter = InputRouter.new(); input.configure(settings,0); routers.append(input)
	lan_paused = false; _lan_input_enabled()
	_lan_refresh()
func _lan_input_enabled() -> void:
	for router: InputRouter in routers: router.set_enabled(_input_enabled())
func _render_network(delta: float) -> void:
	if not lan_active: return
	if lan_session.weak_connection:
		lan_ui.lobby.status.text = "Słabe połączenie — czekam na partnera…"
	elif lan_was_weak: _lan_refresh()
	lan_was_weak = lan_session.weak_connection
	if scan_started>0 and Time.get_ticks_msec()-scan_started>5000 and lan_scan.entries.is_empty() and lan_session.state=="IDLE":
		lan_ui.menu.status.text = "Nie znaleziono pokoju. Wpisz IP gospodarza. Skan kończy się po 10 s."
	if lan_session.snapshot == null or world_view == null: return
	current = lan_session.snapshot.copy()
	var frame: GameTypes.RenderFrame = lan_session.render_frame(Engine.get_physics_interpolation_fraction(),delta)
	world_view.present(frame,delta); world_view.present_snapshot(current,frame)
	fixture_hint.text = "LAN · %s · slot %d · poziom %d/%d · predykcja lokalna\nIntegrity %d · cele %d/3 · czas %d · wynik %d · odliczanie %d\nWASD / Spacja / E / Q · Escape: menu (gra nadal trwa)" % [lan_session.role,1 if lan_session.role=="host" else 2,current.sector_index+1,LevelCatalog.current().count(),current.integrity,current.objective_index,int(ceil(current.remaining_ticks/60.0)),current.score,int(ceil(current.phase_remaining/60.0))]
	fixture_hint.text += "\n"+ObjectiveSystem.message(current,world_view.map)
	if lan_session.weak_connection: fixture_hint.text += "\nSłabe połączenie"
	if lan_session.snapshots_frozen: fixture_hint.text += "\nBrak aktualnego stanu — obraz wstrzymany"

func _lan_events(events: Array[GameEvent]) -> void:
	if world_view == null: return
	for event: GameEvent in events:
		world_view.play_event(event)

func _accepted_lan_result(_id: StringName,_difficulty: int,_score: int,_ticks: int) -> void:
	lan_message=progress_store.warning
	_lan_refresh()

func _open_level_select() -> void:
	if simulation!=null: _leave_expedition()
	$Menu.visible=false
	level_select.visible=true; level_select.bind(progress_store)

func _level_intent(action: StringName,data: Dictionary) -> void:
	match action:
		&"progress_reset":
			chosen_level=StringName(progress_store.data.last_selected.level_id);chosen_difficulty=int(progress_store.data.last_selected.difficulty)
			if lan_active and lan_session.role=="host" and lan_session.state=="LOBBY":lan_session.set_options(chosen_difficulty,lan_session.lobby.seed,chosen_level)
		&"play":
			if lan_active and lan_session.state=="LOBBY":
				lan_session.set_options(int(data.difficulty),lan_session.lobby.seed,StringName(data.level_id)); level_select.visible=false; _lan_refresh(); return
			chosen_level=StringName(data.level_id); chosen_difficulty=int(data.difficulty)
			level_select.visible=false; _open_lan()
			lan_ui.menu.difficulty.select(chosen_difficulty)
			lan_ui.menu.status.text="Host: %d. %s. Możesz też dołączyć do wyboru innego hosta." % [LevelCatalog.current().index_of(chosen_level)+1,LevelCatalog.current().entry(chosen_level).name]+("\n"+progress_store.warning if not progress_store.warning.is_empty() else "")
		&"join_form":
			if lan_active and lan_session.state=="LOBBY": return
			level_select.visible=false; _open_lan()
		&"back":
			level_select.visible=false
			if lan_active: _lan_refresh()
			else: $Menu.visible=true

func _apply_art_theme(lan_button: Button) -> void:
	var theme: Theme = Theme.new(); theme.default_font = assets.fonts.ui; theme.default_font_size = 20
	$Menu.theme = theme; flow_panel.theme = theme; level_select.theme=theme; lan_ui.menu.theme = theme; lan_ui.lobby.theme = theme
	$Menu/Center/Panel/Margin/Content/Title.visible = false
	var title: TextureRect = TextureRect.new(); title.texture = assets.get_texture(&"title")
	title.custom_minimum_size = Vector2(0,112); title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var content: VBoxContainer = $Menu/Center/Panel/Margin/Content; content.add_child(title); content.move_child(title,0)
	lan_button.icon = assets.get_texture(&"icon_join"); lan_button.add_theme_constant_override("icon_max_width",24)
	exit_button.icon = assets.get_texture(&"icon_exit"); exit_button.add_theme_constant_override("icon_max_width",24)

func _warm_world(view: WorldView) -> void:
	view.apply_settings(settings); view.set_quality(not OS.get_cmdline_user_args().has("--low-effects"))
	view.prewarm(); $FlowLayer/Backdrop.visible = true
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
	if is_instance_valid(view): view.finish_warmup()
	$FlowLayer/Backdrop.visible = false
