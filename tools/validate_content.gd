extends SceneTree
const Config = preload("res://core/game_config.gd")
const Map = preload("res://core/map_definition.gd")
static var _validated_sources: Dictionary = {}
static func map_ids() -> Array[StringName]: return LevelCatalog.current().ids()

static func load_content() -> Dictionary:
	var catalog: GameTypes.Result=LevelCatalog.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json")))
	if not catalog.ok: return {"ok":false,"message":catalog.message}
	var config_source: String = FileAccess.get_file_as_string("res://data/gameplay.json")
	var c: Variant = JSON.parse_string(config_source)
	if not c is Dictionary: return {"ok":false,"message":"data/gameplay.json: invalid JSON"}
	var config: GameTypes.Result = Config.from_json(c)
	if not config.ok: return {"ok":false,"message":config.message}
	var maps: Dictionary = {}
	for id: StringName in map_ids():
		var path: String = "res://data/maps/%s.json" % id
		if not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path).size()>65536: return {"ok":false,"message":path+": missing or >64 KiB"}
		var map_source: String = FileAccess.get_file_as_string(path)
		var d: Variant = JSON.parse_string(map_source)
		if not d is Dictionary: return {"ok":false,"message":path+": invalid JSON"}
		var parsed: GameTypes.Result = Map.from_json(d)
		if not parsed.ok: return {"ok":false,"message":path+": "+parsed.message}
		var definition: MapDefinition = parsed.value
		if definition.id != id: return {"ok":false,"message":path+": unexpected map id"}
		var signature: String = config_source.sha256_text()+":"+map_source.sha256_text()
		# Cache only validation facts; parsed definitions are fresh on every call.
		if _validated_sources.get(path,"") != signature:
			var valid: GameTypes.Result = definition.validate(config.value)
			if not valid.ok: return {"ok":false,"message":path+": "+valid.message}
			_validated_sources[path] = signature
		maps[id] = definition
	return {"ok":true,"message":"level catalog: schema, safety, flood-fill PASS","map":maps[&"dock"],"maps":maps,"config":config.value,"pending":[]}

static func validate_assets() -> GameTypes.Result:
	var sizes: Dictionary = {"assets/art/drone_a.svg":Vector2i(64,64),"assets/art/drone_b.svg":Vector2i(64,64),"assets/art/sensor.svg":Vector2i(16,16),"assets/art/station_atlas.svg":Vector2i(1024,1024),"assets/art/devices.svg":Vector2i(512,256),"assets/ui/icons.svg":Vector2i(512,256),"assets/ui/title.svg":Vector2i(640,160),"assets/art/particle.svg":Vector2i(16,16),"assets/art/grain.png":Vector2i(128,128)}
	for id: StringName in [&"dock",&"garden",&"reactor"]: sizes["assets/art/%s_bg.svg" % id] = Vector2i(1280,720)
	for path: String in sizes:
		if not ResourceLoader.exists("res://"+path): return GameTypes.Result.new(false,1,path+": missing asset")
		if path.ends_with(".svg") and FileAccess.file_exists("res://"+path):
			var source: String = FileAccess.get_file_as_string("res://"+path)
			if not source.contains('viewBox="0 0 %d %d"' % [sizes[path].x,sizes[path].y]) or source.contains("<script") or source.contains("href="): return GameTypes.Result.new(false,1,path+": invalid SVG or external dependency")
		var texture: Texture2D = load("res://"+path) as Texture2D
		if texture==null or Vector2i(texture.get_size())!=sizes[path]: return GameTypes.Result.new(false,1,path+": dimensions/import")
	var regions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/atlas_regions.json"))
	if not regions is Dictionary or regions.get("schema_version")!=1 or regions.get("padding")!=2 or regions.get("regions",{}).size()!=40: return GameTypes.Result.new(false,1,"atlas_regions: schema/count/padding")
	for id: String in regions.regions:
		var region: Dictionary = regions.regions[id]
		var cell: int = {"station_atlas":256,"devices":128,"icons":64}.get(region.get("atlas",""),0)
		if cell==0 or not region.get("rect") is Array or region.rect.size()!=4: return GameTypes.Result.new(false,1,id+": atlas/rect")
		for n: Variant in region.rect:
			if not (n is int or n is float) or n!=floor(n): return GameTypes.Result.new(false,1,id+": noninteger region")
		var r: Rect2i = Rect2i(region.rect[0],region.rect[1],region.rect[2],region.rect[3])
		var size: Vector2i = Vector2i(1024,1024) if cell==256 else Vector2i(512,256)
		if not Rect2i(Vector2i.ZERO,size).encloses(r) or r.position.x%cell!=2 or r.position.y%cell!=2 or r.size!=Vector2i(cell-4,cell-4): return GameTypes.Result.new(false,1,id+": bounds or padding2")
	var license_text: String = FileAccess.get_file_as_string("res://assets/fonts/OFL.txt")
	if not license_text.contains("SIL OPEN FONT LICENSE Version 1.1"): return GameTypes.Result.new(false,1,"font: OFL missing")
	var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/fonts/SOURCE.json"))
	if not provenance is Dictionary or provenance.get("license")!="OFL-1.1": return GameTypes.Result.new(false,1,"font: provenance missing")
	for entry: Dictionary in provenance.files:
		var path: String = "res://assets/fonts/"+entry.file
		var digest: String = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
		if digest.is_empty() and entry.file.ends_with(".ttf"):
			var font: FontFile = load(path) as FontFile
			if font!=null:
				var context: HashingContext = HashingContext.new(); context.start(HashingContext.HASH_SHA256); context.update(font.data); digest = context.finish().hex_encode()
		if digest!=entry.sha256: return GameTypes.Result.new(false,1,"font: source checksum mismatch")
	for weight: String in ["Regular","Bold"]:
		var font: Font = load("res://assets/fonts/AtkinsonHyperlegible-%s.ttf" % weight) as Font
		if font==null: return GameTypes.Result.new(false,1,"font import missing")
		for character: String in "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ":
			if not font.has_char(character.unicode_at(0)): return GameTypes.Result.new(false,1,"font: missing Polish glyph "+character)
	return GameTypes.Result.new(true,0,"assets: dimensions, atlases, padding, font/license PASS")

func _initialize() -> void:
	var result: Dictionary = load_content()
	var assets: GameTypes.Result = validate_assets()
	print(JSON.stringify({"ok":result.ok and assets.ok,"message":result.message,"assets":assets.message,"pending":result.get("pending",[])}))
	quit(0 if result.ok and assets.ok else 1)
