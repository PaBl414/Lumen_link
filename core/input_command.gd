class_name InputCommand
extends RefCounted
var tick: int = 0
var axis_x: int = 0
var axis_y: int = 0
var dash_serial: int = 0
var anchor_serial: int = 0
var ping_serial: int = 0

func axis() -> Vector2:
	return (Vector2(clampi(axis_x, -127, 127), clampi(axis_y, -127, 127)) / 127.0).limit_length(1.0)

func copy() -> InputCommand:
	var result: InputCommand = InputCommand.new()
	for field: String in ["tick", "axis_x", "axis_y", "dash_serial", "anchor_serial", "ping_serial"]:
		result.set(field, get(field))
	return result

static func neutral(at_tick: int) -> InputCommand:
	var command: InputCommand = InputCommand.new()
	command.tick = at_tick
	return command
