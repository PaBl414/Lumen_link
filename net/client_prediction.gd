class_name ClientPrediction
extends RefCounted
var player: WorldState.PlayerState
var pending: Array[InputCommand] = []
var predicted_tick: int = 0
var sector: int = -1
var offset: Vector2 = Vector2.ZERO
var config: GameConfig
var collision: CollisionWorld = CollisionWorld.new()
var resyncs: int = 0
var authoritative: WorldState.PlayerState
var authoritative_tick: int = 0
func configure(configuration: GameConfig, map: MapDefinition) -> void:
	config = configuration; collision.configure(map)
func reset() -> void:
	player = null; authoritative = null; pending.clear(); predicted_tick = 0; sector = -1; offset = Vector2.ZERO
func _step(command: InputCommand) -> void:
	for timer: String in ["dash_ticks","stun_ticks","invulnerable_ticks","dash_cooldown"]: player.set(timer,maxi(0,int(player.get(timer))-1))
	if player.mode == GameTypes.PlayerMode.DASH and player.dash_ticks == 0:
		player.mode = GameTypes.PlayerMode.NORMAL; player.velocity = player.velocity.limit_length(config.speed)
	if player.mode == GameTypes.PlayerMode.STUN and player.stun_ticks == 0: player.mode = GameTypes.PlayerMode.NORMAL
	var dash: bool = Simulation._new_serial(command.dash_serial,player.consumed_serials.x)
	var serials: Vector3i = Vector3i(command.dash_serial,command.anchor_serial,command.ping_serial)
	for i: int in range(3):
		if Simulation._new_serial(serials[i],player.consumed_serials[i]): player.consumed_serials[i] = serials[i]
	if dash: Movement.begin_dash(player,command,config)
	Movement.step(player,command,collision,config); predicted_tick = command.tick
func push(command: InputCommand) -> void:
	if player == null or command.tick<=predicted_tick: return
	if pending.size()>=256 or command.tick-predicted_tick>12:
		pending.clear(); resyncs += 1
		if authoritative != null: player = authoritative.copy(); predicted_tick = authoritative_tick; offset = Vector2.ZERO
		return
	while predicted_tick+1<command.tick:
		var neutral: InputCommand = InputCommand.new(); neutral.tick = predicted_tick+1
		neutral.dash_serial = player.consumed_serials.x; neutral.anchor_serial = player.consumed_serials.y; neutral.ping_serial = player.consumed_serials.z
		_step(neutral)
	pending.append(command.copy()); _step(command)
func reconcile(snapshot: GameSnapshot,slot: int) -> void:
	var old: Vector2 = player.position+offset if player != null else snapshot.players[slot].position
	var changed: bool = sector != snapshot.sector_index
	authoritative = snapshot.players[slot].copy(); authoritative_tick = snapshot.tick
	player = authoritative.copy(); predicted_tick = snapshot.tick; sector = snapshot.sector_index
	var replay: Array[InputCommand] = []
	if not changed:
		for command: InputCommand in pending:
			if command.tick>snapshot.tick: replay.append(command.copy())
	pending.clear()
	if replay.size()>256 or (not replay.is_empty() and replay.back().tick-snapshot.tick>12):
		resyncs += 1; replay.clear()
	for command: InputCommand in replay: push(command)
	var error: Vector2 = old-player.position
	offset = error if not changed and error.length()>2 and error.length()<=48 else Vector2.ZERO
func present(delta: float) -> WorldState.PlayerState:
	if player == null: return null
	offset *= exp(-maxf(0,delta)/0.08)
	var result: WorldState.PlayerState = player.copy(); result.position += offset
	return result
