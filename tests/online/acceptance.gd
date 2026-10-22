extends SceneTree
## Exercises the shipped entry/HUD/world with isolated saves in the Python runner.
const C=preload("res://game/online/catalog.gd")
var game: Node3D
var output := "/tmp/draconia-native-review"
var checks := 0
var failures: Array[String]=[]

func _initialize() -> void:call_deferred("_run")

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures.append(message)
		push_error("ACCEPTANCE: "+message)

func frames(count: int=5) -> void:
	for i: int in range(count):await process_frame
	await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await frames(3)
	var image:=root.get_texture().get_image()
	check(image!=null and image.get_width()>=960,"Native framebuffer available: "+name)
	if image!=null:check(image.save_png(output+"/"+name+".png")==OK,"Saved native capture: "+name)

func key(code: Key,pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code,true)
	await frames(2)
	key(code,false)
	await frames(2)

func place(position: Vector3) -> void:
	game.session.send_input({"move":[0.0,0.0],"yaw":PI,"jump":false})
	game.session.realm.state.players["1"].pos=C.array(position)
	game.session.realm.state.players["1"].yaw=PI
	game.session._publish()
	await frames(12)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="):output=arg.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1440,900)
	game=load("res://online.tscn").instantiate()
	root.add_child(game)
	await frames(15)
	check(game.menu_open and not game.playing,"Native entry opens usable realm selection")
	check(game.world.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"Camera uses perspective")
	check(game.world.camera.fov>=60 and game.world.camera.fov<=70,"Third-person field of view")
	check(FileAccess.get_sha256(C.HERO_MODEL)==C.HERO_SHA256,"Exact accepted character binary preserved")
	await capture("01-realm-selection")
	game._begin("solo")
	await frames(12)
	check(game.playing and game.session.mode=="solo","Entry starts the real solo realm")
	check(not game.menu_open and game.hud.visible,"Gameplay HUD replaces realm selection")
	check(game.world.actors.has("p_1"),"World presents the controlled hero")
	var avatar: Node3D=game.world.actors["p_1"].avatar
	for clip: String in ["idle","walk","run","attack","hit","death","combat_idle","cast_start","cast_hold","cast_release","cast_end","dodge"]:
		check(avatar.animator.has_animation(clip),"Preserved native clip: "+clip)
	check(game.hud.icons!=null,"Painted icon atlas is imported and used")
	check(game.world.camera.global_position.z>game.world.actors["p_1"].node.global_position.z,"Camera starts behind the north-facing hero")
	check(game.world.camera.global_position.y<game.world.actors["p_1"].node.global_position.y+5.0,"Camera starts at third-person height, not an overhead view")
	await capture("02-thornwatch-third-person")
	# Engine-level key events exercise actual movement routing. Runner owns focus.
	var start: Vector3=C.vector(game.session.state.players["1"].pos)
	key(KEY_W,true)
	for i: int in range(20):await create_timer(0.03).timeout
	key(KEY_W,false)
	await frames(4)
	var finish: Vector3=C.vector(game.session.state.players["1"].pos)
	check(finish.z<start.z-0.7,"W drives authoritative camera-relative northward movement")
	await tap(KEY_C)
	check(game.hud.panel_mode=="character","C opens the integrated character sheet")
	check(game.world._panel_open,"Character panel blocks world controls")
	await capture("03-character-sheet")
	await tap(KEY_ESCAPE)
	check(not game.hud.is_panel_open() and not game.world._panel_open,"Escape closes character panel and restores controls")
	# Trusted fixture placement shortens travel; F and quest actions use production UI.
	await place(C.ground_position(-4.5,20.0))
	await tap(KEY_F)
	check(game.hud.panel_mode=="steward","F opens the nearby captain's quest dialogue")
	game.hud.command_requested.emit({"type":"quest","id":"road"})
	await frames(3)
	check(game.session.state.players["1"].quests.has("road"),"Quest accepted through HUD → session → authoritative rules")
	await capture("04-quest-dialogue")
	await tap(KEY_ESCAPE)
	await tap(KEY_ENTER)
	check(game.hud.is_panel_open(),"Enter opens chat and blocks movement")
	await tap(KEY_ESCAPE)
	check(not game.hud.is_panel_open(),"Escape leaves chat cleanly")
	# Real action state and authored cast/roll animation visibility.
	game.hud.activate_ability("ward")
	await create_timer(0.22).timeout
	await frames(2)
	check(not avatar.sword.visible,"Held sword is hidden through the unarmed cast")
	await capture("05-iron-vow-cast")
	await create_timer(1.5).timeout
	await frames(3)
	check(avatar.sword.visible,"Held sword returns after casting")
	game.hud.activate_ability("roll")
	await create_timer(0.2).timeout
	await frames(2)
	check(not avatar.sword.visible,"Held sword is hidden through the source roll")
	await create_timer(1.0).timeout
	await frames(3)
	check(avatar.sword.visible,"Held sword returns after roll")
	await place(C.ground_position(0,-5))
	game.world.select_target("fang_1")
	await frames(8)
	check(game.hud.target_frame.visible,"Selected hostile has a live target frame")
	await capture("06-blackbriar-road")
	# Paused death was a concrete integration regression: respawn must restore input.
	game.show_pause()
	var p: Dictionary=game.session.realm.state.players["1"]
	p.dead=true;p.hp=0.0;p.action="death";p.action_time=3.0;p.action_duration=2.4167
	game.session._publish()
	game._resume()
	game.hud.command_requested.emit({"type":"respawn"})
	await frames(8)
	check(not game.session.state.players["1"].dead,"Respawn is accepted after death animation")
	check(game.world.controls_enabled and not game.world._panel_open,"Death while menu open does not permanently disable movement")
	check(not game.hud.is_panel_open(),"Respawn closes death panel")
	root.size=Vector2i(960,640)
	await frames(5)
	game.hud.toggle_panel("character")
	await capture("07-character-small-window")
	check(game.hud.panel_frame.get_global_rect().end.x<=game.hud.root_ui.size.x+1,"Small-window panel fits horizontally")
	game.hud.close_panels()
	game._return_to_lobby()
	await frames(4)
	check(not game.playing and game.session.mode=="idle" and game.menu_open,"Save & Return restores usable realm selection")
	game._begin("solo")
	await frames(4)
	check(game.session.state.players["1"].quests.has("road"),"Solo progression survives save and re-entry")
	game.session.stop()
	game.queue_free()
	await frames(3)
	var report: Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"captures":"Actual native Godot viewports", "fixture_scope":"Some server-owned positions/death state are set explicitly to shorten UI setup. Combat/quest invariants have separate rules and real-network suites."}
	var file:=FileAccess.open(output+"/acceptance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("NATIVE_ACCEPTANCE ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
