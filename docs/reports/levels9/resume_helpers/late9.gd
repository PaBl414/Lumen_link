extends SceneTree
func _initialize() -> void:
 var t: TestAssert=TestAssert.new();preload("res://tests/unit/test_terminal_inputs.gd").new().run(t);print(JSON.stringify(t.summary()));quit(int(t.failed>0))
