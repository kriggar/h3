extends Node3D
## Native third-person entry. World presentation never owns progression.

const Catalog = preload("res://game/online/catalog.gd")
const Session = preload("res://game/online/session.gd")
const Realm = preload("res://game/online/realm.gd")

var session: Node
var world: Node3D
var hud: CanvasLayer
var menu_layer: CanvasLayer
var menu_root: Control
var menu_panel: PanelContainer
var menu_status: Label
var player_name: LineEdit
var address: LineEdit
var port_field: SpinBox
var menu_open := false
var playing := false
var connecting := false
var hint_timer := 0.0
var soundscape: Node
var title_font: Font = preload("res://assets/cinzel.ttf")
var body_font: Font
var _arguments: Dictionary = {}
var _quitting := false

func _ready() -> void:
	_arguments=_parse_arguments()
	session=Session.new()
	session.name="Session"
	add_child(session)
	session.updated.connect(_on_snapshot)
	session.notice.connect(_on_notice)
	session.disconnected.connect(_on_disconnected)
	session.event_received.connect(_on_event)
	if _arguments.has("server"):
		var result: Error=session.start_dedicated(int(_arguments.get("port",Catalog.PORT)))
		if result!=OK:
			push_error("Could not start realm server: "+error_string(result))
			get_tree().quit(1)
		else:print("DRACONIA_REALM_READY port="+str(_arguments.get("port",Catalog.PORT)))
		return
	world=load("res://game/online/world.gd").new()
	world.name="World"
	add_child(world)
	world.input_changed.connect(func(command: Dictionary):
		if playing and not menu_open:session.send_input(command))
	world.action_requested.connect(_request_command)
	world.target_changed.connect(_on_target_changed)
	world.interaction_requested.connect(_on_interaction)
	hud=load("res://game/online/hud.gd").new()
	hud.name="Interface"
	add_child(hud)
	hud.command_requested.connect(_request_command)
	hud.panel_changed.connect(_on_panel_changed)
	hud.menu_requested.connect(show_pause)
	hud.visible=false
	if ResourceLoader.exists("res://game/online/soundscape.gd"):
		soundscape=load("res://game/online/soundscape.gd").new()
		add_child(soundscape)
	menu_layer=CanvasLayer.new()
	menu_layer.layer=20
	add_child(menu_layer)
	var preview: RefCounted=Realm.new()
	preview.add_player(1,"Mara")
	world.set_snapshot(preview.snapshot(),1)
	_show_lobby()
	if _arguments.has("solo"):_begin("solo")
	elif _arguments.has("host"):_begin("host")
	elif _arguments.has("join"):
		address.text=str(_arguments.join)
		_begin("join")
	get_tree().auto_accept_quit=false

func _parse_arguments() -> Dictionary:
	var result: Dictionary={}
	for raw: String in OS.get_cmdline_user_args():
		if not raw.begins_with("--"):continue
		var pair:=raw.trim_prefix("--").split("=",true,1)
		result[pair[0]]=pair[1] if pair.size()>1 else true
	return result

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_game()
	elif what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		if playing and not menu_open:show_pause()

func _quit_game() -> void:
	if _quitting:return
	_quitting=true
	playing=false
	connecting=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(world):
		world.controls_enabled=false
		world.set_panel_open(true)
	if is_instance_valid(session):session.stop()
	if is_instance_valid(soundscape):soundscape.shutdown()
	# Stop/detach audio before engine teardown. The mixer releases pending loop
	# playback references during ordinary frames. Headless frames can run faster
	# than the mixer, so also allow a short real-time drain. Repeated clicks are safe.
	var tree:=get_tree()
	var drain_until:=Time.get_ticks_msec()+120
	var remaining_frames:=8
	while remaining_frames>0 or Time.get_ticks_msec()<drain_until:
		await tree.process_frame
		remaining_frames-=1
	tree.quit()

func _process(delta: float) -> void:
	if not playing or world==null or hud==null:return
	if soundscape!=null:
		var player: Dictionary=session.state.get("players",{}).get(str(session.local_id),{})
		if not player.is_empty():
			var presentation: Dictionary={}
			var actor_key := "p_"+str(session.local_id)
			if world.actors.has(actor_key):
				var visual: Dictionary=world.actors[actor_key]
				if visual.avatar.has_method("animation_diagnostics"):
					presentation=visual.avatar.animation_diagnostics()
					var motion: Dictionary=visual.get("motion",{})
					var velocity: Vector3=motion.get("velocity",Vector3.ZERO)
					presentation.motion_speed=Vector2(velocity.x,velocity.z).length()
					presentation.teleported=bool(motion.get("teleported",false))
			soundscape.update_player(player,delta,presentation)
	hint_timer-=delta
	if hint_timer<=0:
		hint_timer=0.15
		var nearby: Dictionary=world.nearest_interaction()
		var hint: String=""
		if not nearby.is_empty():
			var label:=str(nearby.get("name",nearby.get("id","")))
			var kind:=str(nearby.get("kind","npc"))
			hint=("Gather " if kind in ["gather","emberbloom"] else "Loot " if kind in ["loot","drop"] else "Speak with ")+label
		if not menu_open:hud.set_interaction_hint(hint)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_ESCAPE:
		if connecting:
			session.stop()
			connecting=false
			_show_lobby()
		elif playing:
			if menu_open:_resume()
			elif hud.is_panel_open():hud.close_panels()
			else:show_pause()
		get_viewport().set_input_as_handled()
		return
	if not playing or menu_open:return
	var focus:=get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:return
	match event.keycode:
		KEY_ENTER,KEY_KP_ENTER:hud.open_chat()
		KEY_C:hud.toggle_panel("character")
		KEY_I,KEY_B:hud.toggle_panel("inventory")
		KEY_J,KEY_L:hud.toggle_panel("journal")
		KEY_1:hud.activate_ability("strike")
		KEY_2:hud.activate_ability("cleave")
		KEY_3:hud.activate_ability("ward")
		KEY_4:hud.activate_ability("roll")
		KEY_5:hud.activate_ability("potion")
		_:return
	get_viewport().set_input_as_handled()

func _request_command(command: Dictionary) -> void:
	if not playing or menu_open:return
	session.command(command)

func _on_snapshot(snapshot: Dictionary) -> void:
	if world==null:return
	if connecting and snapshot.get("players",{}).has(str(session.local_id)):
		connecting=false
		_enter_game()
	world.set_snapshot(snapshot,session.local_id)
	if hud!=null:
		hud.update_state(snapshot,session.local_id,world.target_id)
		hud.set_connection_status(session.status)

func _on_target_changed(id: String) -> void:
	if hud==null:return
	hud.set_target(id)
	if not session.state.is_empty():hud.update_state(session.state,session.local_id,id)

func _on_notice(message: String) -> void:
	if is_instance_valid(menu_status):menu_status.text=message
	if hud!=null:hud.show_notice(message)

func _on_event(event: Dictionary) -> void:
	if world!=null:world.show_event(event)
	if hud!=null:hud.show_event(event)
	if soundscape!=null:soundscape.play_event(event,session.local_id)

func _on_disconnected(reason: String) -> void:
	playing=false
	connecting=false
	if hud!=null:
		hud.close_panels()
		hud.visible=false
	if world!=null:
		_show_lobby()
		menu_status.text=reason

func _on_interaction(id: String,kind: String) -> void:
	if not playing or menu_open:return
	for npc: Dictionary in Catalog.NPCS:
		if str(npc.id)==id:
			hud.show_interaction(id,kind)
			return
	if kind in ["gather","emberbloom"]:_request_command({"type":"gather","id":id})
	elif kind in ["drop","loot"]:_request_command({"type":"loot","id":id})
	else:_request_command({"type":"interact","id":id})

func _on_panel_changed(open: bool) -> void:
	if world!=null:
		world.controls_enabled=playing
		world.set_panel_open(open or menu_open or not playing)
	if open and playing:_stop_moving()

func _stop_moving() -> void:
	var player: Dictionary=session.state.get("players",{}).get(str(session.local_id),{})
	session.send_input({"move":[0.0,0.0],"yaw":float(player.get("yaw",PI)),"jump":false})

func _frame(bg: Color,border: Color,width: int=1) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=bg
	box.border_color=border
	box.set_border_width_all(width)
	box.set_corner_radius_all(2)
	box.content_margin_left=24
	box.content_margin_right=24
	box.content_margin_top=22
	box.content_margin_bottom=22
	box.shadow_color=Color(0,0,0,0.5)
	box.shadow_size=18
	return box

func _label(text: String,size: int,color: Color,heading: bool=false) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	if heading:label.add_theme_font_override("font",title_font)
	return label

func _button(text: String,callback: Callable,primary: bool=false) -> Button:
	var button:=Button.new()
	button.text=text
	button.custom_minimum_size.y=46
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size",16)
	button.add_theme_font_override("font",title_font)
	button.add_theme_color_override("font_color",Color("f1ddad"))
	button.add_theme_stylebox_override("normal",_frame(Color("472b22") if primary else Color("1d2526"),Color("927447"),2 if primary else 1))
	button.add_theme_stylebox_override("hover",_frame(Color("4a3d2e"),Color("d2b574"),2))
	button.add_theme_stylebox_override("pressed",_frame(Color("1d1714"),Color("f0ce84"),2))
	button.add_theme_stylebox_override("focus",_frame(Color(0,0,0,0),Color("c5a765"),2))
	button.pressed.connect(callback)
	return button

func _create_menu(width: float=410.0,centered: bool=false) -> VBoxContainer:
	if is_instance_valid(menu_root):
		menu_layer.remove_child(menu_root)
		menu_root.queue_free()
	menu_root=Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(menu_root)
	var shade:=ColorRect.new()
	shade.color=Color(0.015,0.023,0.025,0.48 if centered else 0.14)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(shade)
	var align: Container=CenterContainer.new() if centered else MarginContainer.new()
	align.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if align is MarginContainer:
		align.add_theme_constant_override("margin_left",48)
		align.add_theme_constant_override("margin_top",32)
		align.add_theme_constant_override("margin_bottom",28)
		align.add_theme_constant_override("margin_right",48)
	menu_root.add_child(align)
	menu_panel=PanelContainer.new()
	menu_panel.custom_minimum_size.x=width
	menu_panel.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	menu_panel.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	menu_panel.add_theme_stylebox_override("panel",_frame(Color(0.045,0.062,0.065,0.97),Color("816b44"),2))
	align.add_child(menu_panel)
	var v:=VBoxContainer.new()
	v.add_theme_constant_override("separation",12)
	menu_panel.add_child(v)
	menu_open=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if world!=null:world.set_panel_open(true)
	return v

func _show_lobby() -> void:
	playing=false
	if world!=null:world.controls_enabled=false
	if hud!=null:hud.visible=false
	var v:=_create_menu()
	var over:=_label("A WORLD BEYOND THE OLD ROAD",11,Color("af9670"))
	over.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(over)
	var title:=_label("DRACONIA",36,Color("ead7ab"),true)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var subtitle:=_label("THE BLACKBRIAR MARCH",14,Color("b9b9a2"),true)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(subtitle)
	v.add_child(HSeparator.new())
	var desc:=_label("The watchfires are fading.\nBeyond Thornwatch, the forest remembers.",15,Color("b9c1b9"))
	desc.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(desc)
	player_name=LineEdit.new()
	player_name.text=str(_arguments.get("name","Mara"))
	player_name.placeholder_text="Character name"
	player_name.max_length=20
	player_name.custom_minimum_size.y=38
	player_name.tooltip_text="One hero. Your name is visible to other players."
	v.add_child(player_name)
	v.add_child(_button("Enter the March",func():_begin("solo"),true))
	v.add_child(_button("Host a Realm",func():_begin("host")))
	var network:=HBoxContainer.new()
	network.add_theme_constant_override("separation",8)
	v.add_child(network)
	address=LineEdit.new()
	address.placeholder_text="Host IP address"
	address.text="127.0.0.1"
	address.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	address.custom_minimum_size.y=38
	network.add_child(address)
	port_field=SpinBox.new()
	port_field.min_value=1024
	port_field.max_value=65535
	port_field.value=int(_arguments.get("port",Catalog.PORT))
	port_field.custom_minimum_size.x=100
	port_field.tooltip_text="UDP port (must match the host)"
	network.add_child(port_field)
	v.add_child(_button("Join a Realm",func():_begin("join")))
	menu_status=_label("Solo journeys save locally. Realms support up to 4 players.\nDirect IP / LAN · Your host keeps your realm progress.",12,Color("8e9e98"))
	menu_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	menu_status.custom_minimum_size=Vector2(360,50)
	v.add_child(menu_status)
	var foot:=_label("WASD move  ·  Mouse drag orbit  ·  Wheel zoom\n1–5 abilities  ·  Tab target  ·  F interact",12,Color("a99c7e"))
	foot.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foot)
	var version:=_label("MULTIPLAYER RPG FOUNDATION   /   "+Catalog.VERSION,10,Color("77847c"))
	version.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(version)

func _begin(mode: String) -> void:
	if connecting:return
	var name_value:=player_name.text.strip_edges()
	if name_value.is_empty():
		menu_status.text="Give your character a name before entering."
		return
	var result: Error=ERR_INVALID_PARAMETER
	if mode=="host":result=session.host_game(name_value,int(port_field.value))
	elif mode=="join":
		if address.text.strip_edges().is_empty():
			menu_status.text="Enter the host's IP address."
			return
		result=session.join_game(name_value,address.text.strip_edges(),int(port_field.value))
	else:result=session.start_solo(name_value)
	if result!=OK:
		menu_status.text="Could not enter: "+error_string(result)+". Check the address and UDP port."
		return
	if mode=="join":
		connecting=true
		menu_status.text="Connecting to "+address.text+"…  Esc to cancel."
	else:_enter_game()

func _enter_game() -> void:
	playing=true
	connecting=false
	menu_open=false
	if is_instance_valid(menu_root):menu_root.visible=false
	hud.visible=true
	world.set_panel_open(false)
	world.controls_enabled=true
	_on_snapshot(session.state)
	hud.show_notice("Welcome to Thornwatch. Speak with Captain Elric beside the watchhall.")

func show_pause() -> void:
	if not playing:return
	hud.close_panels()
	_stop_moving()
	var v:=_create_menu(420,true)
	var title:=_label("The Watchfire",26,Color("ead7ab"),true)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var status:=_label(session.status,13,Color("aeb8aa"))
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(status)
	v.add_child(_button("Return to the March",_resume,true))
	v.add_child(_button("Character",func():
		_resume()
		hud.toggle_panel("character")))
	v.add_child(_button("Save & Return to Realms",_return_to_lobby))
	v.add_child(_button("Save & Quit",_quit_game))
	var note:=_label("WASD  Move relative to the camera\nLMB / RMB drag  Orbit    Wheel  Zoom\nSpace  Jump    Tab  Cycle hostile targets\nF  Interact    1–5  Abilities\nC  Character    I  Inventory    J  Journal\n\nThe world continues while menus are open.",13,Color("b2b5a6"))
	v.add_child(note)
	var volume_row:=HBoxContainer.new()
	volume_row.add_theme_constant_override("separation",18)
	v.add_child(volume_row)
	volume_row.add_child(_label("Sound",14,Color("b7a171")))
	var volume:=HSlider.new()
	volume.min_value=-45
	volume.max_value=0
	volume.value=AudioServer.get_bus_volume_db(0)
	volume.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	volume.tooltip_text="Master volume"
	volume.value_changed.connect(func(value: float):AudioServer.set_bus_volume_db(0,value))
	volume_row.add_child(volume)
	menu_status=_label("Progress is saved by the current realm host.",12,Color("b7a171"))
	v.add_child(menu_status)

func _resume() -> void:
	menu_open=false
	if is_instance_valid(menu_root):menu_root.visible=false
	world.set_panel_open(hud.is_panel_open())
	world.controls_enabled=playing

func _return_to_lobby() -> void:
	playing=false
	session.stop()
	hud.close_panels()
	world.select_target("")
	_show_lobby()
