class_name PacketCodec
extends RefCounted
const P = preload("res://net/protocol.gd")
class DecodedMessage extends RefCounted:
	var type: int
	var session_id: int
	var match_id: int
	var sequence: int
	var payload: Dictionary = {}
var bytes: PackedByteArray = PackedByteArray()
var cursor: int = 0
var writing: bool = false
var valid: bool = true
var problem: String = ""

func _bad(detail: String) -> void:
	valid = false
	if problem.is_empty(): problem = detail
func _int(value: Variant, size: int, low: int = 0, high: int = 0xffffffff) -> int:
	if not valid: return 0
	var number: int = 0
	if writing:
		if not value is int: _bad("integer type"); return 0
		number = value
	else:
		if cursor+size > bytes.size(): _bad("truncated integer"); return 0
		match size:
			1: number = bytes.decode_u8(cursor)
			2: number = bytes.decode_u16(cursor)
			4: number = bytes.decode_u32(cursor)
			8: number = bytes.decode_u64(cursor)
		if low < 0 and size == 1 and number >= 128: number -= 256
	if number < low or number > high: _bad("integer range"); return 0
	if writing:
		bytes.resize(cursor+size)
		match size:
			1: bytes.encode_u8(cursor,number & 255)
			2: bytes.encode_u16(cursor,number)
			4: bytes.encode_u32(cursor,number)
			8: bytes.encode_u64(cursor,number)
	cursor += size
	return number
func _float(value: Variant) -> float:
	if not valid: return 0
	var number: float = 0
	if writing:
		if not (value is float or value is int): _bad("float type"); return 0
		number = float(value)
	else:
		if cursor+4 > bytes.size(): _bad("truncated float"); return 0
		number = bytes.decode_float(cursor)
	if not is_finite(number): _bad("nonfinite float"); return 0
	if writing: bytes.resize(cursor+4); bytes.encode_float(cursor,number)
	cursor += 4
	return number
func _raw(value: Variant, size: int) -> PackedByteArray:
	if not valid: return PackedByteArray()
	var result: PackedByteArray
	if writing:
		if not value is PackedByteArray or value.size() != size: _bad("raw bytes length"); return PackedByteArray()
		result = value; bytes.append_array(result)
	else:
		if cursor+size > bytes.size(): _bad("truncated raw bytes"); return PackedByteArray()
		result = bytes.slice(cursor,cursor+size)
	cursor += size
	return result
func _string(value: Variant, max_bytes: int, max_chars: int) -> String:
	var raw: PackedByteArray = PackedByteArray()
	if writing:
		if not value is String: _bad("string type"); return ""
		raw = value.to_utf8_buffer()
	var size: int = _int(raw.size(),1,0,max_bytes)
	raw = _raw(raw,size)
	if not P.valid_utf8(raw): _bad("invalid UTF8"); return ""
	var result: String = raw.get_string_from_utf8()
	if result.to_utf8_buffer() != raw or result.length() > max_chars: _bad("UTF8/character length")
	for i: int in range(result.length()):
		var ch: int = result.unicode_at(i)
		if ch < 32 or (ch >= 127 and ch <= 159): _bad("control character")
	return result
func _field(d: Dictionary,key: String,size: int,lo: int = 0,hi: int = 0xffffffff) -> void:
	d[key] = _int(d.get(key),size,lo,hi)
func _text(d: Dictionary,key: String,max_bytes: int,max_chars: int) -> void:
	d[key] = _string(d.get(key),max_bytes,max_chars)
func _hash(d: Dictionary) -> void:
	d["content_hash"] = _raw(d.get("content_hash"),32)
func _snapshot(value: Variant) -> GameSnapshot:
	var s: GameSnapshot = value if writing and value is GameSnapshot else GameSnapshot.new()
	if writing and not value is GameSnapshot: _bad("snapshot type"); return s
	for field: String in ["tick","sector_tick"]: s.set(field,_int(s.get(field),4))
	s.remaining_ticks = _int(s.remaining_ticks,2,0,14400); s.phase_remaining = _int(s.phase_remaining,2,0,180)
	for field: Array in [["integrity",9],["sector_index",LevelCatalog.MAX_LEVELS-1],["phase",4],["objective_index",3]]: s.set(field[0],_int(s.get(field[0]),1,0,field[1]))
	s.active_socket = _int(s.active_socket,1,-1,2); s.link_status = _int(s.link_status,1,0,6)
	if writing and s.charges.size() != 3: _bad("charge count"); return s
	if not writing: s.charges = PackedInt32Array([0,0,0])
	for i: int in range(3): s.charges[i] = _int(s.charges[i],2,0,300)
	s.extract_ticks = _int(s.extract_ticks,2,0,120); s.socket_cooldown = _int(s.socket_cooldown,1,0,30); s.damage_cooldown = _int(s.damage_cooldown,1,0,30)
	s.score = _int(s.score,4); s.complete_mask = _int(s.complete_mask,1,0,7); s.last_event_id = _int(s.last_event_id,4)
	s.latched_mask = _int(s.latched_mask,1,0,7)
	s.level_id = StringName(_string(String(s.level_id),32,32))
	if not LevelCatalog.valid_id(String(s.level_id)): _bad("level ID")
	s.obstacle_active_mask = _int(s.obstacle_active_mask,2,0,65535)
	s.obstacle_warning_mask = _int(s.obstacle_warning_mask,2,0,65535)
	if s.obstacle_active_mask&s.obstacle_warning_mask: _bad("obstacle masks overlap")
	for i: int in range(3):
		if s.latched_mask&(1<<i) and s.charges[i]<150: _bad("latch below floor")
	if writing and s.players.size() != 2: _bad("player count"); return s
	if not writing: s.players = [WorldState.PlayerState.new(),WorldState.PlayerState.new()]
	for player: WorldState.PlayerState in s.players:
		for field: String in ["position","velocity","facing"]:
			var v: Vector2 = player.get(field)
			player.set(field,Vector2(_float(v.x),_float(v.y)))
		if not player.position.is_finite() or player.position.x < -64 or player.position.x > 1344 or player.position.y < -64 or player.position.y > 784 or player.velocity.length()>721 or absf(player.facing.length()-1)>0.01: _bad("player vectors")
		for field: Array in [["mode",2],["dash_ticks",10],["stun_ticks",12],["invulnerable_ticks",90],["dash_cooldown",90]]: player.set(field[0],_int(player.get(field[0]),1,0,field[1]))
		for i: int in range(3): player.consumed_serials[i] = _int(player.consumed_serials[i],2,0,65535)
	return s
func _payload(type: int,d: Dictionary) -> void:
	match type:
		P.MessageType.HELLO:
			_text(d,"engine",32,32); _text(d,"engine_build",64,64); _hash(d); _text(d,"name",64,20)
		P.MessageType.WELCOME:
			_field(d,"slot",1,1,1); _text(d,"host_name",64,20)
		P.MessageType.REJECT: _field(d,"code",2,1,10)
		P.MessageType.LOBBY_STATE:
			_field(d,"revision",4); _field(d,"ready_mask",1,0,3); _field(d,"difficulty",1,0,1); _field(d,"seed",4)
			_text(d,"level_id",32,32)
			if not LevelCatalog.current().has_level(StringName(d.level_id)): _bad("unknown level")
			_text(d,"room",80,24); _text(d,"name0",64,20); _text(d,"name1",64,20)
		P.MessageType.SET_READY: _field(d,"revision",4); _field(d,"ready",1,0,1)
		P.MessageType.LOAD_SECTOR:
			_field(d,"sector",1,0,LevelCatalog.MAX_LEVELS-1); _text(d,"level_id",32,32); _field(d,"variant",1,0,2); _field(d,"difficulty",1,0,1); _field(d,"seed",4); _hash(d)
			if LevelCatalog.current().index_of(StringName(d.level_id)) != d.sector: _bad("level/index mismatch")
			if d.variant != (d.seed+17*d.sector)%3: _bad("variant")
		P.MessageType.LOADED: _field(d,"sector",1,0,LevelCatalog.MAX_LEVELS-1); _hash(d)
		P.MessageType.BEGIN,P.MessageType.SNAPSHOT,P.MessageType.SESSION_STATE:
			d["snapshot"] = _snapshot(d.get("snapshot"))
			if type == P.MessageType.BEGIN and d.snapshot.phase != GameTypes.MatchPhase.COUNTDOWN: _bad("Begin phase")
			if type == P.MessageType.SESSION_STATE: _field(d,"vote_mask",1,0,3); _field(d,"next_seed",4)
		P.MessageType.INPUT_BATCH:
			_field(d,"sector",1,0,LevelCatalog.MAX_LEVELS-1)
			var entries: Variant = d.get("commands",[])
			if writing and not entries is Array: _bad("input array"); return
			var count: int = _int(entries.size(),1,1,6)
			var result: Array[InputCommand] = []; var previous: int = -1
			for i: int in range(count):
				if not valid: break
				var c: InputCommand = entries[i].copy() if writing and entries[i] is InputCommand else InputCommand.new()
				if writing and not entries[i] is InputCommand: _bad("input record"); break
				c.tick = _int(c.tick,4); c.axis_x = _int(c.axis_x,1,-127,127); c.axis_y = _int(c.axis_y,1,-127,127)
				c.dash_serial = _int(c.dash_serial,2,0,65535); c.anchor_serial = _int(c.anchor_serial,2,0,65535); c.ping_serial = _int(c.ping_serial,2,0,65535)
				if c.tick <= previous: _bad("input tick order")
				previous = c.tick; result.append(c)
			d["commands"] = result
		P.MessageType.EVENTS:
			var entries: Variant = d.get("events",[])
			if writing and not entries is Array: _bad("event array"); return
			var count: int = _int(entries.size(),1,1,8)
			var result: Array[GameEvent] = []
			for i: int in range(count):
				if not valid: break
				var e: GameEvent = entries[i].copy() if writing and entries[i] is GameEvent else GameEvent.new()
				if writing and not entries[i] is GameEvent: _bad("event record"); break
				e.id = _int(e.id,4); e.tick = _int(e.tick,4); e.type = _int(e.type,1,0,6); e.player_id = _int(e.player_id,1,0,255)
				if e.player_id not in [0,1,255]: _bad("event player")
				e.object_id = _int(e.object_id,1,0,255); e.value = _int(e.value,2,0,65535)
				if (e.type == 2 and e.value > 9) or (e.type == 3 and e.value > 2) or (e.type in [1,4,5,6] and e.value != 0): _bad("event value")
				e.position = Vector2(_float(e.position.x),_float(e.position.y))
				if e.position.x < -64 or e.position.x > 1344 or e.position.y < -64 or e.position.y > 784: _bad("event position")
				result.append(e)
			d["events"] = result
		P.MessageType.PING,P.MessageType.PONG:
			_field(d,"echo_us",8,-0x7fffffffffffffff-1,0x7fffffffffffffff)
			if type == P.MessageType.PONG: _field(d,"host_tick",4)
		P.MessageType.VOTE: _field(d,"kind",1,0,2); _field(d,"value",1,0,1)
		P.MessageType.LEAVE: _field(d,"reason",2,1,10)
		P.MessageType.ERROR: _field(d,"code",2,1,10); _field(d,"fatal",1,0,1)
		_: _bad("unknown message")

func encode(type: int, header: Dictionary, payload: Variant) -> GameTypes.Result:
	bytes = PackedByteArray(); cursor = 0; writing = true; valid = true; problem = ""
	if not payload is Dictionary or type < 1 or type > 17: return GameTypes.Result.new(false,4,"invalid message")
	_raw(PackedByteArray([0x4c,0x4d,0x4c,0x4b]),4); _int(P.VERSION,2,P.VERSION,P.VERSION); _int(type,1,1,17); _int(0,1,0,0)
	_int(header.get("session_id",0),4); _int(header.get("match_id",0),4); _int(header.get("sequence",0),4); _int(0,2,0,978)
	var copied: Dictionary = payload.duplicate(true)
	# DTOs must never be modified during encoding.
	if copied.get("snapshot") is GameSnapshot: copied.snapshot = copied.snapshot.copy()
	_payload(type,copied)
	if bytes.size() > 1000: _bad("packet cap")
	if valid: bytes.encode_u16(20,bytes.size()-22)
	return GameTypes.Result.new(valid,0 if valid else 4,problem,bytes if valid else null)

func decode(packet: PackedByteArray) -> GameTypes.Result:
	bytes = packet; cursor = 0; writing = false; valid = true; problem = ""
	if packet.size() < 22 or packet.size() > 1000: return GameTypes.Result.new(false,4,"packet length")
	if _raw(null,4) != PackedByteArray([0x4c,0x4d,0x4c,0x4b]): _bad("magic")
	_int(null,2,P.VERSION,P.VERSION)
	var msg: DecodedMessage = DecodedMessage.new()
	msg.type = _int(null,1,1,17); _int(null,1,0,0)
	msg.session_id = _int(null,4); msg.match_id = _int(null,4); msg.sequence = _int(null,4)
	var size: int = _int(null,2,0,978)
	if size != packet.size()-22: _bad("payload length")
	_payload(msg.type,msg.payload)
	if cursor != packet.size(): _bad("trailing bytes")
	return GameTypes.Result.new(valid,0 if valid else 4,problem,msg if valid else null)
