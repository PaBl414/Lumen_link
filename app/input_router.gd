class_name InputRouter
extends RefCounted
var enabled: bool = false
var slot: int = 0
var held: Dictionary = {}
var serials: Vector3i = Vector3i.ZERO
var sampled_serials: Vector3i = Vector3i.ZERO
var stick: Vector2 = Vector2.ZERO
var last_axis: Vector2 = Vector2.ZERO

func configure(_settings: GameTypes.SettingsData, player_slot: int = 0) -> void:
	slot = player_slot
	serials = Vector3i.ZERO
	sampled_serials = Vector3i.ZERO
	clear()

func set_enabled(value: bool) -> void:
	enabled = value and (slot == 0 or OS.is_debug_build())
	if not enabled: clear()

func clear() -> void:
	serials = sampled_serials
	held.clear()
	stick = Vector2.ZERO
	last_axis = Vector2.ZERO

func feed(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventKey and event.echo: return
	if slot == 0:
		if event is InputEventJoypadMotion:
			if event.axis == JOY_AXIS_LEFT_X: stick.x = event.axis_value
			if event.axis == JOY_AXIS_LEFT_Y: stick.y = event.axis_value
		for action: String in ["move_left", "move_right", "move_up", "move_down", "dash", "anchor", "ping"]:
			if event is InputEventJoypadMotion: continue
			if event.is_action(action): _button(action, event.is_pressed())
	elif event is InputEventKey:
		var keys: Dictionary = {KEY_J: "move_left", KEY_L: "move_right", KEY_I: "move_up", KEY_K: "move_down", KEY_SHIFT: "dash", KEY_U: "anchor", KEY_O: "ping"}
		if keys.has(event.physical_keycode): _button(keys[event.physical_keycode], event.pressed)

func _button(action: String, pressed: bool) -> void:
	if pressed and not held.get(action, false):
		var index: int = ["dash", "anchor", "ping"].find(action)
		if index >= 0: serials[index] = (serials[index] + 1) & 0xffff
	held[action] = pressed

func sample(target_tick: int) -> InputCommand:
	var command: InputCommand = InputCommand.neutral(target_tick)
	command.dash_serial = serials.x; command.anchor_serial = serials.y; command.ping_serial = serials.z
	if enabled:
		var analog: Vector2 = stick.limit_length(1)
		analog = analog.normalized() * clampf((analog.length() - 0.2) / 0.8, 0, 1)
		last_axis = (Vector2(int(held.get("move_right", false)) - int(held.get("move_left", false)), int(held.get("move_down", false)) - int(held.get("move_up", false))) + analog).limit_length(1)
		command.axis_x = roundi(last_axis.x * 127)
		command.axis_y = roundi(last_axis.y * 127)
	sampled_serials = serials
	return command
