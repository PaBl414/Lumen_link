class_name SettingsStore
extends RefCounted
var path: String = "user://settings.json"
var warning: String = ""
const FIELDS: Array[String] = ["master_volume","music_volume","sfx_volume","fullscreen","fps_limit","vsync","ui_scale","shake","reduced_motion","color_accessibility","hints","bindings","last_ip"]

static func encode(settings: GameTypes.SettingsData) -> Dictionary:
	var data: Dictionary = {"schema_version":1}
	for field: String in FIELDS: data[field] = settings.get(field)
	return data

func validate(data: Dictionary) -> GameTypes.Result:
	if data.get("schema_version") != 1 or data.size() != FIELDS.size()+1:
		return GameTypes.Result.new(false,1,"settings: invalid schema")
	var defaults: Dictionary = encode(GameTypes.SettingsData.new())
	for field: String in FIELDS:
		if not data.has(field): return GameTypes.Result.new(false,1,"settings: missing "+field)
		var value: Variant = data[field]
		if defaults[field] is float:
			if not (value is int or value is float) or not is_finite(float(value)): return GameTypes.Result.new(false,1,"settings: invalid "+field)
		elif field == "fps_limit":
			if not (value is int or value is float) or not is_finite(float(value)) or value != floor(value) or int(value) not in [0,60,120]: return GameTypes.Result.new(false,1,"settings: invalid fps_limit")
		elif typeof(value) != typeof(defaults[field]): return GameTypes.Result.new(false,1,"settings: invalid "+field)
	for field: String in ["master_volume","music_volume","sfx_volume","shake"]:
		if data[field] < 0 or data[field] > 1: return GameTypes.Result.new(false,1,"settings: range "+field)
	if data.ui_scale not in [1.0,1.15,1.3] or data.last_ip.length() > 64: return GameTypes.Result.new(false,1,"settings: invalid scale/IP")
	# Bindings become editable in M12; accept only known actions and bounded primitive event data.
	for action: Variant in data.bindings:
		if not action is String or not InputMap.has_action(action) or not data.bindings[action] is Array or data.bindings[action].size() > 8: return GameTypes.Result.new(false,1,"settings: invalid bindings")
		if action == "ui_cancel" and data.bindings[action].is_empty(): return GameTypes.Result.new(false,1,"settings: ui_cancel cannot be empty")
		for binding: Variant in data.bindings[action]:
			if not binding is Dictionary or binding.size() != 2 or binding.get("type") not in ["key","button"] or not (binding.get("code") is int or binding.get("code") is float) or binding.code < 0 or binding.code > 0x7fffffff or binding.code != floor(binding.code): return GameTypes.Result.new(false,1,"settings: invalid binding event")
	var settings: GameTypes.SettingsData = GameTypes.SettingsData.new()
	for field: String in FIELDS: settings.set(field, int(data[field]) if field == "fps_limit" else data[field])
	settings.bindings = settings.bindings.duplicate(true)
	return GameTypes.Result.new(true,0,"",settings)

func load_settings() -> GameTypes.SettingsData:
	warning = ""
	if not FileAccess.file_exists(path): return GameTypes.SettingsData.new()
	var file: FileAccess = FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > 65536:
		warning = "settings: unreadable/oversized; defaults used"
		return GameTypes.SettingsData.new()
	var parser: JSON = JSON.new()
	var parsed: Error = parser.parse(file.get_as_text()); file.close()
	var data: Variant = parser.data if parsed == OK else null
	var result: GameTypes.Result = validate(data) if data is Dictionary else GameTypes.Result.new(false,1,"settings: malformed JSON")
	if result.ok: return result.value
	warning = result.message + "; defaults used"
	# Preserve unknown versions/corrupt files before any later save.
	var error: Error = DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".bak"))
	if error != OK: warning += "; backup failed (%d)" % error
	return GameTypes.SettingsData.new()

func save_settings(settings: GameTypes.SettingsData) -> GameTypes.Result:
	var data: Dictionary = encode(settings)
	var result: GameTypes.Result = validate(data)
	return atomic_write(path,JSON.stringify(data)) if result.ok else result

static func atomic_write(target: String, text: String) -> GameTypes.Result:
	var absolute: String = ProjectSettings.globalize_path(target)
	var file: FileAccess = FileAccess.open(target+".tmp",FileAccess.WRITE)
	if file == null: return GameTypes.Result.new(false,FileAccess.get_open_error(),"Cannot open temporary file: "+target)
	file.store_string(text); file.flush()
	var error: Error = file.get_error(); file.close()
	if error != OK: return GameTypes.Result.new(false,error,"Cannot write: "+target)
	error = DirAccess.rename_absolute(absolute+".tmp",absolute)
	return GameTypes.Result.new(error == OK,error,"" if error == OK else "Atomic rename failed: "+target)
