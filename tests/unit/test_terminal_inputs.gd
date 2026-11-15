extends RefCounted
func run(t: TestAssert) -> void:
 var session: MatchSession=MatchSession.new()
 var content: Dictionary=preload("res://tools/validate_content.gd").load_content()
 session.role="host";session.state="RESULTS";session.approved=true;session.connected_peer=2;session.session_id=1;session.match_id=2
 session.simulation=Simulation.new();session.simulation.initialize(content.config,content.map,0,0)
 session.simulation.world.phase=GameTypes.MatchPhase.WON;session.snapshot=session.simulation.snapshot()
 var before: Vector2=session.snapshot.players[1].position
 for sequence: int in range(6):
  var command: InputCommand=InputCommand.new();command.tick=1;command.axis_x=127
  var packet: GameTypes.Result=PacketCodec.new().encode(9,{"session_id":1,"match_id":2,"sequence":sequence},{"sector":0,"commands":[command]})
  session._packet(2,packet.value)
 t.equal(session.state,"RESULTS","TI six valid in-flight input packets cannot disconnect terminal session")
 if session.snapshot!=null:t.equal(session.snapshot.players[1].position,before,"TI late input cannot move terminal world")
 t.is_true(session.replication.inputs[1].is_empty(),"TI terminal packets never enter next level input queue")
 t.is_true(not session.progress.completed(&"dock"),"TI late input cannot confirm completion")
 session.leave(8,false);set_meta("completed",true)
