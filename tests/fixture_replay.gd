extends RefCounted
static func load_run(map_id: StringName,variant: int,difficulty: int) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/%s_success.json" % map_id))
	if not data is Dictionary or (data.get("schema_version")!=1 and data.get("schema_version")!=2) or data.get("map") != String(map_id): return {}
	for run: Dictionary in data.runs:
		if run.variant == variant and run.difficulty == difficulty: return run
	return {}
static func commands(row: Array,tick: int) -> Array[InputCommand]:
	var result: Array[InputCommand] = []
	for slot: int in range(2):
		var command: InputCommand = InputCommand.new(); command.tick = tick
		command.axis_x = int(row[1+slot*2]); command.axis_y = int(row[2+slot*2]); 
		if row.size()>=7: command.anchor_serial = int(row[5+slot])
		if row.size()>=9: command.dash_serial = int(row[7+slot])
		result.append(command)
	return result
static func play(sim: Simulation,run: Dictionary) -> int:
	var steps: int = 0
	for row: Array in run.get("frames",[]):
		if row.size() not in [5,7,9] or int(row[0])<1 or int(row[0])>20000: return -1
		for i: int in range(int(row[0])):
			if sim.world.phase != GameTypes.MatchPhase.PLAYING: return steps
			sim.step(commands(row,sim.world.tick+1)); steps += 1
	return steps
static func command_at(run: Dictionary,relative_tick: int,slot: int,target_tick: int) -> InputCommand:
	var elapsed: int = 0
	for row: Array in run.get("frames",[]):
		elapsed += int(row[0])
		if relative_tick<=elapsed: return commands(row,target_tick)[slot]
	return InputCommand.neutral(target_tick)
