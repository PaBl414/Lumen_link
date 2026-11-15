class_name SnapshotBuffer
extends RefCounted
var snapshots: Array[GameSnapshot] = []
var sector: int = -1
var collision: CollisionWorld = CollisionWorld.new()
func reset() -> void:
	snapshots.clear(); sector = -1
func insert(snapshot: GameSnapshot) -> void:
	if sector != snapshot.sector_index: reset(); sector = snapshot.sector_index
	for stored: GameSnapshot in snapshots:
		if stored.tick == snapshot.tick: return
	snapshots.append(snapshot.copy()); snapshots.sort_custom(func(a: GameSnapshot,b: GameSnapshot) -> bool: return a.tick<b.tick)
	while snapshots.size()>32: snapshots.pop_front()
func sample(tick: float,slot: int) -> WorldState.PlayerState:
	if snapshots.is_empty(): return null
	var before: GameSnapshot = snapshots[0]
	for after: GameSnapshot in snapshots:
		if after.tick>tick:
			var result: WorldState.PlayerState = before.players[slot].copy()
			var alpha: float = clampf((tick-before.tick)/maxf(1,after.tick-before.tick),0,1)
			result.position = result.position.lerp(after.players[slot].position,alpha)
			result.velocity = result.velocity.lerp(after.players[slot].velocity,alpha)
			return result
		before = after
	var result: WorldState.PlayerState = before.players[slot].copy()
	var ahead: float = clampf(tick-before.tick,0,6)
	if ahead>0:
		var moved: GameTypes.MoveResult = collision.move(result.position,result.velocity,ahead/60.0)
		result.position = moved.position; result.velocity = moved.velocity
	return result
