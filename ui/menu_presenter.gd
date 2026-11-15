class_name MenuPresenter
extends Control
signal intent(action: StringName,payload: Dictionary)
var player_name: LineEdit
var room_name: LineEdit
var ip: LineEdit
var port: SpinBox
var seed: SpinBox
var difficulty: OptionButton
var status: Label
var rooms: ItemList
var entries: Array = []
var actions: Array[Button] = []
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new(); panel.position = Vector2(190,20); panel.size = Vector2(900,680); add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for key: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+key,20)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new(); box.add_theme_constant_override("separation",8); margin.add_child(box)
	var title: Label = Label.new(); title.text = "LUMEN LINK · Połączenie LAN"; title.add_theme_font_size_override("font_size",24); box.add_child(title)
	var grid: GridContainer = GridContainer.new(); grid.columns = 2; box.add_child(grid)
	player_name = _line(grid,"Twoja nazwa","Gracz")
	room_name = _line(grid,"Nazwa pokoju","LUMEN LINK")
	ip = _line(grid,"IPv4 gospodarza","127.0.0.1")
	port = _spin(grid,"Port gry",1024,65535,7777)
	seed = _spin(grid,"Seed (host)",0,0xffffffff,0)
	var label: Label = Label.new(); label.text = "Trudność (host)"; grid.add_child(label)
	difficulty = OptionButton.new(); difficulty.add_item("Normal"); difficulty.add_item("Relaxed"); grid.add_child(difficulty)
	var row: HBoxContainer = HBoxContainer.new(); box.add_child(row)
	_button(row,"Utwórz pokój",&"host"); _button(row,"Dołącz po IP",&"join"); _button(row,"Szukaj LAN",&"scan")
	rooms = ItemList.new(); rooms.custom_minimum_size = Vector2(0,80); box.add_child(rooms)
	rooms.item_activated.connect(_activate_room)
	status = Label.new(); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status.custom_minimum_size.y = 40; box.add_child(status)
	_button(box,"Anuluj / Wróć",&"back")
	var help: Label = Label.new(); help.text = "Wyszukiwanie: UDP 7778; gra: wybrany port UDP.\nJeśli lista jest pusta, wpisz IP gospodarza. Zezwól aplikacji na sieć prywatną."; box.add_child(help)
func _line(grid: GridContainer,text: String,value: String) -> LineEdit:
	var label: Label = Label.new(); label.text = text; grid.add_child(label)
	var field: LineEdit = LineEdit.new(); field.text = value; field.custom_minimum_size.x = 420; grid.add_child(field); return field
func _spin(grid: GridContainer,text: String,low: float,high: float,value: float) -> SpinBox:
	var label: Label = Label.new(); label.text = text; grid.add_child(label)
	var field: SpinBox = SpinBox.new(); field.min_value = low; field.max_value = high; field.value = value; grid.add_child(field); return field
func _payload() -> Dictionary:
	return {"name":player_name.text.strip_edges(),"room":room_name.text.strip_edges(),"ip":ip.text.strip_edges(),"port":int(port.value),"seed":int(seed.value),"difficulty":difficulty.selected}
func _button(parent: Node,text: String,action: StringName) -> void:
	var button: Button = Button.new(); button.text = text; button.custom_minimum_size.y = 40; parent.add_child(button)
	button.pressed.connect(func() -> void: intent.emit(action,_payload()))
	if action != &"back": actions.append(button)
func bind(model: Dictionary) -> void:
	status.text = model.get("message","")
	set_busy(model.get("busy",false))
func set_busy(value: bool) -> void:
	for button: Button in actions: button.disabled = value
func set_rooms(value: Array) -> void:
	entries = value; rooms.clear()
	for entry: Dictionary in entries:
		rooms.add_item("%s · %s:%d · %s · %s" % [entry.room,entry.ip,entry.port,entry.engine,"zajęty" if entry.occupied else "wolny"])
		rooms.set_item_disabled(rooms.item_count-1,entry.occupied)
func _activate_room(index: int) -> void:
	if index<0 or index>=entries.size() or entries[index].occupied: return
	ip.text = entries[index].ip; port.value = entries[index].port; intent.emit(&"join",_payload())
