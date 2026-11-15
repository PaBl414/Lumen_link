extends SceneTree
# Current M11c geometry checks; historical pocket certificate lives in reports.
func _initialize() -> void:
	var assertions: TestAssert = TestAssert.new()
	var suite: RefCounted = preload("res://tests/unit/test_relay_puzzles.gd").new(); suite.run(assertions)
	assertions.is_true(suite.get_meta("completed",false),"M11c geometry suite completed")
	print(JSON.stringify(assertions.summary())); quit(1 if assertions.failed else 0)
