extends RefCounted
const Settings = preload("res://services/settings_store.gd")
const Records = preload("res://services/records_store.gd")
const Logs = preload("res://services/log_service.gd")
func run(t: TestAssert) -> void:
	var folder: String = "user://test_persistence_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var store: Settings = Settings.new(); store.path = folder+"/settings.json"
	var settings: GameTypes.SettingsData = store.load_settings()
	t.near(settings.master_volume,1,0.001,"PS01 missing settings defaults")
	settings.master_volume = 0.4; settings.fps_limit = 120
	t.is_true(store.save_settings(settings).ok,"PS01 atomic settings save")
	t.near(store.load_settings().master_volume,0.4,0.00001,"PS01 settings roundtrip")
	t.is_true(not FileAccess.file_exists(store.path+".tmp"),"PS01 temp consumed by rename")
	Settings.atomic_write(store.path,"{bad JSON")
	t.near(store.load_settings().master_volume,1,0.001,"PS01 malformed fallback")
	t.is_true(FileAccess.file_exists(store.path+".bak"),"PS01 corrupted backup")
	Settings.atomic_write(store.path,'{"schema_version":99}')
	store.load_settings()
	t.is_true(not store.warning.is_empty(),"PS01 unknown schema warning")
	settings.shake = NAN
	t.fails(store.save_settings(settings),"PS01 reject NaN")
	settings.shake = 1; settings.bindings = {"ui_cancel":[]}
	t.fails(store.save_settings(settings),"PS01 reject last cancel binding removal")
	var records: Records = Records.new(); records.path = folder+"/records.json"
	records.load_records(); t.is_true(records.best(0) == null,"PS01 no records returns null")
	for pair: Vector2i in [Vector2i(100,200),Vector2i(200,300),Vector2i(200,100)]:
		var record: GameTypes.RecordData = GameTypes.RecordData.new()
		record.score = pair.x; record.duration_ticks = pair.y; record.date_utc = "2026-11-15T00:00:00Z"
		t.is_true(records.submit(record).ok,"PS01 submit record")
	records.load_records()
	t.equal(records.best(0).duration_ticks,100,"PS01 tie sorted by elapsed time")
	var best: GameTypes.RecordData = records.best(0); best.score = 999
	t.equal(records.best(0).score,200,"PS01 best is copy")
	t.is_true(records.best(1) == null,"PS01 difficulties separate")
	for index: int in range(102):
		var record: GameTypes.RecordData = GameTypes.RecordData.new(); record.score = index
		records.submit(record)
	t.equal(records.records.size(),100,"PS01 cap100")
	records.load_records(); t.equal(records.records.size(),100,"PS01 cap100 persisted")
	var old_count: int = records.records.size()
	records.path = folder+"/missing/records.json"
	t.fails(records.submit(best),"PS01 save error explicit")
	t.equal(records.records.size(),old_count,"PS01 failed save rolls back memory")
	records.path = folder+"/records.json"; Settings.atomic_write(records.path,'{"schema_version":1,"records":[{}]}')
	records.load_records(); t.equal(records.records.size(),0,"PS01 corrupt records empty fallback")
	var log: Logs = Logs.new(); log.path = folder+"/test.log"; log.max_lines = 2; log.max_bytes = 128
	log.write(1,&"TEST","one\ncontrol\tcharacters"); log.write(1,&"TEST","two"); log.write(1,&"TEST","three")
	t.equal(log.ring.size(),2,"PS01 log ring cap")
	t.is_true(log.flush().ok,"PS01 log flush")
	for index: int in range(4):
		log.write(1,&"TEST","x".repeat(90)); t.is_true(log.flush().ok,"PS01 rotation")
	t.is_true(FileAccess.file_exists(log.path+".2"),"PS01 three log files")
	for filename: String in DirAccess.get_files_at(folder): DirAccess.remove_absolute(ProjectSettings.globalize_path(folder+"/"+filename))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	set_meta("completed",true)
