class_name ProgressStore
extends RefCounted
const SCHEMA_VERSION: int = 1
var path: String = "user://progress.json"
var catalog: LevelCatalog
var data: Dictionary = {}
var warning: String = ""
var dirty: bool = false
var read_only_version: bool = false
func _init(levels: LevelCatalog = null) -> void:
	catalog = levels if levels!=null else LevelCatalog.current(); data = defaults()
func defaults() -> Dictionary:
	return {"schema_version":SCHEMA_VERSION,"completed":[],"records":{},"last_selected":{"level_id":String(catalog.first_id()),"difficulty":0}}
static func _uint(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=0 and value<=0xffffffff and value==floor(value)
func validate(value: Variant) -> GameTypes.Result:
	if not value is Dictionary or value.size()!=4 or value.get("schema_version")!=SCHEMA_VERSION or not value.get("completed") is Array or value.completed.size()>1024 or not value.get("records") is Dictionary or value.records.size()>1024 or not value.get("last_selected") is Dictionary: return GameTypes.Result.new(false,1,"progress: invalid schema")
	var seen: Dictionary = {}
	for id: Variant in value.completed:
		if not LevelCatalog.valid_id(id) or seen.has(id): return GameTypes.Result.new(false,1,"progress: invalid completed ID")
		seen[id] = true
	for id: Variant in value.records:
		var row: Variant = value.records[id]
		if not LevelCatalog.valid_id(id) or not row is Dictionary or row.size()>2: return GameTypes.Result.new(false,1,"progress: invalid records")
		for difficulty: Variant in row:
			var record: Variant = row[difficulty]
			if difficulty not in ["normal","relaxed"] or not record is Dictionary or record.size()!=2 or not _uint(record.get("best_score")) or not _uint(record.get("best_time_ticks")) or record.best_time_ticks<1: return GameTypes.Result.new(false,1,"progress: invalid record")
	var selected: Dictionary = value.last_selected
	if selected.size()!=2 or not LevelCatalog.valid_id(selected.get("level_id")) or not _uint(selected.get("difficulty")) or selected.difficulty>1: return GameTypes.Result.new(false,1,"progress: invalid selection")
	return GameTypes.Result.new(true,0,"",value.duplicate(true))
func _read(target: String) -> Variant:
	var file: FileAccess = FileAccess.open(target,FileAccess.READ)
	if file==null: return null
	if file.get_length()>1048576: file.close(); return null
	var parser: JSON = JSON.new(); var error: Error = parser.parse(file.get_as_text()); file.close(); return parser.data if error==OK else null
func load_progress() -> void:
	data = defaults(); warning = ""; dirty = false; read_only_version = false
	var raw: Variant = _read(path)
	if raw is Dictionary and _uint(raw.get("schema_version")) and raw.schema_version>SCHEMA_VERSION:
		read_only_version = true; warning = "Zapis pochodzi z nowszej wersji. Pozostawiono go bez zmian; używam postępu w pamięci."; return
	var primary: GameTypes.Result = validate(raw)
	if primary.ok: data = primary.value
	else:
		var backup: GameTypes.Result = validate(_read(path+".bak"))
		if backup.ok:
			data = backup.value; warning = "Odzyskano postęp z kopii zapasowej."; dirty = true
		elif FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak"): warning = "Brak poprawnego zapisu postępu. Używam bezpiecznych wartości początkowych."
	if not catalog.has_level(StringName(data.last_selected.level_id)): data.last_selected.level_id = String(catalog.first_id())
func completed(id: StringName) -> bool: return String(id) in data.completed
func unlocked(id: StringName) -> bool:
	var index: int = catalog.index_of(id)
	return index>=0 and (index==0 or completed(id) or completed(StringName(catalog.entries[index-1].id)))
func continue_id() -> StringName:
	for id: StringName in catalog.ids():
		if not completed(id): return id
	return &""
func best(id: StringName,difficulty: int) -> Dictionary:
	return data.records.get(String(id),{}).get("normal" if difficulty==0 else "relaxed",{}).duplicate(true)
func select_level(id: StringName,difficulty: int,host_unlock: bool = false) -> GameTypes.Result:
	if not catalog.has_level(id) or difficulty not in [0,1] or (not host_unlock and not unlocked(id)): return GameTypes.Result.new(false,1,"Poziom jest zablokowany.")
	if data.last_selected.level_id==String(id) and int(data.last_selected.difficulty)==difficulty and not dirty: return GameTypes.Result.new(true,0,"")
	data.last_selected = {"level_id":String(id),"difficulty":difficulty}; dirty = true
	return save()
func accept_completion(id: StringName,difficulty: int,score: int,time_ticks: int) -> GameTypes.Result:
	if not catalog.has_level(id) or difficulty not in [0,1] or not _uint(score) or not _uint(time_ticks) or time_ticks<1: return GameTypes.Result.new(false,1,"progress: invalid accepted result")
	if not completed(id): data.completed.append(String(id))
	var key: String = "normal" if difficulty==0 else "relaxed"
	if not data.records.has(String(id)): data.records[String(id)] = {}
	var previous: Dictionary = best(id,difficulty)
	data.records[String(id)][key] = {"best_score":maxi(score,int(previous.get("best_score",0))),"best_time_ticks":mini(time_ticks,int(previous.get("best_time_ticks",time_ticks)))}
	data.last_selected = {"level_id":String(id),"difficulty":difficulty}; dirty = true
	return save()
func save() -> GameTypes.Result:
	var valid: GameTypes.Result = validate(data)
	if not valid.ok: return valid
	if read_only_version: return _io_error("Nie nadpisano nowszego formatu; postęp pozostaje w pamięci.")
	# First flush new contents. Only a valid primary may replace the last valid backup.
	var written: GameTypes.Result = SettingsStore.atomic_write(path+".pending",JSON.stringify(data,"\t")+"\n")
	if not written.ok: return _io_error("Nie zapisano postępu na dysku; pozostaje w pamięci. "+written.message)
	var old: Variant = _read(path)
	if validate(old).ok:
		var backup: GameTypes.Result = SettingsStore.atomic_write(path+".bak",JSON.stringify(old,"\t")+"\n")
		if not backup.ok: return _io_error("Nie zapisano kopii; nowy postęp pozostaje w pamięci.")
	var error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".pending"),ProjectSettings.globalize_path(path))
	if error!=OK: return _io_error("Nie zastąpiono pliku postępu; nowy postęp pozostaje w pamięci.")
	# First save also gets a valid backup. Failure does not undo the successful primary.
	if not validate(_read(path+".bak")).ok:
		var backup: GameTypes.Result = SettingsStore.atomic_write(path+".bak",JSON.stringify(data,"\t")+"\n")
		if not backup.ok: return _io_error("Postęp zapisany; nie udało się utworzyć kopii zapasowej.")
	dirty = false; warning = ""; return GameTypes.Result.new(true,0,"")
func _io_error(message: String) -> GameTypes.Result:
	warning = message; dirty = true; return GameTypes.Result.new(false,ERR_CANT_CREATE,message)
func reset_progress(confirmed: bool) -> GameTypes.Result:
	if not confirmed: return GameTypes.Result.new(false,1,"Wymagane potwierdzenie resetu.")
	if read_only_version: return _io_error("Nie usunięto zapisu z nowszej wersji.")
	data = defaults(); dirty = true
	var result: GameTypes.Result = save()
	if result.ok:
		# Reset both generations: recovery must not silently restore deliberately erased progress.
		result = SettingsStore.atomic_write(path+".bak",JSON.stringify(data,"\t")+"\n")
		if not result.ok: return _io_error("Reset w pamięci; nie udało się zresetować kopii.")
	return result
