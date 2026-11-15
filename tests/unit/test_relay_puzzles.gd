extends RefCounted
func run(t: TestAssert) -> void:
	var content: Dictionary = preload("res://tools/validate_content.gd").load_content()
	var hints: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/map_solution_hints.json"))
	var link_system: LinkSystem = LinkSystem.new()
	for id: String in hints:
		var map: MapDefinition = content.maps[StringName(id)]
		var collision: CollisionWorld = CollisionWorld.new(); collision.configure(map)
		for i: int in range(3):
			var stages: Array = hints[id][i].stages
			for stage: int in range(stages.size()):
				var hint: Dictionary = stages[stage]
				var world: WorldState = WorldState.new(); world.reset(map,content.config,6); world.objective_index = i
				if stage==1: world.latched_mask = 1<<i; world.charges[i] = 150
				for slot: int in range(2): world.players[slot].position = Vector2(hint.ends[slot][0],hint.ends[slot][1])
				var selected: int = int(hint.socket)
				var link: GameTypes.LinkResult = link_system.evaluate(world.players,selected,map,collision)
				t.is_true(link_system.hits_beacon(link,map.beacons[i]),"M11c real geometry powers %s/%d/%d len%.1f" % [id,i,stage,link.length])
				t.is_true(ObjectiveSystem.fields_satisfied(world,map,i),"M11c different players satisfy fields %s/%d/%d" % [id,i,stage])
				world.players.reverse()
				t.is_true(ObjectiveSystem.fields_satisfied(world,map,i),"M11c swapped roles satisfy fields %s/%d/%d" % [id,i,stage])
				if selected>=0:
					t.is_true(not link_system.hits_beacon(link_system.evaluate(world.players,-1,map,collision),map.beacons[i]),"M11c relay has geometric purpose %s/%d/%d" % [id,i,stage])
				if not map.objective_rule(i).stabilization.is_empty():
					world.players[1].position = world.players[0].position
					t.is_true(not ObjectiveSystem.fields_satisfied(world,map,i),"M11c walking together cannot bypass fields %s/%d/%d" % [id,i,stage])
					if stage==1:
						for slot: int in range(2):
							var a: Vector2 = map.objective_rule(i).stabilization[0][slot]; var b: Vector2 = map.objective_rule(i).stabilization[1][slot]
							t.is_true(a.distance_to(b)>88,"M11c phase change requires both to leave previous fields %s/%d/%d" % [id,i,slot])
	# The dock optical channel is the only relay task without stabilization.
	# Search every 8-unit reachable-style position for the former overlapping-arm exploit.
	var dock: MapDefinition = content.maps[&"dock"]; var collision: CollisionWorld = CollisionWorld.new(); collision.configure(dock)
	var players: Array[WorldState.PlayerState] = [WorldState.PlayerState.new(),WorldState.PlayerState.new()]
	var exploit: bool = false
	for y: int in range(104,677,8):
		for x: int in range(48,1237,8):
			var point: Vector2 = Vector2(x,y); var blocked: bool = false
			for wall: Rect2 in dock.walls:
				if wall.grow(12).has_point(point): blocked = true; break
			if blocked: continue
			for player: WorldState.PlayerState in players: player.position = point
			if link_system.hits_beacon(link_system.evaluate(players,0,dock,collision),dock.beacons[1]): exploit = true
	t.is_true(not exploit,"M11c dock channel rejects colocated drones on sampled8 grid")
	players[0].position = Vector2(384,192); players[1].position = Vector2(904,320)
	var blocked_link: GameTypes.LinkResult = link_system.evaluate(players,-1,dock,collision)
	t.equal(blocked_link.status,GameTypes.LinkStatus.OCCLUDED,"M11c dock corner blocks direct link")
	t.equal(blocked_link.blocked_segment,0,"M11c blockage identifies actual segment")
	t.is_true(blocked_link.blocked_point.is_finite() and blocked_link.blocked_point!=players[0].position.lerp(players[1].position,0.5),"M11c marker uses collision contact rather than midpoint")
	# Previously demonstrated boundary exploits, checked against the final rules/geometry.
	for sample: Dictionary in [
		{"map":&"garden","goal":2,"phase":0,"socket":2,"a":Vector2(836,224),"b":Vector2(1060,384)},
		{"map":&"garden","goal":2,"phase":1,"socket":1,"a":Vector2(740,144),"b":Vector2(1124,480)},
		{"map":&"reactor","goal":2,"phase":0,"socket":-1,"a":Vector2(656,440),"b":Vector2(1056,540)},
		{"map":&"reactor","goal":2,"phase":1,"socket":-1,"a":Vector2(728,316),"b":Vector2(1136,620)},
		{"map":&"reactor","goal":2,"phase":1,"socket":1,"a":Vector2(724,304),"b":Vector2(1124,592)}]:
		var definition: MapDefinition = content.maps[sample.map]; var world: WorldState = WorldState.new(); world.reset(definition,content.config,6)
		world.objective_index = sample.goal; world.latched_mask = (1<<int(sample.goal)) if sample.phase==1 else 0
		world.players[0].position = sample.a; world.players[1].position = sample.b
		var geometry: CollisionWorld = CollisionWorld.new(); geometry.configure(definition)
		var bypass: bool = ObjectiveSystem.fields_satisfied(world,definition,sample.goal) and link_system.hits_beacon(link_system.evaluate(world.players,sample.socket,definition,geometry),definition.beacons[sample.goal])
		t.is_true(not bypass,"M11c rejects former edge bypass %s/%d/%d/%d" % [sample.map,sample.goal,sample.phase,sample.socket])
	set_meta("completed",true)
