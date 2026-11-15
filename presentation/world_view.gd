class_name WorldView
extends Node2D
class WorldLayer extends Node2D:
	var view: WorldView
	var kind: String
	func _draw() -> void: view.draw_layer(kind,self)
var difficulty: int = 0
var variant: int = 0
var pings: Dictionary = {}
var render_tick: float = -1
var snapshot: GameSnapshot
var link_view: LinkView
var map: MapDefinition
var drones: Array[DroneView] = []
var assets: AssetCatalog
var layers: Array[WorldLayer] = []
var devices: Array[Sprite2D] = []
var emitters: Array[Sprite2D] = []
var fx: FxPool
var wall_style: StyleBoxTexture
var high_quality: bool = true
var reduced_motion: bool = false
var visual_time: float = 0.0
var warming: bool = false
var latch_flashes: Dictionary = {}
var warm_sprites: Array[Sprite2D] = []
func _ready() -> void:
	visibility_changed.connect(func() -> void: $HUD.visible = is_visible_in_tree())
func configure(definition: MapDefinition,level: int = 0,layout_variant: int = 0,catalog: AssetCatalog = null) -> void:
	difficulty = level; variant = layout_variant; map = definition
	assets = catalog if catalog!=null else AssetCatalog.new()
	if assets.textures.is_empty():
		var loaded: GameTypes.Result = assets.load_boot()
		if not loaded.ok: push_error(loaded.message); return
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	link_view = $LinkView as LinkView
	for pair: Array in [["background",-100],["floor",-60],["walls",-40],["fields",5],["telegraph",-20],["devices",0],["hazards",30],["obstacles",35],["markers",45]]:
		var layer: WorldLayer = WorldLayer.new(); layer.view = self; layer.kind = pair[0]; layer.z_index = pair[1]; add_child(layer); layers.append(layer)
	wall_style = StyleBoxTexture.new(); wall_style.texture = assets.get_texture(&"station_12")
	wall_style.texture_margin_left = 18; wall_style.texture_margin_right = 18; wall_style.texture_margin_top = 18; wall_style.texture_margin_bottom = 18
	var background: Sprite2D = Sprite2D.new(); background.texture = assets.get_texture(StringName(map.background_asset.trim_suffix("_background")+"_bg")); background.modulate = Color(LevelCatalog.current().entry(map.id).get("tint","ffffff")); background.centered = false; background.z_index = -100; add_child(background)
	var material: ShaderMaterial = ShaderMaterial.new(); material.shader = preload("res://shaders/background.gdshader"); material.set_shader_parameter("grain_texture",assets.get_texture(&"grain")); background.material = material
	for i: int in range(3):
		var device: Sprite2D = Sprite2D.new(); device.position = map.beacons[i]; device.texture = assets.get_texture(&"beacon_off"); device.scale = Vector2.ONE*0.26
		var effect: ShaderMaterial = ShaderMaterial.new(); effect.shader = preload("res://shaders/device.gdshader"); device.material = effect; add_child(device); devices.append(device)
	for hazard: MapDefinition.HazardDef in map.hazards:
		var emitter: Sprite2D = Sprite2D.new(); emitter.texture = assets.get_texture(&"pulse" if hazard.type=="PULSE" else &"sweep"); emitter.position = hazard.a; emitter.scale = Vector2.ONE*(0.32 if hazard.type=="PULSE" else 0.26); emitter.z_index = 29
		var effect: ShaderMaterial = ShaderMaterial.new(); effect.shader = preload("res://shaders/device.gdshader"); emitter.material = effect; add_child(emitter); emitters.append(emitter)
	for slot: int in range(2):
		var drone: DroneView = preload("res://scenes/drone.tscn").instantiate(); drone.configure(slot); add_child(drone); drones.append(drone)
	fx = FxPool.new(); fx.z_index = 50; add_child(fx)
func set_quality(high: bool) -> void:
	high_quality = high; link_view.set_quality(high); fx.set_quality(high)
func set_reduced_motion(value: bool) -> void:
	reduced_motion = value; link_view.set_reduced_motion(value); fx.set_reduced_motion(value)
	for drone: DroneView in drones: drone.set_reduced_motion(value)
	for device: Sprite2D in devices+emitters: (device.material as ShaderMaterial).set_shader_parameter("motion",0.0 if value else 1.0)
	($CameraRig as CameraRig).reduced_motion = value
func apply_settings(settings: GameTypes.SettingsData) -> void:
	set_reduced_motion(settings.reduced_motion); ($CameraRig as CameraRig).shake = settings.shake
func present(frame: GameTypes.RenderFrame,delta: float) -> void:
	visual_time += maxf(0,delta)
	for slot: int in range(mini(drones.size(),frame.players.size())):
		drones[slot].present(frame.players[slot],delta)
		if frame.players[slot].mode==GameTypes.PlayerMode.DASH and frame.players[slot].consumed_serials.x!=drones[slot].dash_serial:
			var dash: GameEvent = GameEvent.new(); dash.type = GameEvent.EventType.DASH; dash.player_id = slot; dash.value = frame.players[slot].consumed_serials.x; dash.position = frame.players[slot].position
			play_event(dash)
func play_event(event: GameEvent) -> void:
	var visual: GameEvent = event.copy()
	if visual.type==GameEvent.EventType.BEACON and visual.object_id<3: visual.position = map.beacons[visual.object_id]
	elif visual.type in [GameEvent.EventType.HIT,GameEvent.EventType.DASH]: visual.position = drones[visual.player_id].position
	elif visual.type==GameEvent.EventType.SOCKET and visual.object_id<map.sockets.size(): visual.position = map.sockets[visual.object_id]
	if visual.type==GameEvent.EventType.PING: pings[visual.player_id] = visual
	fx.emit_event(visual)
	if visual.player_id<drones.size(): drones[visual.player_id].play_event(visual)
	if visual.type==GameEvent.EventType.HIT: ($CameraRig as CameraRig).impulse(3,0.16)
	elif visual.type==GameEvent.EventType.BEACON: ($CameraRig as CameraRig).impulse(1.5,0.1)
func present_snapshot(value: GameSnapshot,frame: GameTypes.RenderFrame = null) -> void:
	if snapshot!=null:
		for i: int in range(3):
			if value.latched_mask&(1<<i) and not snapshot.latched_mask&(1<<i): latch_flashes[i] = visual_time+1.2
	snapshot = value; render_tick = frame.tick_float if frame!=null else value.tick
	var collision: CollisionWorld = CollisionWorld.new(); collision.configure(map)
	var players: Array[WorldState.PlayerState] = []; players.assign(frame.players if frame!=null else snapshot.players)
	var link: GameTypes.LinkResult = LinkSystem.new().evaluate(players,snapshot.active_socket,map,collision,snapshot.sector_tick,difficulty,variant)
	var status: int = snapshot.link_status
	for player: WorldState.PlayerState in players:
		if player.mode==GameTypes.PlayerMode.DASH and status!=GameTypes.LinkStatus.JAMMED: status = GameTypes.LinkStatus.PLAYER_BUSY
	if status in [GameTypes.LinkStatus.OCCLUDED,GameTypes.LinkStatus.SHUTTERED] and not link.blocked_point.is_finite(): link = LinkSystem.new().evaluate(snapshot.players,snapshot.active_socket,map,collision,snapshot.sector_tick,difficulty,variant)
	link_view.present(PackedVector2Array(link.points),status,0,link.blocked_point)
	for i: int in range(devices.size()):
		devices[i].texture = assets.get_texture(&"beacon_on" if snapshot.complete_mask&(1<<i) else &"beacon_off")
		(devices[i].material as ShaderMaterial).set_shader_parameter("charge",float(snapshot.charges[i])/300)
	for i: int in range(emitters.size()):
		var phase: Dictionary = HazardSystem.new().phase_at(map.hazards[i],snapshot.sector_tick+maxi(0,int(render_tick)-snapshot.tick),difficulty,variant)
		(emitters[i].material as ShaderMaterial).set_shader_parameter("warning",1.0 if phase.phase in [1,2] else 0.0)
		(emitters[i].material as ShaderMaterial).set_shader_parameter("charge",1.0 if phase.phase==2 else 0.0)
	for drone: DroneView in drones: drone.celebrating = snapshot.phase==GameTypes.MatchPhase.WON
	for layer: WorldLayer in layers: layer.queue_redraw()
func _tex(canvas: CanvasItem,id: StringName,position: Vector2,size: float) -> void:
	canvas.draw_texture_rect(assets.get_texture(id),Rect2(position-Vector2.ONE*size/2,Vector2.ONE*size),false)
func draw_layer(kind: String,canvas: CanvasItem) -> void:
	if map==null: return
	if kind=="floor":
		var style: Dictionary=LevelCatalog.current().entry(map.id)
		var tint: Color=Color(style.get("tint","ffffff"))
		if style.get("motif","") in ["circuits","channels","orbits","interference","heart"]:
			for band: int in range(5):
				var y: float=128+band*112
				if style.motif=="orbits": canvas.draw_arc(Vector2(640,360),float(104+band*64),0,TAU,80,Color(tint,0.09),2,true)
				elif style.motif=="heart": canvas.draw_line(Vector2(64,y),Vector2(640,360),Color(tint,0.12),2,true); canvas.draw_line(Vector2(1216,y),Vector2(640,360),Color(tint,0.12),2,true)
				else: canvas.draw_dashed_line(Vector2(64,y),Vector2(1216,y),Color(tint,0.12),3,18,true,true)
		for i: int in range(map.sockets.size()):
			canvas.draw_texture_rect(assets.get_texture(StringName("station_%02d" % (i*4+2))),Rect2(map.sockets[i]-Vector2(48,48),Vector2(96,96)),false,Color(1,1,1,0.5))
	elif kind=="fields" and snapshot!=null:
		for id: int in range(map.objectives.size()):
			if id!=snapshot.objective_index: continue
			var rule: MapDefinition.ObjectiveDef = map.objectives[id]
			for stage: int in range(rule.stabilization.size()):
				var active: bool = snapshot.objective_index==id and stage==(1 if snapshot.latched_mask&(1<<id) else 0)
				for slot: int in range(2):
					var point: Vector2 = rule.stabilization[stage][slot]
					var occupied: bool = false
					for player: WorldState.PlayerState in snapshot.players:
						if player.mode==0 and player.position.distance_to(point)<=44: occupied = true
					var color: Color = Color("6fe2bb") if occupied and active else (Color("efd58c") if active else Color("6e8793"))
					canvas.draw_line(point,map.beacons[id],Color(color,0.20 if active else 0.07),1,true)
					if active:
						canvas.draw_circle(point,44,Color(color,0.14 if occupied else 0.035)); canvas.draw_arc(point,44,0,TAU,48,color,3 if occupied else 2,true)
					else:
						for angle: int in range(0,360,30): canvas.draw_arc(point,44,deg_to_rad(angle),deg_to_rad(angle+16),4,Color(color,0.35),1,true)
					canvas.draw_string(assets.fonts.bold,point+Vector2(-23,61),"%d%s%s" % [id+1,"A" if slot==0 else "B",("·%d" % (stage+1)) if rule.stabilization.size()==2 else ""],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(color,1.0 if active else 0.5))
	elif kind=="obstacles":
		for obstacle: MapDefinition.ObstacleDef in map.obstacles:
			var phase: int = ObstacleSystem.phase_at(obstacle,snapshot.sector_tick if snapshot!=null else 0,difficulty,variant).phase
			var tint: Color = Color("b38beb") if obstacle.type=="JAM" else Color("76d4e4")
			if phase==1: tint=Color("f4d27a")
			canvas.draw_rect(obstacle.rect,Color(tint,0.22 if phase==2 else 0.035))
			canvas.draw_rect(obstacle.rect,Color(tint,1.0 if phase>0 else 0.4),false,3 if phase>0 else 1)
			if obstacle.type=="SHUTTER" and phase==2:
				canvas.draw_line(obstacle.rect.position,obstacle.rect.end,tint,4,true); canvas.draw_line(Vector2(obstacle.rect.end.x,obstacle.rect.position.y),Vector2(obstacle.rect.position.x,obstacle.rect.end.y),tint,4,true)
			canvas.draw_string(assets.fonts.bold,obstacle.rect.position+Vector2(0,-7),("ZAKŁÓCENIA" if obstacle.type=="JAM" else "PRZESŁONA")+(([" · CISZA"," · UWAGA"," · ZAKŁÓCA"] if obstacle.type=="JAM" else [" · OTWARTA"," · UWAGA"," · ZAMKNIĘTA"])[phase]),HORIZONTAL_ALIGNMENT_LEFT,-1,12,tint)
	elif kind=="walls":
		for wall: Rect2 in map.walls:
			canvas.draw_rect(Rect2(wall.position+Vector2(6,6),wall.size),Color(0,0,0,0.18))
			canvas.draw_style_box(wall_style,wall)
	elif kind=="devices":
		for i: int in range(map.sockets.size()): _tex(canvas,&"socket_on" if snapshot!=null and snapshot.active_socket==i else &"socket_off",map.sockets[i],24)
		var complete: bool = snapshot!=null and snapshot.objective_index>=3
		_tex(canvas,&"exit_on" if complete else &"exit_off",map.exit_position,144)
		canvas.draw_arc(map.exit_position,64,0,TAU,64,Color("e9f6bf") if complete else Color("526d76"),2,true)
		if snapshot!=null:
			for i: int in range(3):
				var active: bool = i==snapshot.objective_index and snapshot.objective_index<3
				canvas.draw_arc(map.beacons[i],18,-PI/2,-PI/2+TAU*maxf(0.001,float(snapshot.charges[i])/300),48,Color("e9f6bf"),3,true)
				canvas.draw_string(assets.fonts.ui,map.beacons[i]+Vector2(-4,-23),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f2f5ef") if active else Color("8ca6ab"))
		if snapshot!=null:
			for id: int in range(map.objectives.size()):
				if id!=snapshot.objective_index or map.objectives[id].stabilization.size()!=2: continue
				var latched: bool = snapshot.latched_mask&(1<<id)!=0
				canvas.draw_string(assets.fonts.bold,map.beacons[id]+Vector2(-30,36),"150 ✓ · 2/2" if latched else "1/2 → 150",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("6fe2bb") if latched else Color("efd58c"))
				if not reduced_motion and visual_time<float(latch_flashes.get(id,0.0)):
					var progress: float = 1.0-(float(latch_flashes[id])-visual_time)/1.2
					canvas.draw_arc(map.beacons[id],24+progress*64,0,TAU,48,Color(0.43,0.89,0.73,1-progress),4,true)
					canvas.draw_string(assets.fonts.bold,map.beacons[id]+Vector2(-80,-48),"150 ZACHOWANE · ZMIEŃCIE POLA",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("6fe2bb"))
	elif kind in ["telegraph","hazards"]:
		var tick: int = snapshot.sector_tick+maxi(0,int(render_tick)-snapshot.tick) if snapshot!=null else 0
		for hazard: MapDefinition.HazardDef in map.hazards:
			var phase: Dictionary = HazardSystem.new().phase_at(hazard,tick,difficulty,variant)
			var active: bool = phase.phase==2
			if kind=="telegraph" and phase.phase==1:
				if hazard.type=="PULSE":
					canvas.draw_arc(hazard.a,hazard.radius,0,TAU,48,Color("f4d27a"),2,true)
					for angle: int in range(0,360,45):
						var direction: Vector2 = Vector2.from_angle(deg_to_rad(angle)); canvas.draw_line(hazard.a+direction*38,hazard.a+direction*48,Color("f4d27a"),2,true)
				else:
					var area: Rect2 = Rect2(hazard.a,Vector2.ZERO).expand(hazard.b).expand(hazard.a+hazard.travel).expand(hazard.b+hazard.travel).grow(5)
					canvas.draw_rect(area,Color(0.96,0.82,0.48,0.08)); canvas.draw_rect(area,Color("f4d27a"),false,1)
			elif kind=="hazards":
				if hazard.type=="PULSE":
					if active:
						canvas.draw_circle(hazard.a,hazard.radius,Color(0.94,0.44,0.47,0.12))
						canvas.draw_arc(hazard.a,hazard.radius,0,TAU,64,Color("f07178"),3,true)
						for angle: int in range(0,360,30):
							var direction: Vector2 = Vector2.from_angle(deg_to_rad(angle)); canvas.draw_line(hazard.a+direction*30,hazard.a+direction*42,Color("f07178"),2,true)
						canvas.draw_string(assets.fonts.bold,hazard.a+Vector2(-4,6),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f2f5ef"))
				else:
					if active:
						var a: Vector2 = hazard.a+phase.offset; var b: Vector2 = hazard.b+phase.offset
						canvas.draw_line(a,b,Color(0.94,0.44,0.47,0.13),16 if high_quality else 10,true)
						canvas.draw_line(a,b,Color("f07178"),10,true); canvas.draw_line(a,b,Color("f2f5ef"),2,true)
	elif kind=="markers" and snapshot!=null:
		for slot: int in pings:
			var ping: GameEvent = pings[slot]
			if snapshot.tick-ping.tick<90:
				canvas.draw_arc(ping.position,30+slot*5,0,TAU,32,Color("e9f6bf"),2,true)
				_tex(canvas,&"icon_ping",ping.position-Vector2(0,34),24)
func prewarm() -> void:
	warming = true
	var ring: GameEvent = GameEvent.new(); ring.id = -1; ring.type = GameEvent.EventType.BEACON; ring.position = Vector2(640,360); fx.emit_event(ring)
	var trail: GameEvent = GameEvent.new(); trail.id = -2; trail.type = GameEvent.EventType.DASH; trail.value = 65535; trail.position = Vector2(640,360); fx.emit_event(trail)
	for shader: Shader in [preload("res://shaders/device.gdshader"),preload("res://shaders/link.gdshader"),preload("res://shaders/background.gdshader")]:
		var sprite: Sprite2D = Sprite2D.new(); sprite.texture = assets.get_texture(&"particle"); sprite.position = Vector2(640,360); sprite.scale = Vector2(2,2); sprite.z_index = 60
		var material: ShaderMaterial = ShaderMaterial.new(); material.shader = shader
		if shader==preload("res://shaders/background.gdshader"): material.set_shader_parameter("grain_texture",assets.get_texture(&"grain"))
		sprite.material = material; add_child(sprite); warm_sprites.append(sprite)
	link_view.present(PackedVector2Array([Vector2(620,360),Vector2(660,360)]),GameTypes.LinkStatus.ACTIVE,0)
func finish_warmup() -> void:
	for sprite: Sprite2D in warm_sprites: sprite.queue_free()
	warm_sprites.clear(); fx.clear(); warming = false; link_view.present(PackedVector2Array(),GameTypes.LinkStatus.PLAYER_BUSY,0)
