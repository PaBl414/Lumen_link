extends RefCounted
const Fault = preload("res://tests/integration/fault_link.gd")
func run(t: TestAssert) -> void:
	var config: GameConfig = GameConfig.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay.json"))).value
	var map: MapDefinition = MapDefinition.from_json(JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/dock.json"))).value
	var sim: Simulation = Simulation.new(); sim.initialize(config,map,0,0)
	# Prediction isolates movement; hazards and goals remain host-owned.
	map.hazards.clear()
	var prediction: ClientPrediction = ClientPrediction.new(); prediction.configure(config,map); prediction.reconcile(sim.snapshot(),1)
	var serial: int = 0
	for tick: int in range(1,241):
		var command: InputCommand = InputCommand.new(); command.tick = tick; command.axis_x = 127 if tick<60 else -127
		if tick==20: serial = 1
		command.dash_serial = serial
		prediction.push(command); sim.step([InputCommand.new(),command])
		if tick%2==0: prediction.reconcile(sim.snapshot(),1)
	t.near(prediction.player.position.distance_to(sim.world.players[1].position),0,0.1,"PR01 core movement exact")
	t.equal(prediction.player.dash_cooldown,sim.world.players[1].dash_cooldown,"PR01 timers exact")
	t.is_true(prediction.pending.size()<=256,"PR01 bounded history")
	var rejected: GameSnapshot = sim.snapshot(); rejected.players[1].mode = GameTypes.PlayerMode.STUN
	rejected.players[1].stun_ticks = 12; rejected.players[1].dash_cooldown = 80; rejected.players[1].invulnerable_ticks = 90
	rejected.players[1].facing = Vector2.UP; rejected.players[1].consumed_serials.x = 2
	prediction.reconcile(rejected,1)
	var next: InputCommand = InputCommand.new(); next.tick = rejected.tick+1; next.dash_serial = 2
	prediction.push(next)
	t.equal(prediction.player.mode,GameTypes.PlayerMode.STUN,"PR02 rejected dash stays stun")
	t.equal(prediction.player.dash_cooldown,79,"PR02 full cooldown restored")
	t.equal(prediction.player.invulnerable_ticks,89,"PR02 invulnerability restored")
	t.equal(prediction.player.facing,Vector2.UP,"PR02 facing restored")
	t.equal(prediction.player.consumed_serials.x,2,"PR02 serial consumed once")
	var correction: GameSnapshot = rejected.copy(); correction.tick += 1
	correction.players[1].position = prediction.player.position+Vector2(10,0)
	prediction.reconcile(correction,1)
	t.near(prediction.offset.length(),10,0.1,"PR02 smoothing moderate correction")
	prediction.present(0.08); t.near(prediction.offset.length(),10/exp(1),0.01,"PR02 smoothing 80ms")
	correction.players[1].position += Vector2(100,0); prediction.reconcile(correction,1)
	t.equal(prediction.offset,Vector2.ZERO,"PR02 correction over48 snaps")
	var gap: InputCommand = next.copy(); gap.tick += 100; prediction.push(gap)
	t.is_true(prediction.pending.is_empty() and prediction.resyncs>0,"PR02 replay gap bounded resync")
	var clock: NetworkClock = NetworkClock.new(); clock.reset(100)
	clock.on_pong(1000000,1100000,100)
	t.equal(clock.lead,5,"M09 RTT100 lead5")
	clock.on_pong(0,1000000,100); t.is_true(clock.lead<=8,"M09 lead capped8")
	var last_tick: int = 100
	for frame: int in range(120):
		clock.advance(1.0/60); clock.observe(100+frame)
		var ticks: Array[int] = clock.next_command_ticks()
		t.is_true(ticks.size()<=3,"M09 catchup max3")
		for tick: int in ticks: t.is_true(tick>last_tick,"M09 target monotonic"); last_tick = tick
	var stalled: NetworkClock = NetworkClock.new(); stalled.reset(100)
	var produced: Array[int] = []
	for i: int in range(60):
		stalled.advance(1.0/60); produced.append_array(stalled.next_command_ticks(3,112))
	t.equal(produced.back(),112,"M09 stalled host caps future at snapshot+12")
	t.is_true(stalled.next_command_ticks(3,112).is_empty(),"M09 stalled host skips commands instead of disconnect")
	clock.observe(500); t.is_true(clock.resync_required,"M09 clock drift resync")
	var buffer: SnapshotBuffer = SnapshotBuffer.new(); buffer.collision.configure(map)
	for tick: int in range(40):
		var snap: GameSnapshot = sim.snapshot(); snap.tick = tick; snap.players[0].position = Vector2(100+tick,600); snap.players[0].velocity = Vector2(60,0)
		buffer.insert(snap)
	t.equal(buffer.snapshots.size(),32,"M09 buffer32")
	t.near(buffer.sample(35.5,0).position.x,135.5,0.01,"M09 interpolate position")
	t.near(buffer.sample(100,0).position.x,145,0.01,"M09 extrapolate max6 then freeze")
	var sector: GameSnapshot = sim.snapshot(); sector.sector_index = 1; buffer.insert(sector)
	t.equal(buffer.snapshots.size(),1,"M09 sector clears buffer")
	var view: WorldView = preload("res://scenes/world.tscn").instantiate()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(view); view.configure(map)
	var frame: GameTypes.RenderFrame = GameTypes.RenderFrame.new()
	for player: WorldState.PlayerState in sim.snapshot().players: frame.players.append(player.copy())
	frame.tick_float = sim.world.tick+4
	view.present_snapshot(sim.snapshot(),frame)
	t.is_true(view.link_view.points.size()>=2,"M09 render frame typed link endpoints")
	t.equal(view.render_tick,frame.tick_float,"M09 hazard presentation uses predicted tick")
	view.free()
	_faults(t,config,map)
	set_meta("completed",true)
func _faults(t: TestAssert,config: GameConfig,map: MapDefinition) -> void:
	var sim: Simulation = Simulation.new(); sim.initialize(config,map,0,0)
	var prediction: ClientPrediction = ClientPrediction.new(); prediction.configure(config,map); prediction.reconcile(sim.snapshot(),1)
	var replication: HostReplication = HostReplication.new()
	var up: Fault = Fault.new(123); var down: Fault = Fault.new(456)
	var clock: NetworkClock = NetworkClock.new(); clock.reset(0); clock.on_pong(0,100000,0)
	var history: Array[InputCommand] = []; var last_snapshot: int = 0; var dashes: int = 0
	for frame: int in range(720):
		var now: float = frame*1000.0/60
		if frame==600:
			up.loss = 0; up.duplicates = 0; up.reorder = 0; down.loss = 0; down.duplicates = 0; down.reorder = 0
		for batch: Array in up.receive(now):
			var commands: Array[InputCommand] = []; commands.assign(batch); replication.enqueue(1,commands,sim.world.tick)
		for snapshot: GameSnapshot in down.receive(now):
			if snapshot.tick>last_snapshot:
				last_snapshot = snapshot.tick; clock.observe(snapshot.tick); prediction.reconcile(snapshot,1)
		clock.advance(1.0/60)
		for tick: int in clock.next_command_ticks():
			var command: InputCommand = InputCommand.new(); command.tick = tick; command.axis_x = 127 if frame<300 else 0
			command.dash_serial = 1 if frame>=60 else 0
			history.append(command); prediction.push(command)
			while history.size()>6: history.pop_front()
		if frame%2==0: up.send(history.duplicate(),now)
		var events: Array[GameEvent] = sim.step(replication.commands_for(sim.world.tick+1))
		for event: GameEvent in events:
			if event.type==GameEvent.EventType.DASH and event.player_id==1: dashes += 1
		if frame%2==0: down.send(sim.snapshot(),now)
	t.equal(dashes,1,"PR03 faults one dash")
	t.is_true(up.dropped>0 and down.dropped>0 and up.duplicated>0 and down.reordered>0,"PR03 faults exercised")
	t.near(prediction.player.position.distance_to(sim.world.players[1].position),0,0.1,"PR03 clean2s converges")
	t.equal(prediction.player.dash_cooldown,sim.world.players[1].dash_cooldown,"PR03 clean timers converge")
	t.equal(prediction.player.consumed_serials,sim.world.players[1].consumed_serials,"PR03 clean serials converge")
