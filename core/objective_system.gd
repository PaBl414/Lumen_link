class_name ObjectiveSystem
extends RefCounted
const LinkSystem = preload("res://core/link_system.gd")
static func active_pair(state: RefCounted,map: MapDefinition,id: int) -> PackedVector2Array:
	var rule: MapDefinition.ObjectiveDef = map.objective_rule(id)
	if rule.stabilization.is_empty(): return PackedVector2Array()
	return rule.stabilization[1 if rule.stabilization.size()==2 and state.latched_mask&(1<<id) else 0]

static func fields_satisfied(state: RefCounted,map: MapDefinition,id: int) -> bool:
	var pair: PackedVector2Array = active_pair(state,map,id)
	if pair.is_empty(): return true
	if state.players[0].mode!=GameTypes.PlayerMode.NORMAL or state.players[1].mode!=GameTypes.PlayerMode.NORMAL: return false
	var a: Vector2 = state.players[0].position; var b: Vector2 = state.players[1].position
	return (a.distance_to(pair[0])<=44 and b.distance_to(pair[1])<=44) or (b.distance_to(pair[0])<=44 and a.distance_to(pair[1])<=44)

static func message(state: RefCounted,map: MapDefinition) -> String:
	if state.objective_index>=3: return "Oba drony do wyjścia — utrzymajcie pozycję przez 2 s."
	var id: int = state.objective_index
	var prefix: String = "Cel %d · " % (id+1)
	var rule: MapDefinition.ObjectiveDef = map.objective_rule(id)
	if rule.stabilization.size()==2: prefix += "etap %d/2 · " % (2 if state.latched_mask&(1<<id) else 1)
	if state.link_status==GameTypes.LinkStatus.JAMMED: return prefix+"Strefa zakłóceń wyłącza przewód. Opuśćcie jej obszar."
	if state.link_status==GameTypes.LinkStatus.SHUTTERED: return prefix+"Przesłona optyczna zamknięta. Zmieńcie trasę lub wykorzystajcie otwarte okno."
	if not fields_satisfied(state,map,id): return prefix+"Dwa różne pola, po jednym dronie w NORMAL."
	if state.link_status==GameTypes.LinkStatus.ACTIVE:
		var collision: CollisionWorld = CollisionWorld.new(); collision.configure(map)
		var link: GameTypes.LinkResult = LinkSystem.new().evaluate(state.players,state.active_socket,map,collision)
		var detail: String = "Ładowanie. " if LinkSystem.new().hits_beacon(link,map.beacons[id]) else "Przeprowadźcie środek przewodu przez cel (48 od końców). "
		return prefix+detail+rule.hint
	var reasons: Array[String] = ["Ustawcie przewód przez cel.","Przewód za krótki.","Przewód za długi (limit 720).","Ściana blokuje przewód.","Zryw lub ogłuszenie przerywa zasilanie."]
	return prefix+reasons[clampi(state.link_status,0,4)]+" "+rule.hint

func step(world: WorldState, link: GameTypes.LinkResult, map: MapDefinition, _config: GameConfig, events: Array[GameEvent]) -> void:
	if world.objective_index >= 3: return
	var id: int = world.objective_order[world.objective_index]
	if fields_satisfied(world,map,id) and LinkSystem.new().hits_beacon(link,map.beacons[id]):
		world.charges[id] += 1
		world.last_power_ticks[id] = world.tick
		if map.objective_rule(id).stabilization.size()==2 and world.charges[id]>=150: world.latched_mask |= 1<<id
	else:
		var gap: int = world.tick-world.last_power_ticks[id]
		if gap > 30 and gap % 2 == 0: world.charges[id] = maxi(150 if world.latched_mask&(1<<id) else 0,world.charges[id]-1)
	if world.charges[id] >= 300:
		world.complete_mask |= 1 << id
		world.completed_beacons_total += 1
		world.score += 1000
		world.objective_index += 1
		if world.objective_index < 3: world.last_power_ticks[world.objective_order[world.objective_index]] = world.tick + 1
		var event: GameEvent = GameEvent.new()
		event.type = GameEvent.EventType.BEACON; event.tick = world.tick; event.object_id = id; event.value = id
		events.append(event)

func finish_sector(world: WorldState) -> void:
	if world.phase != GameTypes.MatchPhase.PLAYING: return
	world.score += 10 * int(world.remaining_ticks / 60)
	world.phase = GameTypes.MatchPhase.WON
	if world.phase == GameTypes.MatchPhase.WON: world.score += 600 * world.integrity

func final_score(world: WorldState) -> int:
	return 1000 * world.completed_beacons_total if world.phase == GameTypes.MatchPhase.FAILED else world.score
