class_name GameSnapshot
extends RefCounted
const World = preload("res://core/world_state.gd")
# Only wire fields: host-only histories never escape into the view.
const SCALARS: Array[String] = ["tick", "sector_tick", "remaining_ticks", "phase_remaining", "integrity", "sector_index", "phase", "objective_index", "active_socket", "link_status", "extract_ticks", "socket_cooldown", "damage_cooldown", "score", "complete_mask", "last_event_id", "latched_mask", "level_id", "obstacle_active_mask", "obstacle_warning_mask"]
var tick: int = 0
var sector_tick: int = 0
var remaining_ticks: int = 0
var phase_remaining: int = 0
var integrity: int = 0
var sector_index: int = 0
var level_id: StringName = &"dock"
var obstacle_active_mask: int = 0
var obstacle_warning_mask: int = 0
var phase: int = 0
var objective_index: int = 0
var latched_mask: int = 0
var active_socket: int = 0
var link_status: int = 0
var extract_ticks: int = 0
var socket_cooldown: int = 0
var damage_cooldown: int = 0
var score: int = 0
var complete_mask: int = 0
var last_event_id: int = 0
var players: Array[World.PlayerState] = []
var charges: PackedInt32Array = PackedInt32Array()

static func capture(world: World) -> GameSnapshot:
	var snapshot: GameSnapshot = GameSnapshot.new()
	for field: String in SCALARS:
		snapshot.set(field, world.get(field))
	snapshot.charges = world.charges.duplicate()
	for player: World.PlayerState in world.players:
		snapshot.players.append(player.copy())
	return snapshot

func copy() -> GameSnapshot:
	var snapshot: GameSnapshot = GameSnapshot.new()
	for field: String in SCALARS:
		snapshot.set(field, get(field))
	snapshot.charges = charges.duplicate()
	for player: World.PlayerState in players:
		snapshot.players.append(player.copy())
	return snapshot

func validate(map: MapDefinition, config: GameConfig) -> GameTypes.Result:
	if players.size() != 2 or charges.size() != 3 or tick < 0 or tick > 0xffffffff:
		return GameTypes.Result.new(false, GameTypes.ErrorCode.INVALID_DATA, "snapshot counts/tick")
	if level_id!=map.id or sector_index<0 or sector_index>=LevelCatalog.MAX_LEVELS: return GameTypes.Result.new(false,1,"snapshot level ID")
	var allowed: int = (1<<map.obstacles.size())-1
	if obstacle_active_mask<0 or obstacle_warning_mask<0 or obstacle_active_mask & ~allowed or obstacle_warning_mask & ~allowed or obstacle_active_mask&obstacle_warning_mask: return GameTypes.Result.new(false,1,"snapshot obstacle masks")
	if phase==GameTypes.MatchPhase.WON and (objective_index!=3 or complete_mask!=7 or extract_ticks!=120 or integrity<=0 or charges!=PackedInt32Array([300,300,300])): return GameTypes.Result.new(false,1,"snapshot unconfirmed victory")
	if active_socket < -1 or active_socket>=map.sockets.size(): return GameTypes.Result.new(false,1,"snapshot socket index")
	if latched_mask<0 or latched_mask>7: return GameTypes.Result.new(false,1,"snapshot latch mask")
	for i: int in range(3):
		if map.objective_rule(i).stabilization.size()==2 and charges[i]>=150 and not latched_mask&(1<<i): return GameTypes.Result.new(false,1,"snapshot missing latch")
		if latched_mask & (1<<i) and (map.objective_rule(i).stabilization.size()!=2 or charges[i]<150): return GameTypes.Result.new(false,1,"snapshot latch inconsistent")
	for p: World.PlayerState in players:
		if not p.position.is_finite() or not p.velocity.is_finite() or not p.facing.is_finite() or absf(p.facing.length() - 1) > 0.01 or p.velocity.length() > 721 or not map.bounds.grow(-11.99).has_point(p.position):
			return GameTypes.Result.new(false, GameTypes.ErrorCode.INVALID_DATA, "snapshot player vector")
		if p.mode < 0 or p.mode > 2 or p.dash_ticks < 0 or p.dash_ticks > config.dash_ticks or p.dash_cooldown < 0 or p.dash_cooldown > 90 or p.stun_ticks < 0 or p.stun_ticks > 12 or p.invulnerable_ticks < 0 or p.invulnerable_ticks > 90:
			return GameTypes.Result.new(false, GameTypes.ErrorCode.INVALID_DATA, "snapshot player timers/mode")
	return GameTypes.Result.new(true, 0, "")
