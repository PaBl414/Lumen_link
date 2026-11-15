class_name NetworkClock
extends RefCounted
var estimated_tick: float = 0.0
var correction_target: float = 0.0
var rtt_ms: float = 0.0
var lead: int = 2
var last_command_tick: int = 0
var initialized: bool = false
var resync_required: bool = false
func reset(tick: int = 0) -> void:
	estimated_tick = tick; correction_target = tick; last_command_tick = tick
	initialized = true; resync_required = false
func observe(tick: int) -> void:
	var estimate: float = tick+rtt_ms*60.0/2000.0
	if not initialized: reset(tick)
	if absf(estimate-estimated_tick)>12:
		estimated_tick = estimate; last_command_tick = maxi(last_command_tick,int(floor(estimate))); resync_required = true
	correction_target = estimate
func on_pong(sent_us: int,received_us: int,host_tick: int) -> void:
	if received_us<sent_us: return
	var sample: float = (received_us-sent_us)/1000.0
	rtt_ms = sample if rtt_ms == 0 else lerpf(rtt_ms,sample,0.2)
	lead = clampi(int(ceil(rtt_ms*60.0/2000.0))+2,2,8)
	observe(host_tick)
func advance(delta: float) -> void:
	if not initialized: return
	estimated_tick += delta*60.0; correction_target += delta*60.0
	estimated_tick += clampf(correction_target-estimated_tick,-0.25,0.25)
func next_command_ticks(limit: int = 3,ceiling_tick: int = 0xffffffff) -> Array[int]:
	var ticks: Array[int] = []
	var target: int = mini(int(floor(estimated_tick))+lead,ceiling_tick)
	for i: int in range(mini(clampi(limit,1,3),maxi(0,target-last_command_tick))):
		last_command_tick += 1; ticks.append(last_command_tick)
	return ticks
