class_name SceneRouter
extends RefCounted
signal scene_ready(scene_id: StringName)
const Catalog = preload("res://services/asset_catalog.gd")
var container: Node
var active: Node
var pending_generation: int = 0
var active_generation: int = -1
var assets: Catalog
var _requested_generation: int = -1
var pending: bool = false

func configure(target: Node, catalog: Catalog = null) -> void:
	container = target
	assets = catalog if catalog != null else Catalog.new()

func show(scene_id: StringName,map_id: StringName = &"dock") -> GameTypes.Result:
	if container == null or scene_id != &"world": return GameTypes.Result.new(false,1,"Unknown scene or missing container")
	clear()
	pending = true; _requested_generation = pending_generation
	assets.begin_sector(map_id)
	return GameTypes.Result.new(true,0,"",pending_generation)

func poll() -> GameTypes.Result:
	if not pending: return GameTypes.Result.new(false,ERR_BUSY,"idle")
	var generation: int = _requested_generation
	var result: GameTypes.Result = assets.poll_loading()
	if generation != pending_generation: return GameTypes.Result.new(false,ERR_BUSY,"cancelled")
	if not result.ok:
		if result.code != ERR_BUSY: pending = false
		return result
	pending = false; active_generation = generation
	active = assets.get_scene(&"world").instantiate()
	container.add_child(active)
	scene_ready.emit(&"world")
	return GameTypes.Result.new(true,0,"",active)

func clear() -> void:
	pending_generation += 1; pending = false; active_generation = -1
	if is_instance_valid(active):
		if active.get_parent() != null: active.get_parent().remove_child(active)
		active.queue_free()
	active = null
	if assets != null: assets.release_sector()
