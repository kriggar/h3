extends SceneTree
## Runs the shipped scene and menu/HUD/world integration in separate processes.
## No simulated peers, fixture snapshot dictionaries, or server state edits.
const C=preload("res://game/online/catalog.gd")
var game: Node3D
var output := ""
var role := ""
var port := 24572
var checks := 0
var failures: Array[String]=[]
var moving := false
var started_ms := 0
var move_clock := 0.0

func _initialize() -> void:call_deferred("_run")

func _process(delta: float) -> bool:
	# Run after the world's idle-input poll, as a real producer of client intents.
	# The transport and server movement validation are unmodified production code.
	move_clock+=delta
	if moving and move_clock>=1.0/30.0:
		move_clock=0.0
		call_deferred("_move_remote")
	return false

func _move_remote() -> void:
	if game==null or not game.playing:return
	var p: Dictionary=game.session.state.get("players",{}).get(str(game.session.local_id),{})
	if p.is_empty():return
	var move := [-1.0,0.0] if float(p.pos[0])>-2.15 else [0.0,0.0]
	game.session.send_input({"move":move,"yaw":PI,"jump":false})

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures.append(message)
		push_error("ENTRY NETWORK "+role+": "+message)

func wait_until(predicate: Callable,message: String,seconds: float=10.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<deadline:
		if predicate.call():
			check(true,message)
			return true
		await create_timer(0.05).timeout
	check(false,message+" (timeout)")
	_diagnostic(message)
	return false

func _diagnostic(message: String) -> void:
	if game==null:return
	var s: Node=game.session
	var data: Dictionary={"message":message,"playing":game.playing,"connecting":game.connecting,"menu_open":game.menu_open,"mode":s.mode,"status":s.status,"local_id":s.local_id,"snapshot_players":s.state.get("players",{}).keys(),"session_path":str(s.get_path()),"physics_processing":s.is_physics_processing(),"tree_paused":paused,"multiplayer_poll":multiplayer_poll,"pending_count":s._pending.size(),"registered_peer_count":s._peer_tokens.size(),"welcomed":s._welcomed}
	if s._peer!=null:
		data.peer_status=s._peer.get_connection_status()
		data.peers=s.multiplayer.get_peers()
	if s.realm!=null:
		data.realm_tick=s.realm.state.tick
		data.realm_players=s.realm.state.players.keys()
	_mark("diagnostic",data)
	print("ENTRY_DIAGNOSTIC "+JSON.stringify(data))

func _run() -> void:
	started_ms=Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):role=arg.trim_prefix("--role=")
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
		if arg.begins_with("--test-port="):port=int(arg.trim_prefix("--test-port="))
	root.size=Vector2i(1440,900)
	game=load("res://online.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if role=="host" and DisplayServer.get_name()!="headless":
		# Let native shaders/material uploads settle before a peer's connection clock starts.
		for unused: int in range(6):await process_frame
		await RenderingServer.frame_post_draw
	check(game.name=="Draconia" and game.session.get_path()==NodePath("/root/Draconia/Session"),"Shipped main scene provides production RPC node path")
	check(game.menu_open and not game.playing and not game.connecting,"Shipped entry opens realm selection")
	check(is_instance_valid(game.world) and is_instance_valid(game.hud),"Shipped entry creates actual world and HUD")
	game.port_field.value=port
	game.player_name.text="Mara of Thornwatch" if role=="host" else "Rowan Wayfarer"
	game.address.text="127.0.0.1"
	if role=="host":await _host()
	else:await _client()
	await _finish()

func _host() -> void:
	game._begin("host")
	check(game.playing and game.session.mode=="host" and game.session.local_id==1,"Host menu enters actual listen-server gameplay")
	check(not game.menu_open and not game.connecting and game.hud.visible,"Host menu closes and live HUD is visible")
	check(game.world.controls_enabled and not game.world._panel_open,"Host entry enables third-person controls")
	_mark("ready",{"port":port})
	if not await wait_until(func():return game.session.state.get("players",{}).size()==2,"Host receives a real second player",18.0):return
	var remote := _remote_id()
	check(remote>1,"Remote adventurer has a true ENet peer ID")
	check(game.session.state.players[str(remote)].name=="Rowan Wayfarer","Host snapshot contains the guest's chosen name")
	if not await wait_until(func():return game.world.actors.has("p_"+str(remote)) and game.hud.party_rows.has(str(remote)),"Host main callbacks populate remote avatar and party frame"):return
	check(game.world.actors.has("p_1"),"Host world retains its own exact player character")
	check(game.world.actors["p_"+str(remote)].avatar.animator.has_animation("run"),"Remote player uses the preserved character animation set")
	check(game.world.actors["p_1"].avatar.body.scene_file_path==C.HERO_MODEL and game.world.actors["p_"+str(remote)].avatar.body.scene_file_path==C.HERO_MODEL,"Both real players instantiate the retained Mara model")
	check(game.hud.party_box.visible and str(game.hud.party_rows[str(remote)].name.text).contains("Rowan Wayfarer"),"Host party UI presents the guest's name")
	if not await wait_until(func():return float(game.session.state.players[str(remote)].pos[0])<-1.8,"Client intention moves authoritative remote position left"):return
	if not await wait_until(func():return game.world.actors["p_"+str(remote)].node.position.x<-1.6,"Host remote model follows replicated movement"):return
	if not await wait_until(func():return str(game.hud.log_label.text).contains("Rowan Wayfarer: The old road is open."),"Guest HUD chat reaches host main event routing and visible log"):return
	game.hud.open_chat()
	check(game.hud.chat_open and game.world._panel_open,"Host chat pauses world controls through production panel callback")
	game.hud.chat_input.text="I see you beneath the lanterns."
	game.hud.chat_input.text_submitted.emit(game.hud.chat_input.text)
	check(not game.hud.chat_open and not game.world._panel_open,"Host submitting chat restores world controls")
	if not await wait_until(func():return FileAccess.file_exists(output+"/client-observed.json"),"Client confirms both scene actors, party frame and return chat"):return
	# Only presentation is adjusted for the evidence camera; no gameplay state changes.
	if DisplayServer.get_name()!="headless":
		game.world.camera_distance=7.6
		game.world.camera_pitch=0.19
		await create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image!=null and image.get_width()==1440 and image.get_height()==900,"Native listen-server framebuffer is available")
		if image!=null:check(image.save_png(output+"/host-two-real-players.png")==OK,"Saved actual native screenshot of two connected heroes")
	game.show_pause()
	check(game.menu_open and game.playing,"Host can open shipped pause/realm menu")
	game._return_to_lobby()
	check(not game.playing and game.menu_open and game.session.mode=="idle" and not game.hud.visible,"Host Save & Return closes server and returns to usable realm selection")
	check(not game.world.controls_enabled,"Host lobby blocks world movement")
	if not await wait_until(func():return FileAccess.file_exists(output+"/client-disconnected.json"),"Guest receives host loss and returns through shipped lobby callback"):return
	game.player_name.text="Mara of Thornwatch"
	game._begin("solo")
	check(game.playing and game.session.mode=="solo" and game.session.state.players.size()==1,"Host lobby can immediately start an independent solo journey")
	check(game.hud.party_rows.is_empty() and not game.hud.party_box.visible,"Starting solo clears former party UI")
	check(not game.world.actors.has("p_"+str(remote)),"Starting solo removes the departed guest model")
	game._return_to_lobby()

func _client() -> void:
	game._begin("join")
	check(game.connecting and not game.playing and game.menu_open,"Join menu enters connecting state before first snapshot")
	check(str(game.menu_status.text).contains("Connecting"),"Join menu reports connection progress")
	if not await wait_until(func():return game.playing and not game.connecting,"First server snapshot enters shipped client gameplay",15.0):return
	check(game.session.mode=="client" and game.session.local_id>1,"Client entry retains server-assigned peer identity")
	check(not game.menu_open and game.hud.visible and game.world.controls_enabled,"Client gameplay closes lobby, displays HUD and enables controls")
	check(game.session.state.players.size()==2,"Client receives host and self in real shared snapshot")
	check(game.world.actors.has("p_1") and game.world.actors.has("p_"+str(game.session.local_id)),"Client main callback creates both actual player models")
	check(game.hud.player_name.text=="Rowan Wayfarer","Client player frame uses chosen local name")
	check(game.hud.party_rows.has("1") and str(game.hud.party_rows["1"].name.text).contains("Mara of Thornwatch"),"Client party UI shows the host")
	check(game.world.actors["p_1"].label.text=="Mara of Thornwatch","Remote 3D nameplate matches the host identity")
	moving=true
	if not await wait_until(func():return float(game.session.state.players[str(game.session.local_id)].pos[0])<-2.0,"Production client input receives authoritative movement confirmation"):return
	moving=false
	game.session.send_input({"move":[0.0,0.0],"yaw":PI,"jump":false})
	game.hud.open_chat()
	check(game.hud.chat_open and game.world._panel_open,"Client chat activates real UI input and blocks movement")
	game.hud.chat_input.text="The old road is open."
	game.hud.chat_input.text_submitted.emit(game.hud.chat_input.text)
	check(not game.hud.chat_open and not game.world._panel_open,"Client submit closes chat and restores controls")
	if not await wait_until(func():return str(game.hud.log_label.text).contains("Mara of Thornwatch: I see you beneath the lanterns."),"Host HUD chat returns through network and client main event routing"):return
	_mark("observed",{"local_id":game.session.local_id,"players":game.session.state.players.size(),"x":game.session.state.players[str(game.session.local_id)].pos[0]})
	if not await wait_until(func():return not game.playing and not game.connecting and game.session.mode=="idle","Host departure executes shipped disconnect-to-lobby flow",12.0):return
	check(game.menu_open and game.menu_root.visible and not game.hud.visible,"Client sees a usable realm-selection menu after host loss")
	check(not game.world.controls_enabled and game.world._panel_open,"Disconnected client cannot continue sending world movement")
	check(str(game.menu_status.text).contains("host") or str(game.menu_status.text).contains("Host"),"Client lobby explains the host disconnection")
	_mark("disconnected",{"ok":true})
	game.player_name.text="Rowan Wayfarer"
	game._begin("solo")
	check(game.playing and game.session.mode=="solo" and game.session.state.players.size()==1,"Client lobby can start solo after losing the host")
	check(game.hud.party_rows.is_empty() and not game.hud.party_box.visible,"Former host party row clears on new solo session")
	game._return_to_lobby()

func _remote_id() -> int:
	for id: String in game.session.state.get("players",{}):
		if int(id)!=game.session.local_id:return int(id)
	return 0

func _mark(name: String,data: Dictionary) -> void:
	var file := FileAccess.open(output+"/"+role+"-"+name+".json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(data))

func _finish() -> void:
	moving=false
	if game!=null:game.session.stop()
	var report := {"role":role,"checks":checks,"passed":failures.is_empty(),"failures":failures,"seconds":(Time.get_ticks_msec()-started_ms)/1000.0}
	_mark("report",report)
	print(JSON.stringify(report))
	if game!=null:
		game.queue_free()
		game=null
		for unused: int in range(8):await process_frame
	quit(0 if failures.is_empty() else 1)
