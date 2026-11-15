class_name CameraRig
extends Camera2D
var shake: float = 0.5
var reduced_motion: bool = false
var remaining: float = 0.0
var duration: float = 0.16
var amplitude: float = 0.0
var elapsed: float = 0.0
func _ready() -> void:
	position = Vector2(640,360); zoom = Vector2.ONE
func impulse(strength: float,time: float = 0.16) -> void:
	if reduced_motion or shake<=0: return
	amplitude = minf(3,maxf(amplitude,strength)); duration = clampf(time,0.01,0.16); remaining = duration
func _process(delta: float) -> void:
	elapsed += delta; remaining = maxf(0,remaining-delta)
	offset = Vector2.ZERO
	if not reduced_motion and remaining>0:
		offset = Vector2(sin(elapsed*137),cos(elapsed*163)).limit_length(1)*amplitude*clampf(shake,0,1)*remaining/duration
	else: amplitude = 0
