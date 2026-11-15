class_name LogService
extends RefCounted
const Store = preload("res://services/settings_store.gd")
var ring: PackedStringArray = PackedStringArray()
var max_lines: int = 500
var max_bytes: int = 2 * 1024 * 1024
var path: String = "user://lumen.log"
func write(level: int, code: StringName, message: String) -> void:
	var clean: String = ""
	for i: int in range(mini(message.length(),2000)):
		var ch: int = message.unicode_at(i)
		clean += message[i] if ch >= 32 and ch != 127 else " "
	ring.append("%d [%s] %s" % [level,String(code).validate_filename(),clean])
	while ring.size() > max_lines: ring.remove_at(0)
func flush() -> GameTypes.Result:
	if ring.is_empty(): return GameTypes.Result.new(true,0,"")
	var existing: String = ""
	if FileAccess.file_exists(path):
		var input: FileAccess = FileAccess.open(path,FileAccess.READ)
		if input != null and input.get_length() <= max_bytes: existing = input.get_as_text()
	var addition: String = "\n".join(ring)+"\n"
	if existing.to_utf8_buffer().size()+addition.to_utf8_buffer().size() > max_bytes:
		if FileAccess.file_exists(path+".1"):
			var error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".1"),ProjectSettings.globalize_path(path+".2"))
			if error != OK: return GameTypes.Result.new(false,error,"log rotation .2 failed")
		if FileAccess.file_exists(path):
			var error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".1"))
			if error != OK: return GameTypes.Result.new(false,error,"log rotation .1 failed")
		existing = ""
	while addition.to_utf8_buffer().size() > max_bytes and not ring.is_empty():
		ring.remove_at(0); addition = "\n".join(ring)+"\n"
	var result: GameTypes.Result = Store.atomic_write(path,existing+addition)
	if result.ok: ring.clear()
	return result
