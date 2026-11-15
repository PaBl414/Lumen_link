extends RefCounted
# Offline authoring/test driver. Produces real inputs only; never mutates simulation.
var difficulty_level: int = 0
var phase_variant: int = 0
var map: MapDefinition
var hints: Array
var grid: AStarGrid2D = AStarGrid2D.new()
var base_free: Dictionary = {}
var dynamic_cells: Dictionary = {}
var paths: Array = [PackedVector2Array(),PackedVector2Array()]
var destinations: Array[Vector2] = [Vector2.INF,Vector2.INF]
var cursors: Array[int] = [0,0]
var anchor_serials: Array[int] = [0,0]
var dash_serials: Array[int] = [0,0]
var last_plan: int = -100
var hazards: HazardSystem = HazardSystem.new()
var collision: CollisionWorld = CollisionWorld.new()
var retreats: int = 0
var dashes: int = 0
func configure(definition: MapDefinition,solutions: Array,difficulty: int = 0,variant: int = 0) -> void:
	difficulty_level = difficulty; phase_variant = variant
	map = definition; hints = solutions; collision.configure(map)
	grid.region = Rect2i(6,13,149,72); grid.cell_size = Vector2(8,8); grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER; grid.update()
	for y: int in range(13,85):
		for x: int in range(6,155):
			var cell: Vector2i = Vector2i(x,y); var point: Vector2 = Vector2(cell)*8
			var free: bool = map.bounds.grow(-16).has_point(point)
			for wall: Rect2 in map.walls:
				if wall.grow(14).has_point(point): free = false
			if free: base_free[cell] = true
			else: grid.set_point_solid(cell)
func unsafe(point: Vector2,tick: int,difficulty: int,variant: int,horizon: int = 45) -> bool:
	for obstacle: MapDefinition.ObstacleDef in map.obstacles:
		if obstacle.type!="JAM" or not obstacle.rect.grow(16).has_point(point): continue
		for dt: int in range(0,horizon+1,3):
			if ObstacleSystem.phase_at(obstacle,tick+dt,difficulty,variant).phase==2: return true
	for h: MapDefinition.HazardDef in map.hazards:
		if h.type=="PULSE":
			var offset: Vector2 = (point-h.a).abs()-Vector2(12,12)
			if Vector2(maxf(0,offset.x),maxf(0,offset.y)).length_squared()>h.radius*h.radius: continue
			var period: int = 300 if difficulty==0 else 360
			var phase_tick: int = posmod(tick+int(floor(float(h.offset)*period/300))+37*variant,period)
			if phase_tick+horizon >= (240 if difficulty==0 else 330): return true
		else:
			var area: Rect2 = Rect2(h.a,Vector2.ZERO).expand(h.b).expand(h.a+h.travel).expand(h.b+h.travel).grow(17)
			if not area.has_point(point): continue
			for dt: int in range(0,horizon+1,3):
				var phase: Dictionary = hazards.phase_at(h,tick+dt,difficulty,variant)
				if phase.phase==2 and Rect2(h.a+phase.offset,Vector2.ZERO).expand(h.b+phase.offset).grow(17).has_point(point): return true
	return false
func safe_retreat(point: Vector2,state: RefCounted) -> Vector2:
	var best: Vector2 = point; var best_distance: float = INF
	for radius: int in [80,112,160,208]:
		for angle: int in range(16):
			var candidate: Vector2 = ((point+Vector2.RIGHT.rotated(angle*TAU/16)*radius)/8).round()*8
			if not base_free.has(Vector2i((candidate/8).round())) or unsafe(candidate,state.sector_tick,difficulty_level,phase_variant,90): continue
			if not collision.blocks_segment(point,candidate,12) and point.distance_to(candidate)<best_distance: best = candidate; best_distance = point.distance_to(candidate)
		if best_distance<INF: return best
	return best
func _refresh(state: RefCounted) -> void:
	for cell: Vector2i in dynamic_cells:
		if base_free.has(cell): grid.set_point_solid(cell,false)
	dynamic_cells.clear()
	for h: MapDefinition.HazardDef in map.hazards:
		var area: Rect2 = Rect2(); var exists: bool = false
		for dt: int in range(0,49,6):
			var phase: Dictionary = hazards.phase_at(h,state.sector_tick+dt,difficulty_level,phase_variant)
			if phase.phase!=2: continue
			var rect: Rect2 = Rect2(h.a-Vector2(64,64),Vector2(128,128)) if h.type=="PULSE" else Rect2(h.a+phase.offset,Vector2.ZERO).expand(h.b+phase.offset).grow(21)
			area = area.merge(rect) if exists else rect; exists = true
		if not exists: continue
		var first: Vector2i = Vector2i((area.position/8).floor()); var last: Vector2i = Vector2i((area.end/8).ceil())
		for y: int in range(maxi(first.y,13),mini(last.y+1,85)):
			for x: int in range(maxi(first.x,6),mini(last.x+1,155)):
				var cell: Vector2i = Vector2i(x,y)
				if base_free.has(cell): grid.set_point_solid(cell); dynamic_cells[cell] = true
func commands(state: RefCounted,target_tick: int) -> Array[InputCommand]:
	var ends: Array = [[1144,592],[1192,592]]; var escapes: Array = ends
	var desired: int = -1; var operator: int = 0
	if state.objective_index<3:
		var stages: Array = hints[state.objective_index].stages
		var stage: Dictionary = stages[1 if stages.size()==2 and state.latched_mask&(1<<state.objective_index) else 0]
		ends = stage.ends; escapes = stage.escape; desired = int(stage.socket); operator = int(stage.operator)
	else: desired = state.active_socket
	var switching: bool = state.active_socket!=desired
	var activation: Vector2 = Vector2.INF
	if switching: activation = map.sockets[state.active_socket if desired<0 else desired]
	var replan: bool = state.tick-last_plan>=12
	if replan: _refresh(state); last_plan = state.tick
	var result: Array[InputCommand] = []
	for slot: int in range(2):
		var player: WorldState.PlayerState = state.players[slot]
		var target: Vector2 = activation if switching and slot==operator else Vector2(ends[slot][0],ends[slot][1])
		if unsafe(target,state.sector_tick,difficulty_level,phase_variant):
			var escape: Vector2 = Vector2(escapes[slot][0],escapes[slot][1])
			if escape.distance_to(target)<48 or unsafe(escape,state.sector_tick,difficulty_level,phase_variant,75): escape = safe_retreat(target,state)
			if escape!=destinations[slot]: retreats += 1
			target = escape
		var command: InputCommand = InputCommand.new(); command.tick = target_tick
		if switching and slot==operator and player.position.distance_to(activation)<=36 and state.socket_cooldown==0 and anchor_serials[slot]==player.consumed_serials.y:
			anchor_serials[slot] = (anchor_serials[slot]+1)&65535
		if target!=destinations[slot] or replan:
			destinations[slot] = target; cursors[slot] = 0
			var start: Vector2i = Vector2i((player.position/8).round()); var end: Vector2i = Vector2i((target/8).round())
			paths[slot] = grid.get_point_path(start,end) if grid.is_in_boundsv(start) and grid.is_in_boundsv(end) else PackedVector2Array()
		var delta: Vector2 = Vector2.ZERO
		if not paths[slot].is_empty():
			while cursors[slot]<paths[slot].size()-1 and player.position.distance_to(paths[slot][cursors[slot]])<2.5: cursors[slot] += 1
			delta = paths[slot][cursors[slot]]-player.position
		# An emergency dash is allowed only to a verified free, safe endpoint, never on cooldown spam.
		if unsafe(player.position,state.sector_tick,difficulty_level,phase_variant,9) and player.dash_cooldown==0 and player.mode==0:
			var refuge: Vector2 = safe_retreat(player.position,state)
			if refuge.distance_to(player.position)>60 and refuge.distance_to(player.position)<=120:
				delta = refuge-player.position; dash_serials[slot] = (dash_serials[slot]+1)&65535; dashes += 1
		var axis: Vector2 = (delta*0.05).limit_length(1)
		command.axis_x = roundi(axis.x*127); command.axis_y = roundi(axis.y*127)
		command.anchor_serial = anchor_serials[slot]; command.dash_serial = dash_serials[slot]; result.append(command)
	return result
