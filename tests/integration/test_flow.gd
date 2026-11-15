extends RefCounted
func _wait_loaded(app: AppRoot,tree: SceneTree) -> void:
 var deadline: int=Time.get_ticks_msec()+5000
 while app.scene_router.pending and Time.get_ticks_msec()<deadline: await tree.create_timer(0.01).timeout
func run_async(t: TestAssert) -> void:
 var tree: SceneTree=Engine.get_main_loop() as SceneTree
 var app: AppRoot=load("res://scenes/app.tscn").instantiate();tree.root.add_child(app);await tree.process_frame
 var folder: String="user://test_flow_%d" % Time.get_ticks_usec();DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 app.progress_store=ProgressStore.new();app.progress_store.path=folder+"/progress.json"
 app.records_store.path=folder+"/legacy.json";app.records_store.records.clear()
 app._open_level_select();t.is_true(app.level_select.visible and app.level_select.list.item_count==LevelCatalog.current().count(),"F01 selector presents entire catalog")
 app.level_select.visible=false
 app._start_fixture(app.assets.dock);var generation: int=app.scene_router.pending_generation;app.cancel_loading();await tree.process_frame
 t.is_true(app.scene_router.active==null and not app.scene_router.pending and app.scene_router.pending_generation>generation,"F01 cancelled generation cannot attach")
 app.chosen_difficulty=1;app.chosen_level=LevelCatalog.current().first_id();app._start_fixture(app.assets.dock);await _wait_loaded(app,tree)
 for id: StringName in LevelCatalog.current().ids():
  t.equal(app.simulation.map.id,id,"F01 chosen stable level ID")
  t.equal(app.simulation.world.integrity,9,"F01 new level Relaxed integrity")
  t.equal(app.simulation.world.score,0,"F01 score resets each level")
  for tick: int in range(180):app._physics_process(1.0/60)
  t.equal(app.state.current,app.State.Screen.PLAYING,"F01 common countdown")
  var fixture: Dictionary=preload("res://tests/fixture_replay.gd").load_run(id,0,1)
  t.is_true(not fixture.is_empty(),"F01 actual input fixture exists")
  preload("res://tests/fixture_replay.gd").play(app.simulation,fixture);app._physics_process(1.0/60)
  t.equal(app.current.phase,GameTypes.MatchPhase.WON,"F01 level completed by movement inputs")
  t.is_true(app.progress_store.completed(id),"F01 completion saved immediately")
  var next: StringName=LevelCatalog.current().next_id(id)
  if next!=&"":
   app.vote_continue(0);t.equal(app.state.current,app.State.Screen.RESULTS,"F01 one local vote cannot advance")
   app.vote_continue(1);await _wait_loaded(app,tree)
 t.equal(app.progress_store.continue_id(),&"","F01 all nine complete")
 t.equal(app.records_store.records.size(),0,"F01 new level scores never overwrite legacy campaign records")
 var reload: ProgressStore=ProgressStore.new();reload.path=app.progress_store.path;reload.load_progress()
 t.equal(reload.data.completed.size(),LevelCatalog.current().count(),"F01 restart restores nine stable IDs")
 var score: int=app.current.score
 for tick: int in range(5):app._physics_process(1.0/60)
 t.equal(app.current.score,score,"F01 terminal state stable")
 app._leave_expedition();app.queue_free();await tree.process_frame
 for file: String in DirAccess.get_files_at(folder):DirAccess.remove_absolute(ProjectSettings.globalize_path(folder+"/"+file))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(folder));set_meta("completed",true)
