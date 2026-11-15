extends RefCounted
func run(t: TestAssert) -> void:
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/dock.json"))).value
	var sim: Simulation = Simulation.new(); sim.initialize(config,map,0,0)
	var snap: GameSnapshot = sim.snapshot()
	t.is_true(snap.validate(map,config).ok,"S03 valid snapshot")
	snap.players[0].position = Vector2.ZERO; snap.charges[0] = 200
	t.equal(sim.world.players[0].position,map.spawns[0],"S03 snapshot players cannot mutate host")
	t.equal(sim.world.charges[0],0,"S03 snapshot charges cannot mutate host")
	var second: GameSnapshot = snap.copy(); second.players[1].velocity = Vector2.ONE; second.charges[1] = 100
	t.equal(snap.players[1].velocity,Vector2.ZERO,"S03 copy players isolated")
	t.equal(snap.charges[1],0,"S03 copy charges isolated")
	sim.world.players[0].consumed_serials.x = 65535
	var command: InputCommand = InputCommand.new(); command.dash_serial = 0
	t.equal(sim.step([command,InputCommand.new()]).size(),1,"S03 serial wraps forward")
	command.dash_serial = 65535
	sim.step([command,InputCommand.new()])
	t.equal(sim.world.players[0].consumed_serials.x,0,"S03 old serial ignored")
	var tick: int = sim.world.tick
	sim.step([])
	t.equal(sim.world.tick,tick,"S03 exact two commands required")
	map.spawns[0] = map.walls[0].get_center()
	sim.initialize(config,map,0,0)
	t.is_true(sim.world == null,"S03 invalid map blocks simulation")
	_success_fixtures(t,config)
	set_meta("completed",true)

func _success_fixtures(t: TestAssert,config: GameConfig) -> void:
	var ids: Array[StringName] = LevelCatalog.current().ids()
	var replay: Script = preload("res://tests/fixture_replay.gd")
	for id: StringName in ids:
		var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/%s.json" % id))).value
		for variant: int in range(3):
			for difficulty: int in range(2):
				var run: Dictionary = replay.load_run(id,variant,difficulty)
				t.is_true(not run.is_empty() and run.get("ok",false),"C02 success fixture %s/v%d/d%d" % [id,variant,difficulty])
				if run.is_empty(): continue
				var sim: Simulation = Simulation.new(); sim.initialize(config,map,variant,difficulty)
				var ticks: int = replay.play(sim,run)
				t.equal(ticks,int(run.ticks),"C02 replay exact ticks %s/v%d/d%d" % [id,variant,difficulty])
				t.equal(sim.world.phase,GameTypes.MatchPhase.WON,"C02 real sector success %s/v%d/d%d" % [id,variant,difficulty])
				t.equal(sim.world.complete_mask,7,"C02 all three goals %s/v%d/d%d" % [id,variant,difficulty])
				t.equal(sim.world.integrity,int(run.integrity),"C02 real hazards intact %s/v%d/d%d" % [id,variant,difficulty])
				t.equal(sim.world.score,int(run.score),"C02 deterministic score %s/v%d/d%d" % [id,variant,difficulty])
	# Compose the isolated recordings into six real complete campaigns, resetting integrity and score at every level.
	for seed: int in range(3):
		for difficulty: int in range(2):
			var sim: Simulation = Simulation.new()
			for sector: int in range(ids.size()):
				var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/%s.json" % ids[sector]))).value
				if sector==0: sim.initialize(config,map,seed,difficulty)
				else: sim.reset_sector(map,sector)
				t.equal(sim.world.score,0,"C02 per-level score resets")
				t.equal(sim.world.integrity,6 if difficulty==0 else 9,"C02 per-level starting integrity")
				var variant: int = posmod(seed+17*sector,3)
				t.equal(sim.world.objective_order,PackedInt32Array([0,1,2]),"C02 campaign order seed%d sector%d" % [seed,sector])
				replay.play(sim,replay.load_run(ids[sector],variant,difficulty))
			t.equal(sim.world.phase,GameTypes.MatchPhase.WON,"C02 full campaign seed%d/d%d" % [seed,difficulty])
			t.equal(sim.world.completed_beacons_total,3,"C02 final level has three completed goals")
