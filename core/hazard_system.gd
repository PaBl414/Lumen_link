class_name HazardSystem
extends RefCounted
var segment_times: Array = []

func phase_at(h: MapDefinition.HazardDef, tick: int, difficulty: int, variant: int) -> Dictionary:
	var pulse: bool = h.type == "PULSE"
	var times: Array = ([180,60,60,0] if difficulty == 0 else [240,90,30,0]) if pulse else ([60,90,180,30] if difficulty == 0 else [120,120,120,60])
	var period: int = 300 if pulse else 360
	var actual: int = 360 if pulse else 420
	if difficulty == 0: actual = period
	var absolute: int = tick + int(floor(float(h.offset) * actual / period)) + 37 * variant
	var phase_tick: int = posmod(absolute,actual)
	var phase: int = 0
	var local: int = phase_tick
	while phase < 3 and local >= times[phase]:
		local -= times[phase]; phase += 1
	var progress: float = clampf(float(local) / maxf(1,times[2]-1),0,1) if phase == 2 else 0.0
	if int(floor(float(absolute)/actual)) % 2 != 0: progress = 1-progress
	return {"phase":phase,"offset":h.travel*progress,"period":actual}

func hits(h: MapDefinition.HazardDef, path: Array[Vector4], tick: int, difficulty: int, variant: int, times: Array[Vector2] = []) -> bool:
	var current: Dictionary = phase_at(h,tick,difficulty,variant)
	if current.phase != 2: return false
	var index: int = -1
	for segment: Vector4 in path:
		index += 1
		var a: Vector2 = Vector2(segment.x,segment.y)
		var b: Vector2 = Vector2(segment.z,segment.w)
		if h.type == "PULSE":
			# Rounded rectangle = two strips plus four corner disks; exact swept square/circle.
			for rect: Rect2 in [Rect2(h.a-Vector2(12+h.radius,12),Vector2(24+2*h.radius,24)),Rect2(h.a-Vector2(12,12+h.radius),Vector2(24,24+2*h.radius))]:
				if _segment_rect(a,b,rect): return true
			for corner: Vector2 in [Vector2(-12,-12),Vector2(-12,12),Vector2(12,-12),Vector2(12,12)]:
				var center: Vector2 = h.a+corner
				if center.distance_to(Geometry2D.get_closest_point_to_segment(center,a,b)) <= h.radius: return true
		else:
			var previous: Dictionary = phase_at(h,maxi(0,tick-1),difficulty,variant)
			var old_offset: Vector2 = previous.offset if previous.phase == 2 else current.offset
			var rect: Rect2 = Rect2(h.a,Vector2.ZERO).expand(h.b).grow(17)
			var interval: Vector2 = times[index] if index < times.size() else Vector2(0,1)
			if _segment_rect(a-old_offset.lerp(current.offset,interval.x),b-old_offset.lerp(current.offset,interval.y),rect): return true
	return false

func _segment_rect(a: Vector2,b: Vector2,rect: Rect2) -> bool:
	return (a.x >= rect.position.x and a.x <= rect.end.x and a.y >= rect.position.y and a.y <= rect.end.y) or CollisionWorld._sweep_aabb(a,b-a,rect).x <= 1

func apply(world: WorldState, paths: Array, map: MapDefinition, _config: GameConfig, events: Array[GameEvent]) -> void:
	for slot: int in range(2):
		var p: WorldState.PlayerState = world.players[slot]
		if p.mode == GameTypes.PlayerMode.DASH or p.invulnerable_ticks > 0: continue
		for h: MapDefinition.HazardDef in map.hazards:
			if hits(h,paths[slot],world.sector_tick,world.difficulty,world.variant,segment_times[slot] if segment_times.size() == 2 else []):
				if world.damage_cooldown == 0:
					world.integrity -= 1; world.damage_cooldown = 30
				p.mode = GameTypes.PlayerMode.STUN; p.stun_ticks = 12; p.invulnerable_ticks = 90; p.velocity = Vector2.ZERO
				var event: GameEvent = GameEvent.new()
				event.type = GameEvent.EventType.HIT; event.tick = world.tick; event.player_id = slot; event.value = world.integrity
				events.append(event)
				break
