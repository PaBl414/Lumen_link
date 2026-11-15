extends RefCounted
const Session = preload("res://app/match_session.gd")
const Discovery = preload("res://net/lan_discovery.gd")
const P = preload("res://net/protocol.gd")
func _pump(host: Session,client: Session,condition: Callable,ms: int = 2200) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var deadline: int = Time.get_ticks_msec()+ms
	while not condition.call() and Time.get_ticks_msec()<deadline:
		host.poll(); client.poll(); host.fixed_update([]); client.fixed_update([]); await tree.create_timer(0.005).timeout
	return condition.call()
func run_async(t: TestAssert) -> void:
	var build: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://build_manifest.json"))
	var host: Session = Session.new(); var client: Session = Session.new()
	host.configure(build); client.configure(build)
	host.progress.path="user://session_host_progress.json"; client.progress.path="user://session_client_progress.json"
	host.transport.bind_ip = "127.0.0.1"; host.discovery.bind_ip = "127.0.0.1"
	var port: int = 21000+int(Time.get_ticks_msec()%1000)
	t.is_true(host.host({"port":port,"name":"Host","room":"Test"}).ok,"M07 host")
	t.fails(host.request_start(),"M07 alone cannot start")
	t.is_true(client.join("127.0.0.1",port,"Gość").ok,"M07 literal IP join")
	t.is_true(await _pump(host,client,func() -> bool: return host.approved and client.approved and client.lobby.names[1]=="Gość"),"M07 Hello Welcome LobbyState")
	t.equal(client.session_id,host.session_id,"M07 same session")
	host.set_ready(true); client.set_ready(true)
	t.is_true(await _pump(host,client,func() -> bool: return host.lobby.can_start()),"M07 both ready")
	host.set_options(1,3)
	t.equal(host.lobby.ready_mask,0,"M07 seed change clears both")
	await _pump(host,client,func() -> bool: return client.lobby.seed==3)
	host.set_ready(true); client.set_ready(true)
	t.is_true(await _pump(host,client,func() -> bool: return host.lobby.can_start()),"M07 new revision ready")
	var begins: Array[GameSnapshot] = []
	host.countdown_started.connect(func(value: GameSnapshot) -> void: begins.append(value))
	client.countdown_started.connect(func(value: GameSnapshot) -> void: begins.append(value))
	t.is_true(host.request_start().ok,"M07 start gate")
	await _pump(host,client,func() -> bool: return client.state=="LOADING")
	var generation: int = host.generation
	host.loaded(generation)
	client.loaded(client.generation-1)
	await _pump(host,client,func() -> bool: return false,30)
	t.equal(host.state,"LOADING","M07 late generation cannot Begin")
	client.loaded(client.generation)
	t.is_true(await _pump(host,client,func() -> bool: return begins.size()==2),"M07 both Loaded then Begin")
	t.equal(begins[0].phase_remaining,180,"M07 host countdown180")
	t.equal(begins[1].phase_remaining,180,"M07 guest countdown180")
	t.equal(host.match_id,client.match_id,"M07 same match")
	t.is_true(await _pump(host,client,func() -> bool: return host.state=="PLAYING" and client.state=="PLAYING",4500),"M07 real snapshot countdown both sides")
	t.is_true(client.simulation == null,"M08 client never owns Simulation")
	client.render_frame(1,0)
	client.transport.packet.disconnect(client._packet)
	await _pump(host,client,func() -> bool: return false,320)
	var frozen: GameTypes.RenderFrame = client.render_frame(1,0)
	t.is_true(client.snapshots_frozen,"N03 freeze after250ms")
	await _pump(host,client,func() -> bool: return false,200)
	t.equal(client.render_frame(1,0).players[1].position,frozen.players[1].position,"N03 frozen transform stable")
	client.transport.packet.connect(client._packet)
	await _pump(host,client,func() -> bool: return Time.get_ticks_msec()-client.last_snapshot_ms<100)
	client.render_frame(1,0)
	t.is_true(not client.snapshots_frozen and client.state=="PLAYING","N03 recovers after500ms loss")
	var dashes: Array[int] = []
	host.events_ready.connect(func(events: Array[GameEvent]) -> void:
		for event: GameEvent in events:
			if event.type == GameEvent.EventType.DASH and event.player_id == 1: dashes.append(event.id))
	var command: InputCommand = InputCommand.new(); command.tick = host.simulation.world.tick+3; command.dash_serial = 1
	var replay: PackedByteArray = preload("res://net/packet_codec.gd").new().encode(9,{"session_id":client.session_id,"match_id":client.match_id,"sequence":0},{"sector":0,"commands":[command]}).value
	for repeat: int in range(30): client.transport.send(1,replay,P.mode(9),P.channel(9))
	await _pump(host,client,func() -> bool: return host.simulation.world.tick>command.tick+12)
	t.equal(dashes.size(),1,"N06 same wire packet30 causes one guest dash")
	var authoritative_integrity: int = host.snapshot.integrity
	var fake: GameSnapshot = client.snapshot.copy(); fake.integrity = 9; fake.score = 999999; fake.charges[0] = 300
	client._send(10,{"snapshot":fake})
	await _pump(host,client,func() -> bool: return false,30)
	t.equal(host.simulation.world.score,0,"M08 forged client snapshot cannot score")
	t.equal(host.simulation.world.charges[0],0,"M08 forged client charge ignored")
	t.equal(host.simulation.world.integrity,authoritative_integrity,"M08 forged client integrity ignored")
	# Ten real rematches over the same ENet connection, targeted terminal fixtures on the host only.
	var seen_matches: Array[int] = [host.match_id]
	for rematch: int in range(10):
		if rematch == 0:
			var world: WorldState = host.simulation.world
			world.objective_index = 3; world.extract_ticks = 119; world.integrity = 1; world.sector_tick = 239
			world.difficulty = 0; world.variant = 0; world.damage_cooldown = 0
			for player: WorldState.PlayerState in world.players:
				player.position = host.simulation.map.exit_position; player.velocity = Vector2.ZERO
				player.mode = GameTypes.PlayerMode.NORMAL; player.invulnerable_ticks = 0; player.dash_ticks = 0
			var pulse: MapDefinition.HazardDef = MapDefinition.HazardDef.new(); pulse.type = "PULSE"; pulse.a = host.simulation.map.exit_position; pulse.radius = 48
			host.simulation.map.hazards = [pulse]
		host.simulation.world.remaining_ticks = 1
		await _pump(host,client,func() -> bool: return host.state=="RESULTS" and client.state=="RESULTS")
		t.equal(host.snapshot.score,client.snapshot.score,"M08 agreed terminal score")
		if rematch == 0:
			t.equal(host.snapshot.phase,GameTypes.MatchPhase.FAILED,"S01 LAN death before extraction")
			t.equal(client.snapshot.integrity,0,"S01 LAN guest sees authoritative death")
		host.vote(1,true); client.vote(2,true)
		await _pump(host,client,func() -> bool: return false,20)
		t.equal(host.state,"RESULTS","M08 mixed votes cannot start")
		client.vote(1,true)
		await _pump(host,client,func() -> bool: return client.state=="LOADING")
		host.loaded(host.generation); client.loaded(client.generation)
		await _pump(host,client,func() -> bool: return host.state=="PLAYING" and client.state=="PLAYING")
		t.is_true(host.match_id not in seen_matches,"M08 rematch fresh id")
		seen_matches.append(host.match_id)
		t.equal(host.match_id,client.match_id,"M08 rematch peer id agrees")
		t.equal(host.replication.inputs[1].size(),0,"M08 rematch clears queues")
		t.is_true(client.simulation == null,"M08 rematch no guest Simulation")
	host.simulation.world.remaining_ticks = 1
	await _pump(host,client,func() -> bool: return host.state=="RESULTS" and client.state=="RESULTS")
	host.vote(2,true); client.vote(2,true)
	t.is_true(await _pump(host,client,func() -> bool: return host.state=="LOBBY" and client.state=="LOBBY"),"M08 shared return to lobby")
	t.is_true(host.match_id==0 and client.match_id==0 and host.lobby.ready_mask==0 and client.lobby.ready_mask==0,"M08 return clears match and ready")
	t.is_true(host.simulation==null and client.simulation==null,"M08 return destroys match Simulation")
	client.leave(); await _pump(host,client,func() -> bool: return host.state=="IDLE",1000)
	host.leave(); client.leave()
	# A fresh port after teardown; mismatched content must be rejected before ready.
	host.host({"port":port,"name":"Host"})
	var bad_build: Dictionary = build.duplicate(); bad_build.content_sha256 = "00".repeat(32)
	client.configure(bad_build)
	var failures: Array[int] = []
	client.failed.connect(func(code: int,_message: String) -> void: failures.append(code))
	client.join("127.0.0.1",port,"Gość")
	t.is_true(await _pump(host,client,func() -> bool: return not failures.is_empty()),"M07 incompatible build rejected")
	if not failures.is_empty(): t.equal(failures[0],2,"M07 content error code")
	host.leave(); client.leave()
	# Host-side load timeout restores a usable lobby and clears ready.
	client.configure(build); host.host({"port":port,"name":"Host"}); client.join("127.0.0.1",port,"Client")
	await _pump(host,client,func() -> bool: return host.approved and client.approved)
	host.set_ready(true); client.set_ready(true)
	await _pump(host,client,func() -> bool: return host.lobby.can_start())
	host.request_start(); await _pump(host,client,func() -> bool: return client.state=="LOADING")
	host.poll(host.deadline+1)
	t.equal(host.state,"LOBBY","M07 load timeout returns lobby")
	t.equal(host.lobby.ready_mask,0,"M07 timeout clears ready")
	await _pump(host,client,func() -> bool: return client.state=="LOBBY")
	host.set_ready(true); client.set_ready(true)
	await _pump(host,client,func() -> bool: return host.lobby.can_start())
	host.request_start(); await _pump(host,client,func() -> bool: return client.state=="LOADING")
	client.cancel()
	t.is_true(await _pump(host,client,func() -> bool: return host.state=="LOBBY" and client.state=="LOBBY"),"M07 client load cancellation returns both to lobby")
	host.leave(); client.leave()
	var discovery: Discovery = Discovery.new(); var scanner: Discovery = Discovery.new()
	discovery.discovery_port = port+1; scanner.discovery_port = port+1
	discovery.bind_ip = "127.0.0.1"; scanner.bind_ip = "127.0.0.1"; scanner.broadcast = false
	t.is_true(discovery.start_host({"port":port,"engine":"4.5.2","room":"Discovery"}).ok,"M07 discovery host")
	t.is_true(scanner.start_scan().ok,"M07 discovery scan")
	t.is_true(scanner.udp.get_local_port() != port+1,"M07 scanner uses ephemeral port")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var deadline: int = Time.get_ticks_msec()+1500
	while scanner.entries.is_empty() and Time.get_ticks_msec()<deadline:
		scanner.poll(Time.get_ticks_msec()); discovery.poll(Time.get_ticks_msec()); await tree.create_timer(0.01).timeout
	t.is_true(not scanner.entries.is_empty(),"M07 actual UDP probe/reply")
	scanner.poll(Time.get_ticks_msec()+4000)
	t.is_true(scanner.entries.is_empty(),"M07 TTL expires")
	discovery.stop(); scanner.stop()
	failures.clear(); client.configure(build); client.join("127.0.0.1",port+2,"Client")
	client.poll(client.deadline+1)
	t.is_true(5 in failures and client.state=="IDLE","M07 handshake8s timeout cleanup")
	client.leave()
	set_meta("completed",true)
