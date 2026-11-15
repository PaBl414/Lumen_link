extends SceneTree
## Explicit suite registry. Missing/broken suites are failures, never silent skips.

const Assertions = preload("res://tests/test_assert.gd")
const SUITES: Dictionary = {
	"unit": ["res://tests/unit/test_terminal_inputs.gd","res://tests/unit/test_obstacles.gd","res://tests/unit/test_progress.gd","res://tests/unit/test_stabilization.gd","res://tests/unit/test_relay_puzzles.gd","res://tests/unit/test_prediction.gd", "res://tests/unit/test_content.gd", "res://tests/unit/test_collision.gd", "res://tests/unit/test_movement.gd", "res://tests/unit/test_input.gd", "res://tests/unit/test_simulation.gd", "res://tests/unit/test_link.gd", "res://tests/unit/test_objectives.gd", "res://tests/unit/test_hazards.gd", "res://tests/unit/test_persistence.gd", "res://tests/unit/test_protocol.gd"],
	"integration": ["res://tests/integration/test_level_select.gd","res://tests/integration/test_level_progress_lan.gd","res://tests/integration/test_stabilization_lan.gd","res://tests/integration/test_presentation.gd", "res://tests/integration/test_boot.gd", "res://tests/integration/test_flow.gd", "res://tests/integration/test_network.gd", "res://tests/integration/test_session.gd"],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var t: Assertions = Assertions.new()
	# Parse every runtime script, including scene dependencies whose _ready error would not abort a suite.
	for folder: String in ["app","core","net","ui","services","presentation"]:
		for filename: String in DirAccess.get_files_at("res://"+folder):
			if filename.ends_with(".gd"):
				var required: Script = load("res://"+folder+"/"+filename) as Script
				t.is_true(required != null and required.can_instantiate(),"Runtime parse: "+folder+"/"+filename)
	var selected: String = "all"
	var self_test_failure: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--suite="):
			selected = argument.trim_prefix("--suite=")
		elif argument == "--self-test-failure":
			self_test_failure = true
		else:
			t.is_true(false, "Unknown argument: " + argument)
	var paths: Array[String] = []
	if selected == "all":
		for group: String in SUITES:
			for path: String in SUITES[group]:
				paths.append(path)
	elif SUITES.has(selected):
		for path: String in SUITES[selected]:
			paths.append(path)
	else:
		t.is_true(false, "Unknown suite: " + selected)
	for path: String in paths:
		print("SUITE "+path)
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			t.is_true(false, "Suite failed to load: " + path)
			continue
		var suite: RefCounted = script.new() as RefCounted
		if suite == null:
			t.is_true(false, "Suite must extend RefCounted: " + path)
			continue
		# Completion sentinel detects a runtime error aborting the suite body.
		suite.set_meta("completed", false)
		if suite.has_method("run_async"):
			await suite.run_async(t)
		elif suite.has_method("run"):
			suite.run(t)
		else:
			t.is_true(false, "Suite lacks run/run_async: " + path)
		t.is_true(suite.get_meta("completed", false), "Suite completed: " + path)
	if self_test_failure:
		t.equal(1, 2, "Intentional runner failure (--self-test-failure)")
	var report: Dictionary = t.summary()
	report["suite"] = selected
	report["suite_count"] = paths.size()
	report["exit_code"] = 1 if t.failed > 0 else 0
	print(JSON.stringify(report))
	quit(report["exit_code"])
