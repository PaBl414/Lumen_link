class_name MessageGuard
extends RefCounted
const P = preload("res://net/protocol.gd")
const Codec = preload("res://net/packet_codec.gd")
var sequences: Dictionary = {}
var buckets: Dictionary = {}
var violations: Dictionary = {}
var excess_since: Dictionary = {}
var excess_last: Dictionary = {}
func reset() -> void:
	sequences.clear(); buckets.clear(); violations.clear(); excess_since.clear(); excess_last.clear()
func record_invalid(peer: int, now_ms: int) -> bool:
	var recent: Array = violations.get(peer,[])
	recent = recent.filter(func(time: int) -> bool: return now_ms-time <= 10000)
	recent.append(now_ms); violations[peer] = recent
	return recent.size() >= 3
func _error(peer: int,now_ms: int,detail: String) -> GameTypes.Result:
	return GameTypes.Result.new(false,P.ErrorCode.BAD_PACKET,detail,{"disconnect":record_invalid(peer,now_ms)})
func _take(key: String,now: int,rate: float,burst: float,cost: float) -> bool:
	var bucket: Vector2 = buckets.get(key,Vector2(burst,now))
	bucket.x = minf(burst,bucket.x+maxf(0,now-bucket.y)*rate/1000)
	bucket.y = now
	var ok: bool = bucket.x >= cost
	if ok: bucket.x -= cost
	buckets[key] = bucket
	return ok
func accept(peer: int,msg: Codec.DecodedMessage,context: Dictionary,now_ms: int) -> GameTypes.Result:
	var host: bool = context.get("is_host",false)
	var phase: String = context.get("state","")
	var allowed: Array = [1,5,7,9,12,13,14,15] if host else [2,3,4,6,8,10,11,12,13,15,16,17]
	if msg.type not in allowed: return _error(peer,now_ms,"sender role")
	if (msg.type == 1 and phase != "HANDSHAKE") or (msg.type in [2,3] and phase != "CONNECTING") or ((msg.type == 5 and phase != "LOBBY") or (msg.type == 4 and phase not in ["LOBBY","INTERMISSION","RESULTS"])) or (msg.type in [7,8] and phase != "LOADING") or (msg.type == 9 and phase not in ["COUNTDOWN","PLAYING","RESULTS","INTERMISSION"]): return _error(peer,now_ms,"message state")
	if msg.type == 6 and phase not in ["LOBBY","LOADING","INTERMISSION","RESULTS"]: return _error(peer,now_ms,"load state")
	if msg.type in [10,11,17] and phase not in ["COUNTDOWN","PLAYING","READY","INTERMISSION","RESULTS"]: return _error(peer,now_ms,"game state")
	if msg.type == 14 and ((msg.payload.kind == 0 and phase not in ["INTERMISSION","RESULTS"]) or (msg.payload.kind in [1,2] and phase not in ["RESULTS","WON","FAILED"])): return _error(peer,now_ms,"vote state")
	if msg.type == 1:
		if msg.session_id != 0 or msg.match_id != 0: return _error(peer,now_ms,"Hello identifiers")
	elif msg.type not in [2,3] and msg.session_id != context.get("session_id",0): return GameTypes.Result.new(false,0,"stale session",{"disconnect":false})
	if msg.type in [1,2,3,4,5] and msg.match_id != 0: return _error(peer,now_ms,"lobby match id")
	if msg.type in [7,8,9,10,11,12,13,14,15,16,17] and msg.match_id != context.get("match_id",0): return GameTypes.Result.new(false,0,"stale match",{"disconnect":false})
	if msg.type in [7,9] and msg.payload.sector != context.get("sector",0): return GameTypes.Result.new(false,0,"old sector",{"disconnect":false})
	if msg.type in [8,10,17] and msg.payload.snapshot.sector_index != context.get("sector",0): return GameTypes.Result.new(false,0,"old snapshot sector",{"disconnect":false})
	if msg.type in [12,13] and not context.get("approved",false): return _error(peer,now_ms,"unapproved heartbeat")
	var prefix: String = str(peer)
	var rate: float = 4 if msg.type == 12 else (5 if msg.type in [5,14] else (60 if msg.type == 9 else 120))
	if not _take(prefix+"/packets",now_ms,120,60,1) or not _take(prefix+"/bytes",now_ms,65536,32768,context.get("packet_size",1000)) or not _take(prefix+"/type/"+str(msg.type),now_ms,rate,rate,1):
		if not excess_since.has(peer) or now_ms-int(excess_last.get(peer,0))>2000: excess_since[peer] = now_ms
		excess_last[peer] = now_ms
		return GameTypes.Result.new(false,P.ErrorCode.OVERLOAD,"rate limit",{"disconnect":now_ms-int(excess_since[peer])>=2000})
	if excess_last.has(peer) and now_ms-int(excess_last[peer])>2000:
		excess_since.erase(peer); excess_last.erase(peer)
	var key: String = prefix+"/"+str(msg.type)
	if sequences.has(key) and not P.newer(msg.sequence,sequences[key]): return GameTypes.Result.new(false,0,"duplicate/stale",{"disconnect":false})
	sequences[key] = msg.sequence
	return GameTypes.Result.new(true,0,"")
