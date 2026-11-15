extends RefCounted
const P = preload("res://net/protocol.gd")
const Codec = preload("res://net/packet_codec.gd")
const Guard = preload("res://net/message_guard.gd")
static func snapshot() -> GameSnapshot:
	var s: GameSnapshot = GameSnapshot.new()
	s.tick = 10; s.sector_tick = 10; s.remaining_ticks = 10800; s.phase_remaining = 180; s.integrity = 6; s.active_socket = -1
	s.charges = PackedInt32Array([0,0,0])
	for x: float in [112.,176.]:
		var player: WorldState.PlayerState = WorldState.PlayerState.new(); player.position = Vector2(x,592)
		s.players.append(player)
	return s
static func samples() -> Dictionary:
	var hash: PackedByteArray = PackedByteArray(); hash.resize(32)
	var command: InputCommand = InputCommand.new(); command.tick = 1
	var event: GameEvent = GameEvent.new(); event.id = 1; event.position = Vector2(100,100)
	return {1:{"engine":"4.5.2","engine_build":"6ce3de25a","content_hash":hash,"name":"Gość"},2:{"slot":1,"host_name":"Host"},3:{"code":1},4:{"level_id":"dock","revision":1,"ready_mask":3,"difficulty":0,"seed":0,"room":"Pokój","name0":"Host","name1":"Gość"},5:{"revision":1,"ready":1},6:{"sector":0,"level_id":"dock","variant":0,"difficulty":0,"seed":0,"content_hash":hash},7:{"sector":0,"content_hash":hash},8:{"snapshot":snapshot()},9:{"sector":0,"commands":[command]},10:{"snapshot":snapshot()},11:{"events":[event]},12:{"echo_us":1000},13:{"echo_us":1000,"host_tick":10},14:{"kind":0,"value":1},15:{"reason":8},16:{"code":6,"fatal":0},17:{"snapshot":snapshot(),"vote_mask":3,"next_seed":4}}
func run(t: TestAssert) -> void:
	var vectors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/protocol_vectors.json"))
	var header: Dictionary = {"session_id":1,"match_id":2,"sequence":3}
	var codec: Codec = Codec.new()
	var encoded: GameTypes.Result = codec.encode(12,header,{"echo_us":1000})
	t.equal(encoded.value.hex_encode(),vectors.ping_hex,"P01 independent Ping golden")
	t.equal(codec.decode(vectors.ping_hex.hex_decode()).value.payload.echo_us,1000,"P01 decode golden")
	var opaque: GameTypes.Result = codec.encode(12,header,{"echo_us":-1})
	t.equal(opaque.value.slice(22),PackedByteArray([255,255,255,255,255,255,255,255]),"P01 all u64 bits preserved")
	t.equal(codec.decode(opaque.value).value.payload.echo_us,-1,"P01 opaque signed representation roundtrip")
	for type: int in samples():
		encoded = codec.encode(type,header,samples()[type])
		t.is_true(encoded.ok,"P02 encode type %d" % type)
		if not encoded.ok: continue
		var data: PackedByteArray = encoded.value
		var decoded: GameTypes.Result = codec.decode(data)
		t.is_true(decoded.ok,"P02 decode type %d" % type)
		if decoded.ok: t.equal(codec.encode(type,header,decoded.value.payload).value,data,"P02 roundtrip %d" % type)
		var trailing: PackedByteArray = data.duplicate(); trailing.append(0)
		t.fails(codec.decode(trailing),"P02 trailing %d" % type)
		var truncated_ok: bool = true
		for i: int in range(data.size()):
			if codec.decode(data.slice(0,i)).ok: truncated_ok = false
		t.is_true(truncated_ok,"P03 truncation every byte %d" % type)
	encoded = codec.encode(10,header,{"snapshot":snapshot()})
	t.equal(encoded.value.size(),139,"P02 snapshot v3 total139 for dock")
	t.equal(encoded.value.slice(22).hex_encode(),vectors.snapshot_body_hex,"P02 independent snapshot117/player35")
	var bad: PackedByteArray = encoded.value.duplicate(); bad.encode_float(22+47,NAN)
	t.fails(codec.decode(bad),"P03 NaN rejected")
	bad.encode_float(22+47,INF); t.fails(codec.decode(bad),"P03 Infinity rejected")
	bad = encoded.value.duplicate(); bad[22+14] = 255; t.fails(codec.decode(bad),"P03 bad phase")
	encoded = codec.encode(9,header,samples()[9]); bad = encoded.value.duplicate(); bad[23] = 255
	t.fails(codec.decode(bad),"P03 count before allocation")
	bad = encoded.value.duplicate(); bad[28] = 128
	t.fails(codec.decode(bad),"P03 axis -128")
	encoded = codec.encode(1,{},samples()[1]); bad = encoded.value.duplicate(); bad[23] = 255
	t.fails(codec.decode(bad),"P03 malformed UTF8 rejected before conversion")
	bad = encoded.value.duplicate(); bad[23] = 0
	t.fails(codec.decode(bad),"P03 NUL rejected")
	t.is_true(P.newer(0,0xffffffff) and not P.newer(0xffffffff,0),"P04 modular sequence")
	var guard: Guard = Guard.new()
	var msg: Codec.DecodedMessage = codec.decode(vectors.ping_hex.hex_decode()).value
	var context: Dictionary = {"is_host":true,"state":"PLAYING","session_id":1,"match_id":2,"approved":true,"sector":0,"packet_size":30}
	t.is_true(guard.accept(2,msg,context,0).ok,"P04 guard accepted")
	t.fails(guard.accept(2,msg,context,1),"P04 duplicate rejected")
	msg.session_id = 9; t.fails(guard.accept(2,msg,context,2),"P04 old session rejected")
	guard.reset(); msg.session_id = 1
	var rate_hits: int = 0
	for i: int in range(8): msg.sequence = i; rate_hits += int(not guard.accept(2,msg,context,100).ok)
	t.is_true(rate_hits >= 4,"P04 Ping rate limit4")
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/dock.json"))).value
	var sim: Simulation = Simulation.new(); sim.initialize(config,map,0,0)
	var command: InputCommand = InputCommand.new(); command.dash_serial = 17
	var events: Array[GameEvent] = sim.step([command,InputCommand.new()])
	t.equal(events[0].value,17,"P02 real DASH carries serial")
	t.is_true(codec.encode(11,header,{"events":events}).ok,"P02 generated event wire validation")
	var longest: GameSnapshot=snapshot();longest.level_id=StringName("a".repeat(32));longest.sector_index=63
	t.equal(codec.encode(10,{}, {"snapshot":longest}).value.size(),22+P.MAX_SNAPSHOT_BYTES,"P05 max stable ID and catalog index remain within packet cap")
	var original: LevelCatalog=LevelCatalog.current();var reordered: LevelCatalog=LevelCatalog.new();reordered.entries=original.entries.duplicate(true);reordered.entries.reverse();LevelCatalog._default=reordered
	var index: int=reordered.index_of(&"dock")
	var load_packet: GameTypes.Result
	# A hash is always exactly32 bytes.
	var hash: PackedByteArray=PackedByteArray();hash.resize(32)
	load_packet=codec.encode(6,{}, {"sector":index,"level_id":"dock","variant":(17*index)%3,"difficulty":0,"seed":0,"content_hash":hash})
	t.is_true(load_packet.ok and codec.decode(load_packet.value).value.payload.level_id=="dock","P05 reordered catalog loads stable ID with newly derived ordinal")
	LevelCatalog._default=original
	set_meta("completed",true)
