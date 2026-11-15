class_name GameEvent
extends RefCounted
enum EventType { DASH, SOCKET, HIT, BEACON, PING, SECTOR_END, MATCH_END }
var id: int = 0
var tick: int = 0
var type: int = EventType.DASH
var player_id: int = 0
var object_id: int = 255
var value: int = 0
var position: Vector2 = Vector2.ZERO
func copy() -> GameEvent:
	var event: GameEvent = GameEvent.new()
	for field: String in ["id", "tick", "type", "player_id", "object_id", "value", "position"]:
		event.set(field, get(field))
	return event
