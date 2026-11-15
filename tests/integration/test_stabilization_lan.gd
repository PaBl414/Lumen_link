extends RefCounted
const Session = preload("res://app/match_session.gd")
func _pump(host: Session,client: Session,condition: Callable,ms: int = 4000) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree; var end: int = Time.get_ticks_msec()+ms
	while not condition.call() and Time.get_ticks_msec()<end:
		host.poll(); client.poll(); host.fixed_update([]); client.fixed_update([]); await tree.create_timer(0.005).timeout
	return condition.call()
func run_async(t: TestAssert) -> void:
	var build: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://build_manifest.json"))
	var host: Session = Session.new(); var client: Session = Session.new(); host.configure(build); client.configure(build)
	host.progress.path="user://st_host_progress.json"; client.progress.path="user://st_client_progress.json"
	host.transport.bind_ip = "127.0.0.1"; host.discovery.bind_ip = "127.0.0.1"
	var port: int = 23100+int(Time.get_ticks_msec()%400)
	t.is_true(host.host({"port":port,"name":"Host","difficulty":1}).ok,"ST LAN host")
	t.is_true(client.join("127.0.0.1",port,"Guest").ok,"ST LAN join")
	t.is_true(await _pump(host,client,func() -> bool: return client.approved and host.approved),"ST LAN handshake")
	host.set_ready(true); client.set_ready(true); await _pump(host,client,func() -> bool: return host.lobby.can_start())
	host.request_start(); await _pump(host,client,func() -> bool: return client.state=="LOADING")
	host.loaded(host.generation); client.loaded(client.generation)
	t.is_true(await _pump(host,client,func() -> bool: return host.state=="PLAYING" and client.state=="PLAYING"),"ST LAN starts")
	# Focused transport fixtures, not campaign completion evidence: move to Garden by real barrier/votes.
	host.simulation.world.charges=PackedInt32Array([300,300,300]); host.simulation.world.complete_mask=7
	host.simulation.world.objective_index = 3; host.simulation.world.extract_ticks = 119
	for player: WorldState.PlayerState in host.simulation.world.players: player.position = host.simulation.map.exit_position; player.velocity = Vector2.ZERO
	await _pump(host,client,func() -> bool: return host.state=="RESULTS" and client.result_confirmed)
	host.vote(0,true); client.vote(0,true); await _pump(host,client,func() -> bool: return client.state=="LOADING")
	host.loaded(host.generation); client.loaded(client.generation)
	t.is_true(await _pump(host,client,func() -> bool: return host.state=="PLAYING" and client.state=="PLAYING"),"ST LAN Garden starts")
	var world: WorldState = host.simulation.world
	world.charges[0] = 149
	for slot: int in range(2):
		world.players[slot].position = host.simulation.map.objective_rule(0).stabilization[0][slot]; world.players[slot].velocity = Vector2.ZERO
	client.transport.packet.disconnect(client._packet)
	await _pump(host,client,func() -> bool: return false,330)
	t.equal(host.snapshot.latched_mask,1,"ST LAN authoritative latch during dropped packets")
	t.equal(host.snapshot.charges[0],150,"ST LAN holds half while old fields no longer qualify")
	t.equal(client.snapshot.latched_mask,0,"ST LAN did not receive latch while disconnected")
	client.render_frame(1,0); t.is_true(client.snapshots_frozen,"ST LAN freezes on loss")
	client.transport.packet.connect(client._packet)
	t.is_true(await _pump(host,client,func() -> bool: return client.snapshot.latched_mask==1),"ST LAN restores latch from subsequent full snapshot")
	t.equal(client.snapshot.charges[0],150,"ST LAN restores floor without stage event")
	t.equal(ObjectiveSystem.active_pair(client.snapshot,client.receive_map,0),client.receive_map.objective_rule(0).stabilization[1],"ST LAN second pair reconstructed")
	t.is_true(client.simulation==null,"ST LAN client cannot simulate objectives")
	world.charges=PackedInt32Array([300,300,300]); world.complete_mask=7; world.latched_mask=5
	world.objective_index = 3; world.extract_ticks = 119
	for player: WorldState.PlayerState in world.players: player.position = host.simulation.map.exit_position; player.velocity = Vector2.ZERO
	await _pump(host,client,func() -> bool: return host.state=="RESULTS" and client.result_confirmed)
	host.vote(0,true); client.vote(0,true); await _pump(host,client,func() -> bool: return client.state=="LOADING")
	host.loaded(host.generation); client.loaded(client.generation)
	t.is_true(await _pump(host,client,func() -> bool: return host.state=="PLAYING" and client.state=="PLAYING"),"ST LAN Reactor starts")
	t.equal(host.snapshot.latched_mask,0,"ST LAN host resets latch at sector barrier")
	t.equal(client.snapshot.latched_mask,0,"ST LAN guest resets latch at sector barrier")
	client.leave(); host.leave()
	set_meta("completed",true)
