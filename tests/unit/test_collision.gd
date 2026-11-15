extends RefCounted
const World = preload("res://core/collision_world.gd")
const Map = preload("res://core/map_definition.gd")

func run(t: TestAssert) -> void:
	var map: Map = Map.new()
	map.bounds = Rect2(32,88,1216,600)
	map.walls = [Rect2(200,200,40,100)]
	var world: World = World.new(); world.configure(map)
	var hit: RefCounted = world.move(Vector2(180,250), Vector2(720,0), 1.0/60)
	t.near(hit.position.x, 187.99, 0.001, "K01 dash wall no tunneling")
	t.near(hit.velocity.x, 0, 0.001, "K01 remove normal velocity")
	hit = world.move(Vector2(180,250), Vector2(720,720), 1.0/60)
	t.near(hit.position.x, 187.99, 0.001, "K01 slide x")
	t.near(hit.position.y, 262, 0.001, "K01 slide y")
	t.equal(hit.segments.size(), 2, "K01 actual slide path")
	for pair: Array in [[Vector2(50,150),Vector2(-720,0),44.01,0],[Vector2(1230,150),Vector2(720,0),1235.99,0],[Vector2(500,106),Vector2(0,-720),100.01,1],[Vector2(500,670),Vector2(0,720),675.99,1]]:
		hit = world.move(pair[0],pair[1],1.0/60)
		t.near(hit.position[pair[3]], pair[2], 0.001, "K01 boundary")
	t.is_true(world.blocks_segment(Vector2(100,250), Vector2(300,250),3), "K01 occluded")
	t.is_true(world.blocks_segment(Vector2(100,197), Vector2(300,197),3), "K01 tangent blocks")
	t.is_true(not world.blocks_segment(Vector2(100,196), Vector2(300,196),3), "K01 parallel clear")
	map.walls = [Rect2(200,100,20,200),Rect2(100,200,200,20)]
	world.configure(map)
	var first: RefCounted = world.move(Vector2(180,180),Vector2(720,720),1.0/60)
	map.walls.reverse(); world.configure(map)
	var second: RefCounted = world.move(Vector2(180,180),Vector2(720,720),1.0/60)
	t.equal(first.position,second.position,"K02 order independent corner")
	t.equal(first.segments,second.segments,"K02 order independent path")
	t.near(first.position.x,187.99,0.001,"K02 corner x")
	t.near(first.position.y,187.99,0.001,"K02 corner y")
	world.walls = [Rect2(200,200,40,100)]
	hit = world.move(Vector2(188.01,250),Vector2.ZERO,1.0/60)
	t.near(hit.position.x,187.99,0.001,"K01 tiny penetration correction")
	hit = world.move(Vector2(189,250),Vector2.ZERO,1.0/60)
	t.near(hit.position.x,189,0.001,"K01 large penetration requires authority")
	set_meta("completed",true)
