class_name DroneView
extends Node2D
var slot: int = 0
var mode: int = 0
var reduced_motion: bool = false
var phase: float = 0.0
var flash_left: float = 0.0
var invulnerable: bool = false
var dash_serial: int = -1
var celebrating: bool = false
var last_clip: String = ""
var visual: Node2D
var animation: AnimationPlayer
func _ready() -> void:
	visual = $Visual; animation = $AnimationPlayer
	var library: AnimationLibrary = AnimationLibrary.new()
	for name: String in ["idle","move","dash","hit","celebrate"]:
		var clip: Animation = Animation.new(); clip.length = {"idle":1.8,"move":0.5,"dash":0.167,"hit":0.2,"celebrate":1.0}[name]
		clip.loop_mode = Animation.LOOP_LINEAR if name in ["idle","move"] else Animation.LOOP_NONE
		var track: int = clip.add_track(Animation.TYPE_VALUE); clip.track_set_path(track,NodePath("Visual/DashAxis:scale" if name=="dash" else "Visual:scale"))
		var peak: Vector2 = Vector2(1,1)
		if name=="move": peak = Vector2(0.96,1.04)
		elif name=="dash": peak = Vector2(1.18,0.95)
		elif name=="hit": peak = Vector2(0.96,0.96)
		elif name=="celebrate": peak = Vector2(1.08,1.08)
		clip.track_insert_key(track,0,Vector2.ONE); clip.track_insert_key(track,minf(0.07,clip.length/2),peak); clip.track_insert_key(track,clip.length,Vector2.ONE)
		library.add_animation(name,clip)
	animation.add_animation_library("",library)
	animation.play("idle")
func configure(player_slot: int) -> void:
	slot = player_slot
	$Visual/DashAxis/Art/Body.texture = preload("res://assets/art/drone_a.svg") if slot==0 else preload("res://assets/art/drone_b.svg")
	$Visual/DashAxis/Art/Sensor.self_modulate = Color("66e0c2") if slot==0 else Color("ffbe78")
	queue_redraw()
func set_reduced_motion(value: bool) -> void:
	reduced_motion = value; last_clip = ""
	if value and animation != null: animation.stop(); visual.scale = Vector2.ONE; visual.position = Vector2.ZERO; visual.rotation = 0; $Visual/DashAxis.scale = Vector2.ONE; $Visual/DashAxis.rotation = 0; $Visual/DashAxis/Art.rotation = 0
func present(player: WorldState.PlayerState, delta: float) -> void:
	position = player.position; mode = player.mode; invulnerable = player.invulnerable_ticks>0
	phase += maxf(0,delta); flash_left = maxf(0,flash_left-delta)
	$Visual/DashAxis/Art/Body.self_modulate = Color(1.7,1.7,1.7) if flash_left>0 else Color.WHITE
	$Visual/DashAxis/Art/Sensor.position = Vector2(3,-2)+player.facing*2
	if not reduced_motion:
		visual.position.y = sin(phase*TAU/1.8)*1.5 if player.velocity.length()<20 else 0.0
		visual.position.x = sin(phase*TAU/0.12)*2 if mode==GameTypes.PlayerMode.STUN else 0.0
		visual.rotation = clampf(player.velocity.x/240.0,-1,1)*deg_to_rad(8) if mode!=GameTypes.PlayerMode.DASH else 0.0
		$Visual/DashAxis.rotation = player.facing.angle() if mode==GameTypes.PlayerMode.DASH else 0.0
		$Visual/DashAxis/Art.rotation = -$Visual/DashAxis.rotation
		if mode!=GameTypes.PlayerMode.DASH or celebrating: $Visual/DashAxis.scale = Vector2.ONE
		else: visual.scale = Vector2.ONE
		var name: String = "celebrate" if celebrating else ("hit" if mode==GameTypes.PlayerMode.STUN else ("dash" if mode==GameTypes.PlayerMode.DASH else ("move" if player.velocity.length()>20 else "idle")))
		if last_clip!=name:
			animation.play(name); last_clip = name
	queue_redraw()
func play_event(event: GameEvent) -> void:
	if event.type==GameEvent.EventType.DASH:
		if dash_serial==event.value: return
		dash_serial = event.value
	elif event.type==GameEvent.EventType.HIT: flash_left = 0.08
	elif event.type==GameEvent.EventType.MATCH_END: celebrating = event.value==1
func _draw() -> void:
	# The shadow marks the physical24x24 square; all bob/lean affects Visual only.
	draw_rect(Rect2(-12,-7,24,24),Color(0,0,0,0.18))
	if invulnerable:
		var alpha: float = 0.75 if reduced_motion else 0.55+0.25*sin(phase*TAU*4)
		if slot==0: draw_arc(Vector2.ZERO,25,0,TAU,48,Color(0.86,0.91,0.87,alpha),2,true)
		else: draw_polyline(PackedVector2Array([Vector2(0,-27),Vector2(27,0),Vector2(0,27),Vector2(-27,0),Vector2(0,-27)]),Color(0.86,0.91,0.87,alpha),2,true)
	if mode==GameTypes.PlayerMode.STUN:
		for x: int in [-10,0,10]: draw_circle(Vector2(x,-29),2,Color("f4d27a"))
