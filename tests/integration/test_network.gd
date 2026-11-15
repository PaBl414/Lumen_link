extends RefCounted
const Transport = preload("res://net/net_transport.gd")
const Codec = preload("res://net/packet_codec.gd")
const P = preload("res://net/protocol.gd")
func run_async(t: TestAssert) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var host: Transport = Transport.new(); host.bind_ip = "127.0.0.1"
	var client: Transport = Transport.new()
	var port: int = 19000+int(Time.get_ticks_msec()%1000)
	t.equal(host.start_host(port),OK,"N05 host bind")
	t.equal(client.start_client("localhost",port),ERR_INVALID_PARAMETER,"N05 literal IPv4 only")
	t.equal(client.start_client("127.0.0.1",port),OK,"N01 client connect")
	var deadline: int = Time.get_ticks_msec()+2000
	while (host.connected_peer == 0 or client.connected_peer == 0) and Time.get_ticks_msec()<deadline:
		host.poll(); client.poll(); await tree.create_timer(0.005).timeout
	t.is_true(host.connected_peer != 0 and client.connected_peer == 1,"N01 actual ENet connected")
	var occupied: Transport = Transport.new(); occupied.bind_ip = "127.0.0.1"
	t.is_true(occupied.start_host(port) != OK,"N05 occupied port error")
	occupied.close()
	var third: Transport = Transport.new(); third.start_client("127.0.0.1",port)
	deadline = Time.get_ticks_msec()+400
	while Time.get_ticks_msec()<deadline:
		host.poll(); client.poll(); third.poll(); await tree.create_timer(0.005).timeout
	t.equal(third.connected_peer,0,"N05 third peer refused")
	third.close()
	var received: Array[PackedByteArray] = []
	host.packet.connect(func(_id: int, data: PackedByteArray) -> void: received.append(data))
	var packet: PackedByteArray = Codec.new().encode(12,{"session_id":1,"match_id":2,"sequence":3},{"echo_us":1000}).value
	t.equal(client.send(1,packet,P.mode(12),P.channel(12)),OK,"N01 send_bytes")
	deadline = Time.get_ticks_msec()+1000
	while received.is_empty() and Time.get_ticks_msec()<deadline:
		host.poll(); client.poll(); await tree.create_timer(0.005).timeout
	t.is_true(not received.is_empty() and received[0] == packet,"N01 peer_packet exact30")
	var critical: PackedByteArray = Codec.new().encode(2,{}, {"slot":1,"host_name":"Host"}).value
	for index: int in range(130): host._receive(2,critical)
	t.equal(host.queue.size(),128,"N01 queue bounded128")
	t.is_true(host.overload,"N01 reliable overflow explicit")
	var errors: Array[int] = []
	host.failed.connect(func(code: int) -> void: errors.append(code))
	host.poll()
	t.is_true(7 in errors,"N01 reliable overflow signals OVERLOAD")
	t.is_true(host.queue.size() >= 64,"N01 drain at most64")
	client.close(); host.close(); host.close()
	t.equal(host.start_host(port),OK,"N05 close rebind")
	host.close()
	var replication: HostReplication = preload("res://net/host_replication.gd").new()
	var command: InputCommand = InputCommand.new(); command.tick = 1; command.dash_serial = 1; command.anchor_serial = 1
	for repeat: int in range(30):
		replication.enqueue(0,[command],0); replication.enqueue(1,[command.copy()],0)
	t.equal(replication.inputs[1].size(),1,"N06 duplicate batch queue dedup")
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_map.json"))).value
	var sim: Simulation = Simulation.new(); sim.initialize(config,map,0,0)
	sim.world.players[0].position = map.sockets[0]; sim.world.players[1].position = map.sockets[1]
	var dash_count: int = 0
	for tick: int in range(1,32):
		var events: Array[GameEvent] = sim.step(replication.commands_for(tick))
		for event: GameEvent in events:
			if event.type == GameEvent.EventType.DASH: dash_count += 1
		if tick == 1: t.equal(sim.world.active_socket,1,"M08 simultaneous socket odd priority")
	t.equal(dash_count,2,"N06 exactly one dash per slot")
	t.equal(sim.world.tick,31,"N06 one simulation step per tick")
	replication.reset(); command.tick = 1; command.axis_x = 127
	replication.enqueue(1,[command],0); replication.commands_for(1)
	for tick: int in range(2,8): t.equal(replication.commands_for(tick)[1].axis_x,127,"M08 missing axis grace6")
	t.equal(replication.commands_for(8)[1].axis_x,0,"M08 neutral after6 missing")
	command.tick = 22
	t.fails(replication.enqueue(1,[command],8),"M08 future cap12")
	command.tick = 9; command.dash_serial = 1000
	t.fails(replication.enqueue(1,[command],8),"M08 serial jump rejected")
	t.equal(replication.inputs[1].size(),0,"M08 invalid batch atomic")
	replication.reset(); command.tick = sim.world.tick+8; command.dash_serial = 0
	t.is_true(replication.enqueue(1,[command],sim.world.tick).ok,"M09 future input queued")
	t.is_true(replication.capture(sim).tick<replication.last_received_tick[1],"M09 ack is simulated tick not received input")
	set_meta("completed",true)
