class_name LobbyState
extends RefCounted
var revision: int = 1
var ready_mask: int = 0
var names: Array[String] = ["Host",""]
var room: String = "LUMEN LINK"
var difficulty: int = 0
var seed: int = 0
var level_id: StringName = LevelCatalog.current().first_id()
func set_ready(slot: int,value: bool) -> void:
	if slot not in [0,1]: return
	if value: ready_mask |= 1 << slot
	else: ready_mask &= ~(1 << slot)
func set_options(level: int,expedition_seed: int, selected_id: StringName = level_id) -> void:
	if level not in [0,1] or expedition_seed < 0 or expedition_seed > 0xffffffff: return
	if not LevelCatalog.current().has_level(selected_id): return
	if difficulty != level or seed != expedition_seed or level_id != selected_id:
		difficulty = level; seed = expedition_seed; level_id = selected_id; revision = (revision+1)&0xffffffff; ready_mask = 0
func can_start() -> bool:
	return ready_mask == 3 and not names[1].is_empty()
func payload() -> Dictionary:
	return {"level_id":String(level_id),"revision":revision,"ready_mask":ready_mask,"difficulty":difficulty,"seed":seed,"room":room,"name0":names[0],"name1":names[1]}
func apply(data: Dictionary) -> void:
	level_id = StringName(data.level_id); revision = data.revision; ready_mask = data.ready_mask; difficulty = data.difficulty; seed = data.seed
	room = data.room; names = [data.name0,data.name1]
