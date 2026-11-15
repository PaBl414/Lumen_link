class_name Protocol
extends RefCounted
const VERSION: int = 3
const MAX_PACKET_BYTES: int = 1000
const HEADER_BYTES: int = 22
const SNAPSHOT_BYTES: int = 113 # base plus UTF-8 level ID (1..32 bytes)
const MAX_SNAPSHOT_BYTES: int = SNAPSHOT_BYTES+32
const PLAYER_BYTES: int = 35
enum MessageType { HELLO=1, WELCOME, REJECT, LOBBY_STATE, SET_READY, LOAD_SECTOR, LOADED, BEGIN, INPUT_BATCH, SNAPSHOT, EVENTS, PING, PONG, VOTE, LEAVE, ERROR, SESSION_STATE }
enum ErrorCode { VERSION_MISMATCH=1, CONTENT_MISMATCH, FULL, BAD_PACKET, TIMEOUT, LOAD_FAILED, OVERLOAD, PEER_LEFT, PORT_IN_USE, INVALID_STATE }
enum Channel { CONTROL, INPUT, STATE }
enum VoteKind { NEXT, REMATCH, LOBBY }
static func channel(type: int) -> int:
	if type == MessageType.INPUT_BATCH: return Channel.INPUT
	if type in [MessageType.SNAPSHOT,MessageType.PING,MessageType.PONG]: return Channel.STATE
	return Channel.CONTROL
static func mode(type: int) -> int:
	return MultiplayerPeer.TRANSFER_MODE_RELIABLE if channel(type) == 0 else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
static func newer(a: int,b: int) -> bool:
	var d: int = (a-b)&0xffffffff
	return d > 0 and d < 0x80000000
static func text(code: int) -> String:
	return {1:"Obie osoby potrzebują tej samej wersji gry.",2:"Obie osoby potrzebują identycznej zawartości gry.",3:"Pokój jest zajęty.",4:"Odebrano nieprawidłowe dane.",5:"Nie udało się połączyć. Sprawdź IP i sieć — pokój może być zajęty.",6:"Nie udało się załadować sektora.",7:"Przeciążenie połączenia.",8:"Partner opuścił grę.",9:"Port jest zajęty. Wybierz inny.",10:"Niedozwolony stan sesji."}.get(code,"Błąd połączenia.")
static func ipv4(ip: String) -> bool:
	var parts: PackedStringArray = ip.split(".")
	if parts.size() != 4: return false
	for part: String in parts:
		if part.is_empty() or part.length() > 3: return false
		for ch: String in part:
			if ch < "0" or ch > "9": return false
		if int(part)>255: return false
	return ip != "0.0.0.0" and ip != "255.255.255.255"
static func valid_utf8(data: PackedByteArray) -> bool:
	var i: int = 0
	while i<data.size():
		var first: int = data[i]; var count: int = 0
		if first < 128: i += 1; continue
		if first>=0xc2 and first<=0xdf: count = 1
		elif first>=0xe0 and first<=0xef: count = 2
		elif first>=0xf0 and first<=0xf4: count = 3
		else: return false
		if i+count>=data.size(): return false
		for j: int in range(1,count+1):
			if data[i+j]<0x80 or data[i+j]>0xbf: return false
		if (first==0xe0 and data[i+1]<0xa0) or (first==0xed and data[i+1]>=0xa0) or (first==0xf0 and data[i+1]<0x90) or (first==0xf4 and data[i+1]>0x8f): return false
		i += count+1
	return true
