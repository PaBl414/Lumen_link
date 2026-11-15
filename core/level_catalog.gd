class_name LevelCatalog
extends RefCounted
const MAX_LEVELS: int = 64
static var _default: LevelCatalog
var entries: Array[Dictionary] = []
static func valid_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length()>32: return false
	for i: int in range(value.length()):
		var ch: String = value[i]
		if not ((ch>="a" and ch<="z") or (i>0 and ((ch>="0" and ch<="9") or ch=="_"))): return false
	return true
static func from_json(value: Variant) -> GameTypes.Result:
	if not value is Dictionary or value.size()!=2 or value.get("schema_version")!=1 or not value.get("levels") is Array or value.levels.is_empty() or value.levels.size()>MAX_LEVELS: return GameTypes.Result.new(false,1,"catalog: invalid schema/count")
	var catalog: LevelCatalog = LevelCatalog.new(); var seen: Dictionary = {}
	for row: Variant in value.levels:
		if not row is Dictionary or row.size()!=5 or not valid_id(row.get("id")) or seen.has(row.id) or not row.get("name") is String or row.name.is_empty() or row.name.length()>64 or row.get("theme") not in ["dock","garden","reactor"] or not row.get("tint") is String or not Color.html_is_valid(row.tint) or not row.get("motif") is String: return GameTypes.Result.new(false,1,"catalog: invalid entry")
		seen[row.id] = true; catalog.entries.append(row.duplicate(true))
	return GameTypes.Result.new(true,0,"",catalog)
static func current() -> LevelCatalog:
	if _default==null:
		var parsed: GameTypes.Result = from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json")))
		if parsed.ok: _default = parsed.value
		else: push_error(parsed.message); _default = LevelCatalog.new()
	return _default
func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Dictionary in entries: result.append(StringName(entry.id))
	return result
func count() -> int: return entries.size()
func index_of(id: StringName) -> int: return ids().find(id)
func has_level(id: StringName) -> bool: return index_of(id)>=0
func entry(id: StringName) -> Dictionary:
	var index: int = index_of(id)
	return entries[index].duplicate(true) if index>=0 else {}
func first_id() -> StringName: return StringName(entries[0].id) if not entries.is_empty() else &""
func next_id(id: StringName) -> StringName:
	var index: int = index_of(id)
	return StringName(entries[index+1].id) if index>=0 and index+1<count() else &""
