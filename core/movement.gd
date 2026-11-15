class_name Movement
extends RefCounted

static func begin_dash(player: WorldState.PlayerState, command: InputCommand, config: GameConfig) -> bool:
	if player.mode != GameTypes.PlayerMode.NORMAL or player.dash_cooldown > 0:
		return false
	var direction: Vector2 = command.axis()
	if not direction.is_zero_approx(): player.facing = direction.normalized()
	player.mode = GameTypes.PlayerMode.DASH
	player.dash_ticks = config.dash_ticks
	player.dash_cooldown = int(config.data.dash.cooldown_ticks)
	player.velocity = player.facing * float(config.data.dash.speed)
	return true

static func step(player: WorldState.PlayerState, command: InputCommand, collision: CollisionWorld, config: GameConfig) -> GameTypes.MoveResult:
	var axis: Vector2 = command.axis()
	if player.mode == GameTypes.PlayerMode.STUN:
		player.velocity = Vector2.ZERO
	elif player.mode == GameTypes.PlayerMode.DASH:
		player.velocity = player.facing * float(config.data.dash.speed)
	else:
		if not axis.is_zero_approx(): player.facing = axis.normalized()
		var acceleration: float = float(config.data.movement.deceleration if axis.is_zero_approx() else config.data.movement.acceleration)
		player.velocity = player.velocity.move_toward(axis * config.speed, acceleration * config.dt)
	var moved: GameTypes.MoveResult = collision.move(player.position, player.velocity, config.dt)
	player.position = moved.position
	player.velocity = moved.velocity
	return moved
