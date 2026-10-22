extends SceneTree
## Focused normal-quit regression. The real main callback performs engine quit.
var route := "window"
var report_path := ""
var checks := 0
var failures: Array[String]=[]
var quit_deadline := 0

func _initialize() -> void:call_deferred("_run")

func _process(_delta: float) -> bool:
	if quit_deadline>0 and Time.get_ticks_msec()>quit_deadline:
		check(false,"Production quit did not finish")
		_write_report()
		quit(1)
	return false

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures.append(message)
		push_error("SHUTDOWN: "+message)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shutdown-route="):route=arg.trim_prefix("--shutdown-route=")
		if arg.begins_with("--report="):report_path=arg.trim_prefix("--report=")
	if route=="audio-only":
		await _audio_only()
		return
	var entry: String=ProjectSettings.get_setting("application/run/main_scene")
	var error := change_scene_to_file(entry)
	check(error==OK,"Load the shipped project entry")
	if error!=OK:
		_write_report()
		quit(1)
		return
	for unused: int in range(12):await process_frame
	var game: Node=current_scene
	check(game!=null and game.playing and game.session.mode=="solo","Actual main entry starts solo before normal quit")
	if game==null or not game.playing:
		_write_report()
		quit(1)
		return
	var sound: Node=game.soundscape
	check(sound._loops.size()==2,"Both original ambience loops are alive before quit")
	check(sound._loops[0].playing and sound._loops[1].playing,"Ambience playbacks are active before teardown")
	sound._play("blade")
	if route=="menu":
		game.show_pause()
		var button := _find_quit(game.menu_root)
		check(button!=null,"Shipped pause menu exposes Save & Quit")
		if button==null:
			_write_report()
			quit(1)
			return
		button.pressed.emit()
		button.pressed.emit()
	else:
		game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(game._quitting and not game.playing and not game.connecting,"Normal quit enters guarded teardown immediately")
	check(game.session.mode=="idle","Normal quit synchronously saves and closes session")
	check(not game.world.controls_enabled,"Normal quit blocks further movement input")
	check(sound._shut_down and not sound.enabled,"Normal quit explicitly shuts down soundscape")
	check(sound._voices.is_empty() and sound._loops.is_empty() and sound._streams.is_empty(),"Audio teardown releases all cached references")
	for player: Node in sound.get_children():
		if player is AudioStreamPlayer:check(not player.playing and player.stream==null,"Every player stops and detaches its stream")
	check(FileAccess.file_exists("user://blackbriar/solo_profile.json"),"Normal quit writes solo progress before engine shutdown")
	_write_report()
	# Do not free the scene or quit from the harness: production _quit_game owns it.
	# A frame watchdog avoids leaving a test coroutine alive during engine quit.
	quit_deadline=Time.get_ticks_msec()+4000

func _find_quit(node: Node) -> Button:
	if node is Button and node.text=="Save & Quit":return node
	for child: Node in node.get_children():
		var found := _find_quit(child)
		if found!=null:return found
	return null

func _audio_only() -> void:
	var sound: Node=load("res://game/online/soundscape.gd").new()
	root.add_child(sound)
	for unused: int in range(8):await process_frame
	check(sound._loops.size()==2,"Audio-only fixture starts both ambience loops")
	sound._play("blade")
	sound.shutdown()
	sound.shutdown()
	check(sound._shut_down and not sound.enabled,"Sound shutdown is idempotent")
	for player: Node in sound.get_children():
		if player is AudioStreamPlayer:check(not player.playing and player.stream==null,"Audio-only teardown stops and detaches every stream")
	for unused: int in range(8):await process_frame
	_write_report()
	quit(0 if failures.is_empty() else 1)

func _write_report() -> void:
	var report := {"route":route,"checks":checks,"passed":failures.is_empty(),"failures":failures}
	print("NORMAL_QUIT "+JSON.stringify(report))
	if not report_path.is_empty():
		var file := FileAccess.open(report_path,FileAccess.WRITE)
		if file!=null:
			file.store_string(JSON.stringify(report,"\t"))
			file.close()
