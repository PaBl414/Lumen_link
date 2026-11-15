extends RefCounted
const Objectives = preload("res://core/objective_system.gd")
func run(t: TestAssert) -> void:
	var world: WorldState = WorldState.new()
	var map: MapDefinition = MapDefinition.new(); map.beacons = [Vector2(100,100),Vector2(150,100),Vector2(200,100)]
	var link: GameTypes.LinkResult = GameTypes.LinkResult.new(); link.points = [Vector2(0,100),Vector2(300,100)]; link.length = 300; link.status = 0
	var events: Array[GameEvent] = []
	for tick: int in range(1,301):
		world.tick = tick; Objectives.new().step(world,link,map,null,events)
	t.equal(world.charges[0],300,"O01 charge300")
	t.equal(world.charges[1],0,"O01 next not same tick")
	t.equal(events.size(),1,"O01 one event")
	world.objective_index = 0; world.charges[0] = 100; world.last_power_ticks[0] = 300; link.status = 4
	for tick: int in range(301,341):
		world.tick = tick; Objectives.new().step(world,link,map,null,events)
	t.equal(world.charges[0],95,"O02 grace30 then decay5")
	world.remaining_ticks = 60; world.phase = GameTypes.MatchPhase.PLAYING
	Objectives.new().finish_sector(world)
	var score: int = world.score; Objectives.new().finish_sector(world)
	t.equal(world.score,score,"S02 finish idempotent")
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var dock: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/dock.json"))).value
	var sim: Simulation = Simulation.new(); sim.initialize(config,dock,0,1)
	var replay: Script = preload("res://tests/fixture_replay.gd")
	replay.play(sim,replay.load_run(&"dock",0,1))
	t.equal(sim.world.phase,GameTypes.MatchPhase.WON,"M04 dock success: goals=%d positions=%s/%s" % [sim.world.objective_index,sim.world.players[0].position,sim.world.players[1].position])
	set_meta("completed",true)
