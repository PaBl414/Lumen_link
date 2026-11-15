class_name Simulation
extends RefCounted
const LinkSystem = preload("res://core/link_system.gd")
const HazardSystem = preload("res://core/hazard_system.gd")
const ObjectiveSystem = preload("res://core/objective_system.gd")
var world: WorldState
var config: GameConfig
var map: MapDefinition
var collision: CollisionWorld = CollisionWorld.new()
var seed: int = 0
var campaign_seed: int = 0
var difficulty: int = 0
var variant: int = 0

func initialize(configuration: GameConfig, definition: MapDefinition, expedition_seed: int, level: int) -> void:
	# Invalid data never creates an active world.
	world = null
	if not definition.validate(configuration).ok or level not in [0, 1]: return
	config = configuration; map = definition; seed = expedition_seed; campaign_seed = expedition_seed; difficulty = level
	variant = posmod(seed, 3)
	collision.configure(map)
	world = WorldState.new()
	world.difficulty = difficulty; world.variant = variant
	world.reset(map, config, int(config.data.difficulties["NORMAL" if level == 0 else "RELAXED"].integrity))
	world.objective_order = PackedInt32Array([0,1,2])
	var masks: Vector2i = ObstacleSystem.masks(map,0,difficulty,variant); world.obstacle_active_mask = masks.x; world.obstacle_warning_mask = masks.y

static func _new_serial(value: int, previous: int) -> bool:
	var difference: int = (value - previous) & 0xffff
	return difference > 0 and difference <= 64

func step(commands: Array[InputCommand]) -> Array[GameEvent]:
	var events: Array[GameEvent] = []
	if world == null or commands.size() != 2: return events
	if world.phase == GameTypes.MatchPhase.COUNTDOWN:
		world.tick += 1; world.phase_remaining = maxi(0,world.phase_remaining-1)
		if world.phase_remaining == 0: world.phase = GameTypes.MatchPhase.PLAYING
		return events
	if world.phase != GameTypes.MatchPhase.PLAYING: return events
	world.tick += 1
	world.sector_tick += 1
	world.socket_cooldown = maxi(0,world.socket_cooldown-1)
	world.damage_cooldown = maxi(0,world.damage_cooldown-1)
	var paths: Array = []
	var times: Array = []
	_advance_timers()
	_consume_actions(commands, events)
	for slot: int in range(2):
		var p: WorldState.PlayerState = world.players[slot]
		var command: InputCommand = commands[slot]
		var serials: Vector3i = Vector3i(command.dash_serial, command.anchor_serial, command.ping_serial)
		var dash_edge: bool = _new_serial(serials.x, p.consumed_serials.x)
		for index: int in range(3):
			if _new_serial(serials[index], p.consumed_serials[index]): p.consumed_serials[index] = serials[index]
		if dash_edge and Movement.begin_dash(p, command, config):
			var event: GameEvent = GameEvent.new()
			event.tick = world.tick; event.player_id = slot; event.position = p.position; event.value = command.dash_serial
			events.append(event)
		var moved: GameTypes.MoveResult = Movement.step(p, command, collision, config)
		if moved.segments.is_empty():
			moved.segments.append(Vector4(p.position.x,p.position.y,p.position.x,p.position.y))
			moved.segment_times.append(Vector2(0,1))
		paths.append(moved.segments)
		times.append(moved.segment_times)
	var hazards: HazardSystem = HazardSystem.new()
	hazards.segment_times = times
	hazards.apply(world,paths,map,config,events)
	if world.integrity <= 0:
		world.phase = GameTypes.MatchPhase.FAILED
		world.score = ObjectiveSystem.new().final_score(world)
		var ended: GameEvent = GameEvent.new(); ended.type = GameEvent.EventType.MATCH_END; ended.tick = world.tick
		events.append(ended)
		for event: GameEvent in events:
			if event.id == 0: world.last_event_id += 1; event.id = world.last_event_id
		return events
	var link: GameTypes.LinkResult = LinkSystem.new().evaluate(world.players,world.active_socket,map,collision,world.sector_tick,world.difficulty,world.variant)
	world.link_status = link.status
	var masks: Vector2i = ObstacleSystem.masks(map,world.sector_tick,world.difficulty,world.variant); world.obstacle_active_mask = masks.x; world.obstacle_warning_mask = masks.y
	ObjectiveSystem.new().step(world,link,map,config,events)
	_resolve_phase(events)
	for event: GameEvent in events:
		if event.id == 0:
			world.last_event_id += 1; event.id = world.last_event_id
	return events

func _consume_actions(commands: Array[InputCommand], events: Array[GameEvent]) -> void:
	var first: int = world.tick % 2
	for slot: int in [first,1-first]:
		var player: WorldState.PlayerState = world.players[slot]
		if _new_serial(commands[slot].ping_serial,player.consumed_serials.z) and player.mode != GameTypes.PlayerMode.STUN and world.tick-world.last_ping_ticks[slot] >= 60:
			world.last_ping_ticks[slot] = world.tick
			var ping: GameEvent = GameEvent.new(); ping.type = GameEvent.EventType.PING; ping.player_id = slot; ping.position = player.position; ping.tick = world.tick
			events.append(ping)
		if _new_serial(commands[slot].anchor_serial,player.consumed_serials.y) and player.mode != GameTypes.PlayerMode.STUN and world.socket_cooldown == 0:
			var socket: int = LinkSystem.new().find_socket(player.position,map)
			if socket >= 0:
				world.active_socket = -1 if world.active_socket == socket else socket
				world.socket_cooldown = 30
				var event: GameEvent = GameEvent.new()
				event.type = GameEvent.EventType.SOCKET; event.tick = world.tick; event.object_id = socket
				events.append(event)

func snapshot() -> GameSnapshot:
	return GameSnapshot.capture(world) if world != null else null

func _resolve_phase(events: Array[GameEvent]) -> void:
	if world.objective_index >= 3 and world.players[0].position.distance_to(map.exit_position) <= 64 and world.players[1].position.distance_to(map.exit_position) <= 64:
		world.extract_ticks += 1
	else: world.extract_ticks = 0
	if world.extract_ticks >= 120:
		ObjectiveSystem.new().finish_sector(world)
	else:
		world.remaining_ticks = maxi(0,world.remaining_ticks-1)
		if world.remaining_ticks == 0:
			world.phase = GameTypes.MatchPhase.FAILED
			world.score = ObjectiveSystem.new().final_score(world)

	if world.phase != GameTypes.MatchPhase.PLAYING:
		var event: GameEvent = GameEvent.new(); event.tick = world.tick
		event.type = GameEvent.EventType.SECTOR_END if world.phase == GameTypes.MatchPhase.INTERMISSION else GameEvent.EventType.MATCH_END
		events.append(event)

func _advance_timers() -> void:
	for p: WorldState.PlayerState in world.players:
		for timer: String in ["dash_ticks", "stun_ticks", "invulnerable_ticks", "dash_cooldown"]:
			p.set(timer, maxi(0, int(p.get(timer)) - 1))
		if p.mode == GameTypes.PlayerMode.DASH and p.dash_ticks == 0:
			p.mode = GameTypes.PlayerMode.NORMAL
			p.velocity = p.velocity.limit_length(config.speed)
		if p.mode == GameTypes.PlayerMode.STUN and p.stun_ticks == 0: p.mode = GameTypes.PlayerMode.NORMAL

func reset_sector(definition: MapDefinition, index: int) -> void:
	if world==null or index<0 or index>=LevelCatalog.current().count() or LevelCatalog.current().index_of(definition.id)!=index: return
	var original_seed: int = campaign_seed
	initialize(config,definition,original_seed+17*index,difficulty)
	campaign_seed = original_seed

func start_countdown(ticks: int = 180) -> void:
	if world == null or ticks <= 0: return
	world.phase = GameTypes.MatchPhase.COUNTDOWN; world.phase_remaining = ticks
