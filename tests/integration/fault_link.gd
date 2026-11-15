class_name FaultLink
extends RefCounted
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var loss: float = 0.2
var duplicates: float = 0.1
var reorder: float = 0.2
var queue: Array[Dictionary] = []
var dropped: int = 0
var duplicated: int = 0
var reordered: int = 0
func _init(seed_value: int = 90210) -> void: rng.seed = seed_value
func send(payload: Variant,now_ms: float) -> void:
	if rng.randf()<loss: dropped += 1; return
	var delay: float = 50+rng.randf_range(-15,15)
	if rng.randf()<reorder: delay += 50; reordered += 1
	queue.append({"at":now_ms+delay,"payload":payload})
	if rng.randf()<duplicates:
		queue.append({"at":now_ms+delay+3,"payload":payload}); duplicated += 1
func receive(now_ms: float) -> Array:
	queue.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.at<b.at)
	var delivered: Array = []
	while not queue.is_empty() and queue[0].at<=now_ms: delivered.append(queue.pop_front().payload)
	return delivered
