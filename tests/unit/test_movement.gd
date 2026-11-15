extends RefCounted
func run(t: TestAssert) -> void:
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/dock.json"))).value
	var simulation: Simulation = Simulation.new()
	simulation.initialize(config, map, 0, 0)
	var p: WorldState.PlayerState = simulation.world.players[0]
	var command: InputCommand = InputCommand.new()
	command.axis_x = 127; command.axis_y = 127
	var maximum: float = 0
	var isolated: WorldState.PlayerState = WorldState.PlayerState.new()
	isolated.position = Vector2(200,400)
	var collision: CollisionWorld = CollisionWorld.new(); collision.configure(map)
	Movement.step(isolated, command, collision, config)
	t.near(isolated.velocity.length(),30,0.001,"M01 acceleration per fixed tick")
	isolated.velocity = Vector2(240,0)
	Movement.step(isolated,InputCommand.new(),collision,config)
	t.near(isolated.velocity.length(),200,0.001,"M01 braking per fixed tick")
	for tick: int in range(600):
		simulation.step([command, InputCommand.neutral(tick)])
		maximum = maxf(maximum, p.velocity.length())
	t.is_true(maximum <= 240.001, "M01 600 diagonal ticks no boost")
	simulation.initialize(config, map, 0, 0)
	p = simulation.world.players[0]
	command = InputCommand.new(); command.dash_serial = 1
	var start: Vector2 = p.position
	for tick: int in range(10): simulation.step([command, InputCommand.neutral(tick)])
	t.near(p.position.distance_to(start),120,0.001,"M02 exact 120-unit dash from rest")
	t.equal(p.mode,GameTypes.PlayerMode.DASH,"M02 tenth tick dash")
	simulation.step([command,InputCommand.new()])
	t.equal(p.mode,GameTypes.PlayerMode.NORMAL,"M02 eleventh tick normal")
	t.is_true(p.velocity.length() <= 240,"M02 end dash speed clamped")
	var dash_count: int = 0
	for tick: int in range(100): dash_count += simulation.step([command,InputCommand.new()]).size()
	t.equal(dash_count,0,"M03 repeated serial never retriggers")
	command.dash_serial = 2
	t.equal(simulation.step([command,InputCommand.new()]).size(),1,"M03 new serial after cooldown")
	# A rejected edge is consumed during cooldown, not queued for later.
	command.dash_serial = 3
	simulation.step([command,InputCommand.new()])
	for tick: int in range(100): simulation.step([command,InputCommand.new()])
	t.equal(p.mode,GameTypes.PlayerMode.NORMAL,"M03 cooldown edge consumed")
	# Both slots may occupy the same space and do not affect each other's motion.
	simulation.initialize(config,map,0,0)
	simulation.world.players[1].position = simulation.world.players[0].position
	command = InputCommand.new(); command.axis_x = 127
	simulation.step([command,command.copy()])
	t.equal(simulation.world.players[0].position,simulation.world.players[1].position,"M01 drones pass through each other")
	p = simulation.world.players[0]
	var wall: Rect2 = simulation.map.walls[0]
	p.position = Vector2(wall.position.x-12,wall.get_center().y); p.dash_cooldown = 0
	command.dash_serial = 1
	for tick: int in range(10): simulation.step([command,InputCommand.new()])
	t.is_true(p.position.x < wall.position.x-12+0.001,"K01 dash cannot tunnel dock wall")
	# Stun ignores input, consumes edges and decrements cooldown.
	p.mode = GameTypes.PlayerMode.STUN; p.stun_ticks = 12; p.dash_cooldown = 90
	start = p.position; command.dash_serial = 2
	simulation.step([command,InputCommand.new()])
	t.equal(p.position,start,"M02 stun blocks movement")
	t.equal(p.consumed_serials.x,2,"M02 stun consumes edge")
	t.equal(p.dash_cooldown,89,"M02 cooldown during stun")
	set_meta("completed",true)
