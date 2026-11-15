extends SceneTree
# IO integration fixture. Requires an explicitly isolated user data directory.
func _initialize() -> void:
 var args: PackedStringArray=OS.get_cmdline_user_args()
 var isolated: String="";var action: String=""
 for arg: String in args:
  if arg.begins_with("--isolated="):isolated=arg.trim_prefix("--isolated=")
  if arg.begins_with("--action="):action=arg.trim_prefix("--action=")
 var path: String=ProjectSettings.globalize_path("user://progress.json")
 if isolated.is_empty() or not path.begins_with(isolated+"/"):push_error("Requires isolated XDG_DATA_HOME");quit(1);return
 var store: ProgressStore=ProgressStore.new();store.load_progress()
 if action=="write":
  store.accept_completion(&"dock",0,100,300);store.accept_completion(&"garden",1,200,600)
 elif action=="reset":store.reset_progress(true)
 elif action=="cancel_reset":store.reset_progress(false)
 elif action!="read":quit(1);return
 print(JSON.stringify({"path":path,"data":store.data,"warning":store.warning,"dirty":store.dirty}));quit(0)
