class_name LobbyPresenter
extends Control
signal intent(action: StringName,payload: Dictionary)
var summary: Label
var status: Label
var select_button: Button
var level_choice: OptionButton
var seed: SpinBox
var difficulty: OptionButton
var ready_button: Button
var start: Button
var apply_options: Button
var model: Dictionary = {}
var next_button: Button
var rematch_button: Button
var lobby_button: Button
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new(); panel.position = Vector2(260,30); panel.size = Vector2(760,660); add_child(panel)
	var box: VBoxContainer = VBoxContainer.new(); box.add_theme_constant_override("separation",10); panel.add_child(box)
	summary = Label.new(); summary.add_theme_font_size_override("font_size",24); box.add_child(summary)
	status = Label.new(); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; box.add_child(status)
	level_choice = OptionButton.new(); box.add_child(level_choice)
	for id: StringName in LevelCatalog.current().ids(): level_choice.add_item("%d. %s" % [level_choice.item_count+1,LevelCatalog.current().entry(id).name])
	seed = SpinBox.new(); seed.max_value = 0xffffffff; box.add_child(seed)
	difficulty = OptionButton.new(); difficulty.add_item("Normal"); difficulty.add_item("Relaxed"); box.add_child(difficulty)
	apply_options = Button.new(); apply_options.text = "Zastosuj poziom / seed / trudność (zeruje gotowość)"; box.add_child(apply_options)
	apply_options.pressed.connect(func() -> void: intent.emit(&"options",{"seed":int(seed.value),"difficulty":difficulty.selected,"level_id":String(LevelCatalog.current().ids()[level_choice.selected])}))
	select_button=_vote_button(box,"Podgląd i wybór poziomów",&"select_level")
	ready_button = Button.new(); ready_button.text = "Zmień gotowość"; box.add_child(ready_button)
	ready_button.pressed.connect(func() -> void: intent.emit(&"ready",{}))
	start = Button.new(); start.text = "Rozpocznij (host)"; box.add_child(start)
	start.pressed.connect(func() -> void: intent.emit(&"start",{}))
	next_button = _vote_button(box,"Dalej",&"next")
	rematch_button = _vote_button(box,"Rewanż",&"rematch")
	lobby_button = _vote_button(box,"Wybór map (oboje)",&"lobby")
	var leave: Button = Button.new(); leave.text = "Anuluj / Opuść"; box.add_child(leave)
	leave.pressed.connect(func() -> void: intent.emit(&"cancel",{}))
func _vote_button(box: Node,text: String,action: StringName) -> Button:
	var button: Button = Button.new(); button.text = text; box.add_child(button)
	button.pressed.connect(func() -> void: intent.emit(action,{})); return button
func bind(value: Dictionary) -> void:
	model = value
	var lobby: RefCounted = value.lobby
	var host: bool = value.role == "host"
	var phase: String = value.state
	summary.text = "%s\nHost: %s [%s]\nGość: %s [%s]" % [lobby.room,lobby.names[0],"gotowy" if lobby.ready_mask&1 else "czeka",lobby.names[1] if not lobby.names[1].is_empty() else "Czekam na gracza","gotowy" if lobby.ready_mask&2 else "czeka"]
	status.text = "Stan: %s\n%s\nPoziom i trudność wybiera host. Zmiana zeruje gotowość." % [phase,value.get("message","")]
	next_button.visible = phase == "RESULTS" and value.get("confirmed",false) and LevelCatalog.current().next_id(lobby.level_id)!=&""; rematch_button.visible = phase == "RESULTS"; lobby_button.visible = phase == "RESULTS"
	var snapshot: GameSnapshot = value.get("snapshot")
	if snapshot != null and phase in ["INTERMISSION","RESULTS"]:
		status.text = "Wynik %d · integralność %d · cele %d/3\nGłosy: %d/2 · obaj zatwierdźcie tę samą akcję" % [snapshot.score,snapshot.integrity,snapshot.objective_index,int((int(value.get("votes",0))&1)!=0)+int((int(value.get("votes",0))&2)!=0)]
	select_button.visible=host and phase=="LOBBY"
	level_choice.select(LevelCatalog.current().index_of(lobby.level_id)); level_choice.disabled = not (host and phase=="LOBBY")
	var progress: ProgressStore = value.get("progress")
	for index: int in range(level_choice.item_count): level_choice.set_item_disabled(index,host and progress!=null and not progress.unlocked(LevelCatalog.current().ids()[index]))
	status.text += "\n%d. %s · %s" % [LevelCatalog.current().index_of(lobby.level_id)+1,LevelCatalog.current().entry(lobby.level_id).name,"Normal" if lobby.difficulty==0 else "Relaxed"]
	if phase=="RESULTS" and snapshot!=null and snapshot.phase==GameTypes.MatchPhase.WON and not value.get("confirmed",false): status.text += "\nCzekam na potwierdzenie wyniku hosta…"
	if phase=="LOBBY" and progress!=null and progress.continue_id()==&"":status.text+="\nKampania ukończona — wybierz poziom do powtórki."
	seed.value = lobby.seed; difficulty.select(lobby.difficulty)
	seed.editable = host and phase in ["LOBBY","RESULTS"]; difficulty.disabled = not (host and phase == "LOBBY")
	apply_options.visible = host and phase in ["LOBBY","RESULTS"]
	if phase == "RESULTS": seed.value = value.get("next_seed",lobby.seed)
	ready_button.visible = phase == "LOBBY"; ready_button.disabled = not value.get("approved",false)
	start.visible = host and phase == "LOBBY"; start.disabled = not lobby.can_start() or not value.get("approved",false)
func present_loading(progress: float,remote_loaded: bool) -> void:
	status.text = "Ładowanie: %d%% · Partner: %s\nM11a/b — czekam na wspólny start" % [int(progress*100),"gotowy" if remote_loaded else "czekam"]
