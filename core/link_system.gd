class_name LinkSystem
extends RefCounted
func find_socket(position: Vector2, map: MapDefinition) -> int:
	var best: int = -1
	var distance: float = 44.0
	for i: int in range(map.sockets.size()):
		var candidate: float = position.distance_to(map.sockets[i])
		if candidate <= distance and (best == -1 or candidate < distance):
			best = i; distance = candidate
	return best
func evaluate(players: Array[WorldState.PlayerState], socket_id: int, map: MapDefinition, collision: CollisionWorld,tick: int = 0,difficulty: int = 0,variant: int = 0) -> GameTypes.LinkResult:
	var result: GameTypes.LinkResult = GameTypes.LinkResult.new()
	result.points.append(players[0].position)
	if socket_id >= 0: result.points.append(map.sockets[socket_id])
	result.points.append(players[1].position)
	var blocked: bool = false
	var shuttered: bool = false
	var masks: Vector2i = ObstacleSystem.masks(map,tick,difficulty,variant)
	for i: int in range(result.points.size()-1):
		result.length += result.points[i].distance_to(result.points[i+1])
		var contact: Vector2 = collision.first_block(result.points[i],result.points[i+1],3)
		if not blocked and contact.is_finite():
			result.blocked_point = contact; result.blocked_segment = i
		blocked = blocked or contact.is_finite()
	for obstacle: MapDefinition.ObstacleDef in map.obstacles:
		if obstacle.type!="SHUTTER" or not masks.x&(1<<obstacle.id): continue
		for i: int in range(result.points.size()-1):
			var a: Vector2 = result.points[i]; var b: Vector2 = result.points[i+1]; var rect: Rect2 = obstacle.rect.grow(3)
			var hit: Vector3 = CollisionWorld._sweep_aabb(a,b-a,rect)
			if rect.has_point(a) or hit.x<=1:
				if not blocked and not shuttered: result.blocked_segment = i; result.blocked_point = a if rect.has_point(a) else a.lerp(b,hit.x)
				shuttered = true
	result.status = GameTypes.LinkStatus.ACTIVE
	if ObstacleSystem.jams(players,map,masks.x): result.status = GameTypes.LinkStatus.JAMMED
	elif players[0].mode != 0 or players[1].mode != 0: result.status = GameTypes.LinkStatus.PLAYER_BUSY
	elif result.length < 56: result.status = GameTypes.LinkStatus.TOO_SHORT
	elif result.length > 720: result.status = GameTypes.LinkStatus.TOO_LONG
	elif blocked: result.status = GameTypes.LinkStatus.OCCLUDED
	elif shuttered: result.status = GameTypes.LinkStatus.SHUTTERED
	return result
func hits_beacon(link: GameTypes.LinkResult, center: Vector2) -> bool:
	if link.status != GameTypes.LinkStatus.ACTIVE: return false
	var along: float = 0
	for i: int in range(link.points.size()-1):
		var a: Vector2 = link.points[i]
		var b: Vector2 = link.points[i+1]
		var length: float = a.distance_to(b)
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(center,a,b)
		var distance: float = along + a.distance_to(closest)
		if closest.distance_to(center) <= 25 and distance >= 48 and link.length-distance >= 48: return true
		along += length
	return false
