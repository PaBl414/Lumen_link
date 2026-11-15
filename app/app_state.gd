class_name AppState
extends RefCounted
const Types = preload("res://core/game_types.gd")
const Result = Types.Result
enum Screen { BOOT, MENU, LOADING, COUNTDOWN, PLAYING, INTERMISSION, RESULTS, HOST_FORM, JOIN_FORM, CONNECTING, LOBBY }
var current: int = Screen.BOOT
var return_to: int = Screen.MENU
var session_active: bool = false
func allows(next: int) -> bool:
	var transitions: Dictionary = {
		Screen.BOOT:[Screen.MENU], Screen.MENU:[Screen.LOADING,Screen.HOST_FORM,Screen.JOIN_FORM],
		Screen.LOADING:[Screen.COUNTDOWN,Screen.MENU,Screen.LOBBY], Screen.COUNTDOWN:[Screen.PLAYING,Screen.MENU,Screen.LOADING],
		Screen.PLAYING:[Screen.INTERMISSION,Screen.RESULTS,Screen.MENU,Screen.LOADING],
		Screen.INTERMISSION:[Screen.LOADING,Screen.MENU,Screen.LOBBY], Screen.RESULTS:[Screen.LOADING,Screen.MENU,Screen.LOBBY],
		Screen.HOST_FORM:[Screen.LOBBY,Screen.MENU,Screen.JOIN_FORM],
		Screen.JOIN_FORM:[Screen.HOST_FORM,Screen.CONNECTING,Screen.MENU],
		Screen.CONNECTING:[Screen.LOBBY,Screen.JOIN_FORM,Screen.MENU],
		Screen.LOBBY:[Screen.LOADING,Screen.MENU]}
	return next in transitions.get(current,[]) and (next not in [Screen.LOADING,Screen.COUNTDOWN,Screen.PLAYING] or session_active)
func transition(next: int) -> Result:
	if not allows(next): return Result.new(false,ERR_INVALID_PARAMETER,"Niedozwolone przejście ekranu: %d → %d" % [current,next])
	current = next
	return Result.new(true,OK,"",current)
