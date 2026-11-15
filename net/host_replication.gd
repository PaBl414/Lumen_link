class_name HostReplication
extends RefCounted
var inputs: Array[Dictionary] = [{},{}]
var held: Array[InputCommand] = [InputCommand.new(),InputCommand.new()]
var missing: PackedInt32Array = PackedInt32Array([0,0])
var last_received_tick: PackedInt32Array = PackedInt32Array([0,0])
var pending_events: Array[GameEvent] = []
func reset() -> void:
	inputs = [{},{}]; held = [InputCommand.new(),InputCommand.new()]
	missing = PackedInt32Array([0,0]); last_received_tick = PackedInt32Array([0,0]); pending_events.clear()
func enqueue(slot: int,commands: Array[InputCommand],current_tick: int) -> GameTypes.Result:
	if slot not in [0,1] or commands.size()>6: return GameTypes.Result.new(false,4,"command count/slot")
	var previous: int = -1
	for command: InputCommand in commands:
		if command.tick<=previous or command.tick>current_tick+12 or absi(command.axis_x)>127 or absi(command.axis_y)>127: return GameTypes.Result.new(false,4,"command bounds/order")
		previous = command.tick
		if command.tick<=current_tick: continue
		for pair: Vector2i in [Vector2i(command.dash_serial,held[slot].dash_serial),Vector2i(command.anchor_serial,held[slot].anchor_serial),Vector2i(command.ping_serial,held[slot].ping_serial)]:
			var difference: int = (pair.x-pair.y)&0xffff
			if pair.x<0 or pair.x>65535 or (difference>64 and difference<0x8000): return GameTypes.Result.new(false,4,"serial jump")
	for command: InputCommand in commands:
		if command.tick>current_tick and not inputs[slot].has(command.tick):
			inputs[slot][command.tick] = command.copy(); last_received_tick[slot] = maxi(last_received_tick[slot],command.tick)
	return GameTypes.Result.new(true,0,"")
func commands_for(tick: int) -> Array[InputCommand]:
	var result: Array[InputCommand] = []
	for slot: int in range(2):
		for old: Variant in inputs[slot].keys():
			if old<tick: inputs[slot].erase(old)
		var command: InputCommand
		if inputs[slot].has(tick):
			command = inputs[slot][tick].copy(); inputs[slot].erase(tick); missing[slot] = 0
			for field: String in ["dash_serial","anchor_serial","ping_serial"]:
				var delta: int = (int(command.get(field))-int(held[slot].get(field)))&0xffff
				if delta>=0x8000: command.set(field,held[slot].get(field))
			held[slot] = command.copy()
		else:
			missing[slot] += 1; command = held[slot].copy(); command.tick = tick
			if missing[slot]>6: command.axis_x = 0; command.axis_y = 0
		result.append(command)
	return result
func capture(simulation: Simulation) -> GameSnapshot:
	# The snapshot tick acknowledges simulated time, never last_received_tick.
	return simulation.snapshot()
func drain_events(max_count: int) -> Array[GameEvent]:
	var result: Array[GameEvent] = []
	for i: int in range(mini(clampi(max_count,0,8),pending_events.size())): result.append(pending_events.pop_front())
	return result
