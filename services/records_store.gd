class_name RecordsStore
extends RefCounted
const Store = preload("res://services/settings_store.gd")
var path: String = "user://records.json"
var records: Array[GameTypes.RecordData] = []
var warning: String = ""
const FIELDS: Array[String] = ["seed","difficulty","score","duration_ticks","integrity","date_utc"]

func _decode(data: Variant) -> GameTypes.RecordData:
	if not data is Dictionary or data.size() != FIELDS.size(): return null
	for field: String in FIELDS:
		if not data.has(field): return null
		if field == "date_utc":
			if not data[field] is String or data[field].length() > 40: return null
		else:
			var value: Variant = data[field]
			if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 0xffffffff or value != floor(value): return null
	if int(data.difficulty) not in [0,1] or data.integrity > 9: return null
	var record: GameTypes.RecordData = GameTypes.RecordData.new()
	for field: String in FIELDS: record.set(field, data[field] if field == "date_utc" else int(data[field]))
	return record

func _encode(record: GameTypes.RecordData) -> Dictionary:
	var data: Dictionary = {}
	for field: String in FIELDS: data[field] = record.get(field)
	return data

func load_records() -> void:
	records.clear(); warning = ""
	if not FileAccess.file_exists(path): return
	var file: FileAccess = FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > 131072:
		warning = "records: unreadable/oversized"; return
	var parser: JSON = JSON.new()
	var parsed: Error = parser.parse(file.get_as_text()); file.close()
	var data: Variant = parser.data if parsed == OK else null
	if not data is Dictionary or data.get("schema_version") != 1 or not data.get("records") is Array or data.records.size() > 100:
		warning = "records: invalid schema; empty fallback"; return
	for entry: Variant in data.records:
		var record: GameTypes.RecordData = _decode(entry)
		if record == null:
			records.clear(); warning = "records: invalid entry; empty fallback"; return
		records.append(record)
	_sort()

func _sort() -> void:
	records.sort_custom(func(a: GameTypes.RecordData,b: GameTypes.RecordData) -> bool: return a.score > b.score or (a.score == b.score and a.duration_ticks < b.duration_ticks))

func submit(record: GameTypes.RecordData) -> GameTypes.Result:
	var copied: GameTypes.RecordData = _decode(_encode(record))
	if copied == null: return GameTypes.Result.new(false,1,"records: invalid record")
	var old: Array[GameTypes.RecordData] = records.duplicate()
	records.append(copied); _sort()
	if records.size() > 100: records.resize(100)
	var entries: Array = []
	for item: GameTypes.RecordData in records: entries.append(_encode(item))
	var result: GameTypes.Result = Store.atomic_write(path,JSON.stringify({"schema_version":1,"records":entries}))
	if not result.ok: records = old
	return result

func best(difficulty: int) -> GameTypes.RecordData:
	for record: GameTypes.RecordData in records:
		if record.difficulty == difficulty: return _decode(_encode(record))
	return null
