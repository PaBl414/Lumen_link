extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var t: TestAssert=TestAssert.new()
 preload("res://tests/unit/test_protocol.gd").new().run(t)
 await preload("res://tests/integration/test_level_progress_lan.gd").new().run_async(t)
 await preload("res://tests/integration/test_stabilization_lan.gd").new().run_async(t)
 print(JSON.stringify(t.summary()));quit(int(t.failed>0))
