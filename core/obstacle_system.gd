class_name ObstacleSystem
extends RefCounted
static func phase_at(obstacle: MapDefinition.ObstacleDef,tick: int,difficulty: int,variant: int) -> Dictionary:
	var times: PackedInt32Array = obstacle.normal if difficulty==0 else obstacle.relaxed
	var period: int = times[0]+times[1]+times[2]
	var base_period: int = obstacle.normal[0]+obstacle.normal[1]+obstacle.normal[2]
	var phase_tick: int = posmod(tick+int(floor(float(obstacle.offset)*period/base_period))+37*variant,period)
	var phase: int = 0 if phase_tick<times[0] else (1 if phase_tick<times[0]+times[1] else 2)
	var end: int = times[0] if phase==0 else (times[0]+times[1] if phase==1 else period)
	return {"phase":phase,"remaining":end-phase_tick,"period":period}
static func masks(map: MapDefinition,tick: int,difficulty: int,variant: int) -> Vector2i:
	var result: Vector2i = Vector2i.ZERO
	for obstacle: MapDefinition.ObstacleDef in map.obstacles:
		var phase: int = phase_at(obstacle,tick,difficulty,variant).phase
		if phase==2: result.x |= 1<<obstacle.id
		elif phase==1: result.y |= 1<<obstacle.id
	return result
static func jams(players: Array[WorldState.PlayerState],map: MapDefinition,active_mask: int) -> bool:
	for obstacle: MapDefinition.ObstacleDef in map.obstacles:
		if obstacle.type!="JAM" or not active_mask&(1<<obstacle.id): continue
		var rect: Rect2 = obstacle.rect.grow(12)
		for player: WorldState.PlayerState in players:
			if player.position.x>=rect.position.x and player.position.x<=rect.end.x and player.position.y>=rect.position.y and player.position.y<=rect.end.y: return true
	return false
