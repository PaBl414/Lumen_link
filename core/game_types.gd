class_name GameTypes
extends RefCounted

enum PlayerMode { NORMAL, DASH, STUN }
enum MatchPhase { COUNTDOWN, PLAYING, INTERMISSION, WON, FAILED, LOBBY, LOADING }
enum LinkStatus { ACTIVE, TOO_SHORT, TOO_LONG, OCCLUDED, PLAYER_BUSY, SHUTTERED, JAMMED }
enum Difficulty { NORMAL, RELAXED }
enum ErrorCode { NONE, INVALID_DATA, IO_ERROR, INVALID_STATE }

class Result extends RefCounted:
	var ok: bool
	var code: int
	var message: String
	var value: Variant
	func _init(success: bool, error_code: int, detail: String, data: Variant = null) -> void:
		ok = success
		code = error_code
		message = detail
		value = data

class MoveResult extends RefCounted:
	var position: Vector2
	var velocity: Vector2
	var segments: Array[Vector4] = []
	var segment_times: Array[Vector2] = []

class LinkResult extends RefCounted:
	var blocked_point: Vector2 = Vector2.INF
	var blocked_segment: int = -1
	var points: Array[Vector2] = []
	var length: float = 0.0
	var status: int = LinkStatus.PLAYER_BUSY

class RenderFrame extends RefCounted:
	var tick_float: float = 0.0
	var players: Array[RefCounted] = []
	var beacons: Array[Vector2] = []
	var link: LinkResult = LinkResult.new()
	var hazards: Array[Dictionary] = []
	var integrity: int = 0
	var charges: PackedInt32Array = PackedInt32Array()
	var complete_mask: int = 0
	var objective_index: int = 0
	var active_socket: int = -1
	var link_status: int = LinkStatus.PLAYER_BUSY
	var phase: int = MatchPhase.LOBBY
	var remaining_ticks: int = 0
	var score: int = 0

class SettingsData extends RefCounted:
	var master_volume: float = 1.0
	var music_volume: float = 1.0
	var sfx_volume: float = 1.0
	var fullscreen: bool = false
	var fps_limit: int = 60
	var vsync: bool = true
	var ui_scale: float = 1.0
	var shake: float = 0.5
	var reduced_motion: bool = false
	var color_accessibility: bool = false
	var hints: bool = true
	var bindings: Dictionary = {}
	var last_ip: String = ""

class RecordData extends RefCounted:
	var seed: int = 0
	var difficulty: int = Difficulty.NORMAL
	var score: int = 0
	var duration_ticks: int = 0
	var integrity: int = 0
	var date_utc: String = ""
