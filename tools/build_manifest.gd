extends SceneTree
const P = preload("res://net/protocol.gd")
static func _files(folder: String,result: Array[String]) -> void:
	for filename: String in DirAccess.get_files_at(folder):
		result.append(folder+"/"+filename)
	for dirname: String in DirAccess.get_directories_at(folder): _files(folder+"/"+dirname,result)
static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 7: return false
	for key: String in ["schema_version","protocol"]:
		if not (data.get(key) is int or data.get(key) is float) or data[key] != (P.VERSION if key=="protocol" else 1): return false
	for key: String in ["engine_version","engine_build_id","content_sha256","code_revision","build_label"]:
		if not data.get(key) is String: return false
	if data.engine_version.is_empty() or data.engine_version.length()>32 or data.engine_build_id.is_empty() or data.engine_build_id.length()>64 or data.content_sha256.length()!=64: return false
	for ch: String in data.content_sha256:
		if ch not in "0123456789abcdef": return false
	return true

static func calculate() -> Dictionary:
	var paths: Array[String] = []
	for folder: String in ["data","core","net","app"]: _files("res://"+folder,paths)
	paths.sort()
	var hash: HashingContext = HashingContext.new(); hash.start(HashingContext.HASH_SHA256)
	for path: String in paths:
		var name_bytes: PackedByteArray = path.trim_prefix("res://").to_utf8_buffer()
		var data: PackedByteArray = FileAccess.get_file_as_bytes(path)
		var size: PackedByteArray = PackedByteArray(); size.resize(8)
		size.encode_u32(0,name_bytes.size()); size.encode_u32(4,data.size())
		hash.update(size); hash.update(name_bytes); hash.update(data)
	var version: Dictionary = Engine.get_version_info()
	return {"schema_version":1,"protocol":P.VERSION,"engine_version":"%d.%d.%d" % [version.major,version.minor,version.patch],"engine_build_id":version.hash,"content_sha256":hash.finish().hex_encode(),"code_revision":"unversioned","build_label":"Levels9-dev"}
func _initialize() -> void:
	var expected: Dictionary = calculate()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--write" in args:
		var file: FileAccess = FileAccess.open("res://build_manifest.json",FileAccess.WRITE)
		if file == null: quit(1); return
		file.store_string(JSON.stringify(expected,"\t")+"\n"); file.close(); print(JSON.stringify(expected)); quit(0)
	elif "--check" in args:
		var actual: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://build_manifest.json"))
		var ok: bool = actual is Dictionary and actual.size() == expected.size()
		if ok:
			for key: String in expected:
				if not actual.has(key) or actual[key] != expected[key]: ok = false
		print("Manifest PASS" if ok else "Manifest mismatch: run --write after code changes")
		quit(0 if ok else 1)
	else: print("Use --write or --check"); quit(1)
