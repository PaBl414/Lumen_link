extends RefCounted
const Session=preload("res://app/match_session.gd")
func pump(host: Session,guest: Session,condition: Callable,ms: int=5000) -> bool:
 var tree: SceneTree=Engine.get_main_loop() as SceneTree;var end: int=Time.get_ticks_msec()+ms
 while not condition.call() and Time.get_ticks_msec()<end:
  host.poll();guest.poll();host.fixed_update([]);guest.fixed_update([]);await tree.create_timer(0.003).timeout
 return condition.call()
func run_async(t: TestAssert) -> void:
 var build: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://build_manifest.json"))
 var host: Session=Session.new();var guest: Session=Session.new();host.configure(build);guest.configure(build)
 var folder: String="user://level_lan_%d" % Time.get_ticks_usec();DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 host.progress.path=folder+"/host.json";guest.progress.path=folder+"/guest.json"
 host.progress.data.completed=["dock","garden","reactor","switchyard","service_channels"]
 host.transport.bind_ip="127.0.0.1";host.discovery.bind_ip="127.0.0.1"
 var port: int=24500+int(Time.get_ticks_msec()%500)
 t.fails(host.host({"port":port,"level_id":"station_heart"}),"LP host cannot choose locked level")
 t.is_true(host.host({"port":port,"level_id":"observatory"}).ok,"LP host selects unlocked stable ID")
 t.is_true(guest.join("127.0.0.1",port,"Guest").ok,"LP guest joins with local level locked")
 t.is_true(await pump(host,guest,func() -> bool:return guest.approved and guest.lobby.level_id==&"observatory"),"LP guest sees host choice before ready")
 host.set_ready(true);guest.set_ready(true);await pump(host,guest,func() -> bool:return host.lobby.can_start())
 host.set_options(1,0,&"service_channels")
 t.is_true(await pump(host,guest,func() -> bool:return guest.lobby.level_id==&"service_channels" and guest.lobby.ready_mask==0),"LP changing level and difficulty clears BOTH ready flags")
 host.set_options(0,0,&"observatory");await pump(host,guest,func() -> bool:return guest.lobby.level_id==&"observatory")
 host.set_ready(true);guest.set_ready(true);await pump(host,guest,func() -> bool:return host.lobby.can_start());host.request_start()
 await pump(host,guest,func() -> bool:return guest.state=="LOADING");host.loaded(host.generation);guest.loaded(guest.generation)
 t.is_true(await pump(host,guest,func() -> bool:return guest.state=="PLAYING"),"LP selected level starts on both peers")
 t.equal(guest.snapshot.level_id,&"observatory","LP full snapshot stable level ID")
 host.simulation.world.sector_tick=450
 t.is_true(await pump(host,guest,func() -> bool:return guest.snapshot.obstacle_active_mask&1!=0),"LP obstacle activation replicated in snapshot")
 t.is_true(not guest.progress.completed(&"observatory"),"LP playing is not completion")
 # Drop reliable result only: an unreliable WON snapshot must not unlock or persist.
 guest.transport.packet.disconnect(guest._packet)
 var filter: Callable=func(peer: int,bytes: PackedByteArray) -> void:
  if bytes.size()>6 and bytes[6]!=17:guest._packet(peer,bytes)
 guest.transport.packet.connect(filter)
 var world: WorldState=host.simulation.world;world.objective_index=3;world.charges=PackedInt32Array([300,300,300]);world.latched_mask=4;world.complete_mask=7;world.extract_ticks=119
 for player: WorldState.PlayerState in world.players:player.position=host.simulation.map.exit_position;player.velocity=Vector2.ZERO
 t.is_true(await pump(host,guest,func() -> bool:return guest.state=="RESULTS"),"LP unreliable result reaches presentation")
 t.is_true(host.result_confirmed and not guest.result_confirmed,"LP reliable result confirmation is distinct")
 t.is_true(not guest.progress.completed(&"observatory"),"LP unconfirmed win does not save")
 guest.vote(0,true);t.equal(host.state,"RESULTS","LP unconfirmed guest cannot advance")
 guest.transport.packet.disconnect(filter);guest.transport.packet.connect(guest._packet);host._publish_state()
 t.is_true(await pump(host,guest,func() -> bool:return guest.result_confirmed),"LP reliable recovery confirms result")
 t.is_true(guest.progress.completed(&"observatory") and guest.progress.unlocked(&"interference"),"LP guest saves host-unlocked completion and unlocks successor")
 t.is_true(not guest.progress.completed(&"dock"),"LP guest does not invent preceding history")
 var reload: ProgressStore=ProgressStore.new();reload.path=guest.progress.path;reload.load_progress();t.is_true(reload.completed(&"observatory"),"LP accepted result survives process-style reload")
 host.vote(0,true);t.equal(host.state,"RESULTS","LP single vote does not advance")
 guest.vote(0,true);t.is_true(await pump(host,guest,func() -> bool:return guest.state=="LOADING"),"LP both next votes start successor")
 host.loaded(host.generation);guest.loaded(guest.generation);await pump(host,guest,func() -> bool:return guest.state=="PLAYING")
 t.equal(guest.snapshot.level_id,&"interference","LP next stable ID from catalog")
 t.equal(host.snapshot.integrity,6,"LP next level refreshes Normal integrity")
 host.simulation.world.remaining_ticks=1;await pump(host,guest,func() -> bool:return guest.state=="RESULTS")
 t.is_true(not host.progress.completed(&"interference") and not guest.progress.completed(&"interference"),"LP failure never completes level")
 host.leave();guest.leave()
 for file: String in DirAccess.get_files_at(folder):DirAccess.remove_absolute(ProjectSettings.globalize_path(folder+"/"+file))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(folder));set_meta("completed",true)
