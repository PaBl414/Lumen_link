extends SceneTree
# Authoring tool: real inputs only; geometry hints do not alter the simulation.
const Validator = preload("res://tools/validate_content.gd")
const Driver = preload("res://tools/solution_driver.gd")
func _initialize() -> void: _record.call_deferred()
func _append(frames: Array,commands: Array[InputCommand]) -> void:
	var values: Array = [commands[0].axis_x,commands[0].axis_y,commands[1].axis_x,commands[1].axis_y,commands[0].anchor_serial,commands[1].anchor_serial,commands[0].dash_serial,commands[1].dash_serial]
	if not frames.is_empty() and frames.back().slice(1)==values: frames.back()[0] += 1
	else: frames.append([1]+values)
func _run(config: GameConfig,map: MapDefinition,variant: int,difficulty: int,hints: Array) -> Dictionary:
	var sim: Simulation = Simulation.new(); sim.initialize(config,map,variant,difficulty)
	if sim.world==null: return {"ok":false,"error":"invalid map"}
	var driver: RefCounted = Driver.new(); driver.configure(map,hints,difficulty,variant)
	var frames: Array = []; var history: Array = []; var old_goal: int = -1; var old_latch: int = -1
	while sim.world.phase==GameTypes.MatchPhase.PLAYING:
		if sim.world.objective_index!=old_goal or sim.world.latched_mask!=old_latch:
			old_goal = sim.world.objective_index; old_latch = sim.world.latched_mask
			history.append({"tick":sim.world.tick,"goal":old_goal,"latch":old_latch,"integrity":sim.world.integrity})
			print(JSON.stringify({"progress":String(map.id),"variant":variant,"difficulty":difficulty,"state":history.back()}))
		if sim.world.tick%600==0: print(JSON.stringify({"trace":String(map.id),"tick":sim.world.tick,"goal":sim.world.objective_index,"charges":Array(sim.world.charges),"positions":[str(sim.world.players[0].position),str(sim.world.players[1].position)]}))
		var commands: Array[InputCommand] = driver.commands(sim.world,sim.world.tick+1)
		_append(frames,commands); sim.step(commands)
	return {"ok":sim.world.phase==GameTypes.MatchPhase.WON,"variant":variant,"difficulty":difficulty,"seed":variant,"frames":frames,"ticks":sim.world.tick,"integrity":sim.world.integrity,"score":sim.world.score,"complete_mask":sim.world.complete_mask,"latched_mask":sim.world.latched_mask,"history":history,"retreats":driver.retreats,"dashes":driver.dashes,"positions":[str(sim.world.players[0].position),str(sim.world.players[1].position)],"charge":Array(sim.world.charges)}
func _record() -> void:
	var content: Dictionary = Validator.load_content()
	if not content.ok: push_error(content.message); quit(1); return
	var hints: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/map_solution_hints.json"))
	var ids: Array[StringName] = Validator.map_ids().duplicate(); var variants: Array[int] = [0,1,2]; var difficulties: Array[int] = [0,1]
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--map="): ids.assign([StringName(argument.trim_prefix("--map="))])
		if argument=="--quick": variants = [0]; difficulties = [0]
	var failures: int = 0
	for id: StringName in ids:
		var runs: Array = []
		for variant: int in variants:
			for difficulty: int in difficulties:
				var run: Dictionary = _run(content.config,content.maps[id],variant,difficulty,hints[String(id)]); runs.append(run)
				var summary: Dictionary = run.duplicate(); summary.erase("frames"); print(JSON.stringify({"map":id,"result":summary}))
				if not run.ok: failures += 1
		if failures==0 and variants.size()==3:
			var file: FileAccess = FileAccess.open("res://tests/fixtures/%s_success.json" % id,FileAccess.WRITE)
			file.store_string(JSON.stringify({"schema_version":2,"map":id,"format":"RLE [ticks,x0,y0,x1,y1,anchor0,anchor1,dash0,dash1]; actual movement only; no world mutations","runs":runs},"\t")+"\n"); file.close()
	quit(1 if failures else 0)
