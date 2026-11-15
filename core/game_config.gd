class_name GameConfig
extends RefCounted
const Types = preload("res://core/game_types.gd")

var dt: float = 1.0 / 60.0
var speed: float = 240.0
var dash_ticks: int = 10
var timers: Dictionary = {}
var data: Dictionary = {}

static func from_json(source: Dictionary) -> Types.Result:
	var config: GameConfig = GameConfig.new()
	config.data = source.duplicate(true)
	var checked: Types.Result = config.validate()
	if not checked.ok:
		return checked
	config.speed = config.data.movement.speed
	config.dash_ticks = int(config.data.dash.duration_ticks)
	config.timers = config.data.objective.duplicate(true)
	return Types.Result.new(true, 0, "", config)

func validate() -> Types.Result:
	# Exact starting balance and schema, independently embedded to detect missing or changed data.
	var expected: Dictionary = JSON.parse_string('{  "schema_version": 1,  "simulation_hz": 60,  "snapshot_hz": 30,  "input_hz": 30,  "movement": {    "speed": 240,    "acceleration": 1800,    "deceleration": 2400,    "half_size": 12  },  "dash": {    "speed": 720,    "duration_ticks": 10,    "cooldown_ticks": 90  },  "link": {    "min_length": 56,    "max_length": 720,    "width": 6,    "socket_radius": 44,    "socket_cooldown": 30  },  "objective": {    "charge_ticks": 300,    "grace_ticks": 30,    "decay_period_ticks": 2,    "extract_ticks": 120  },  "damage": {    "stun_ticks": 12,    "invulnerable_ticks": 90,    "global_cooldown": 30  },  "difficulties": {    "NORMAL": {      "integrity": 6,      "sector_seconds": 180,      "pulse": {        "off": 180,        "telegraph": 60,        "active": 60      },      "sweep": {        "off": 60,        "telegraph": 90,        "active": 180,        "cooldown": 30      }    },    "RELAXED": {      "integrity": 9,      "sector_seconds": 240,      "pulse": {        "off": 240,        "telegraph": 90,        "active": 30      },      "sweep": {        "off": 120,        "telegraph": 120,        "active": 120,        "cooldown": 60      }    }  }}')
	var problem: String = _check(data, expected, "gameplay")
	return Types.Result.new(problem.is_empty(), Types.ErrorCode.INVALID_DATA if not problem.is_empty() else 0, problem)

static func _check(actual: Variant, expected: Variant, path: String) -> String:
	if expected is Dictionary:
		if not actual is Dictionary or actual.size() != expected.size():
			return path + ": invalid keys/type"
		for key: String in expected:
			if not actual.has(key):
				return path + "." + key + ": missing"
			var problem: String = _check(actual[key], expected[key], path + "." + key)
			if not problem.is_empty():
				return problem
	elif not (actual is float or actual is int) or not is_finite(float(actual)) or actual != expected:
		return path + ": expected " + str(expected)
	return ""
