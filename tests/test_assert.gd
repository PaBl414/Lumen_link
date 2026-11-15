class_name TestAssert
extends RefCounted
## Explicit counters work in release builds too; never rely on engine assert().

var passed: int = 0
var failed: int = 0
var skipped: int = 0
var cases: Array[Dictionary] = []
var _started_ms: int = Time.get_ticks_msec()


func equal(actual: Variant, expected: Variant, name: String) -> void:
	_record(actual == expected, name, "expected=%s actual=%s" % [expected, actual])


func near(actual: float, expected: float, tolerance: float, name: String) -> void:
	_record(is_finite(actual) and is_finite(expected) and tolerance >= 0.0 and absf(actual - expected) <= tolerance, name, "expected=%s actual=%s tolerance=%s" % [expected, actual, tolerance])


func is_true(value: bool, name: String) -> void:
	_record(value, name, "expected true")


func fails(result: Variant, name: String) -> void:
	# Expected-error Result objects must expose ok=false, not merely be non-null.
	_record(result is RefCounted and result.get("ok") == false, name, "expected Result.ok=false")


func summary() -> Dictionary:
	return {"passed": passed, "failed": failed, "skipped": skipped,
		"duration_ms": Time.get_ticks_msec() - _started_ms, "cases": cases.duplicate(true)}


func _record(success: bool, name: String, detail: String) -> void:
	if success:
		passed += 1
	else:
		failed += 1
	cases.append({"name": name, "status": "PASS" if success else "FAIL", "detail": "" if success else detail})
