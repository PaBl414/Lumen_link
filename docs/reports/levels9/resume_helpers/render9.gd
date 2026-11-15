extends SceneTree
var capture_viewport: SubViewport
func _initialize() -> void: run.call_deferred()
func capture(path: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 var error: Error=capture_viewport.get_texture().get_image().save_png(path)
 print(path,' error=',error)
func run() -> void:
 capture_viewport=SubViewport.new();capture_viewport.size=Vector2i(1280,720);capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(capture_viewport)
 root.size=Vector2i(1280,720)
 var app: AppRoot=load("res://scenes/app.tscn").instantiate();capture_viewport.add_child(app);await process_frame
 app._open_level_select();await capture("res://docs/reports/levels9/select-fresh.png")
 app.level_select.progress=ProgressStore.new();app.level_select.progress.data.completed=Array(LevelCatalog.current().ids().map(func(id: StringName) -> String:return String(id)))
 app.level_select.bind(app.level_select.progress);await capture("res://docs/reports/levels9/select-complete.png")
 app.queue_free();await process_frame
 var assets: AssetCatalog=AssetCatalog.new();assets.load_boot()
 var hints: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/map_solution_hints.json"))
 for id: StringName in LevelCatalog.current().ids():
  var map: MapDefinition=assets.maps[id]
  var world: WorldView=load("res://scenes/world.tscn").instantiate();capture_viewport.add_child(world);world.configure(map,0,0,assets)
  var state: WorldState=WorldState.new();state.reset(map,assets.config,6);state.sector_tick=450;state.tick=450
  state.objective_index=1
  var stage: Dictionary=hints[id][1].stages[0];state.active_socket=int(stage.socket)
  for i: int in range(2):state.players[i].position=Vector2(stage.ends[i][0],stage.ends[i][1])
  var masks: Vector2i=ObstacleSystem.masks(map,450,0,0);state.obstacle_active_mask=masks.x;state.obstacle_warning_mask=masks.y
  var collision: CollisionWorld=CollisionWorld.new();collision.configure(map);state.link_status=LinkSystem.new().evaluate(state.players,state.active_socket,map,collision,450).status
  var snapshot: GameSnapshot=GameSnapshot.capture(state)
  var frame: GameTypes.RenderFrame=GameTypes.RenderFrame.new();frame.players.assign(state.players)
  world.present(frame,0);world.present_snapshot(snapshot);await capture("res://docs/reports/levels9/map-%s.png" % id)
  world.queue_free();await process_frame
 quit()
