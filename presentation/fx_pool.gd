class_name FxPool
extends Node2D
const CAPACITY: int = 128
const MAX_PARTICLES: int = 320
var high_quality: bool = true
var reduced_motion: bool = false
var active: Array[Dictionary] = []
var seen: Dictionary = {}
var seen_order: Array[String] = []
var positions: PackedVector2Array = PackedVector2Array()
var velocities: PackedVector2Array = PackedVector2Array()
var life: PackedFloat32Array = PackedFloat32Array()
var colors: PackedColorArray = PackedColorArray()
var unit_ring: PackedVector2Array = PackedVector2Array()
var particle_texture: Texture2D = preload("res://assets/art/particle.svg")
func _init() -> void:
	for i: int in range(41): unit_ring.append(Vector2.from_angle(TAU*i/40))
	positions.resize(MAX_PARTICLES); velocities.resize(MAX_PARTICLES); life.resize(MAX_PARTICLES); colors.resize(MAX_PARTICLES)
func particle_limit() -> int: return 320 if high_quality else 160
func particle_count() -> int:
	var count: int = 0
	for value: float in life:
		if value>0: count += 1
	return count
func set_quality(high: bool) -> void:
	high_quality = high
	for i: int in range(particle_limit(),MAX_PARTICLES): life[i] = 0
func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value: life.fill(0)
func emit_event(event: GameEvent) -> void:
	var key: String = "dash/%d/%d" % [event.player_id,event.value] if event.type==GameEvent.EventType.DASH else "id/%d" % event.id
	if seen.has(key): return
	seen[key] = true; seen_order.append(key)
	while seen_order.size()>512: seen.erase(seen_order.pop_front())
	var color: Color = Color("f07178") if event.type==GameEvent.EventType.HIT else Color("e9f6bf")
	var count: int = 20 if event.type==GameEvent.EventType.BEACON else (12 if event.type==GameEvent.EventType.HIT else 6)
	if event.type not in [GameEvent.EventType.BEACON,GameEvent.EventType.HIT,GameEvent.EventType.DASH,GameEvent.EventType.SOCKET]: return
	if active.size()>=CAPACITY: active.pop_front()
	active.append({"position":event.position,"type":event.type,"age":0.0,"color":color})
	if reduced_motion: count = 0
	var emitted: int = 0
	for i: int in range(particle_limit()):
		if emitted>=count: break
		if life[i]<=0:
			var angle: float = TAU*emitted/maxf(1,count)+event.id*0.19
			positions[i] = event.position; velocities[i] = Vector2.from_angle(angle)*(48+float(emitted%4)*16)
			life[i] = 0.4; colors[i] = color; emitted += 1
	queue_redraw()
func _process(delta: float) -> void:
	update_effects(delta)
func update_effects(delta: float) -> void:
	for i: int in range(particle_limit()):
		if life[i]>0:
			life[i] = maxf(0,life[i]-delta); positions[i] += velocities[i]*delta; velocities[i] *= exp(-delta*3)
	for i: int in range(active.size()-1,-1,-1):
		active[i].age += delta
		if active[i].age>=0.4: active.remove_at(i)
	queue_redraw()
func clear() -> void:
	active.clear(); seen.clear(); seen_order.clear(); life.fill(0); queue_redraw()
func _draw() -> void:
	# One packed segment stream avoids per-ring draw calls and nested packed-array copies.
	var segments: PackedVector2Array = PackedVector2Array()
	var ring_colors: PackedColorArray = PackedColorArray()
	var ring_limit: int = 16 if high_quality else 8
	segments.resize(mini(active.size(),ring_limit)*80); ring_colors.resize(mini(active.size(),ring_limit)*40)
	var point_index: int = 0; var color_index: int = 0
	var drawn: int = 0
	for index: int in range(active.size()-1,-1,-1):
		var effect: Dictionary = active[index]
		if drawn>=ring_limit: break
		if effect.type not in [GameEvent.EventType.BEACON,GameEvent.EventType.HIT]: continue
		drawn += 1
		var center: Vector2 = effect.position
		var progress: float = effect.age/0.4
		var radius: float = (24+68*progress if effect.type==GameEvent.EventType.BEACON else 18+12*progress) if not reduced_motion else 30
		var tint: Color = effect.color; tint.a = 1-progress
		for segment: int in range(40):
			segments[point_index] = center+unit_ring[segment]*radius; point_index += 1
			segments[point_index] = center+unit_ring[segment+1]*radius; point_index += 1
			ring_colors[color_index] = tint; color_index += 1
	segments.resize(point_index); ring_colors.resize(color_index)
	if point_index>0: draw_multiline_colors(segments,ring_colors,2,false)
	for i: int in range(particle_limit()):
		if life[i]>0:
			var tint: Color = colors[i]; tint.a = life[i]/0.4
			draw_texture_rect(particle_texture,Rect2(positions[i]-Vector2(3,3),Vector2(6,6)),false,tint)
