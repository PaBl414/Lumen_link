extends RefCounted
func run_async(t: TestAssert) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var catalog: AssetCatalog = AssetCatalog.new()
	t.is_true(catalog.load_boot().ok,"C01 complete art catalog loads")
	t.is_true(preload("res://tools/validate_content.gd").validate_assets().ok,"C01 dimensions padding font license")
	t.equal(catalog.get_texture(&"station_12").get_size(),Vector2(252,252),"C01 atlas padded region")
	t.is_true(catalog.get_texture(&"icon_dash") is AtlasTexture,"C01 icon uses shared atlas")
	var view: WorldView = preload("res://scenes/world.tscn").instantiate(); tree.root.add_child(view)
	view.configure(catalog.dock,0,0,catalog)
	var sim: Simulation = Simulation.new(); sim.initialize(catalog.config,catalog.dock,0,0)
	var original: GameSnapshot = sim.snapshot()
	for mode: int in range(3):
		var snapshot: GameSnapshot = original.copy(); snapshot.players[0].mode = mode; snapshot.players[0].invulnerable_ticks = 40
		var frame: GameTypes.RenderFrame = GameTypes.RenderFrame.new()
		for player: WorldState.PlayerState in snapshot.players: frame.players.append(player.copy())
		view.present(frame,0.016); view.present_snapshot(snapshot,frame)
		t.equal(view.drones[0].mode,mode,"V01 player mode %d" % mode)
	var vertical: WorldState.PlayerState = original.players[0].copy(); vertical.mode = GameTypes.PlayerMode.DASH; vertical.facing = Vector2.UP; vertical.velocity = Vector2(0,-720)
	view.drones[0].present(vertical,0.016)
	t.near(view.drones[0].get_node("Visual/DashAxis").rotation,-PI/2,0.001,"V01 stretch follows vertical dash direction")
	t.near(view.drones[0].get_node("Visual/DashAxis/Art").rotation,PI/2,0.001,"V01 dash art stays upright")
	for status: int in range(5):
		view.link_view.present(PackedVector2Array([Vector2(112,592),Vector2(500,500)]),status,0.5)
		t.equal(view.link_view.status,status,"V01 link status %d" % status)
		t.equal(view.link_view.lines[2].visible,status==0,"V01 active core only %d" % status)
	t.is_true(view.link_view.lines[2].texture!=null and view.link_view.lines[2].texture_mode==Line2D.LINE_TEXTURE_STRETCH,"V01 flow shader receives continuous UV")
	for name: String in ["idle","move","dash","hit","celebrate"]:
		t.is_true(view.drones[0].animation.has_animation(name),"V01 animation clip "+name)
		t.near(view.drones[0].animation.get_animation(name).length,{"idle":1.8,"move":0.5,"dash":0.167,"hit":0.2,"celebrate":1.0}[name],0.001,"V01 clip duration "+name)
	var celebration: WorldState.PlayerState = original.players[0].copy()
	view.drones[0].celebrating = true; view.drones[0].present(celebration,0.016); view.drones[0].animation.advance(1.1); view.drones[0].present(celebration,0.016)
	t.is_true(not view.drones[0].animation.is_playing(),"V01 celebrate is one shot not automatic loop")
	celebration.mode = GameTypes.PlayerMode.DASH; view.drones[0].present(celebration,0.016)
	t.equal(view.drones[0].last_clip,"celebrate","V01 victory takes precedence over frozen dash mode")
	view.drones[0].celebrating = false
	var event: GameEvent = GameEvent.new(); event.id = 1; event.type = GameEvent.EventType.DASH; event.value = 1
	view.play_event(event); var count: int = view.fx.particle_count()
	event.id = 2; view.play_event(event)
	t.equal(view.fx.particle_count(),count,"V01 dash predicted confirmed dedup serial")
	view.fx.clear()
	for i: int in range(300):
		event.id = i+10; event.type = GameEvent.EventType.BEACON; event.object_id = i%3; view.play_event(event)
	t.equal(view.fx.particle_count(),320,"V01 high max320 particles")
	t.equal(view.fx.active.size(),128,"V01 max128 effect objects")
	view.set_quality(false)
	t.equal(view.fx.particle_count(),160,"V01 low max160 particles")
	view.link_view.present(PackedVector2Array([Vector2.ZERO,Vector2(100,0)]),0,0)
	t.is_true(not view.link_view.lines[0].visible and view.link_view.lines[1].visible,"V01 low single halo keeps core")
	view.set_reduced_motion(true); view.present(GameTypes.RenderFrame.new(),0.1)
	t.equal(view.fx.particle_count(),0,"V01 reduced motion clears scattering")
	t.equal(view.drones[0].visual.scale,Vector2.ONE,"V01 reduced motion removes stretch")
	t.equal(view.drones[0].visual.rotation,0.0,"V01 reduced motion removes lean")
	var camera: CameraRig = view.get_node("CameraRig") as CameraRig
	camera.impulse(3); camera._process(0.01)
	t.equal(camera.offset,Vector2.ZERO,"V01 reduced motion camera stays still")
	view.set_reduced_motion(false); camera.shake = 1; camera.impulse(99); camera._process(0.01)
	t.is_true(camera.offset.length()<=3,"V01 camera max3px")
	view.visible = false; t.is_true(not (view.get_node("HUD") as CanvasLayer).visible,"V01 hidden world hides HUD")
	event.id = 99999; event.type = GameEvent.EventType.BEACON; view.fx.emit_event(event)
	await tree.create_timer(0.5).timeout
	t.is_true(view.fx.active.is_empty() and view.fx.particle_count()==0,"V01 hidden world effects expire in real time")
	view.visible = true
	view.fx.clear(); t.equal(view.fx.particle_count(),0,"V01 FX cleanup")
	view.prewarm(); t.is_true(view.warming and view.warm_sprites.size()==3,"V01 warm all three shaders")
	view.finish_warmup(); t.is_true(not view.warming and view.warm_sprites.is_empty(),"V01 warmup cleanup")
	t.equal(sim.world.tick,original.tick,"V01 presentation never advances simulation")
	t.equal(sim.world.players[0].position,original.players[0].position,"V01 visual transforms never move collider")
	t.equal(sim.world.integrity,original.integrity,"V01 effects never change damage")
	view.queue_free(); await tree.process_frame
	t.equal(tree.root.get_child_count(),0,"V01 world nodes cleaned")
	set_meta("completed",true)
