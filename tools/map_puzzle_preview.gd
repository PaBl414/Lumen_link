extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var viewport: SubViewport = SubViewport.new(); viewport.size = Vector2i(1280,720); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; viewport.world_2d = World2D.new(); root.add_child(viewport)
	var screen: Sprite2D = Sprite2D.new(); screen.centered = false; screen.texture = viewport.get_texture(); root.add_child(screen)
	var catalog: AssetCatalog = AssetCatalog.new(); var loaded: GameTypes.Result = catalog.load_boot()
	if not loaded.ok: push_error(loaded.message); quit(1); return
	var hints: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/map_solution_hints.json"))
	for id: String in hints:
		var world: WorldView = preload("res://scenes/world.tscn").instantiate(); viewport.add_child(world); world.configure(catalog.maps[StringName(id)],0,0,catalog)
		var label: Label = Label.new(); label.position = Vector2(32,8); label.size = Vector2(1216,76); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_override("font",catalog.fonts.ui); label.add_theme_font_size_override("font_size",17); world.get_node("HUD").add_child(label)
		for i: int in range(3):
			for stage: int in range(hints[id][i].stages.size()):
				var sim: Simulation = Simulation.new(); sim.initialize(catalog.config,catalog.maps[StringName(id)],0,0)
				var snapshot: GameSnapshot = sim.snapshot(); snapshot.objective_index = i; snapshot.complete_mask = (1<<i)-1
				var hint: Dictionary = hints[id][i].stages[stage]; snapshot.active_socket = int(hint.socket)
				for previous: int in range(i):
					snapshot.charges[previous] = 300
					if world.map.objective_rule(previous).stabilization.size()==2: snapshot.latched_mask |= 1<<previous
				for slot: int in range(2): snapshot.players[slot].position = Vector2(hint.ends[slot][0],hint.ends[slot][1])
				if stage==1: snapshot.latched_mask |= 1<<i
				var collision: CollisionWorld = CollisionWorld.new(); collision.configure(world.map)
				snapshot.link_status = LinkSystem.new().evaluate(snapshot.players,snapshot.active_socket,world.map,collision).status
				snapshot.charges[i] = 220 if stage==1 else 100
				var frame: GameTypes.RenderFrame = GameTypes.RenderFrame.new(); frame.players.assign(snapshot.players); frame.tick_float = snapshot.tick
				world.present(frame,0.1); world.present_snapshot(snapshot,frame)
				label.text = "%s · cel %d · etap %d\n%s" % [id,i+1,stage+1,ObjectiveSystem.message(snapshot,world.map)]
				await process_frame; await RenderingServer.frame_post_draw
				var picture: Image = viewport.get_texture().get_image(); var path: String = "res://docs/reports/m11c/%s-%d-%d" % [id,i+1,stage+1]
				picture.save_png(path+".png"); picture.convert(Image.FORMAT_L8); picture.save_png(path+"-gray.png")
				if (id=="garden" and i==0 and stage==0) or (id=="dock" and i==1):
					if id=="garden": snapshot.players[1].position = Vector2(400,448)
					else: snapshot.active_socket = -1
					var route: GameTypes.LinkResult = LinkSystem.new().evaluate(snapshot.players,snapshot.active_socket,world.map,collision)
					snapshot.link_status = route.status; frame.players.clear(); frame.players.assign(snapshot.players)
					world.present(frame,0.1); world.present_snapshot(snapshot,frame); label.text = ObjectiveSystem.message(snapshot,world.map)
					await process_frame; await RenderingServer.frame_post_draw
					var extra: Image = viewport.get_texture().get_image(); extra.save_png("res://docs/reports/m11c/"+("fields-empty" if id=="garden" else "blocked-contact")+".png")

		viewport.remove_child(world); world.queue_free(); await process_frame
	quit(0)
