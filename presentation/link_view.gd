class_name LinkView
extends Node2D
var points: PackedVector2Array = PackedVector2Array()
var status: int = 0
var blocked_point: Vector2 = Vector2.INF
var reduced_motion: bool = false
var high_quality: bool = true
var lines: Array[Line2D] = []
var shader_material: ShaderMaterial
func _ready() -> void:
	z_index = 40
	shader_material = ShaderMaterial.new(); shader_material.shader = preload("res://shaders/link.gdshader")
	var white: Image = Image.create(1,1,false,Image.FORMAT_RGBA8); white.fill(Color.WHITE)
	var line_texture: ImageTexture = ImageTexture.create_from_image(white)
	for width: float in [16.0,8.0,3.0]:
		var line: Line2D = Line2D.new(); line.width = width; line.antialiased = true
		line.joint_mode = Line2D.LINE_JOINT_ROUND; line.begin_cap_mode = Line2D.LINE_CAP_ROUND; line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.texture = line_texture; line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.material = shader_material; add_child(line); lines.append(line)
func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if shader_material != null: shader_material.set_shader_parameter("motion",0.0 if value else 1.0)
func set_quality(high: bool) -> void:
	high_quality = high
func present(route: PackedVector2Array, condition: int, _charge: float,contact: Vector2 = Vector2.INF) -> void:
	points = route.duplicate(); status = condition; blocked_point = contact
	for i: int in range(lines.size()):
		lines[i].points = points; lines[i].visible = status==GameTypes.LinkStatus.ACTIVE and (i!=0 or high_quality)
		lines[i].default_color = [Color(0.4,0.88,0.76,0.10),Color(0.65,0.92,0.73,0.23),Color("e9f6bf")][i]
	queue_redraw()
func _draw() -> void:
	if status==GameTypes.LinkStatus.ACTIVE or points.size()<2: return
	var tint: Color = Color("f07178") if status in [GameTypes.LinkStatus.OCCLUDED,GameTypes.LinkStatus.SHUTTERED] else Color("b3c2c6")
	for i: int in range(points.size()-1): draw_dashed_line(points[i],points[i+1],tint,2,10,true,true)
	var center: Vector2 = points[0].lerp(points[points.size()-1],0.5)
	if status in [GameTypes.LinkStatus.OCCLUDED,GameTypes.LinkStatus.SHUTTERED]:
		center = blocked_point if blocked_point.is_finite() else center
		draw_circle(center,12,Color("101b2b")); draw_line(center-Vector2(5,5),center+Vector2(5,5),tint,2,true); draw_line(center+Vector2(-5,5),center+Vector2(5,-5),tint,2,true)
	elif status in [GameTypes.LinkStatus.TOO_SHORT,GameTypes.LinkStatus.TOO_LONG]:
		draw_line(center-Vector2(8,0),center+Vector2(8,0),Color("f4d27a"),2,true)
		draw_line(center-Vector2(8,5),center-Vector2(8,5)*Vector2(1,-1),Color("f4d27a"),2,true)
