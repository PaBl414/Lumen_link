extends SceneTree
var capture_viewport: SubViewport
func _initialize() -> void:run.call_deferred()
func run() -> void:
 capture_viewport=SubViewport.new();capture_viewport.size=Vector2i(1280,720);capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(capture_viewport)
 var assets: AssetCatalog=AssetCatalog.new();assets.load_boot()
 var map: MapDefinition=assets.maps[&"station_heart"]
 var world: WorldView=load("res://scenes/world.tscn").instantiate();capture_viewport.add_child(world);world.configure(map,0,1,assets)
 var state: WorldState=WorldState.new();state.reset(map,assets.config,6);state.latched_mask=1;state.charges[0]=150;state.tick=200;state.sector_tick=200;state.active_socket=0
 state.players[0].position=Vector2(112,272);state.players[1].position=Vector2(384,624)
 var masks: Vector2i=ObstacleSystem.masks(map,200,0,1);state.obstacle_active_mask=masks.x;state.obstacle_warning_mask=masks.y
 var collision: CollisionWorld=CollisionWorld.new();collision.configure(map);state.link_status=LinkSystem.new().evaluate(state.players,0,map,collision,200,0,1).status
 var frame: GameTypes.RenderFrame=GameTypes.RenderFrame.new();frame.players.assign(state.players)
 world.present(frame,0);world.present_snapshot(GameSnapshot.capture(state));await process_frame;await RenderingServer.frame_post_draw
 print("capture error=",capture_viewport.get_texture().get_image().save_png("res://docs/reports/levels9/heart-safe-field.png"));quit()
