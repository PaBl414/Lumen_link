extends RefCounted
func run(t: TestAssert) -> void:
 var content: Dictionary=preload("res://tools/validate_content.gd").load_content()
 var map: MapDefinition=content.maps[&"observatory"]
 var gate: MapDefinition.ObstacleDef=map.obstacles[0]
 t.equal(ObstacleSystem.phase_at(gate,359,0,0).phase,0,"OB open until warning")
 t.equal(ObstacleSystem.phase_at(gate,360,0,0).phase,1,"OB ninety tick warning")
 t.equal(ObstacleSystem.phase_at(gate,450,0,0).phase,2,"OB closed from tick450")
 t.equal(ObstacleSystem.phase_at(gate,540,0,0).phase,0,"OB reopens deterministically")
 var world: WorldState=WorldState.new();world.reset(map,content.config,6)
 world.players[0].position=Vector2(208,240);world.players[1].position=Vector2(464,240)
 var collision: CollisionWorld=CollisionWorld.new();collision.configure(map)
 var system: LinkSystem=LinkSystem.new()
 var link: GameTypes.LinkResult=system.evaluate(world.players,-1,map,collision,450)
 t.equal(link.status,GameTypes.LinkStatus.SHUTTERED,"OB optical shutter blocks direct wire")
 t.is_true(link.blocked_point.is_finite() and link.blocked_segment==0,"OB actual blocked segment contact")
 t.is_true(not collision.blocks_segment(Vector2(208,240),Vector2(464,240),12),"OB shutter does not block drone movement")
 world.players[0].position=Vector2(656,144);world.players[1].position=Vector2(1008,240)
 link=system.evaluate(world.players,0,map,collision,510)
 t.equal(link.status,GameTypes.LinkStatus.SHUTTERED,"OB checks second relay arm")
 t.equal(link.blocked_segment,1,"OB shutter marker on second arm")
 map=content.maps[&"interference"];world.reset(map,content.config,6);collision.configure(map)
 world.players[0].position=Vector2(208,240);world.players[1].position=Vector2(464,240)
 world.players[0].invulnerable_ticks=90;world.players[0].mode=GameTypes.PlayerMode.DASH
 link=system.evaluate(world.players,-1,map,collision,180)
 t.equal(link.status,GameTypes.LinkStatus.JAMMED,"OB dash and immunity cannot cancel interference")
 t.is_true("zakłóceń" in ObjectiveSystem.message(_snapshot(world,link.status),map),"OB explanatory interference message")
 world.players[0].mode=0;world.players[0].position=Vector2(112,240)
 t.equal(system.evaluate(world.players,-1,map,collision,180).status,GameTypes.LinkStatus.ACTIVE,"OB leaving zone restores wire immediately")
 t.equal(world.integrity,6,"OB interference does not deal damage")
 world.obstacle_active_mask=1;world.obstacle_warning_mask=2
 var snap: GameSnapshot=GameSnapshot.capture(world)
 var encoded: GameTypes.Result=PacketCodec.new().encode(10,{}, {"snapshot":snap})
 t.is_true(encoded.ok,"OB snapshot encodes obstacle state and stable ID")
 var restored: GameSnapshot=PacketCodec.new().decode(encoded.value).value.payload.snapshot
 t.equal(restored.level_id,&"interference","OB stable ID roundtrip")
 t.equal(restored.obstacle_active_mask,1,"OB active mask survives full snapshot")
 t.equal(restored.obstacle_warning_mask,2,"OB warning mask survives full snapshot")
 t.is_true(restored.validate(map,content.config).ok,"OB restored state validates")
 restored.obstacle_active_mask=65535;t.fails(restored.validate(map,content.config),"OB rejects nonexistent obstacle bits")
 var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/observatory.json"))
 raw.obstacles[0].normal=[360,1,60];t.fails(MapDefinition.from_json(raw),"OB rejects insufficient reaction warning")
 set_meta("completed",true)
func _snapshot(world: WorldState,status: int) -> GameSnapshot:
 var snap: GameSnapshot=GameSnapshot.capture(world);snap.link_status=status;return snap
