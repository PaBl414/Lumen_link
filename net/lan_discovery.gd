class_name LanDiscovery
extends RefCounted
const P = preload("res://net/protocol.gd")
signal results_changed(entries: Array)
var udp: PacketPeerUDP
var entries: Dictionary = {}
var room: Dictionary = {}
var is_host: bool = false
var scan_started: int = 0
var last_probe_ms: int = -1000
var nonces: Dictionary = {}
var replies: Dictionary = {}
var global_window: int = 0
var global_count: int = 0
var last_error: String = ""
var discovery_port: int = 7778
var bind_ip: String = "*"
var broadcast: bool = true
func start_host(options: Dictionary) -> GameTypes.Result:
	stop(); is_host = true; room = options.duplicate(true)
	udp = PacketPeerUDP.new()
	var error: Error = udp.bind(discovery_port,bind_ip)
	if error != OK: stop(); return GameTypes.Result.new(false,error,"Discovery unavailable; direct IP remains available")
	return GameTypes.Result.new(true,0,"")
func start_scan() -> GameTypes.Result:
	stop(); is_host = false; udp = PacketPeerUDP.new()
	var error: Error = udp.bind(0,bind_ip)
	if error != OK: stop(); return GameTypes.Result.new(false,error,"Discovery scan unavailable")
	udp.set_broadcast_enabled(true); scan_started = Time.get_ticks_msec(); last_probe_ms = -1000
	return GameTypes.Result.new(true,0,"")
func _probe(now: int) -> void:
	var nonce: int = randi() & 0xffffffff
	nonces[nonce] = now
	var data: PackedByteArray = PackedByteArray(); data.resize(64)
	data[0] = 76; data[1] = 77; data[2] = 68; data[3] = 81; data.encode_u16(4,1); data.encode_u32(6,nonce)
	for ip: String in (["255.255.255.255","127.0.0.1"] if broadcast else ["127.0.0.1"]):
		udp.set_dest_address(ip,discovery_port)
		var error: Error = udp.put_packet(data)
		if error != OK: last_error = "Broadcast unavailable; use direct IP"
	last_probe_ms = now
func _reply(data: PackedByteArray,ip: String,port: int,now: int) -> void:
	if data.size() != 64 or data.slice(0,4) != PackedByteArray([76,77,68,81]) or data.decode_u16(4) != 1: return
	for i: int in range(10,64):
		if data[i] != 0: return
	if now-global_window >= 1000: global_window = now; global_count = 0
	var recent: Array = replies.get(ip,[])
	recent = recent.filter(func(time: int) -> bool: return now-time < 1000)
	if recent.size() >= 2 or global_count >= 20: return
	recent.append(now); replies[ip] = recent; global_count += 1
	var response: PackedByteArray = PackedByteArray([76,77,68,82,1,0]); response.resize(13)
	response.encode_u32(6,data.decode_u32(6)); response.encode_u16(10,room.get("port",7777)); response[12] = int(room.get("occupied",false))
	for text: String in [room.get("engine","4.5.2"),room.get("room","LUMEN LINK")]:
		var utf: PackedByteArray = text.to_utf8_buffer()
		if utf.size() > 80: return
		response.append(utf.size()); response.append_array(utf)
	if response.size() > 160: return
	udp.set_dest_address(ip,port); udp.put_packet(response)
func _accept(data: PackedByteArray,ip: String,now: int) -> bool:
	if data.size() < 15 or data.size() > 160 or data.slice(0,4) != PackedByteArray([76,77,68,82]) or data.decode_u16(4) != 1: return false
	var nonce: int = data.decode_u32(6)
	if not nonces.has(nonce) or now-int(nonces[nonce])>3000 or data[12]>1: return false
	var cursor: int = 13; var fields: Array[String] = []
	for limit: int in [32,80]:
		if cursor >= data.size(): return false
		var size: int = data[cursor]; cursor += 1
		if size > limit or cursor+size > data.size(): return false
		var raw: PackedByteArray = data.slice(cursor,cursor+size); cursor += size
		if not P.valid_utf8(raw): return false
		var text: String = raw.get_string_from_utf8()
		if text.to_utf8_buffer() != raw: return false
		for i: int in range(text.length()):
			if text.unicode_at(i)<32 or (text.unicode_at(i)>=127 and text.unicode_at(i)<=159): return false
		fields.append(text)
	if cursor != data.size() or fields[1].length()>24: return false
	var game_port: int = data.decode_u16(10)
	if game_port < 1024: return false
	if entries.size() >= 64 and not entries.has(ip+":"+str(game_port)): return false
	entries[ip+":"+str(game_port)] = {"ip":ip,"port":game_port,"occupied":data[12]==1,"engine":fields[0],"room":fields[1],"seen_ms":now}
	return true
func poll(now: int) -> void:
	if udp == null: return
	var changed: bool = false
	if not is_host and now-scan_started<10000 and now-last_probe_ms >= 1000: _probe(now)
	for i: int in range(mini(32,udp.get_available_packet_count())):
		var data: PackedByteArray = udp.get_packet(); var ip: String = udp.get_packet_ip(); var port: int = udp.get_packet_port()
		if data.size()>256: continue
		if is_host: _reply(data,ip,port,now)
		else: changed = _accept(data,ip,now) or changed
	for key: Variant in entries.keys():
		if now-int(entries[key].seen_ms)>3000: entries.erase(key); changed = true
	for key: Variant in nonces.keys():
		if now-int(nonces[key])>3000: nonces.erase(key)
	# Keep per-IP limiter memory bounded even under a spoofed-source flood.
	for key: Variant in replies.keys():
		if replies[key].is_empty() or now-int(replies[key][-1])>1000: replies.erase(key)
	if changed: results_changed.emit(entries.values())
func stop() -> void:
	if udp != null: udp.close()
	udp = null; entries.clear(); nonces.clear(); replies.clear(); room.clear(); last_error = ""; global_count = 0
	results_changed.emit([])
