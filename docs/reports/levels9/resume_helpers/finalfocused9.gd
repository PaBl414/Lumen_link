extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var t: TestAssert=TestAssert.new()
 for folder: String in ["app","core","net","ui","services","presentation"]:
  for file: String in DirAccess.get_files_at("res://"+folder):
   if file.ends_with(".gd"):t.is_true((load("res://"+folder+"/"+file) as Script).can_instantiate(),"final parse "+file)
 preload("res://tests/unit/test_protocol.gd").new().run(t)
 preload("res://tests/unit/test_obstacles.gd").new().run(t)
 await preload("res://tests/integration/test_level_select.gd").new().run_async(t)
 await preload("res://tests/integration/test_level_progress_lan.gd").new().run_async(t)
 var content: Dictionary=preload("res://tools/validate_content.gd").load_content()
 for variant: int in range(3):
  for difficulty: int in range(2):
   var sim: Simulation=Simulation.new();sim.initialize(content.config,content.maps[&"station_heart"],variant,difficulty)
   var run: Dictionary=preload("res://tests/fixture_replay.gd").load_run(&"station_heart",variant,difficulty)
   preload("res://tests/fixture_replay.gd").play(sim,run)
   t.equal(sim.world.phase,GameTypes.MatchPhase.WON,"final heart input replay v%d d%d" % [variant,difficulty])
 print(JSON.stringify(t.summary()));quit(int(t.failed>0))
