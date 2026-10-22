extends CanvasLayer
## Original native third-person RPG HUD. UI submits intent; the server owns rules.

signal command_requested(command: Dictionary)
signal panel_changed(open: bool)
signal menu_requested

const Catalog=preload("res://game/online/catalog.gd")
const Frame=preload("res://game/online/ui_frame.gd")
const Minimap=preload("res://game/online/ui_minimap.gd")
const TITLE_FONT=preload("res://assets/cinzel.ttf")
const GOLD := Color("d0b273")
const CREAM := Color("e4ddc9")
const MUTED := Color("9faaa6")
const SUBTLE := Color("70817e")
const ICON_PATH := "res://assets/online/icons/abilities.png"

var state: Dictionary={}
var local_id := 1
var target_id := ""
var root_ui: Control
var player_frame: Control
var player_name: Label
var player_level: Label
var player_health: ProgressBar
var player_resource: ProgressBar
var health_text: Label
var resource_text: Label
var player_ward: Label
var party_box: VBoxContainer
var party_rows: Dictionary={}
var target_frame: Control
var target_name: Label
var target_level: Label
var target_health: ProgressBar
var target_health_text: Label
var target_cast: Label
var minimap_frame: Control
var minimap: Control
var tracker: VBoxContainer
var zone_label: Label
var action_frame: Control
var ability_buttons: Dictionary={}
var experience: ProgressBar
var experience_text: Label
var utility_frame: Control
var log_frame: Control
var log_label: Label
var connection_label: Label
var chat_frame: Control
var chat_input: LineEdit
var chat_open := false
var help_label: Label
var interaction_frame: Control
var interaction_label: Label
var notice_frame: Control
var notice_label: Label
var notice_time := 0.0
var zone_banner: Label
var zone_time := 7.0
var cover: Control
var dim: ColorRect
var panel_frame: Control
var panel_body: Control
var panel_title: Label
var panel_subtitle: Label
var panel_mode := ""
var panel_fingerprint := ""
var tracker_fingerprint := ""
var profile_label: Label
var profile_health: Label
var coin_label: Label
var death_button: Button
var event_lines: Array[String]=[]
var preview_factory := Callable()
var icons: Texture2D
var icon_check_timer := 0.0
var _portrait_viewport: SubViewport
var _character_viewport: SubViewport
var _first_state := true

func _ready() -> void:
	layer=10
	root_ui=Control.new()
	root_ui.name="Interface"
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(root_ui)
	root_ui.theme=_theme()
	_load_icons()
	_build_player()
	_build_target()
	_build_map()
	_build_actions()
	_build_footer()
	_build_messages()
	_build_cover()
	root_ui.move_child(notice_frame,root_ui.get_child_count()-1)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh()

func _process(delta: float) -> void:
	if notice_time>0:
		notice_time=maxf(0.0,notice_time-delta)
		notice_frame.modulate.a=minf(1.0,notice_time*2.0)
		notice_frame.visible=notice_time>0.0
	if zone_time>0:
		zone_time=maxf(0.0,zone_time-delta)
		zone_banner.modulate.a=minf(1.0,zone_time)
		zone_banner.visible=zone_time>0.0
	if icons==null:
		icon_check_timer+=delta
		if icon_check_timer>1.0:
			icon_check_timer=0
			_load_icons()
			if icons!=null:_refresh_icons()
	if not state.is_empty():_refresh_cooldowns(delta)

func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size=16
	theme.set_color("font_color","Label",CREAM)
	theme.set_color("font_shadow_color","Label",Color(0,0,0,0.85))
	theme.set_constant("shadow_offset_y","Label",1)
	theme.set_color("font_color","Button",CREAM)
	theme.set_color("font_hover_color","Button",Color("fff1c8"))
	theme.set_color("font_pressed_color","Button",Color("f7d68d"))
	theme.set_color("font_disabled_color","Button",Color("626d68"))
	theme.set_stylebox("normal","Button",_style(Color("28271e"),Color("8a744e")))
	theme.set_stylebox("hover","Button",_style(Color("3c4030"),Color("c6a76a")))
	theme.set_stylebox("pressed","Button",_style(Color("1d231c"),Color("e2c68c")))
	theme.set_stylebox("disabled","Button",_style(Color("131b1b"),Color("3b443c")))
	theme.set_stylebox("focus","Button",_style(Color(0,0,0,0),Color("cbb980")))
	theme.set_stylebox("panel","TooltipPanel",_style(Color("0e1517"),Color("b09a67"),10))
	theme.set_font_size("font_size","TooltipLabel",16)
	theme.set_color("font_color","TooltipLabel",CREAM)
	theme.set_constant("outline_size","TooltipLabel",0)
	theme.set_stylebox("panel","Panel",_style(Color("111b1c"),Color("6e654f")))
	return theme

func _style(fill: Color, edge: Color, margin: int=6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=edge
	style.set_border_width_all(1)
	style.content_margin_left=margin
	style.content_margin_right=margin
	style.content_margin_top=margin
	style.content_margin_bottom=margin
	return style

func _frame(parent: Node, ornate: bool=true) -> Control:
	var control: Control=Frame.new()
	control.ornate=ornate
	parent.add_child(control)
	return control

func _label(parent: Node, text: String, font_size: int=16, color: Color=CREAM, title: bool=false) -> Label:
	var label := Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	if title:label.add_theme_font_override("font",TITLE_FONT)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, call: Callable, min_size: Vector2=Vector2(100,34)) -> Button:
	var button := Button.new()
	button.text=text
	button.custom_minimum_size=min_size
	button.focus_mode=Control.FOCUS_NONE
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.pressed.connect(call)
	parent.add_child(button)
	return button

func _meter(parent: Node, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage=false
	bar.min_value=0
	bar.max_value=100
	bar.value=100
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",_style(Color("080f11"),Color("6c5d3e"),0))
	var colored := _style(fill,fill.lightened(0.28),0)
	bar.add_theme_stylebox_override("fill",colored)
	parent.add_child(bar)
	return bar

func _build_player() -> void:
	player_frame=_frame(root_ui)
	var portrait_border := _frame(player_frame,false)
	portrait_border.position=Vector2(14,14)
	portrait_border.size=Vector2(76,76)
	_portrait_viewport=_preview(portrait_border,Vector2(4,4),Vector2(68,68),true)
	player_level=_label(player_frame,"1",18,GOLD,true)
	player_level.position=Vector2(39,82)
	player_level.size=Vector2(24,24)
	player_level.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	player_name=_label(player_frame,"Mara Veyne",21,CREAM,true)
	player_name.position=Vector2(102,12)
	player_name.size=Vector2(196,28)
	player_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	player_health=_meter(player_frame,Color("496f49"))
	player_health.position=Vector2(102,43)
	player_health.size=Vector2(218,22)
	health_text=_label(player_health,"128 / 128",13)
	health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	health_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	player_resource=_meter(player_frame,Color("496f80"))
	player_resource.position=Vector2(102,69)
	player_resource.size=Vector2(218,15)
	resource_text=_label(player_resource,"100 RESOLVE",10,Color("d0e0dd"))
	resource_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resource_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	resource_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	player_ward=_label(player_frame,"HIGHLANDER  /  VANGUARD",10,MUTED)
	player_ward.position=Vector2(102,90)
	player_ward.size=Vector2(215,20)
	party_box=VBoxContainer.new()
	party_box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	party_box.add_theme_constant_override("separation",8)
	root_ui.add_child(party_box)
	party_box.visible=false

func _build_target() -> void:
	target_frame=_frame(root_ui)
	target_frame.visible=false
	target_name=_label(target_frame,"Duskfang",19,CREAM,true)
	target_name.position=Vector2(35,10)
	target_name.size=Vector2(201,28)
	target_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	target_level=_label(target_frame,"1",16,GOLD,true)
	target_level.position=Vector2(251,11)
	target_level.size=Vector2(23,25)
	target_level.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	target_health=_meter(target_frame,Color("8f4539"))
	target_health.position=Vector2(17,43)
	target_health.size=Vector2(257,20)
	target_health_text=_label(target_health,"85 / 85",12)
	target_health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target_health_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	target_health_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	target_cast=_label(target_frame,"HOSTILE",10,Color("bb8f77"))
	target_cast.position=Vector2(35,68)
	target_cast.size=Vector2(230,18)

func _build_map() -> void:
	minimap_frame=Control.new()
	minimap_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(minimap_frame)
	zone_label=_label(minimap_frame,"THORNWATCH",15,GOLD,true)
	zone_label.position=Vector2(-40,0)
	zone_label.size=Vector2(276,28)
	zone_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	minimap=Minimap.new()
	minimap_frame.add_child(minimap)
	minimap.position=Vector2(0,28)
	minimap.size=Vector2(196,196)
	var sub := _label(minimap_frame,"BLACKBRIAR MARCH",10,MUTED)
	sub.position=Vector2(-20,224)
	sub.size=Vector2(236,20)
	sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	tracker=VBoxContainer.new()
	tracker.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tracker.add_theme_constant_override("separation",8)
	root_ui.add_child(tracker)

func _build_actions() -> void:
	action_frame=_frame(root_ui)
	var title := _label(action_frame,"V A N G U A R D",10,GOLD)
	title.position=Vector2(150,-17)
	title.size=Vector2(180,17)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var index := 0
	for id: String in Catalog.ABILITIES:
		var data: Dictionary=Catalog.ABILITIES[id]
		var socket := _frame(action_frame,false)
		socket.position=Vector2(30+index*80,14)
		socket.size=Vector2(68,68)
		var button := _button(socket,"",activate_ability.bind(id),Vector2.ZERO)
		button.position=Vector2(4,4)
		button.size=Vector2(60,60)
		button.expand_icon=true
		button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width",58)
		button.add_theme_stylebox_override("normal",_style(Color("192222"),Color("514d38"),0))
		button.add_theme_stylebox_override("hover",_style(Color("4c5039"),GOLD,0))
		button.add_theme_stylebox_override("pressed",_style(Color("0c1214"),GOLD,0))
		button.tooltip_text=_ability_tooltip(id)
		var fallback := _label(button,["I","II","III","IV","V"][index],24,GOLD,true)
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		var shade := ColorRect.new()
		shade.color=Color(0.03,0.04,0.045,0.79)
		shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(shade)
		shade.position=Vector2.ZERO
		shade.size=Vector2(60,0)
		var cooldown := _label(button,"",23,CREAM,true)
		cooldown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cooldown.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cooldown.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		var key := _label(socket,str(data.key),13,Color("fff1cd"))
		key.position=Vector2(7,3)
		var count := _label(socket,"",11,CREAM)
		count.position=Vector2(36,49)
		count.size=Vector2(25,17)
		count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		var pip := _label(socket,"",10,Color("c5d8cd"))
		pip.position=Vector2(6,49)
		ability_buttons[id]={"button":button,"fallback":fallback,"shade":shade,"cooldown":cooldown,"count":count,"pip":pip,"socket":socket,"remaining":0.0}
		index+=1
	experience=_meter(action_frame,Color("817044"))
	experience.position=Vector2(24,91)
	experience.size=Vector2(422,5)
	experience_text=_label(action_frame,"LEVEL 1  •  0 / 90 XP",10,Color("bdb89f"))
	experience_text.position=Vector2(24,100)
	experience_text.size=Vector2(422,18)
	experience_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_refresh_icons()

func _build_footer() -> void:
	utility_frame=Control.new()
	utility_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(utility_frame)
	var utility_defs := [["C","Character","character"],["I","Bags","inventory"],["J","Journal","journal"],["Esc","Menu","menu"]]
	for index: int in range(utility_defs.size()):
		var data: Array=utility_defs[index]
		var button := _button(utility_frame,str(data[0]),_utility_pressed.bind(str(data[2])),Vector2(48,39))
		button.position=Vector2(index*55,0)
		button.size=Vector2(48,39)
		button.add_theme_font_override("font",TITLE_FONT)
		button.add_theme_font_size_override("font_size",14)
		button.tooltip_text=str(data[1])+" ["+str(data[0])+"]"
		var label := _label(utility_frame,str(data[1]).to_upper(),9,MUTED)
		label.position=Vector2(index*55-4,44)
		label.size=Vector2(56,15)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	connection_label=_label(root_ui,"OFFLINE ADVENTURE",10,MUTED)
	log_frame=Control.new()
	log_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(log_frame)
	var log_title := _label(log_frame,"THE CHRONICLE",10,GOLD)
	log_title.position=Vector2(0,0)
	log_label=_label(log_frame,"",13,Color("c3cbc0"))
	log_label.position=Vector2(0,23)
	log_label.size=Vector2(303,82)
	log_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	log_label.max_lines_visible=4
	var chat_hint := _label(log_frame,"ENTER TO SPEAK",9,SUBTLE)
	chat_hint.position=Vector2(185,1)
	chat_hint.size=Vector2(118,17)
	chat_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	chat_frame=_frame(root_ui,false)
	chat_frame.visible=false
	chat_input=LineEdit.new()
	chat_input.position=Vector2(9,5)
	chat_input.size=Vector2(304,30)
	chat_input.placeholder_text="Speak to the realm…"
	chat_input.max_length=160
	chat_input.add_theme_font_size_override("font_size",14)
	chat_input.add_theme_color_override("font_color",CREAM)
	chat_input.add_theme_stylebox_override("normal",_style(Color("13201f"),Color("4d5c4d"),6))
	chat_input.add_theme_stylebox_override("focus",_style(Color("182724"),GOLD,6))
	chat_frame.add_child(chat_input)
	chat_input.text_submitted.connect(_submit_chat)
	chat_input.gui_input.connect(_chat_gui_input)
	help_label=_label(root_ui,"WASD  Move    ·    Mouse drag  Look    ·    Tab  Target    ·    F  Interact",11,Color("bdc3ad"))
	help_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _build_messages() -> void:
	interaction_frame=_frame(root_ui,false)
	interaction_frame.visible=false
	interaction_label=_label(interaction_frame,"",15,CREAM)
	interaction_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interaction_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	notice_frame=_frame(root_ui,false)
	notice_frame.visible=false
	notice_label=_label(notice_frame,"",16,GOLD)
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notice_label.offset_left=14
	notice_label.offset_right=-14
	notice_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	zone_banner=_label(root_ui,"The Blackbriar March",30,Color("e9d8ae"),true)
	zone_banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	zone_banner.add_theme_color_override("font_shadow_color",Color(0,0,0,0.95))
	zone_banner.add_theme_constant_override("shadow_offset_y",2)

func _build_cover() -> void:
	cover=Control.new()
	cover.name="Panels"
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(cover)
	dim=ColorRect.new()
	dim.color=Color(0.005,0.012,0.014,0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.add_child(dim)
	dim.gui_input.connect(_outside_panel)
	panel_frame=_frame(cover)
	panel_frame.mouse_filter=Control.MOUSE_FILTER_STOP
	panel_title=_label(panel_frame,"Character",27,GOLD,true)
	panel_title.position=Vector2(28,20)
	panel_title.size=Vector2(700,36)
	panel_subtitle=_label(panel_frame,"",13,MUTED)
	panel_subtitle.position=Vector2(28,61)
	panel_subtitle.size=Vector2(700,25)
	var close := _button(panel_frame,"×",close_panels,Vector2(35,34))
	close.name="Close"
	close.add_theme_font_size_override("font_size",23)
	close.tooltip_text="Close [Esc]"
	panel_body=Control.new()
	panel_body.name="Content"
	panel_body.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel_frame.add_child(panel_body)
	cover.visible=false

func _layout() -> void:
	if root_ui==null:return
	var view := get_viewport().get_visible_rect().size
	player_frame.position=Vector2(24,23)
	player_frame.size=Vector2(337,115)
	party_box.position=Vector2(26,153)
	party_box.size=Vector2(238,194)
	target_frame.position=Vector2(view.x*0.5-145,25)
	target_frame.size=Vector2(290,92)
	minimap_frame.position=Vector2(view.x-225,21)
	minimap_frame.size=Vector2(196,246)
	tracker.position=Vector2(view.x-285,286)
	tracker.size=Vector2(255,270)
	action_frame.position=Vector2(view.x*0.5-235,view.y-137)
	action_frame.size=Vector2(470,121)
	utility_frame.position=Vector2(view.x-250,view.y-82)
	utility_frame.size=Vector2(220,60)
	log_frame.position=Vector2(26,view.y-(195 if chat_open else 163))
	log_frame.size=Vector2(303,105)
	connection_label.position=Vector2(26,view.y-27)
	connection_label.size=Vector2(300,18)
	chat_frame.position=Vector2(24,view.y-76)
	chat_frame.size=Vector2(322,40)
	help_label.position=Vector2(view.x*0.5-330,view.y-184)
	help_label.size=Vector2(660,20)
	interaction_frame.position=Vector2(view.x*0.5-185,view.y-238)
	interaction_frame.size=Vector2(370,36)
	notice_frame.position=Vector2(view.x*0.5-270,view.y-310)
	notice_frame.size=Vector2(540,48)
	zone_banner.position=Vector2(view.x*0.5-320,155)
	zone_banner.size=Vector2(640,50)
	# At a truly small logical viewport, preserve the view and separate corners.
	if view.x<1180:
		player_frame.scale=Vector2.ONE*0.83
		party_box.scale=Vector2.ONE*0.83
		party_box.position.y=128
		target_frame.scale=Vector2.ONE*0.85
		target_frame.position.x=view.x*0.5-123
		minimap_frame.scale=Vector2.ONE*0.83
		minimap_frame.position.x=view.x-187
		tracker.position=Vector2(view.x-224,247)
		tracker.size.x=203
		log_frame.visible=false
		help_label.visible=false
		utility_frame.scale=Vector2.ONE*0.79
		utility_frame.position.x=view.x-191
	else:
		player_frame.scale=Vector2.ONE
		party_box.scale=Vector2.ONE
		target_frame.scale=Vector2.ONE
		minimap_frame.scale=Vector2.ONE
		utility_frame.scale=Vector2.ONE
		log_frame.visible=true
		help_label.visible=true
	if panel_frame!=null:
		var panel_size := Vector2(minf(930,view.x-52),minf(690,view.y-92))
		if panel_mode in ["steward","journal"]:panel_size=Vector2(minf(760,view.x-52),minf(698,view.y-74))
		if panel_mode in ["merchant","keeper"]:panel_size=Vector2(minf(690,view.x-52),minf(530,view.y-74))
		if panel_mode=="death":panel_size=Vector2(minf(540,view.x-52),300)
		panel_frame.size=panel_size
		panel_frame.position=(view-panel_size)*0.5
		var close: Control=panel_frame.get_node("Close")
		close.position=Vector2(panel_size.x-60,23)
		panel_body.position=Vector2(27,100)
		panel_body.size=panel_size-Vector2(54,125)
		panel_title.size.x=panel_size.x-110
		panel_subtitle.size.x=panel_size.x-60

func update_state(snapshot: Dictionary, player_id: int, target: String="") -> void:
	state=snapshot
	local_id=player_id
	target_id=target
	if not is_node_ready():return
	if _first_state and not _player().is_empty():
		_first_state=false
		_event("You have arrived at Thornwatch.")
		zone_time=7.0
	_refresh()

func _player() -> Dictionary:
	return state.get("players",{}).get(str(local_id),{})

func _refresh() -> void:
	var p := _player()
	if p.is_empty():return
	player_name.text=str(p.get("name","Mara Veyne"))
	player_name.tooltip_text=player_name.text
	player_level.text=str(p.get("level",1))
	player_health.max_value=maxf(1,float(p.get("max_hp",100)))
	player_health.value=float(p.get("hp",100))
	health_text.text="%d / %d" % [int(p.get("hp",100)),int(p.get("max_hp",100))]
	player_resource.max_value=maxf(1,float(p.get("max_energy",100)))
	player_resource.value=float(p.get("energy",100))
	resource_text.text="%d  RESOLVE" % int(p.get("energy",100))
	player_ward.text="IRON VOW  ·  %.1fs" % float(p.ward) if float(p.get("ward",0))>0 else "HIGHLANDER  /  VANGUARD"
	player_ward.add_theme_color_override("font_color",GOLD if float(p.get("ward",0))>0 else MUTED)
	var next_xp := int(p.get("next_xp",90))
	experience.max_value=maxf(1,float(next_xp))
	experience.value=float(p.get("xp",0)) if next_xp>0 else experience.max_value
	experience_text.text="LEVEL %d    ·    %d / %d XP" % [int(p.get("level",1)),int(p.get("xp",0)),next_xp] if next_xp>0 else "LEVEL %d    ·    MAXIMUM LEVEL" % int(p.get("level",20))
	var position: Vector3=Catalog.vector(p.get("pos",[0,0,28]))
	zone_label.text="THORNWATCH" if position.z>2 and absf(position.x)<35 else ("THE HOLLOW CROWN" if position.z<-54 else "BLACKBRIAR WOOD")
	minimap.update_state(state,local_id,target_id)
	_update_target()
	_refresh_party()
	for id: String in ability_buttons:
		ability_buttons[id].remaining=float(p.get("cooldowns",{}).get(id,0))
	_refresh_cooldowns(0)
	_refresh_tracker(p)
	if bool(p.get("dead",false)):
		if panel_mode!="death":_open_panel("death")
		if is_instance_valid(death_button):
			var recovering := maxf(0.0,2.5-float(p.get("action_time",0)))
			death_button.disabled=recovering>0.0
			death_button.text="Gathering strength… %.1f s" % recovering if recovering>0.0 else "Return to Thornwatch"
	elif panel_mode=="death":close_panels()
	if not panel_mode.is_empty():
		var fingerprint := JSON.stringify([p.get("level",1),p.get("gold",0),p.get("points",0),p.get("attributes",{}),p.get("inventory",[]),p.get("equipment",{}),p.get("quests",{}),p.get("potions",0),p.get("power",0),p.get("armor",0)])
		if fingerprint!=panel_fingerprint:
			panel_fingerprint=fingerprint
			_rebuild_panel()
		if is_instance_valid(profile_health):profile_health.text="%d / %d HEALTH" % [int(p.get("hp",0)),int(p.get("max_hp",0))]

func _update_target() -> void:
	var target: Dictionary=state.get("enemies",{}).get(target_id,{})
	target_frame.visible=not target.is_empty() and not bool(target.get("dead",false))
	if not target_frame.visible:return
	target_name.text=str(target.get("name","Unknown"))
	target_level.text=str(target.get("level",1))
	target_health.max_value=maxf(1,float(target.get("max_hp",100)))
	target_health.value=float(target.get("hp",100))
	target_health_text.text="%d / %d" % [int(target.get("hp",100)),int(target.get("max_hp",100))]
	var action := str(target.get("action","idle"))
	target_cast.text="HEAVY STRIKE  ·  MOVE CLEAR" if action in ["windup","attack","slam"] else "HOSTILE  ·  LEVEL "+str(target.get("level",1))
	target_cast.add_theme_color_override("font_color",Color("ecac70") if action in ["windup","attack","slam"] else Color("bb8f77"))

func _refresh_party() -> void:
	var players: Dictionary=state.get("players",{})
	var ids: Array=[]
	for id: String in players:
		if int(id)!=local_id:ids.append(id)
	ids.sort()
	var existing := party_rows.keys()
	existing.sort()
	if ids!=existing:
		for child: Node in party_box.get_children():
			party_box.remove_child(child)
			child.queue_free()
		party_rows.clear()
		if not ids.is_empty():_label(party_box,"FELLOW TRAVELLERS",10,GOLD)
		for id: String in ids:
			var frame := _frame(party_box,false)
			frame.custom_minimum_size=Vector2(238,45)
			var name_label := _label(frame,"",13,CREAM)
			name_label.position=Vector2(12,5)
			name_label.size=Vector2(212,20)
			name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			var health := _meter(frame,Color("3f6d5f"))
			health.position=Vector2(12,28)
			health.size=Vector2(212,8)
			party_rows[id]={"name":name_label,"health":health}
	party_box.visible=not ids.is_empty()
	for id: String in ids:
		var player: Dictionary=players[id]
		var label: Label=party_rows[id].name
		label.text=str(player.get("name","Traveller"))+"    ·    "+str(player.get("level",1))
		var health: ProgressBar=party_rows[id].health
		health.max_value=maxf(1.0,float(player.get("max_hp",100)))
		health.value=float(player.get("hp",0))

func _refresh_cooldowns(delta: float) -> void:
	var p := _player()
	if p.is_empty():return
	for id: String in ability_buttons:
		var ui: Dictionary=ability_buttons[id]
		var data: Dictionary=Catalog.ABILITIES[id]
		ui.remaining=maxf(0,float(ui.remaining)-delta)
		var remaining := float(ui.remaining)
		var shade: ColorRect=ui.shade
		shade.size=Vector2(60,60*clampf(remaining/float(data.cooldown),0,1))
		shade.position.y=60-shade.size.y
		var label: Label=ui.cooldown
		label.text=str(int(ceil(remaining))) if remaining>=1 else ("%.1f" % remaining if remaining>0.05 else "")
		var disabled := bool(p.get("dead",false)) or float(p.get("energy",0))<float(data.cost) or (id=="potion" and int(p.get("potions",0))<=0)
		var button: Button=ui.button
		button.modulate=Color(0.46,0.48,0.46,1) if disabled else Color.WHITE
		# Keep unavailable buttons clickable so authoritative rejection is explained.
		var count: Label=ui.count
		count.text=str(p.get("potions",0)) if id=="potion" else ""
		var pip: Label=ui.pip
		pip.text=""

func _refresh_tracker(p: Dictionary) -> void:
	var quests: Dictionary=p.get("quests",{})
	var fingerprint := JSON.stringify(quests)
	if fingerprint==tracker_fingerprint:return
	tracker_fingerprint=fingerprint
	for child: Node in tracker.get_children():
		tracker.remove_child(child)
		child.queue_free()
	var title := _label(tracker,"OBJECTIVES",12,GOLD,true)
	title.add_theme_constant_override("outline_size",2)
	title.add_theme_color_override("font_outline_color",Color(0,0,0,0.7))
	var active := 0
	for id: String in Catalog.QUESTS:
		var current: Dictionary=quests.get(id,{})
		if str(current.get("state",""))!="active":continue
		active+=1
		var q: Dictionary=Catalog.QUESTS[id]
		var title_label := _label(tracker,str(q.name),16,Color("e6ca89"),true)
		title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var finished := int(current.get("progress",0))>=int(q.goal)
		var objective := "Return to Captain Elric" if finished else str(q.objective)+"  (%d/%d)" % [int(current.get("progress",0)),int(q.goal)]
		var body := _label(tracker,objective,14,Color("acd2ae") if finished else Color("dadcc9"))
		body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if active==0:
		var complete := quests.size()>=Catalog.QUESTS.size()
		for q: Dictionary in quests.values():
			if str(q.get("state",""))!="complete":complete=false
		var text := "The March remembers.\nExplore, strengthen your gear, or invite a fellow traveller." if complete else "A stranger at the gate\nSpeak with Captain Elric in Thornwatch."
		var label := _label(tracker,text,14,Color("dadcc9"))
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var hint := _label(tracker,"J  ·  QUEST JOURNAL",10,MUTED)
	hint.add_theme_constant_override("margin_top",8)

func activate_ability(id: String) -> void:
	if not Catalog.ABILITIES.has(id):return
	if is_panel_open() or _player().is_empty():return
	command_requested.emit({"type":"ability","id":id,"target":target_id})

func set_target(id: String) -> void:
	target_id=id
	if is_node_ready():_update_target()

func set_connection_status(status: String) -> void:
	if is_instance_valid(connection_label):connection_label.text=status.to_upper()

func set_interaction_hint(text: String) -> void:
	if not is_instance_valid(interaction_frame):return
	interaction_frame.visible=not text.is_empty() and panel_mode.is_empty()
	interaction_label.text="[ F ]  "+text if not text.is_empty() else ""

func show_notice(text: String) -> void:
	if text.is_empty():return
	if not is_node_ready():return
	notice_label.text=text
	notice_time=4.0
	notice_frame.visible=true
	notice_frame.modulate.a=1

func show_event(event: Dictionary) -> void:
	var text := str(event.get("text",""))
	if text.is_empty():return
	var actor := int(event.get("actor",0))
	var type := str(event.get("type",""))
	if actor!=0 and actor!=local_id and type not in ["join","leave","chat"]:return
	_event(text)
	if type in ["level","level_up","quest","quest_complete","reward","loot","death"]:show_notice(text)

func _event(text: String) -> void:
	event_lines.push_back(text)
	while event_lines.size()>4:event_lines.pop_front()
	if is_instance_valid(log_label):log_label.text="\n".join(event_lines)

func show_interaction(id: String, _kind: String="") -> void:
	if id in ["steward","merchant","keeper"]:_open_panel(id)

func toggle_panel(id: String) -> void:
	if _player().is_empty() or bool(_player().get("dead",false)):return
	if panel_mode==id:
		close_panels()
	else:
		_open_panel(id)

func _open_panel(id: String) -> void:
	_end_chat(false)
	panel_mode=id
	panel_fingerprint=""
	cover.visible=true
	interaction_frame.visible=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	_layout()
	_rebuild_panel()
	panel_changed.emit(true)

func close_panels() -> void:
	_end_chat(false)
	if panel_mode=="death" and bool(_player().get("dead",false)):return
	panel_mode=""
	panel_fingerprint=""
	if is_instance_valid(cover):cover.visible=false
	if is_instance_valid(_character_viewport):_character_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	panel_changed.emit(false)

func is_panel_open() -> bool:
	return not panel_mode.is_empty() or chat_open

func open_chat() -> void:
	if _player().is_empty() or not panel_mode.is_empty():return
	chat_open=true
	chat_frame.visible=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	chat_input.grab_focus()
	_layout()
	panel_changed.emit(true)

func _submit_chat(text: String) -> void:
	var message := text.strip_edges()
	if not message.is_empty():command_requested.emit({"type":"chat","text":message})
	chat_input.text=""
	_end_chat(true)

func _chat_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode==KEY_ESCAPE or event.physical_keycode==KEY_ESCAPE):
		_end_chat(true)
		chat_input.accept_event()

func _end_chat(emit_change: bool) -> void:
	if not chat_open:return
	chat_open=false
	chat_frame.visible=false
	chat_input.release_focus()
	_layout()
	if emit_change:panel_changed.emit(not panel_mode.is_empty())

func set_world_preview_factory(factory: Callable) -> void:
	preview_factory=factory

func _outside_panel(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:close_panels()

func _utility_pressed(id: String) -> void:
	if id=="menu":menu_requested.emit()
	else:toggle_panel(id)

func _rebuild_panel() -> void:
	for child: Node in panel_body.get_children():
		panel_body.remove_child(child)
		child.queue_free()
	_character_viewport=null
	profile_health=null
	profile_label=null
	coin_label=null
	death_button=null
	match panel_mode:
		"character","inventory":_character_panel()
		"journal","steward":_quest_panel()
		"merchant":_merchant_panel()
		"keeper":_keeper_panel()
		"death":_death_panel()

func _column(parent: Node, separation: int=10) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",separation)
	parent.add_child(box)
	return box

func _scroll(parent: Node) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	return scroll

func _character_panel() -> void:
	var p := _player()
	panel_title.text=str(p.get("name","Mara Veyne"))
	panel_subtitle.text="Level %d Highlander Vanguard     ·     %d unspent attribute points" % [int(p.get("level",1)),int(p.get("points",0))]
	var split := HBoxContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation",22)
	panel_body.add_child(split)
	var left := _column(split,8)
	left.custom_minimum_size=Vector2(278,0)
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var preview_holder := Control.new()
	var preview_height := clampf(panel_body.size.y-240.0,180.0,275.0)
	preview_holder.custom_minimum_size=Vector2(278,preview_height)
	left.add_child(preview_holder)
	var preview_frame := _frame(preview_holder)
	preview_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_character_viewport=_preview(preview_holder,Vector2(6,6),Vector2(266,preview_height-12.0),false)
	var portrait_title := _label(preview_holder,"WARDEN OF THE MARCH",10,GOLD)
	portrait_title.position=Vector2(20,preview_height-31.0)
	portrait_title.size=Vector2(238,19)
	portrait_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	profile_health=_label(left,"%d / %d HEALTH" % [int(p.get("hp",0)),int(p.get("max_hp",0))],12,MUTED)
	profile_health.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var combat := _label(left,"%d POWER        %d ARMOR" % [int(p.get("power",0)),int(p.get("armor",0))],15,GOLD,true)
	combat.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for id: String in ["might","vitality","spirit"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",7)
		left.add_child(row)
		var label := _label(row,id.capitalize(),14,CREAM)
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var value := _label(row,str(p.get("attributes",{}).get(id,0)),16,GOLD,true)
		value.custom_minimum_size=Vector2(28,0)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		var button := _button(row,"+",_attribute.bind(id),Vector2(28,27))
		button.disabled=int(p.get("points",0))<=0
		button.tooltip_text={"might":"Increase weapon power.","vitality":"Increase maximum health.","spirit":"Increase maximum resolve."}[id]
	var right := _column(split,9)
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_label(right,"EQUIPMENT",13,GOLD,true)
	var equipment: Dictionary=p.get("equipment",{})
	for slot: String in ["weapon","chest","ring"]:
		var item_id := str(equipment.get(slot,""))
		var data: Dictionary=Catalog.ITEMS.get(item_id,{})
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",9)
		right.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size=Vector2(38,38)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not data.is_empty():icon.texture=_icon(int(data.icon))
		row.add_child(icon)
		var labels := _column(row,0)
		labels.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_label(labels,slot.to_upper(),10,MUTED)
		var name_label := _label(labels,str(data.get("name","Empty")),15,Catalog.rarity_color(str(data.get("rarity","Common"))))
		name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		row.tooltip_text=_item_tooltip(item_id)
	var separator := HSeparator.new()
	right.add_child(separator)
	var bag_header := HBoxContainer.new()
	right.add_child(bag_header)
	var bag_name := _label(bag_header,"SATCHEL",13,GOLD,true)
	bag_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	coin_label=_label(bag_header,"%d CROWNS" % int(p.get("gold",0)),12,GOLD)
	var subtitle := _label(right,"Select equipment to wear it. Hover for its properties.",12,MUTED)
	subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var bag_scroll := ScrollContainer.new()
	bag_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	bag_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_child(bag_scroll)
	var bag := GridContainer.new()
	bag.columns=4
	bag.add_theme_constant_override("h_separation",8)
	bag.add_theme_constant_override("v_separation",8)
	bag_scroll.add_child(bag)
	var inventory: Array=p.get("inventory",[])
	for index: int in range(12):
		var item_id := str(inventory[index]) if index<inventory.size() else ""
		var cell := Control.new()
		cell.custom_minimum_size=Vector2(104,88)
		bag.add_child(cell)
		var cell_frame := _frame(cell,false)
		cell_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if item_id.is_empty():
			var empty := _label(cell,"·",24,Color("43514b"))
			empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			continue
		var item: Dictionary=Catalog.ITEMS.get(item_id,{})
		var button := _button(cell,"",_equip.bind(item_id),Vector2.ZERO)
		button.position=Vector2(5,5)
		button.size=Vector2(94,58)
		button.icon=_icon(int(item.get("icon",5)))
		button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",54)
		button.tooltip_text=_item_tooltip(item_id)
		var is_equipped := item_id in equipment.values()
		var slot_label := _label(cell,"EQUIPPED" if is_equipped else str(item.get("slot","item")).to_upper(),10,GOLD if is_equipped else MUTED)
		slot_label.position=Vector2(5,66)
		slot_label.size=Vector2(94,17)
		slot_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cell_frame.edge=Catalog.rarity_color(str(item.get("rarity","Common"))).darkened(0.23)
	var draught := _label(right,"Rowan Draughts: %d / 20    ·    Use [5] in the field" % int(p.get("potions",0)),12,MUTED)
	draught.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func _quest_panel() -> void:
	var is_dialogue := panel_mode=="steward"
	panel_title.text="Captain Elric" if is_dialogue else "The Warden's Journal"
	panel_subtitle.text="Warden of Thornwatch  ·  Keep the road. Keep your word." if is_dialogue else "The Blackbriar March  ·  Your deeds shape the road ahead."
	var scroll := _scroll(panel_body)
	var column := _column(scroll,14)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var intro := _label(column,"“Beyond those gates, the old promises have teeth. Help us keep the lanterns burning.”" if is_dialogue else "Recorded undertakings",16,CREAM,is_dialogue)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var quests: Dictionary=_player().get("quests",{})
	for id: String in Catalog.QUESTS:
		var q: Dictionary=Catalog.QUESTS[id]
		var current: Dictionary=quests.get(id,{})
		var quest_state := str(current.get("state",""))
		var requirement := str(q.get("requires",""))
		var locked := not requirement.is_empty() and str(quests.get(requirement,{}).get("state",""))!="complete"
		var ready := quest_state=="active" and int(current.get("progress",0))>=int(q.goal)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel",_style(Color("121d1d"),Color("4f5948"),15))
		column.add_child(card)
		var body := _column(card,8)
		var heading := _label(body,str(q.name),20,MUTED if locked else GOLD,true)
		heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var description := _label(body,str(q.description),14,MUTED if locked else CREAM)
		description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var status := str(q.objective)
		if quest_state=="active":status+="   %d / %d" % [int(current.get("progress",0)),int(q.goal)]
		if quest_state=="complete":status="COMPLETED  ·  Reward received"
		elif locked:status="Requires: "+str(Catalog.QUESTS[requirement].name)
		elif ready:status="OBJECTIVE COMPLETE  ·  Return to Captain Elric"
		_label(body,status,13,Color("a0c39c") if ready or quest_state=="complete" else MUTED)
		var reward_id := str(q.get("item",""))
		var reward: Dictionary=Catalog.ITEMS.get(reward_id,{})
		var footer := HBoxContainer.new()
		footer.add_theme_constant_override("separation",16)
		body.add_child(footer)
		var rewards := _label(footer,"%d XP  ·  %d crowns\n%s" % [int(q.xp),int(q.gold),str(reward.get("name",""))],12,GOLD)
		rewards.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		rewards.tooltip_text=_item_tooltip(reward_id)
		if is_dialogue and not locked and quest_state!="complete":
			var text := "Claim reward" if ready else ("In progress" if quest_state=="active" else "Accept quest")
			var button := _button(footer,text,_quest.bind(id),Vector2(134,37))
			button.disabled=quest_state=="active" and not ready
		elif not is_dialogue and quest_state.is_empty() and not locked:
			_label(footer,"Speak to Elric",12,MUTED)

func _merchant_panel() -> void:
	panel_title.text="Mira Rowan"
	panel_subtitle.text="Provisioner of Thornwatch  ·  A good journey begins with a full satchel."
	var scroll := _scroll(panel_body)
	var column := _column(scroll,17)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_label(column,"YOUR PURSE    %d CROWNS" % int(_player().get("gold",0)),14,GOLD,true)
	for data: Dictionary in [{"id":"potion","name":"Rowan Draught","icon":4,"price":8,"description":"Restore 65 health. Carried: %d / 20" % int(_player().get("potions",0))},{"id":"watch_coat","name":"Blackbriar Hauberk","icon":6,"price":38,"description":"+7 armor  ·  +3 vitality. A durable field upgrade."}]:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel",_style(Color("15201f"),Color("5c624e"),15))
		column.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",15)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.texture=_icon(int(data.icon))
		icon.custom_minimum_size=Vector2(66,66)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var text := _column(row,6)
		text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_label(text,str(data.name),18,GOLD,true)
		var description := _label(text,str(data.description),13,CREAM)
		description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var owned: bool=str(data.id)=="watch_coat" and "watch_coat" in _player().get("inventory",[])
		var button := _button(row,"Owned" if owned else "Buy · %d" % int(data.price),_buy.bind(str(data.id)),Vector2(100,40))
		button.disabled=owned or int(_player().get("gold",0))<int(data.price) or (str(data.id)=="potion" and int(_player().get("potions",0))>=20)
	var note := _label(column,"Wear purchased equipment from Character [C]. Draughts are ready on your action bar [5].",13,MUTED)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func _keeper_panel() -> void:
	panel_title.text="Yseld"
	panel_subtitle.text="Keeper of the Old Road"
	var column := _column(panel_body,18)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var quote := _label(column,"“The March was not always silent. The iele danced where the emberblooms grow, and the tower bell could call a lost child home.”",22,GOLD,true)
	quote.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var body := _label(column,"“Now a lord without a name wears a hollow crown. His hunger walks on four legs. Elric keeps the gate; I keep the old stories. Perhaps you will give us a new one.”\n\nFollow the road north to the watchtower ruins. Emberblooms grow in the wood to its east.",17,CREAM)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button(column,"I will remember",close_panels,Vector2(190,40))

func _death_panel() -> void:
	panel_title.text="The road is not over"
	panel_subtitle.text="The lanterns of Thornwatch still burn for you."
	var column := _column(panel_body,22)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := _label(column,"Gather your strength and return to the gate. Your learned skills, possessions, and completed deeds remain.",17,CREAM)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	death_button=_button(column,"Return to Thornwatch",_respawn,Vector2(250,43))
	var recovering := maxf(0.0,2.5-float(_player().get("action_time",0)))
	death_button.disabled=recovering>0.0
	death_button.text="Gathering strength… %.1f s" % recovering if recovering>0.0 else "Return to Thornwatch"

func _attribute(id: String) -> void:
	command_requested.emit({"type":"attribute","id":id})

func _equip(id: String) -> void:
	command_requested.emit({"type":"equip","id":id})

func _quest(id: String) -> void:
	command_requested.emit({"type":"quest","id":id})

func _buy(id: String) -> void:
	command_requested.emit({"type":"buy","id":id})

func _respawn() -> void:
	command_requested.emit({"type":"respawn"})

func _load_icons() -> void:
	if ResourceLoader.exists(ICON_PATH):icons=load(ICON_PATH) as Texture2D

func _icon(index: int) -> Texture2D:
	if icons==null:return null
	var atlas := AtlasTexture.new()
	atlas.atlas=icons
	# The approved painting has an intentionally unequal horizontal divider.
	# Select and square-crop the authored cells without editing the source art.
	var bounds: Array[int]=[0,443,887,1330,1774]
	var column := index%4
	var row := int(index/4)
	var left := float(bounds[column])+3.0
	var right := float(bounds[column+1])-3.0
	var top := 3.0 if row==0 else 431.0
	var bottom := 425.0 if row==0 else 884.0
	var extent := minf(right-left,bottom-top)
	atlas.region=Rect2(Vector2((left+right-extent)*0.5,(top+bottom-extent)*0.5),Vector2.ONE*extent)
	return atlas

func _refresh_icons() -> void:
	for id: String in ability_buttons:
		var button: Button=ability_buttons[id].button
		button.icon=_icon(int(Catalog.ABILITIES[id].icon))
		ability_buttons[id].fallback.visible=icons==null

func _ability_tooltip(id: String) -> String:
	var data: Dictionary=Catalog.ABILITIES[id]
	return "%s  [%s]\n%s\n\n%d resolve · %.1f s cooldown" % [str(data.name),str(data.key),str(data.description),int(data.cost),float(data.cooldown)]

func _item_tooltip(id: String) -> String:
	if not Catalog.ITEMS.has(id):return "Empty equipment slot"
	var data: Dictionary=Catalog.ITEMS[id]
	var text := "%s\n%s %s\n" % [str(data.name),str(data.rarity),str(data.slot).capitalize()]
	for stat: String in ["power","armor","vitality"]:
		if int(data.get(stat,0))>0:text+="\n+%d %s" % [int(data[stat]),stat.capitalize()]
	text+="\n\n"+str(data.description)
	var equipped: String=str(_player().get("equipment",{}).get(str(data.slot),""))
	if equipped==id:text+="\n\nCurrently equipped"
	elif not equipped.is_empty() and Catalog.ITEMS.has(equipped):
		text+="\n\nCompared with "+str(Catalog.ITEMS[equipped].name)+":"
		for stat: String in ["power","armor","vitality"]:
			var diff := int(data.get(stat,0))-int(Catalog.ITEMS[equipped].get(stat,0))
			if diff!=0:text+="\n%+d %s" % [diff,stat.capitalize()]
	return text

func _preview(parent: Control, position: Vector2, dimensions: Vector2, portrait: bool) -> SubViewport:
	var container := SubViewportContainer.new()
	container.position=position
	container.size=dimensions
	container.stretch=true
	container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)
	var viewport := SubViewport.new()
	viewport.size=Vector2i(dimensions*1.5)
	viewport.own_world_3d=true
	viewport.transparent_bg=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_2X
	container.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("172221")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("a6c4cb")
	env.ambient_light_energy=0.65
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=env
	stage.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-35,-28,0)
	key.light_color=Color("ffe1b3")
	key.light_energy=1.5
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-20,145,0)
	fill.light_color=Color("94bbcc")
	fill.light_energy=0.9
	stage.add_child(fill)
	var body: Node3D
	if preview_factory.is_valid():body=preview_factory.call() as Node3D
	elif ResourceLoader.exists("res://game/online/avatar.gd"):
		var avatar_script: Script=load("res://game/online/avatar.gd")
		body=avatar_script.new() as Node3D
	else:
		var scene: PackedScene=load(Catalog.HERO_MODEL) as PackedScene
		body=scene.instantiate() as Node3D
	stage.add_child(body)
	body.rotation.y=0.0 if portrait else -0.16
	if not portrait:
		var plinth := MeshInstance3D.new()
		var pedestal := CylinderMesh.new()
		pedestal.top_radius=0.62
		pedestal.bottom_radius=0.67
		pedestal.height=0.055
		pedestal.radial_segments=48
		plinth.mesh=pedestal
		var stone := StandardMaterial3D.new()
		stone.albedo_color=Color("202820")
		stone.roughness=0.84
		plinth.material_override=stone
		plinth.position.y=-0.038
		stage.add_child(plinth)
		var rim := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius=0.605
		ring.outer_radius=0.624
		ring.rings=48
		ring.ring_segments=8
		rim.mesh=ring
		var bronze := StandardMaterial3D.new()
		bronze.albedo_color=Color("76623e")
		bronze.metallic=0.5
		bronze.roughness=0.62
		rim.material_override=bronze
		rim.position.y=-0.005
		stage.add_child(rim)
	var animation: AnimationPlayer=body.find_child("AnimationPlayer",true,false) as AnimationPlayer
	if animation!=null and animation.has_animation("idle"):animation.play("idle")
	var camera := Camera3D.new()
	camera.fov=27.0 if portrait else 34.0
	camera.near=0.05
	camera.position=Vector3(0,1.47,1.1) if portrait else Vector3(0,1.01,3.65)
	stage.add_child(camera)
	camera.look_at(Vector3(0,1.44,0) if portrait else Vector3(0,0.88,0),Vector3.UP)
	camera.current=true
	return viewport
