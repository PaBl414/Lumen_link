class_name CollisionWorld
extends RefCounted
const Types = preload("res://core/game_types.gd")

var walls: Array[Rect2] = []
var bounds: Rect2

func configure(map: RefCounted) -> void:
	walls.assign(map.walls)
	bounds = map.bounds
	# Four boundary rectangles use the same sweep as physical walls.
	walls.append(Rect2(bounds.position - Vector2(10000, 0), Vector2(10000, bounds.size.y)))
	walls.append(Rect2(Vector2(bounds.end.x, bounds.position.y), Vector2(10000, bounds.size.y)))
	walls.append(Rect2(bounds.position - Vector2(10000, 10000), Vector2(bounds.size.x + 20000, 10000)))
	walls.append(Rect2(Vector2(bounds.position.x - 10000, bounds.end.y), Vector2(bounds.size.x + 20000, 10000)))

# Returns (entry time, normal x, normal y); time=2 means no contact.
static func _sweep_aabb(p: Vector2, delta: Vector2, rect: Rect2) -> Vector3:
	var enter: float = -INF
	var leave: float = INF
	var normal: Vector2 = Vector2.ZERO
	for axis: int in range(2):
		if absf(delta[axis]) < 0.00000001:
			if p[axis] < rect.position[axis] or p[axis] > rect.end[axis]:
				return Vector3(2, 0, 0)
			continue
		var a: float = (rect.position[axis] - p[axis]) / delta[axis]
		var b: float = (rect.end[axis] - p[axis]) / delta[axis]
		var low: float = minf(a, b)
		if low > enter:
			enter = low
			normal = Vector2.ZERO
			normal[axis] = -signf(delta[axis])
		leave = minf(leave, maxf(a, b))
	if enter > leave or leave < 0 or enter > 1 or enter < -0.000001:
		return Vector3(2, 0, 0)
	return Vector3(maxf(0, enter), normal.x, normal.y)

func move(position: Vector2, velocity: Vector2, dt: float) -> Types.MoveResult:
	var result: Types.MoveResult = Types.MoveResult.new()
	result.position = _depenetrate_tiny(position)
	result.velocity = velocity
	var remaining: Vector2 = velocity * dt
	var elapsed: float = 0.0
	for iteration: int in range(3):
		if remaining.length_squared() < 0.0000000001:
			break
		var hit: Vector3 = Vector3(2, 0, 0)
		for wall: Rect2 in walls:
			var candidate: Vector3 = _sweep_aabb(result.position, remaining, wall.grow(12))
			# Stable X-before-Y even when wall array order changes.
			if candidate.x < hit.x or (is_equal_approx(candidate.x, hit.x) and absf(candidate.y) > absf(hit.y)):
				hit = candidate
		var start: Vector2 = result.position
		if hit.x > 1:
			result.position += remaining
			result.segments.append(Vector4(start.x, start.y, result.position.x, result.position.y))
			result.segment_times.append(Vector2(elapsed,1))
			break
		var normal: Vector2 = Vector2(hit.y, hit.z)
		result.position += remaining * hit.x + normal * 0.01
		result.segments.append(Vector4(start.x, start.y, result.position.x, result.position.y))
		var end_time: float = elapsed + (1-elapsed)*hit.x
		result.segment_times.append(Vector2(elapsed,end_time))
		elapsed = end_time
		remaining *= 1 - hit.x
		remaining -= normal * minf(0, remaining.dot(normal))
		result.velocity -= normal * minf(0, result.velocity.dot(normal))
	if not result.segment_times.is_empty() and result.segment_times[-1].y < 1:
		result.segments.append(Vector4(result.position.x,result.position.y,result.position.x,result.position.y))
		result.segment_times.append(Vector2(result.segment_times[-1].y,1))
	return result

func first_block(a: Vector2,b: Vector2,padding: float) -> Vector2:
	var earliest: float = 2.0
	for wall: Rect2 in walls:
		var rect: Rect2 = wall.grow(padding)
		if a.x>=rect.position.x and a.x<=rect.end.x and a.y>=rect.position.y and a.y<=rect.end.y: return a
		earliest = minf(earliest,_sweep_aabb(a,b-a,rect).x)
	return a.lerp(b,earliest) if earliest<=1 else Vector2.INF

func blocks_segment(a: Vector2, b: Vector2, padding: float) -> bool:
	return first_block(a,b,padding).is_finite()

func _depenetrate_tiny(position: Vector2) -> Vector2:
	var corrected: Vector2 = position
	for wall: Rect2 in walls:
		var rect: Rect2 = wall.grow(12)
		if not rect.has_point(corrected): continue
		var distances: Array[float] = [corrected.x - rect.position.x, rect.end.x - corrected.x, corrected.y - rect.position.y, rect.end.y - corrected.y]
		var index: int = 0
		for i: int in range(1,4):
			if distances[i] < distances[index]: index = i
		if distances[index] > 0 and distances[index] < 0.02:
			var normals: Array[Vector2] = [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]
			corrected += normals[index] * (distances[index] + 0.01)
	return corrected
