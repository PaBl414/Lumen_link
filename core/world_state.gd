class_name WorldState
extends RefCounted
const Types = preload("res://core/game_types.gd")
class PlayerState extends RefCounted:
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var facing: Vector2 = Vector2.RIGHT
	var mode: int = Types.PlayerMode.NORMAL
	var dash_ticks: int = 0
	var stun_ticks: int = 0
	var invulnerable_ticks: int = 0
	var dash_cooldown: int = 0
	var consumed_serials: Vector3i = Vector3i.ZERO
	func copy() -> PlayerState:
		var p: PlayerState = PlayerState.new()
		for field: String in ["position", "velocity", "facing", "mode", "dash_ticks", "stun_ticks", "invulnerable_ticks", "dash_cooldown", "consumed_serials"]:
			p.set(field, get(field))
		return p

var tick: int = 0
var sector_tick: int = 0
var remaining_ticks: int = 0
var phase_remaining: int = 0
var phase: int = Types.MatchPhase.PLAYING
var sector_index: int = 0
var level_id: StringName = &"dock"
var obstacle_active_mask: int = 0
var obstacle_warning_mask: int = 0
var integrity: int = 6
var objective_index: int = 0
var latched_mask: int = 0
var active_socket: int = -1
var link_status: int = Types.LinkStatus.PLAYER_BUSY
var charges: PackedInt32Array = PackedInt32Array([0,0,0])
var extract_ticks: int = 0
var socket_cooldown: int = 0
var damage_cooldown: int = 0
var score: int = 0
var complete_mask: int = 0
var last_event_id: int = 0
var players: Array[PlayerState] = []
var last_power_ticks: PackedInt32Array = PackedInt32Array([0,0,0])
var difficulty: int = 0
var variant: int = 0
var objective_order: PackedInt32Array = PackedInt32Array([0,1,2])
var last_ping_ticks: PackedInt32Array = PackedInt32Array([-60,-60])
var completed_beacons_total: int = 0

func reset(map: MapDefinition, config: GameConfig, carry_integrity: int) -> void:
	tick = 0; sector_tick = 0; sector_index = maxi(0,LevelCatalog.current().index_of(map.id)); level_id = map.id
	obstacle_active_mask = 0; obstacle_warning_mask = 0
	phase = Types.MatchPhase.PLAYING
	phase_remaining = 0
	integrity = carry_integrity
	remaining_ticks = int(config.data.difficulties["NORMAL" if difficulty == 0 else "RELAXED"].sector_seconds) * 60
	latched_mask = 0
	objective_index = 0; active_socket = -1; link_status = Types.LinkStatus.PLAYER_BUSY
	charges = PackedInt32Array([0,0,0]); last_power_ticks = PackedInt32Array([0,0,0])
	extract_ticks = 0; socket_cooldown = 0; damage_cooldown = 0; score = 0
	complete_mask = 0; last_event_id = 0; completed_beacons_total = 0
	last_ping_ticks = PackedInt32Array([-60,-60])
	players.clear()
	for spawn: Vector2 in map.spawns:
		var player: PlayerState = PlayerState.new()
		player.position = spawn
		players.append(player)
