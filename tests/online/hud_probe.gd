extends SceneTree
const Hud=preload("res://game/online/hud.gd")
const Realm=preload("res://game/online/realm.gd")
var hud: CanvasLayer
var realm: RefCounted
var output := "/tmp/online-hud-probe"
var checks := 0
var failures := 0
var commands: Array=[]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):output=argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1440,900)
	var back := ColorRect.new()
	back.color=Color("31413e")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(back)
	realm=Realm.new()
	realm.add_player(1,"Mara Veyne",{"level":3,"gold":100,"inventory":["watch_blade","rowan_ring"],"quests":{"road":{"state":"active","progress":2}}})
	var p: Dictionary=realm.state.players["1"]
	hud=Hud.new()
	root.add_child(hud)
	hud.command_requested.connect(on_command)
	hud.update_state(realm.snapshot(),1,"fang_1")
	hud.set_interaction_hint("Speak with Captain Elric")
	hud.set_connection_status("Solo · 1 adventurer")
	await capture("01-hud")
	hud.toggle_panel("character")
	await capture("02-character")
	var before := int(p.attributes.might)
	await click_text("+")
	check(int(p.attributes.might)==before+1,"Native attribute click commits through realm")
	check(int(p.points)==3,"Native attribute click spends one point")
	hud.show_interaction("steward","quests")
	await capture("03-quests")
	hud.show_interaction("merchant","merchant")
	await capture("04-merchant")
	hud.close_panels()
	hud.open_chat()
	hud.chat_input.text="A lantern for the road."
	await capture("07-chat")
	var enter := InputEventKey.new()
	enter.physical_keycode=KEY_ENTER
	enter.keycode=KEY_ENTER
	enter.pressed=true
	Input.parse_input_event(enter)
	for i: int in range(3):await process_frame
	check(not hud.chat_open,"Native Enter closes chat")
	check(not commands.is_empty() and commands[-1].get("type","")=="chat","Native Enter submits actual chat intent")
	hud.open_chat()
	var escape := InputEventKey.new()
	escape.physical_keycode=KEY_ESCAPE
	escape.keycode=KEY_ESCAPE
	escape.pressed=true
	Input.parse_input_event(escape)
	for i: int in range(3):await process_frame
	check(not hud.chat_open and not hud.is_panel_open(),"Native Escape closes focused chat and releases input lock")
	realm.add_player(2,"Rowan Grey")
	hud.update_state(realm.snapshot(),1,"fang_1")
	await capture("08-travellers")
	check(hud.party_rows.size()==1 and hud.party_box.visible,"Actual snapshot peer creates a traveller health frame")
	realm.remove_player(2)
	hud.update_state(realm.snapshot(),1,"fang_1")
	check(hud.party_rows.is_empty() and not hud.party_box.visible,"Removed snapshot peer clears its health frame")
	p.next_xp=0
	p.level=20
	hud.update_state(realm.snapshot(),1,"fang_1")
	check(hud.experience_text.text.contains("MAXIMUM LEVEL"),"Maximum level never shows a zero XP denominator")
	p.next_xp=220
	p.level=3
	root.size=Vector2i(960,640)
	await process_frame
	hud.toggle_panel("character")
	await capture("05-character-small")
	hud.close_panels()
	root.size=Vector2i(1440,900)
	p.dead=true
	p.hp=0
	p.action_time=0.0
	hud.update_state(realm.snapshot(),1,"")
	check(hud.death_button.disabled,"Respawn waits for authoritative death recovery")
	await capture("06-death")
	p.action_time=3.0
	hud.update_state(realm.snapshot(),1,"")
	check(not hud.death_button.disabled,"Respawn becomes available after authoritative recovery")
	print("UI_CHECKS ",checks," FAILURES ",failures)
	var report := {"checks":checks,"failures":failures,"screenshots":8,"scope":"Native UI fixture, actual pointer dispatch and keyboard dispatch; not a world or network playthrough"}
	var file := FileAccess.open(output+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	quit(1 if failures>0 else 0)
func capture(name: String) -> void:
	for i: int in range(8):await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(output+"/"+name+".png")
	print("CAPTURE ",name," ",err," ",root.size)
func on_command(command: Dictionary) -> void:
	commands.append(command)
	if command.get("type","")=="chat":return
	realm.act(1,command)
	hud.update_state(realm.snapshot(),1,"fang_1")
func click_text(text: String) -> void:
	var button := find_button(hud,text)
	check(button!=null,"Native button exists "+text)
	if button==null:return
	var press := InputEventMouseButton.new()
	press.position=button.get_global_rect().get_center()
	press.global_position=press.position
	press.button_index=MOUSE_BUTTON_LEFT
	press.pressed=true
	Input.parse_input_event(press)
	await process_frame
	var release := press.duplicate() as InputEventMouseButton
	release.pressed=false
	Input.parse_input_event(release)
	for i: int in range(3):await process_frame
func find_button(node: Node, text: String) -> Button:
	if node is Button and node.text==text and not node.disabled:return node
	for child: Node in node.get_children():
		var result := find_button(child,text)
		if result!=null:return result
	return null
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		push_error("FAILED: "+message)
		failures+=1
	else:print("PASS ",message)
