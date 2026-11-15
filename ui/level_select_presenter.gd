class_name LevelSelectPresenter
extends Control
signal intent(action: StringName,payload: Dictionary)
class Preview extends Control:
 var map: MapDefinition
 func _draw() -> void:
  if map == null: return
  var scale_map: float = minf(size.x/1280,size.y/720)
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE*scale_map)
  draw_rect(map.bounds,Color("112833"))
  for wall: Rect2 in map.walls: draw_rect(wall,Color("637d89"))
  for obstacle: MapDefinition.ObstacleDef in map.obstacles: draw_rect(obstacle.rect,Color("b08ee0") if obstacle.type=="JAM" else Color("e6c36f"),false,5)
  for point: Vector2 in map.beacons: draw_circle(point,22,Color("efd58c"))
  for point: Vector2 in map.sockets: draw_circle(point,12,Color("6fe2bb"))
  for rule: MapDefinition.ObjectiveDef in map.objectives:
   for pair: PackedVector2Array in rule.stabilization:
    for point: Vector2 in pair: draw_arc(point,44,0,TAU,24,Color("6c9c9c"),2)
  draw_arc(map.exit_position,64,0,TAU,24,Color("a7e7a5"),3)
var progress: ProgressStore
var selected: StringName
var difficulty: OptionButton
var list: ItemList
var description: Label
var legacy: Label
var message: Label
var preview: Preview
var play: Button
var reset_dialog: ConfirmationDialog
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var panel: PanelContainer = PanelContainer.new(); panel.position=Vector2(60,24); panel.size=Vector2(1160,672); add_child(panel)
 var box: VBoxContainer = VBoxContainer.new(); box.add_theme_constant_override("separation",10); panel.add_child(box)
 var title: Label = Label.new(); title.text="LUMEN LINK · Wybór poziomu"; title.add_theme_font_size_override("font_size",26); box.add_child(title)
 var row: HBoxContainer = HBoxContainer.new(); box.add_child(row)
 list=ItemList.new(); list.add_theme_font_size_override("font_size",16); list.custom_minimum_size=Vector2(380,350); row.add_child(list); list.item_selected.connect(_select)
 var detail: VBoxContainer = VBoxContainer.new(); row.add_child(detail)
 preview=Preview.new(); preview.custom_minimum_size=Vector2(720,310); detail.add_child(preview)
 description=Label.new(); detail.add_child(description)
 difficulty=OptionButton.new(); difficulty.add_item("Normal"); difficulty.add_item("Relaxed"); box.add_child(difficulty)
 difficulty.item_selected.connect(func(_i: int) -> void: _refresh_detail())
 var buttons: HBoxContainer = HBoxContainer.new(); box.add_child(buttons)
 _button(buttons,"Kontynuuj kampanię",func() -> void:
  var next: StringName=progress.continue_id()
  if next==&"": message.text="Cała kampania ukończona — wybierz poziom do powtórki."; return
  selected=next; _launch())
 play=_button(buttons,"Zagraj wybrany poziom",_launch)
 _button(buttons,"Dołącz do hosta LAN",func() -> void: intent.emit(&"join_form",{}))
 _button(buttons,"Wróć",func() -> void: intent.emit(&"back",{}))
 legacy=Label.new(); legacy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(legacy)
 message=Label.new(); message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(message)
 _button(box,"Resetuj postęp…",func() -> void: reset_dialog.popup_centered())
 reset_dialog=ConfirmationDialog.new(); reset_dialog.title="Reset postępu"; reset_dialog.dialog_text="Usunąć ukończenia i rekordy wszystkich poziomów?\nStarsze rekordy kampanii pozostaną zachowane."; add_child(reset_dialog)
 reset_dialog.confirmed.connect(func() -> void: progress.reset_progress(true); bind(progress); intent.emit(&"progress_reset",{}))
func _button(parent: Node,text: String,callback: Callable) -> Button:
 var button: Button=Button.new(); button.text=text; button.custom_minimum_size.y=36; parent.add_child(button); button.pressed.connect(callback); return button
func bind(store: ProgressStore) -> void:
 progress=store; selected=StringName(progress.data.last_selected.level_id); difficulty.select(int(progress.data.last_selected.difficulty))
 list.clear()
 for id: StringName in progress.catalog.ids():
  var entry: Dictionary=progress.catalog.entry(id)
  list.add_item("%d. %s · %s" % [list.item_count+1,entry.name,"ukończony" if progress.completed(id) else ("odblokowany" if progress.unlocked(id) else "zablokowany")])
 list.select(maxi(0,progress.catalog.index_of(selected))); _refresh_detail()
 legacy.text=""
 for path: String in ["user://records.json","user://debug_records.json"]:
  var history: RecordsStore=RecordsStore.new();history.path=path;history.load_records()
  if not history.records.is_empty():legacy.text+="Historyczne rekordy kampanii: %d (%s). Zachowane osobno; bez przypisywania ukończeń poziomów.\n" % [history.records.size(),path.get_file()]
 message.text=progress.warning
 if progress.continue_id()==&"": message.text+="\nKampania ukończona! Wszystkie poziomy można powtarzać."
func _select(index: int) -> void:
 selected=progress.catalog.ids()[index]; _refresh_detail()
func _refresh_detail() -> void:
 if progress==null: return
 var parsed: GameTypes.Result=MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/%s.json" % selected)))
 preview.map=parsed.value if parsed.ok else null; preview.queue_redraw()
 description.text=""
 for diff: int in range(2):
  var record: Dictionary=progress.best(selected,diff)
  description.text+="%s: %s\n" % ["Normal" if diff==0 else "Relaxed","brak rekordu" if record.is_empty() else "%d pkt · %.2f s" % [record.best_score,float(record.best_time_ticks)/60]]
 play.disabled=not progress.unlocked(selected)
func _launch() -> void:
 if not progress.unlocked(selected): message.text="Najpierw ukończ poprzedni poziom."; return
 progress.select_level(selected,difficulty.selected)
 intent.emit(&"play",{"level_id":String(selected),"difficulty":difficulty.selected})
