extends RefCounted
const Link = preload("res://core/link_system.gd")
func run(t: TestAssert) -> void:
	var map: MapDefinition = MapDefinition.new(); map.sockets = [Vector2(100,200),Vector2(200,200),Vector2(300,200)]
	var collision: CollisionWorld = CollisionWorld.new()
	var a: WorldState.PlayerState = WorldState.PlayerState.new(); a.position = Vector2(100,100)
	var b: WorldState.PlayerState = WorldState.PlayerState.new()
	var players: Array[WorldState.PlayerState] = [a,b]
	for length: int in [55,56,720,721]:
		b.position = a.position+Vector2(length,0)
		t.equal(Link.new().evaluate(players,-1,map,collision).status,0 if length in [56,720] else (1 if length == 55 else 2),"L01 length %d" % length)
	b.position = Vector2(300,100)
	var link: GameTypes.LinkResult = Link.new().evaluate(players,-1,map,collision)
	t.is_true(not Link.new().hits_beacon(link,Vector2(120,100)),"L03 endpoint too close")
	t.is_true(Link.new().hits_beacon(link,Vector2(148,100)),"L03 exact48")
	collision.walls = [Rect2(190,90,20,20)]
	t.equal(Link.new().evaluate(players,-1,map,collision).status,3,"L02 occluded")
	a.mode = 1
	t.equal(Link.new().evaluate(players,-1,map,collision).status,4,"L02 busy priority")
	t.equal(Link.new().find_socket(Vector2(150,200),map),-1,"L02 out of range")
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var dock: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_map.json"))).value
	var sim: Simulation = Simulation.new(); sim.initialize(config,dock,0,0)
	sim.world.players[0].position = dock.sockets[0]; sim.world.players[1].position = dock.sockets[1]
	var command: InputCommand = InputCommand.new(); command.anchor_serial = 1
	sim.step([command,command.copy()])
	t.equal(sim.world.active_socket,1,"L02 odd tick slot1 wins")
	t.equal(sim.world.socket_cooldown,30,"L02 global cooldown")
	set_meta("completed",true)
