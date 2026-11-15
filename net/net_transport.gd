class_name NetTransport
extends RefCounted
const P = preload("res://net/protocol.gd")
signal packet(peer_id: int, bytes: PackedByteArray)
signal connected(peer_id: int)
signal disconnected(peer_id: int)
signal failed(code: int)
var bind_ip: String = "*"
var peer: ENetMultiplayerPeer
var api: SceneMultiplayer
var connected_peer: int = 0
var queue: Array[Dictionary] = []
var overload: bool = false
var lifecycle: Array[Dictionary] = []
var polling: bool = false
var application_sizes: Array[int] = []

func _make_api() -> void:
	api = SceneMultiplayer.new()
	api.allow_object_decoding = false; api.server_relay = false
	api.set_root_path(NodePath("/root"))
	api.peer_packet.connect(_receive)
	api.peer_connected.connect(_connected)
	api.peer_disconnected.connect(_disconnected)
	api.connection_failed.connect(func() -> void: lifecycle.append({"kind":"failed","id":P.ErrorCode.TIMEOUT}))
	api.server_disconnected.connect(func() -> void: lifecycle.append({"kind":"disconnected","id":1}))
	api.multiplayer_peer = peer
func start_host(port: int) -> Error:
	close()
	if port < 1024 or port > 65535: return ERR_INVALID_PARAMETER
	peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(bind_ip)
	var error: Error = peer.create_server(port,1,3)
	if error != OK: close(); return error
	_make_api(); return OK
func start_client(ip: String,port: int) -> Error:
	close()
	if not P.ipv4(ip) or port < 1024 or port > 65535: return ERR_INVALID_PARAMETER
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip,port,3)
	if error != OK: close(); return error
	_make_api(); return OK
func _connected(id: int) -> void:
	connected_peer = id
	if api != null and peer.get_unique_id() == 1: api.refuse_new_connections = true
	lifecycle.append({"kind":"connected","id":id})
func _disconnected(id: int) -> void:
	connected_peer = 0; lifecycle.append({"kind":"disconnected","id":id})
func _receive(id: int,data: PackedByteArray) -> void:
	if data.size() < 22 or data.size() > 1000: data = PackedByteArray()
	var critical: bool = data.size() < 7 or P.channel(data[6]) == 0
	if queue.size() >= 128:
		var removable: int = -1
		for i: int in range(queue.size()):
			if not queue[i].critical: removable = i; break
		if removable >= 0: queue.remove_at(removable)
		elif critical: overload = true; return
		else: return
	queue.append({"id":id,"bytes":data.duplicate(),"critical":critical})
func poll() -> void:
	if api == null or polling: return
	polling = true
	var current_api: SceneMultiplayer = api
	var error: Error = current_api.poll()
	# Only now may application callbacks close/replace the ENet peer.
	while not lifecycle.is_empty() and api != null:
		var event: Dictionary = lifecycle.pop_front()
		match event.kind:
			"connected": connected.emit(event.id)
			"disconnected": disconnected.emit(event.id)
			"failed": failed.emit(event.id)
	if api != null and error != OK: failed.emit(P.ErrorCode.BAD_PACKET)
	if api != null and overload: overload = false; failed.emit(P.ErrorCode.OVERLOAD)
	for i: int in range(mini(64,queue.size())):
		if queue.is_empty() or api == null: break
		var entry: Dictionary = queue.pop_front()
		packet.emit(entry.id,entry.bytes)
	polling = false
func send(id: int,data: PackedByteArray,mode: int,channel: int) -> Error:
	if api == null or data.size() > 1000 or data.size() < 22 or channel < 0 or channel > 2: return ERR_INVALID_PARAMETER
	var error: Error = api.send_bytes(data,id,mode,channel)
	if error == OK:
		application_sizes.append(data.size())
		if application_sizes.size() > 128: application_sizes.pop_front()
	return error
func close() -> void:
	queue.clear(); lifecycle.clear(); connected_peer = 0; overload = false
	if peer != null:
		if peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED and peer.host != null: peer.host.flush()
		peer.close()
	if api != null: api.multiplayer_peer = OfflineMultiplayerPeer.new()
	api = null; peer = null; application_sizes.clear()
