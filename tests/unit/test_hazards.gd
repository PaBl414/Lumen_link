extends RefCounted
const Hazards = preload("res://core/hazard_system.gd")
func run(t: TestAssert) -> void:
	var h: MapDefinition.HazardDef = MapDefinition.HazardDef.new(); h.type = "PULSE"; h.a = Vector2(100,100); h.radius = 48
	t.equal(Hazards.new().phase_at(h,239,0,0).phase,1,"H01 telegraph boundary")
	t.equal(Hazards.new().phase_at(h,240,0,0).phase,2,"H01 active boundary")
	t.equal(Hazards.new().phase_at(h,0,1,0).period,360,"H01 relaxed pulse period")
	var path: Array[Vector4] = [Vector4(0,100,200,100)]
	t.is_true(Hazards.new().hits(h,path,240,0,0),"H03 swept pulse")
	path = [Vector4(159,159,159,159)]
	t.is_true(not Hazards.new().hits(h,path,240,0,0),"H03 rounded corner clear")
	h.type = "SWEEP"; h.b = Vector2(200,100); h.travel = Vector2(0,100)
	t.equal(Hazards.new().phase_at(h,0,1,0).period,420,"H01 relaxed sweep period")
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/dock.json"))).value
	var sim: Simulation = Simulation.new(); sim.initialize(config,map,0,0)
	sim.world.objective_index = 3; sim.world.extract_ticks = 119; sim.world.remaining_ticks = 1
	for player: WorldState.PlayerState in sim.world.players: player.position = map.exit_position
	sim.step([InputCommand.new(),InputCommand.new()])
	t.equal(sim.world.phase,GameTypes.MatchPhase.WON,"O03 last tick extraction succeeds")
	var score: int = sim.world.score
	sim.step([InputCommand.new(),InputCommand.new()])
	t.equal(sim.world.score,score,"S02 terminal tick does not rescore")
	sim.initialize(config,map,0,0)
	var pulse: MapDefinition.HazardDef = MapDefinition.HazardDef.new(); pulse.type = "PULSE"; pulse.a = map.exit_position; pulse.radius = 48
	map.hazards = [pulse]
	sim.world.objective_index = 3; sim.world.extract_ticks = 119; sim.world.integrity = 1; sim.world.sector_tick = 239
	for player: WorldState.PlayerState in sim.world.players: player.position = map.exit_position
	sim.step([InputCommand.new(),InputCommand.new()])
	t.equal(sim.world.phase,GameTypes.MatchPhase.FAILED,"S01 death before extraction")
	t.equal(sim.world.integrity,0,"H02 simultaneous hit costs once")
	t.equal(sim.world.players[0].stun_ticks,12,"H02 first stun")
	t.equal(sim.world.players[1].stun_ticks,12,"H02 second stun")
	_dash_route(t,config)
	set_meta("completed",true)

func _dash_route(t: TestAssert,config: GameConfig) -> void:
	var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/garden.json"))).value
	var finishes: Array[int] = []
	for use_dash: bool in [false,true]:
		var sim: Simulation = Simulation.new(); sim.initialize(config,map,0,0)
		sim.world.sector_tick = 150; sim.world.objective_index = 2; sim.world.latched_mask = 4; sim.world.charges[2] = 150
		sim.world.players[0].position = Vector2(776,192); sim.world.players[1].position = Vector2(1120,448)
		var initial: int = sim.world.integrity; var arrival: int = -1
		for tick: int in range(1,38):
			var command: InputCommand = InputCommand.new(); command.tick = tick
			var delta: Vector2 = map.sockets[2]-sim.world.players[1].position
			var axis: Vector2 = (delta*0.05).limit_length(1)
			command.axis_x = roundi(axis.x*127); command.axis_y = roundi(axis.y*127); command.dash_serial = 1 if use_dash else 0
			sim.step([InputCommand.neutral(tick),command])
			if arrival<0 and sim.world.players[1].position.distance_to(map.sockets[2])<=44: arrival = tick
			if tick==11 and use_dash: t.equal(sim.world.integrity,initial,"M11c dash crosses active pulse to safe relay approach")
		finishes.append(arrival)
		if not use_dash: t.is_true(sim.world.integrity<initial,"M11c same short walk during active pulse is risky")
	t.is_true(finishes[1]>0 and finishes[0]>finishes[1],"M11c dash materially shortens risky optional route")
