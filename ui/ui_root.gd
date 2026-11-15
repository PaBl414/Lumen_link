class_name UIRoot
extends CanvasLayer
signal intent(action: StringName,payload: Dictionary)
var menu: Control
var lobby: Control
func _ready() -> void:
	layer = 20
	menu = preload("res://scenes/menus.tscn").instantiate(); add_child(menu)
	lobby = preload("res://scenes/lobby.tscn").instantiate(); add_child(lobby)
	menu.intent.connect(_forward); lobby.intent.connect(_forward)
	visible = false
func _forward(action: StringName,payload: Dictionary) -> void:
	intent.emit(action,payload)
func show_screen(screen: int,model: Dictionary) -> void:
	visible = true; menu.visible = screen == 0; lobby.visible = screen != 0
	if screen == 0: menu.bind(model)
	else: lobby.bind(model)
func show_error(code: int,text: String) -> void:
	show_screen(0,{"message":"%d: %s" % [code,text]})
