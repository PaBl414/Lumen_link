extends RefCounted

const Assertions = preload("res://tests/test_assert.gd")
const State = preload("res://app/app_state.gd")
const Root = preload("res://app/app_root.gd")
const BUTTON_PATH: String = "Menu/Center/Panel/Margin/Content/ExitButton"


func run_async(t: Assertions) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var model: State = State.new()
	t.equal(model.current, State.Screen.BOOT, "B01 initial Boot")
	t.fails(model.transition(999), "B01 reject unknown screen")
	t.equal(model.current, State.Screen.BOOT, "B01 invalid transition preserves state")
	t.is_true(model.allows(State.Screen.MENU), "B01 Boot allows Menu")
	t.is_true(model.transition(State.Screen.MENU).ok, "B01 Boot → Menu")
	t.fails(model.transition(State.Screen.BOOT), "B01 cannot reenter Boot")
	var scene: PackedScene = load("res://scenes/app.tscn") as PackedScene
	t.is_true(scene != null, "B01 boot scene loads")
	if scene == null:
		set_meta("completed", true)
		return
	for cycle: int in range(3):
		var app: Root = scene.instantiate() as Root
		t.is_true(app != null, "B01 composition root exists")
		if app == null:
			continue
		tree.root.add_child(app)
		await tree.process_frame
		t.equal(app.state.current, State.Screen.MENU, "B01 menu reached cycle %d" % cycle)
		t.is_true(not tree.multiplayer_poll, "B01 automatic multiplayer poll disabled")
		var button: Button = app.get_node(BUTTON_PATH) as Button
		t.is_true(button.is_visible_in_tree() and not button.disabled, "B01 Exit available")
		t.is_true(button.has_focus(), "B01 keyboard focus")
		t.equal(button.pressed.get_connections().size(), 1, "B01 single Exit listener")
		t.is_true(button.pressed.is_connected(app.shutdown), "B01 Exit routes to shutdown")
		if cycle == 2:
			var content: Dictionary = preload("res://tools/validate_content.gd").load_content()
			app._start_fixture(content.map)
			await app.scene_router.scene_ready
			for tick: int in range(180): app._physics_process(1.0/60)
			await tree.process_frame
			t.is_true(app.fixture_active and app.world_view.drones.size() == 2, "B02 two debug drone views")
			app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			t.is_true(not app.routers[0].enabled and not app.routers[1].enabled, "I01 app focus loss disables both slots")
			app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
			var escape: InputEventKey = InputEventKey.new()
			escape.keycode = KEY_ESCAPE; escape.pressed = true
			app._unhandled_key_input(escape)
			t.is_true(not app.fixture_active and not app.world_view.visible, "I01 menu hides fixture")
			t.is_true(not app.routers[0].enabled and button.has_focus(), "I01 menu neutral and focus restored")
			app._unhandled_key_input(escape)
			t.is_true(app.fixture_active and app.routers[0].enabled, "I01 resume re-enables input")
		app.queue_free()
		await tree.process_frame
		t.equal(tree.root.get_child_count(), 0, "B01 scene cleaned")
	t.equal(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 60, "B01 fixed 60 Hz")
	t.equal(ProjectSettings.get_setting("display/window/size/viewport_width"), 1280, "B01 viewport width")
	t.equal(ProjectSettings.get_setting("display/window/size/viewport_height"), 720, "B01 viewport height")
	t.equal(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility", "B01 Compatibility renderer")
	for action: String in ["move_left", "move_right", "move_up", "move_down", "dash", "anchor", "ping", "ui_cancel"]:
		t.is_true(InputMap.has_action(action) and InputMap.action_get_events(action).size() >= 2, "B01 bindings: " + action)
		t.near(InputMap.action_get_deadzone(action), 0.2, 0.0001, "B01 deadzone: " + action)
	var probe: Assertions = Assertions.new()
	probe.equal(1, 1, "equal pass")
	probe.equal(1, 2, "equal fail")
	probe.near(0.1 + 0.2, 0.3, 0.0001, "near pass")
	probe.near(NAN, 0.0, 0.1, "near rejects NaN")
	probe.is_true(true, "true pass")
	probe.is_true(false, "true fail")
	probe.fails(model.transition(State.Screen.BOOT), "fails pass")
	probe.fails(State.Result.new(true, OK, ""), "fails rejects success")
	t.equal(probe.summary()["passed"], 4, "Assertion helpers count successes")
	t.equal(probe.summary()["failed"], 4, "Assertion helpers count failures")
	set_meta("completed", true)
