class_name AssetCatalog
extends RefCounted
var packed_scenes: Dictionary = {}
var textures: Dictionary = {}
var audio: Dictionary = {}
var fonts: Dictionary = {}
var config: GameConfig
var dock: MapDefinition
var maps: Dictionary = {}
static func map_ids() -> Array[StringName]: return LevelCatalog.current().ids()
var pending_path: String = ""
var loading_error: String = ""

func load_boot() -> GameTypes.Result:
	var data: Dictionary = preload("res://tools/validate_content.gd").load_content()
	if not data.ok: return GameTypes.Result.new(false,1,data.message)
	dock = data.map; maps = data.maps
	config = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var asset_check: GameTypes.Result = preload("res://tools/validate_content.gd").validate_assets()
	if not asset_check.ok: return asset_check
	fonts["ui"] = load("res://assets/fonts/AtkinsonHyperlegible-Regular.ttf")
	fonts["bold"] = load("res://assets/fonts/AtkinsonHyperlegible-Bold.ttf")
	for id: String in ["drone_a","drone_b","sensor","station_atlas","devices","particle","dock_bg","garden_bg","reactor_bg"]: textures[id] = load("res://assets/art/"+id+".svg")
	textures["grain"] = load("res://assets/art/grain.png")
	for id: String in ["icons","title"]: textures[id] = load("res://assets/ui/"+id+".svg")
	var atlas_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/atlas_regions.json"))
	for id: String in atlas_data.regions:
		var entry: Dictionary = atlas_data.regions[id]
		var region: AtlasTexture = AtlasTexture.new(); region.atlas = textures[entry.atlas]
		region.region = Rect2(entry.rect[0],entry.rect[1],entry.rect[2],entry.rect[3]); region.filter_clip = true
		textures[id] = region
	return GameTypes.Result.new(true,0,"")

func begin_sector(map_id: StringName) -> void:
	loading_error = ""; pending_path = ""
	if map_id not in map_ids() or not maps.has(map_id):
		loading_error = "Unknown or unvalidated map: "+String(map_id); return
	pending_path = "res://scenes/world.tscn"
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(pending_path)
	if status in [ResourceLoader.THREAD_LOAD_IN_PROGRESS,ResourceLoader.THREAD_LOAD_LOADED]: return
	var error: Error = ResourceLoader.load_threaded_request(pending_path,"PackedScene")
	if error != OK: loading_error = "Cannot request sector scene (%d)" % error

func poll_loading() -> GameTypes.Result:
	if not loading_error.is_empty(): return GameTypes.Result.new(false,1,loading_error)
	if pending_path.is_empty(): return GameTypes.Result.new(false,ERR_BUSY,"No pending load")
	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(pending_path,progress)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: return GameTypes.Result.new(false,ERR_BUSY,"loading",progress)
	if status != ResourceLoader.THREAD_LOAD_LOADED: return GameTypes.Result.new(false,1,"Sector load failed")
	var scene: PackedScene = ResourceLoader.load_threaded_get(pending_path) as PackedScene
	if scene == null: return GameTypes.Result.new(false,1,"Sector is not a PackedScene")
	packed_scenes["world"] = scene
	return GameTypes.Result.new(true,0,"",scene)

func get_scene(id: StringName) -> PackedScene:
	return packed_scenes.get(String(id)) as PackedScene
func get_texture(id: StringName) -> Texture2D:
	return textures.get(String(id)) as Texture2D
func get_audio(id: StringName) -> AudioStream:
	return audio.get(String(id)) as AudioStream
func release_sector() -> void:
	pending_path = ""; loading_error = ""; packed_scenes.erase("world")

func map_for_sector(index: int) -> MapDefinition:
	return maps.get(map_ids()[index]) as MapDefinition if index>=0 and index<map_ids().size() else null
