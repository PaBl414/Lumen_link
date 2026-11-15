extends RefCounted
func run(t: TestAssert) -> void:
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_map.json"))
	data.schema_version = 2; data.objectives = []; data.walls = []; data.hazards = []
	for i: int in range(3): data.objectives.append({"id":i,"hint":"Sprawdzenie pól","stabilization":[]})
	data.objectives[0].stabilization = [[[200,320],[400,320]],[[200,480],[400,480]]]
	var parsed: GameTypes.Result = MapDefinition.from_json(data)
	t.is_true(parsed.ok,"ST schema2 accepts two-phase fields")
	var map: MapDefinition = parsed.value
	t.is_true(map.validate(config).ok,"ST valid schema2 map passes geometry validation")
	var world: WorldState = WorldState.new(); world.reset(map,config,6)
	world.players[0].position = Vector2(200,320); world.players[1].position = Vector2(400,320)
	t.is_true(ObjectiveSystem.fields_satisfied(world,map,0),"ST distinct players occupy pair")
	world.players.reverse()
	t.is_true(ObjectiveSystem.fields_satisfied(world,map,0),"ST roles can swap")
	world.players[1].position = world.players[0].position
	t.is_true(not ObjectiveSystem.fields_satisfied(world,map,0),"ST one pad cannot count twice")
	world.players[1].position = Vector2(200,320)
	world.players[0].mode = GameTypes.PlayerMode.DASH
	t.is_true(not ObjectiveSystem.fields_satisfied(world,map,0),"ST dash invalidates fields")
	world.players[0].mode = GameTypes.PlayerMode.STUN
	t.is_true(not ObjectiveSystem.fields_satisfied(world,map,0),"ST stun invalidates fields")
	world.players[0].mode = GameTypes.PlayerMode.NORMAL
	world.players[0].position = Vector2(444,320)
	t.is_true(ObjectiveSystem.fields_satisfied(world,map,0),"ST inclusive radius44")
	world.players[0].position.x = 444.1
	t.is_true(not ObjectiveSystem.fields_satisfied(world,map,0),"ST radius44 outside")
	world.players[0].position = Vector2(400,320)
	var link: GameTypes.LinkResult = GameTypes.LinkResult.new(); link.points = [map.beacons[0]-Vector2(100,0),map.beacons[0]+Vector2(100,0)]; link.length = 200; link.status = 0
	var events: Array[GameEvent] = []
	var objective: ObjectiveSystem = ObjectiveSystem.new()
	world.charges[0] = 149; world.tick = 1; objective.step(world,link,map,config,events)
	t.equal(world.charges[0],150,"ST reaches half")
	t.equal(world.latched_mask,1,"ST latch persists in state")
	t.is_true(not ObjectiveSystem.fields_satisfied(world,map,0),"ST activates next stationary pair")
	for tick: int in range(2,202): world.tick = tick; objective.step(world,link,map,config,events)
	t.equal(world.charges[0],150,"ST decay cannot cross latched150")
	world.players[0].position = Vector2(200,480); world.players[1].position = Vector2(400,480)
	link.status = GameTypes.LinkStatus.OCCLUDED; world.tick += 1; objective.step(world,link,map,config,events)
	t.equal(world.charges[0],150,"ST pads alone never power")
	link.status = GameTypes.LinkStatus.ACTIVE
	for tick: int in range(150): world.tick += 1; objective.step(world,link,map,config,events)
	t.equal(world.charges[0],300,"ST second phase finishes")
	t.equal(world.objective_index,1,"ST advances exactly once")
	t.equal(events.size(),1,"ST one beacon event")
	var snap: GameSnapshot = GameSnapshot.capture(world)
	var codec: PacketCodec = PacketCodec.new()
	var encoded: GameTypes.Result = codec.encode(10,{}, {"snapshot":snap})
	t.is_true(encoded.ok,"ST encode full durable state")
	var restored: GameSnapshot = codec.decode(encoded.value).value.payload.snapshot
	t.equal(restored.latched_mask,1,"ST latch restored without visual event")
	t.equal(restored.charges[0],300,"ST full charge restored")
	world.reset(map,config,6)
	t.equal(world.latched_mask,0,"ST sector reset clears latch")
	map.objectives[0].stabilization.resize(1)
	world.players[0].position = Vector2(200,320); world.players[1].position = Vector2(400,320)
	world.charges[0] = 149; world.tick = 1; objective.step(world,link,map,config,events)
	t.equal(world.latched_mask,0,"ST single pair does not latch")
	world.players[0].position = Vector2(600,600)
	for tick: int in range(2,102): world.tick = tick; objective.step(world,link,map,config,events)
	t.is_true(world.charges[0]<150,"ST single pair decays normally")
	map.objectives[0].stabilization.clear()
	t.is_true(ObjectiveSystem.fields_satisfied(world,map,0),"ST legacy plain goals unchanged")
	var bad: Dictionary = data.duplicate(true); bad.objectives[0].stabilization = [[[200,320],[250,320]]]
	t.fails(MapDefinition.from_json(bad).value.validate(config),"ST rejects overlapping pair centers")
	bad = data.duplicate(true); bad.objectives[0].stabilization = [[[200,320]]]
	t.fails(MapDefinition.from_json(bad),"ST rejects malformed pair")
	bad = data.duplicate(true); bad.objectives[0].stabilization = [[[NAN,320],[400,320]]]
	t.fails(MapDefinition.from_json(bad),"ST rejects nonfinite field")
	var old_packet: PackedByteArray = encoded.value.duplicate(); old_packet.encode_u16(4,1)
	t.fails(codec.decode(old_packet),"ST rejects old protocol1")
	snap.charges[0] = 149
	t.fails(codec.encode(10,{}, {"snapshot":snap}),"ST rejects latch below durable floor")
	set_meta("completed",true)
