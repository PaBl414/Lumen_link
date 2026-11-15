class_name MapDefinition
extends RefCounted
const Types = preload("res://core/game_types.gd")
const Config = preload("res://core/game_config.gd")

class ObjectiveDef extends RefCounted:
	var hint: String = "Przeprowadź przewód przez cel."
	var stabilization: Array[PackedVector2Array] = []

class ObstacleDef extends RefCounted:
	var id: int
	var type: String
	var rect: Rect2
	var normal: PackedInt32Array
	var relaxed: PackedInt32Array
	var offset: int

class HazardDef extends RefCounted:
	var id: int
	var type: String
	var a: Vector2
	var b: Vector2
	var travel: Vector2
	var radius: float
	var offset: int

var id: StringName
var bounds: Rect2
var walls: Array[Rect2] = []
var spawns: Array[Vector2] = []
var beacons: Array[Vector2] = []
var sockets: Array[Vector2] = []
var hazards: Array[HazardDef] = []
var exit_position: Vector2
var background_asset: String
var objectives: Array[ObjectiveDef] = []
var obstacles: Array[ObstacleDef] = []

func objective_rule(index: int) -> ObjectiveDef:
	return objectives[index] if index>=0 and index<objectives.size() else ObjectiveDef.new()

static func _error(path: String) -> Types.Result:
	return Types.Result.new(false, Types.ErrorCode.INVALID_DATA, "map." + path)

static func _keys(d: Variant, keys: Array) -> bool:
	if not d is Dictionary or d.size() != keys.size():
		return false
	for key: String in keys:
		if not d.has(key):
			return false
	return true

static func _numbers(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count:
		return false
	for n: Variant in value:
		if not (n is int or n is float) or not is_finite(float(n)):
			return false
	return true

static func _v(a: Array) -> Vector2:
	return Vector2(a[0], a[1])

static func from_json(d: Dictionary) -> Types.Result:
	var schema_keys: Array = ["schema_version", "id", "bounds", "spawns", "walls", "beacons", "sockets", "exit", "hazards", "background_asset"]
	if d.get("schema_version")==2 or d.get("schema_version")==3: schema_keys.append("objectives")
	if d.get("schema_version")==3: schema_keys.append("obstacles")
	if not _keys(d, schema_keys) or (d.schema_version!=1 and d.schema_version!=2 and d.schema_version!=3):
		return _error("schema: invalid keys/version")
	if not d.id is String or d.id.is_empty() or not d.background_asset is String or d.background_asset.is_empty():
		return _error("id/background_asset: required nonempty string")
	if not _numbers(d.bounds, 4) or Rect2(d.bounds[0], d.bounds[1], d.bounds[2], d.bounds[3]) != Rect2(32, 88, 1216, 600):
		return _error("bounds: expected [32,88,1216,600]")
	var map: MapDefinition = MapDefinition.new()
	map.id = d.id
	map.background_asset = d.background_asset
	map.bounds = Rect2(32, 88, 1216, 600)
	for group: String in ["spawns", "walls", "beacons", "sockets", "hazards"]:
		if not d[group] is Array:
			return _error(group + ": expected array")
	if d.spawns.size() != 2 or d.walls.size() > 32 or d.hazards.size() > 8 or d.beacons.size() != 3 or (d.sockets.size()<1 or d.sockets.size()>3):
		return _error("counts: expected 2 spawns, 3 beacons, 1..3 sockets, <=32 walls, <=8 hazards")
	for spawn: Variant in d.spawns:
		if not _numbers(spawn, 2):
			return _error("spawns: finite vector required")
		map.spawns.append(_v(spawn))
	for group: String in ["walls", "beacons", "sockets", "hazards"]:
		var entries: Array = d[group].duplicate(true)
		var ids: Array[int] = []
		for entry: Variant in entries:
			if not entry is Dictionary or not entry.has("id") or not (entry.id is float or entry.id is int):
				return _error(group + ": missing numeric id")
			var n: float = entry.id
			var cap: int = 32 if group == "walls" else (8 if group == "hazards" else 3)
			if not is_finite(n) or n != floor(n) or n < 0 or n >= cap or int(n) in ids:
				return _error(group + ": invalid/duplicate id")
			ids.append(int(n))
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
		for e: Dictionary in entries:
			if group == "walls":
				if not _keys(e, ["id", "rect"]) or not _numbers(e.rect, 4) or e.rect[2] <= 0 or e.rect[3] <= 0:
					return _error("walls.rect: invalid rectangle")
				map.walls.append(Rect2(e.rect[0], e.rect[1], e.rect[2], e.rect[3]))
			elif group != "hazards":
				if not _keys(e, ["id", "position"]) or not _numbers(e.position, 2):
					return _error(group + ".position: invalid vector")
				if group == "beacons": map.beacons.append(_v(e.position))
				else: map.sockets.append(_v(e.position))
			else:
				if not e.has("type") or e.type not in ["PULSE", "SWEEP"]:
					return _error("hazards.type: unknown")
				var keys: Array = ["id", "type", "a", "phase_offset"] + (["radius"] if e.type == "PULSE" else ["b", "travel"])
				if not _keys(e, keys) or not _numbers(e.a, 2) or not (e.phase_offset is float or e.phase_offset is int) or not is_finite(float(e.phase_offset)) or e.phase_offset < 0 or e.phase_offset != floor(e.phase_offset):
					return _error("hazards: schema/vector/offset")
				var h: HazardDef = HazardDef.new()
				h.id = int(e.id); h.type = e.type; h.a = _v(e.a); h.offset = int(e.phase_offset)
				if h.type == "PULSE":
					if not (e.radius is float or e.radius is int) or e.radius != 48:
						return _error("hazards.radius: expected 48")
					h.radius = e.radius
				else:
					if not _numbers(e.b, 2) or not _numbers(e.travel, 2): return _error("hazards: invalid b/travel")
					h.b = _v(e.b); h.travel = _v(e.travel)
					if h.a == h.b or not ((h.a.x == h.b.x and h.travel.y == 0 and h.travel.x != 0) or (h.a.y == h.b.y and h.travel.x == 0 and h.travel.y != 0)):
						return _error("hazards: sweep must be perpendicular and axis aligned")
				map.hazards.append(h)
	if not _keys(d.exit, ["position", "radius"]) or not _numbers(d.exit.position, 2) or d.exit.radius != 64:
		return _error("exit: invalid schema/position/radius")
	map.exit_position = _v(d.exit.position)
	if d.schema_version>=2:
		if not d.objectives is Array or d.objectives.size()!=3: return _error("objectives: expected three rules")
		for i: int in range(3):
			var rule: Variant = d.objectives[i]
			if not _keys(rule,["id","hint","stabilization"]) or rule.id!=i or not rule.hint is String or rule.hint.is_empty() or rule.hint.length()>160 or not rule.stabilization is Array or rule.stabilization.size()>2:
				return _error("objectives: invalid rule")
			var definition: ObjectiveDef = ObjectiveDef.new(); definition.hint = rule.hint
			for pair: Variant in rule.stabilization:
				if not pair is Array or pair.size()!=2 or not _numbers(pair[0],2) or not _numbers(pair[1],2): return _error("stabilization: expected pairs of finite vectors")
				definition.stabilization.append(PackedVector2Array([_v(pair[0]),_v(pair[1])]))
			map.objectives.append(definition)
	if d.schema_version==3:
		if not d.obstacles is Array or d.obstacles.size()>16: return _error("obstacles: invalid count")
		for i: int in range(d.obstacles.size()):
			var row: Variant = d.obstacles[i]
			if not _keys(row,["id","type","rect","normal","relaxed","phase_offset"]) or row.id!=i or row.type not in ["SHUTTER","JAM"] or not _numbers(row.rect,4) or row.rect[2]<=0 or row.rect[3]<=0 or not _numbers(row.normal,3) or not _numbers(row.relaxed,3) or not (row.phase_offset is int or row.phase_offset is float) or not is_finite(float(row.phase_offset)) or row.phase_offset<0 or row.phase_offset>0xffffffff or row.phase_offset!=floor(row.phase_offset): return _error("obstacles: invalid data")
			for schedule: Array in [row.normal,row.relaxed]:
				for duration: Variant in schedule:
					if duration!=floor(duration) or duration<1 or duration>3600: return _error("obstacles: invalid cycle")
				if schedule[1]<30: return _error("obstacles: warning must be >=30 ticks")
			var obstacle: ObstacleDef = ObstacleDef.new(); obstacle.id = i; obstacle.type = row.type; obstacle.rect = Rect2(row.rect[0],row.rect[1],row.rect[2],row.rect[3]); obstacle.normal = PackedInt32Array(row.normal); obstacle.relaxed = PackedInt32Array(row.relaxed); obstacle.offset = int(row.phase_offset); map.obstacles.append(obstacle)
	return Types.Result.new(true, 0, "", map)

func validate(config: Config) -> Types.Result:
	if not config.validate().ok: return _error("config: invalid")
	var safe_spawn: Rect2 = Rect2(64, 536, 176, 112)
	if exit_position != Vector2(1168, 592): return _error("exit.position: expected (1168,592)")
	for i: int in range(walls.size()):
		var wall: Rect2 = walls[i]
		if not bounds.encloses(wall) or wall.intersects(safe_spawn, true) or _circle_rect(exit_position, 96, wall):
			return _error("walls[%d]: bounds/safe zone" % i)
		for j: int in range(i):
			if wall.intersects(walls[j]): return _error("walls[%d]: overlapping wall" % i)
	for point: Vector2 in spawns + sockets + beacons:
		if not bounds.grow(-12).has_point(point): return _error("position outside playable bounds")
		for wall: Rect2 in walls:
			if wall.grow(12).has_point(point): return _error("spawn/socket/beacon inside wall")
	for h: HazardDef in hazards:
		var area: Rect2
		if h.type == "PULSE":
			area = Rect2(h.a - Vector2.ONE * h.radius, Vector2.ONE * h.radius * 2)
		else:
			area = Rect2(h.a, Vector2.ZERO).expand(h.b).expand(h.a + h.travel).expand(h.b + h.travel).grow(5)
		if not bounds.encloses(area) or _circle_rect(exit_position, 96, area) or area.intersects(safe_spawn, true):
			return _error("hazards[%d]: bounds/safe zone" % h.id)
	for obstacle: ObstacleDef in obstacles:
		if not bounds.encloses(obstacle.rect) or obstacle.rect.intersects(safe_spawn,true) or _circle_rect(exit_position,80,obstacle.rect): return _error("obstacle: bounds/safe zone")
	if not objectives.is_empty() and objectives.size()!=3: return _error("objectives: count")
	for rule: ObjectiveDef in objectives:
		for pair: PackedVector2Array in rule.stabilization:
			if pair.size()!=2 or pair[0].distance_to(pair[1])<160: return _error("stabilization: centers must be >=160 apart")
			for point: Vector2 in pair:
				if not bounds.grow(-44).has_point(point): return _error("stabilization: field outside bounds")
				for wall: Rect2 in walls:
					if _circle_rect(point,44,wall): return _error("stabilization: field intersects wall")
	if not _reachable(): return _error("sockets/exit: unreachable from spawn")
	return Types.Result.new(true, 0, "", self)

static func _circle_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	return center.distance_squared_to(center.clamp(rect.position, rect.end)) <= radius * radius

func _reachable() -> bool:
	# 8-unit grid; both starts must reach every socket and the exit.
	for spawn: Vector2 in spawns:
		var queue: Array[Vector2i] = [Vector2i((spawn - bounds.position) / 8)]
		var seen: Dictionary = {queue[0]: true}
		var cursor: int = 0
		while cursor < queue.size():
			var cell: Vector2i = queue[cursor]; cursor += 1
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = cell + step
				if seen.has(next): continue
				var point: Vector2 = bounds.position + Vector2(next) * 8
				if not bounds.grow(-12).has_point(point): continue
				var blocked: bool = false
				for wall: Rect2 in walls:
					if wall.grow(12).has_point(point): blocked = true; break
				if not blocked: seen[next] = true; queue.append(next)
		var goals: Array[Vector2] = sockets.duplicate(); goals.append(exit_position)
		for rule: ObjectiveDef in objectives:
			for pair: PackedVector2Array in rule.stabilization:
				for point: Vector2 in pair: goals.append(point)
		for goal: Vector2 in goals:
			if not seen.has(Vector2i((goal - bounds.position) / 8)): return false
	return true
