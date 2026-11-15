extends Node
# Native render QA, not a gameplay bot or release scene. Saves exact720p GPU readbacks.
var catalog: AssetCatalog = AssetCatalog.new()
var viewport: SubViewport
var world: WorldView
var snapshot: GameSnapshot
var stress: bool = false
var serial: int = 1000
var frames: Array[float] = []
var calls: Array[int] = []
var report: Dictionary = {}
var previous_us: int = 0
var particle_peak: int = 0
var capture_dir: String = "res://docs/reports/m11"
class Board extends Node2D:
	var catalog: AssetCatalog
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,720),Color("101b2b"))
		draw_texture_rect(catalog.get_texture(&"title"),Rect2(20,0,640,160),false)
		draw_string(catalog.fonts.ui,Vector2(700,66),"PORCELANA / MIEDŹ / ŚWIATŁO",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("dce8de"))
		draw_string(catalog.fonts.ui,Vector2(700,102),"ĄĆĘŁŃÓŚŹŻ · ąćęłńóśźż · 0123456789",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("b3c2c6"))
		for i: int in range(2):
			draw_texture_rect(catalog.get_texture(&"drone_a" if i==0 else &"drone_b"),Rect2(40+i*200,170,160,160),false)
			draw_texture_rect(catalog.get_texture(&"sensor"),Rect2(108+i*200,234,32,32),false)
			draw_string(catalog.fonts.bold,Vector2(75+i*200,360),"A / OKRĄG" if i==0 else "B / ROMB",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("dce8de"))
		for i: int in range(8):
			var id: StringName = [&"beacon_off",&"beacon_on",&"socket_off",&"socket_on",&"exit_off",&"exit_on",&"pulse",&"sweep"][i]
			draw_texture_rect(catalog.get_texture(id),Rect2(480+(i%4)*184,166+(i/4)*150,116,116),false)
		for i: int in range(16): draw_texture_rect(catalog.get_texture(StringName("station_%02d" % i)),Rect2(24+i*76,505,70,70),false)
		draw_texture_rect(catalog.get_texture(&"icons"),Rect2(24,594,512,256),false)
		for i: int in range(3): draw_texture_rect(catalog.get_texture([&"dock_bg",&"garden_bg",&"reactor_bg"][i]),Rect2(584+i*226,600,210,118),false)
func _ready() -> void: _run.call_deferred()
func _process(delta: float) -> void:
	if world==null or snapshot==null: return
	var frame: GameTypes.RenderFrame = GameTypes.RenderFrame.new()
	for player: WorldState.PlayerState in snapshot.players: frame.players.append(player.copy())
	frame.tick_float = snapshot.tick; world.present(frame,delta); world.present_snapshot(snapshot,frame)
	if stress:
		for i: int in range(6):
			serial += 1; var event: GameEvent = GameEvent.new(); event.id = serial; event.type = GameEvent.EventType.BEACON
			event.position = Vector2(200+(serial%6)*160,180+(serial%4)*120); world.fx.emit_event(event)
	particle_peak = maxi(particle_peak,world.fx.particle_count())
	var now: int = Time.get_ticks_usec()
	if previous_us>0: frames.append((now-previous_us)/1000.0); calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	previous_us = now
func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	image.save_png(capture_dir+"/"+name+".png")
	image.convert(Image.FORMAT_L8); image.save_png(capture_dir+"/"+name+"-gray.png")
	print("CAPTURE ",name)
func _sample(name: String,count: int = 90) -> void:
	frames.clear(); calls.clear(); previous_us = 0; particle_peak = 0
	for i: int in range(count): await get_tree().process_frame
	var sorted: Array[float] = frames.duplicate(); sorted.sort()
	report[name] = {"p95_ms":sorted[int((sorted.size()-1)*0.95)],"max_ms":sorted.back(),"max_draw_calls":calls.max(),"particles":world.fx.particle_count(),"max_particles":particle_peak,"effects":world.fx.active.size()}
func _run() -> void:
	if DisplayServer.get_name()=="headless": push_error("Native renderer required"); get_tree().quit(1); return
	DisplayServer.window_set_title("LUMEN LINK M11 RENDER QA")
	var loaded: GameTypes.Result = catalog.load_boot()
	if not loaded.ok: push_error(loaded.message); get_tree().quit(1); return
	viewport = SubViewport.new(); viewport.size = Vector2i(1280,720); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; viewport.world_2d = World2D.new(); add_child(viewport)
	var screen: Sprite2D = Sprite2D.new(); screen.centered = false; screen.texture = viewport.get_texture(); add_child(screen)
	var board: Board = Board.new(); board.catalog = catalog; viewport.add_child(board)
	await get_tree().process_frame; await _save("asset-board")
	board.queue_free(); await get_tree().process_frame
	for id: StringName in catalog.map_ids():
		if world!=null: viewport.remove_child(world); world.queue_free(); world = null
		snapshot = null
		world = preload("res://scenes/world.tscn").instantiate(); viewport.add_child(world); world.configure(catalog.maps[id],0,0,catalog)
		world.prewarm(); await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw; world.finish_warmup()
		var sim: Simulation = Simulation.new(); sim.initialize(catalog.config,catalog.maps[id],0,0)
		var run: Dictionary = preload("res://tests/fixture_replay.gd").load_run(id,0,0)
		for tick: int in range(1,481): sim.step([preload("res://tests/fixture_replay.gd").command_at(run,tick,0,tick),preload("res://tests/fixture_replay.gd").command_at(run,tick,1,tick)])
		snapshot = sim.snapshot()
		await _sample(String(id)); await _save(String(id))
	snapshot.players[0].position = Vector2(928,520); snapshot.players[1].position = Vector2(1088,520)
	snapshot.link_status = GameTypes.LinkStatus.ACTIVE; snapshot.complete_mask = 3; snapshot.charges = PackedInt32Array([300,300,200]); snapshot.objective_index = 2
	await _sample("active-link",60); await _save("active-link")
	for i: int in range(6): await get_tree().process_frame
	# Presentation-only mode fixtures exercise dash/stun, an occluded link and maxFX.
	snapshot.players[0].mode = GameTypes.PlayerMode.DASH; snapshot.players[0].consumed_serials.x = 1
	snapshot.players[1].mode = GameTypes.PlayerMode.STUN; snapshot.players[1].invulnerable_ticks = 60
	await _sample("first-dash",12)
	# Capture the peak stretch separately so GPU readback does not pollute first-use timing.
	snapshot.players[0].mode = 0; await get_tree().process_frame
	snapshot.players[0].mode = GameTypes.PlayerMode.DASH; snapshot.players[0].consumed_serials.x = 2
	for i: int in range(4): await get_tree().process_frame
	await _save("dash-stun")
	snapshot.players[0].mode = 0; snapshot.players[1].mode = 0; snapshot.players[0].position = Vector2(320,360); snapshot.players[1].position = Vector2(496,360); snapshot.link_status = GameTypes.LinkStatus.OCCLUDED
	await get_tree().process_frame; await _save("occluded")
	stress = true; world.set_quality(true); await _sample("high-stress"); await _save("high-stress")
	world.set_quality(false); await _sample("low-stress"); await _save("low-stress")
	world.set_reduced_motion(true); await _sample("reduced-motion",30); await _save("reduced-motion")
	stress = false
	var file: FileAccess = FileAccess.open(capture_dir+"/render-metrics.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")+"\n"); file.close()
	print(JSON.stringify(report)); get_tree().quit(0)
