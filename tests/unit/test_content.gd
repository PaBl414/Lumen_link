extends RefCounted
const Types = preload("res://core/game_types.gd")
const Config = preload("res://core/game_config.gd")
const Map = preload("res://core/map_definition.gd")

func run(t: TestAssert) -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))
	var config: Config = Config.from_json(c).value
	t.is_true(config.validate().ok, "C01 config valid")
	for value: float in [NAN, -1.0, 0.0, 30.0]:
		var bad: Dictionary = c.duplicate(true); bad.simulation_hz = value
		t.fails(Config.from_json(bad), "C01 invalid tickrate " + str(value))
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_map.json"))
	var map: Map = Map.from_json(d).value
	t.is_true(map.validate(config).ok, "C01 dock reachable and safe")
	t.equal(map.walls[0], Rect2(432,384,96,176), "C01 exact dock wall")
	var invalid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/invalid_map.json"))
	t.fails(Map.from_json(invalid).value.validate(config), "C01 spawn overlaps wall")
	for field: String in ["background_asset", "bounds", "spawns", "exit"]:
		var bad: Dictionary = d.duplicate(true); bad.erase(field)
		t.fails(Map.from_json(bad), "C01 missing " + field)
	var bad: Dictionary = d.duplicate(true); bad.spawns[0][0] = NAN
	t.fails(Map.from_json(bad), "C01 NaN position")
	bad = d.duplicate(true); bad.extra = 1
	t.fails(Map.from_json(bad), "C01 unknown field")
	bad = d.duplicate(true); bad.walls.resize(33)
	t.fails(Map.from_json(bad), "C01 33 walls")
	bad = d.duplicate(true); bad.hazards.resize(9)
	t.fails(Map.from_json(bad), "C01 9 hazards")
	bad = d.duplicate(true); bad.walls[1].rect = bad.walls[0].rect
	t.fails(Map.from_json(bad).value.validate(config), "C01 overlapping walls")
	bad = d.duplicate(true); bad.sockets[0].position = [450,420]
	t.fails(Map.from_json(bad).value.validate(config), "C01 socket in wall")
	bad = d.duplicate(true); bad.walls = [{"id": 0, "rect": [600, 88, 40, 600]}]
	t.fails(Map.from_json(bad).value.validate(config), "C01 disconnected socket/exit")
	bad = d.duplicate(true); bad.walls[0].rect = [1100,550,40,40]
	t.fails(Map.from_json(bad).value.validate(config), "C01 exit safety")
	bad = d.duplicate(true); bad.hazards[0].a = [112,592]
	t.fails(Map.from_json(bad).value.validate(config), "C01 hazard spawn safety")
	t.equal(Types.PlayerMode.STUN, 2, "C01 player enum")
	t.equal(Types.Difficulty.RELAXED, 1, "C01 difficulty enum")
	var content: Dictionary = preload("res://tools/validate_content.gd").load_content()
	t.is_true(content.ok,"C02 all maps validate")
	if content.ok:
		content.maps[&"garden"].walls.clear()
		var fresh: Dictionary = preload("res://tools/validate_content.gd").load_content()
		t.equal(fresh.maps[&"garden"].walls.size(),Map.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/garden.json"))).value.walls.size(),"C02 validation cache never shares mutable maps")
		content = fresh
	if content.ok:
		for id: StringName in LevelCatalog.current().ids():
			for variant: int in range(3):
				for difficulty: int in range(2):
					var sim: Simulation = Simulation.new(); sim.initialize(config,content.maps[id],variant,difficulty)
					t.is_true(sim.world != null and sim.variant==variant,"C02 schema safety reachable %s/v%d/d%d" % [id,variant,difficulty])
		t.is_true(content.maps[&"dock"].walls != content.maps[&"garden"].walls and content.maps[&"garden"].walls != content.maps[&"reactor"].walls,"C02 distinct geometry")
	set_meta("completed", true)
