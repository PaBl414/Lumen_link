extends RefCounted
func run_async(t: TestAssert) -> void:
 var tree: SceneTree=Engine.get_main_loop() as SceneTree
 var progress: ProgressStore=ProgressStore.new();progress.path="user://selector_%d.json" % Time.get_ticks_usec()
 var view: LevelSelectPresenter=LevelSelectPresenter.new();tree.root.add_child(view);await tree.process_frame;view.bind(progress)
 t.equal(view.list.item_count,LevelCatalog.current().count(),"LS dynamic catalog count")
 view._select(8);t.is_true(view.play.disabled and view.preview.map.id==&"station_heart","LS locked level still has actual map preview")
 progress.accept_completion(&"dock",0,500,1200);progress.accept_completion(&"dock",1,700,900);view.bind(progress)
 t.is_true("500" in view.description.text and "700" in view.description.text,"LS records of both difficulties visible")
 var intents: Array=[];view.intent.connect(func(action: StringName,data: Dictionary) -> void:intents.append({"action":action,"data":data}))
 view._select(1);view.difficulty.select(1);view._launch()
 t.is_true(intents.back().action==&"play" and intents.back().data.level_id=="garden" and intents.back().data.difficulty==1,"LS play uses stable selected ID and difficulty")
 view.reset_dialog.popup_centered();await tree.process_frame
 t.is_true(progress.completed(&"dock"),"LS opening confirmation does not reset")
 view.reset_dialog.canceled.emit();t.is_true(progress.completed(&"dock"),"LS cancellation preserves progress")
 view.reset_dialog.confirmed.emit();t.is_true(not progress.completed(&"dock") and view.selected==LevelCatalog.current().first_id(),"LS confirmed reset updates store and selector")
 var reload: ProgressStore=ProgressStore.new();reload.path=progress.path;reload.load_progress();t.is_true(reload.data.completed.is_empty(),"LS confirmed UI reset persists")
 for suffix: String in ["",".bak",".pending",".tmp"]:
  if FileAccess.file_exists(progress.path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.path+suffix))
 view.queue_free();await tree.process_frame;set_meta("completed",true)
