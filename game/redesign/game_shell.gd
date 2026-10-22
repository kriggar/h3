extends Control
## Native Godot shell. Realm and action models own every mechanical mutation.

const Realm = preload("res://game/redesign/realm_rules.gd")
const Action = preload("res://game/redesign/action_rules.gd")
const Items = preload("res://game/redesign/item_rules.gd")
const TownStage = preload("res://game/redesign/town_stage.gd")
const DungeonStage = preload("res://game/redesign/dungeon_stage.gd")
const ArenaOverlay = preload("res://game/redesign/arena_overlay.gd")
const ExpeditionChart = preload("res://game/redesign/expedition_chart.gd")
const HeroFolio = preload("res://game/redesign/hero_folio.gd")
const Identity = preload("res://game/redesign/hero_identity.gd")
const UI = preload("res://game/redesign/manuscript_theme.gd")
const Art = preload("res://game/redesign/manuscript_art.gd")
const BuildingCardButton = preload("res://game/redesign/building_card_button.gd")
const PaintedButton = preload("res://game/redesign/manuscript_button.gd")
const SAVE_PATH: String = "user://draconia-action-save.json"
const AUTO_PATH: String = "user://draconia-action-autosave.json"
const AUDIO_DRAIN_MIN_MS: int = 100
const AUDIO_DRAIN_LIMIT_MS: int = 250
const QUALITY: Dictionary = {"normal":Color("4c3a27"),"magic":Color("315d83"),"rare":Color("8a651c"),"set":Color("3d663b"),"unique":Color("94512b")}

var realm: Dictionary = {}
var action_state: Dictionary = {}
var current_view: String = "town"
var selected_building: String = "granary"
var selected_skill: String = "cleave"
var stage: Node3D
var arena_overlay: Control
var world_container: SubViewportContainer
var world_viewport: SubViewport
var modal_layer: Control
var modal_content: VBoxContainer
var toast_label: Label
var _world_title: Label
var _world_subtitle: Label
var _title: Label
var _calendar: Label
var _resource_labels: Dictionary = {}
var _right: VBoxContainer
var _right_actions: VBoxContainer
var _sidebar: PanelContainer
var _footer: HBoxContainer
var _footer_buttons: Dictionary = {}
var _skill_buttons: Dictionary = {}
var _health: ProgressBar
var _focus: ProgressBar
var _health_label: Label
var _focus_label: Label
var _objective: Label
var _objective_detail: Label
var _target_readout: Label
var _expedition_chart: Control
var _pause_label: Label
var _loot_box: VBoxContainer
var _status: Label
var _interaction: Dictionary = {}
var _accumulator: float = 0.0
var _hud_clock: float = 0.0
var _autosave_clock: float = 0.0
var _toast_time: float = 0.0
var _last_loot_key: String = ""
var _paused_before_modal: bool = false
var _resolution_pending: bool = false
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var sound_enabled: bool = true
var qa_no_autoload: bool = false
var qa_no_autosave: bool = false
var _hero_inspect_yaw: float = 0.0
var _hero_inspect_zoom: float = 2.35
var _attribute_draft: Dictionary = {}
var _quit_in_progress: bool = false
var _quit_handler_installed: bool = false
var _previous_auto_accept_quit: bool = true
var _quit_audio_drain_timed_out: bool = false
var _quit_epoch: int = 0
var _quit_previous_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT

func _ready() -> void:
	_install_quit_handler()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.make_theme()
	_build_layout()
	_setup_audio()
	if realm.is_empty():
		realm = Realm.create_realm(711)
	if not qa_no_autoload and FileAccess.file_exists(AUTO_PATH):
		if load_game(AUTO_PATH,false):
			return
	_show_town()
	_status.text = "Mara Veyne reaches Dawnreach. A broken bell is sounding beneath the old vault."

func _install_quit_handler() -> void:
	if _quit_handler_installed:
		return
	_previous_auto_accept_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	_quit_handler_installed = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()

func _exit_tree() -> void:
	# This is also safe when a containing scene is disposed without requesting quit.
	# An engine-forced --quit-after can still bypass the live audio-drain interval.
	_release_owned_audio()
	_quit_epoch += 1
	if _quit_in_progress:
		process_mode = _quit_previous_process_mode
	_quit_in_progress = false
	if _quit_handler_installed and get_tree() != null:
		get_tree().auto_accept_quit = _previous_auto_accept_quit
	_quit_handler_installed = false

func _owned_audio_players(node: Node, result: Array[Node]) -> void:
	for child: Node in node.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
			result.append(child)
		_owned_audio_players(child,result)

func _release_owned_audio(dispose_players: bool = false) -> Array[WeakRef]:
	var players: Array[Node] = []
	var playbacks: Array[WeakRef] = []
	_owned_audio_players(self,players)
	for player: Node in players:
		if player.call("has_stream_playback"):
			# The strong temporary belongs only to this synchronous helper. Do not
			# retain it in request_quit's coroutine while waiting for server cleanup.
			var playback: AudioStreamPlayback = player.call("get_stream_playback")
			playbacks.append(weakref(playback))
		player.call("stop")
		player.set("stream",null)
		if dispose_players:
			# A spatial player can still own a pending first-physics playback after
			# stop(). Dispose it while frames are alive, before waiting on weakrefs.
			player.queue_free()
	_music = null
	_ambience = null
	return playbacks

func _audio_playbacks_released(playbacks: Array[WeakRef]) -> bool:
	for reference: WeakRef in playbacks:
		if reference.get_ref() != null:
			return false
	return true

func request_quit() -> void:
	if _quit_in_progress or not is_inside_tree():
		return
	_quit_in_progress = true
	_quit_epoch += 1
	var request_epoch: int = _quit_epoch
	_quit_previous_process_mode = process_mode
	# Freeze the shell and its descendants without adding a pause order or changing
	# the authoritative expedition snapshot. SceneTree frames keep running.
	process_mode = Node.PROCESS_MODE_DISABLED
	var tree: SceneTree = get_tree()
	# Let any already-deferred encounter resolution finish before saving it.
	await tree.process_frame
	if request_epoch != _quit_epoch or not is_inside_tree() or get_tree() != tree:
		return
	if not qa_no_autosave and not save_game(false,AUTO_PATH):
		process_mode = _quit_previous_process_mode
		_quit_in_progress = false
		_show_quit_save_error()
		return
	var playbacks: Array[WeakRef] = _release_owned_audio(true)
	var started: int = Time.get_ticks_msec()
	_quit_audio_drain_timed_out = false
	while true:
		await tree.process_frame
		if request_epoch != _quit_epoch or not is_inside_tree() or get_tree() != tree:
			return
		var elapsed: int = Time.get_ticks_msec()-started
		var released: bool = _audio_playbacks_released(playbacks)
		if elapsed >= AUDIO_DRAIN_MIN_MS and released:
			break
		if elapsed >= AUDIO_DRAIN_LIMIT_MS:
			_quit_audio_drain_timed_out = not released
			if _quit_audio_drain_timed_out:
				push_warning("Audio playback did not release within the bounded shutdown interval.")
			break
	_complete_quit()

func _complete_quit() -> void:
	get_tree().quit()

func _show_quit_save_error() -> void:
	var message: String = "The chronicle could not be saved. Draconia remains open; your previous save is unchanged."
	_notice(message)
	if is_instance_valid(modal_layer) and modal_layer.visible and is_instance_valid(modal_content):
		# Keep the message above the menu shade. Reusing its content avoids any
		# modal open/close path, so a failed quit never injects an action pause.
		var label: Label = modal_content.get_node_or_null("QuitSaveError") as Label
		if label == null:
			label = UI.body(message,18,UI.OXBLOOD)
			label.name = "QuitSaveError"
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			modal_content.add_child(label)
			modal_content.move_child(label,0)
		label.text = message
		var scroll: Node = modal_content.get_parent()
		if scroll is ScrollContainer:
			scroll.ensure_control_visible.call_deferred(label)

func _body(text: String, size_value: int = 17, color: Color = UI.INK) -> Label:
	var label: Label = UI.body(text,size_value-3,color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(text: String, callback: Callable, parent: Node, height: float = 40) -> Button:
	var button: Button = UI.button(text,callback,Vector2(0,height))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	return button

func _small_panel(parent: Node, margins: int = 12) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",UI.parchment(margins))
	parent.add_child(panel)
	return panel

func _art_image(parent: Node, texture: Texture2D, dimensions: Vector2) -> TextureRect:
	var picture: TextureRect = TextureRect.new()
	picture.texture=texture
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size=dimensions
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _painted(text: String, texture: Texture2D, callback: Callable, parent: Node, dimensions: Vector2, mode: String = "tile") -> Button:
	var button: Button = PaintedButton.new()
	button.text=text
	button.artwork=texture
	button.paint_layout=mode
	button.custom_minimum_size=dimensions
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.focus_mode=Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _building_card(id: String, text_value: String, callback: Callable, parent: Node, dimensions: Vector2) -> Button:
	var button: Button=BuildingCardButton.new()
	button.building_id=id
	button.text=text_value
	button.artwork=Art.building(id)
	button.custom_minimum_size=dimensions
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.focus_mode=Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _section(parent: Node, text: String, size_value: int = 16) -> void:
	var row: HBoxContainer=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	parent.add_child(row)
	for index: int in range(3):
		if index==1:
			var label: Label=UI.heading(text,size_value,UI.OXBLOOD)
			label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(label)
		else:
			var rule: HSeparator=HSeparator.new()
			rule.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			row.add_child(rule)

func _build_layout() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("211d18")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,8)
	add_child(margin)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation",5)
	margin.add_child(layout)
	var top_frame: PanelContainer=PanelContainer.new()
	top_frame.add_theme_stylebox_override("panel",UI.chrome(10))
	layout.add_child(top_frame)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation",16)
	top_frame.add_child(top)
	_art_image(top,Art.crest(),Vector2(58,58))
	var title_column: VBoxContainer = VBoxContainer.new()
	title_column.custom_minimum_size.x = 202
	title_column.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	title_column.add_theme_constant_override("separation",0)
	top.add_child(title_column)
	_title = UI.heading("DRACONIA",27,UI.IVORY)
	title_column.add_child(_title)
	_calendar = _body("Day 1 · Dawn",16,Color("cdb78b"))
	title_column.add_child(_calendar)
	var resources: HBoxContainer = HBoxContainer.new()
	resources.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources.alignment = BoxContainer.ALIGNMENT_CENTER
	resources.add_theme_constant_override("separation",8)
	top.add_child(resources)
	for resource: String in Realm.RESOURCES:
		var chip: PanelContainer=PanelContainer.new()
		chip.add_theme_stylebox_override("panel",UI.paper(5))
		chip.custom_minimum_size=Vector2(116,56)
		resources.add_child(chip)
		var cell: HBoxContainer=HBoxContainer.new()
		cell.add_theme_constant_override("separation",5)
		chip.add_child(cell)
		_art_image(cell,Art.symbol(resource),Vector2(46,46))
		var numbers: VBoxContainer=VBoxContainer.new()
		numbers.add_theme_constant_override("separation",-3)
		numbers.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		cell.add_child(numbers)
		var caption: Label=UI.heading("TIMBER" if resource=="wood" else resource.to_upper(),11,UI.MUTED)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		numbers.add_child(caption)
		var value: Label=UI.heading("0",23)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		numbers.add_child(value)
		_resource_labels[resource]=value
	var menu: Button = _button("MENU",_open_menu,top,43)
	menu.custom_minimum_size.x = 84
	menu.size_flags_horizontal = Control.SIZE_SHRINK_END
	menu.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var center: HBoxContainer = HBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation",5)
	layout.add_child(center)
	var world_frame: PanelContainer=PanelContainer.new()
	world_frame.add_theme_stylebox_override("panel",UI.chrome(7))
	center.add_child(world_frame)
	world_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var world_stack: Control = Control.new()
	world_frame.add_child(world_stack)
	world_container = SubViewportContainer.new()
	world_container.name = "NativeWorld"
	world_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_container.stretch = true
	world_container.mouse_filter = Control.MOUSE_FILTER_STOP
	world_stack.add_child(world_container)
	world_container.gui_input.connect(_on_world_input)
	world_container.mouse_exited.connect(func()->void:
		if current_view=="town" and is_instance_valid(stage):stage.set_hovered(""))
	world_viewport = SubViewport.new()
	world_viewport.name = "WorldViewport"
	world_viewport.size = Vector2i(960,640)
	world_viewport.own_world_3d = true
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.msaa_3d = Viewport.MSAA_2X
	world_container.add_child(world_viewport)
	arena_overlay = ArenaOverlay.new()
	arena_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_overlay.clip_contents=true
	arena_overlay.visible = false
	world_stack.add_child(arena_overlay)
	var banner: PanelContainer=PanelContainer.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	banner.position=Vector2(16,14)
	banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override("panel",UI.chrome(11))
	world_stack.add_child(banner)
	var banner_column: VBoxContainer=VBoxContainer.new()
	banner_column.add_theme_constant_override("separation",0)
	banner_column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_column)
	_world_title=UI.heading("DAWNREACH",23,UI.IVORY)
	_world_title.mouse_filter=Control.MOUSE_FILTER_IGNORE
	banner_column.add_child(_world_title)
	_world_subtitle=_body("Hold of the Ashen Crown",14,Color("cbb58d"))
	_world_subtitle.mouse_filter=Control.MOUSE_FILTER_IGNORE
	banner_column.add_child(_world_subtitle)
	_pause_label = UI.heading("TACTICAL PAUSE",23,Color("ead8aa"))
	_pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_pause_label.position.y = 105
	_pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_label.add_theme_color_override("font_shadow_color",Color("1b1814"))
	_pause_label.add_theme_constant_override("shadow_offset_y",2)
	_pause_label.visible = false
	world_stack.add_child(_pause_label)
	toast_label = _body("",18,UI.IVORY)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast_label.offset_left = 18
	toast_label.offset_right = -18
	toast_label.offset_top = -66
	toast_label.offset_bottom = -12
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color",Color("121710"))
	toast_label.add_theme_constant_override("shadow_offset_x",2)
	toast_label.add_theme_constant_override("shadow_offset_y",2)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.visible = false
	world_stack.add_child(toast_label)
	_sidebar = _small_panel(center,18)
	_sidebar.custom_minimum_size.x = 352
	var sidebar_column: VBoxContainer = VBoxContainer.new()
	sidebar_column.add_theme_constant_override("separation",5)
	_sidebar.add_child(sidebar_column)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_column.add_child(scroll)
	_right = VBoxContainer.new()
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right.add_theme_constant_override("separation",7)
	scroll.add_child(_right)
	_right_actions=VBoxContainer.new()
	_right_actions.add_theme_constant_override("separation",3)
	sidebar_column.add_child(_right_actions)
	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation",7)
	var footer_frame: PanelContainer=PanelContainer.new()
	footer_frame.add_theme_stylebox_override("panel",UI.chrome(9))
	layout.add_child(footer_frame)
	footer_frame.add_child(_footer)
	_status = _body("",14,Color("c8b18b"))
	_status.custom_minimum_size.y = 18
	_status.max_lines_visible = 1
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(_status)
	modal_layer = Control.new()
	modal_layer.name = "ModalLayer"
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.visible = false
	add_child(modal_layer)
	resized.connect(_responsive)
	_responsive()

func _responsive() -> void:
	if _sidebar != null:
		_sidebar.custom_minimum_size.x = 304 if size.x < 1100 else 352
	if is_instance_valid(_expedition_chart):
		_expedition_chart.custom_minimum_size.y = 120 if size.y < 740 else 146

func _clear(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _replace_stage(new_stage: Node3D) -> void:
	if is_instance_valid(stage):
		world_viewport.remove_child(stage)
		stage.queue_free()
	stage = new_stage
	world_viewport.add_child(stage)

func _show_town() -> void:
	current_view = "town"
	action_state = {}
	_interaction.clear()
	_resolution_pending = false
	_accumulator = 0.0
	_pause_label.visible = false
	arena_overlay.visible = false
	arena_overlay.stage = null
	var town: Node3D = TownStage.new()
	town.town_data = realm.settlements.dawnwatch
	_replace_stage(town)
	_refresh_header()
	_town_sidebar()
	_town_footer()
	_status.text = "Dawnreach · Choose a town work, prepare your hero, or browse the next expedition."

func _refresh_header() -> void:
	_calendar.text = str(Realm.calendar(realm).label)
	for key: String in _resource_labels:
		_resource_labels[key].text = str(int(realm.resources[key]))

func _portrait(parent: Node, width: float = 268, height: float = 126) -> void:
	var frame: PanelContainer=PanelContainer.new()
	frame.add_theme_stylebox_override("panel",UI.tile())
	parent.add_child(frame)
	_art_image(frame,Art.portrait(),Vector2(width,height))

func _town_sidebar() -> void:
	_clear(_right)
	_clear(_right_actions)
	_world_title.text="DAWNREACH"
	_world_subtitle.text="Hold of the Ashen Crown"
	_section(_right,"THE ASHEN CROWN",15)
	var hero_row: HBoxContainer = HBoxContainer.new()
	hero_row.add_theme_constant_override("separation",10)
	_right.add_child(hero_row)
	_portrait(hero_row,94,68)
	var hero_text: VBoxContainer = VBoxContainer.new()
	hero_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	hero_text.add_theme_constant_override("separation",0)
	hero_row.add_child(hero_text)
	hero_text.add_child(UI.heading("Mara Veyne",19))
	hero_text.add_child(_body("Level %d · %s" % [realm.hero.level,Identity.class_name_for(realm.hero)],14,UI.MUTED))
	hero_text.add_child(_body("Health %d / %d   ·   Focus %d" % [realm.hero.hp,realm.hero.maxHp,realm.hero.mana],14,UI.OXBLOOD))
	var progression: Dictionary=Realm.progression_view(realm)
	if int(progression.unspent)>0:
		_button("%d ATTRIBUTE POINTS · C" % int(progression.unspent),func()->void:_open_inventory("","character"),_right,28)
	_section(_right,"TOWN WORKS")
	var definition: Dictionary = {}
	for candidate: Dictionary in Realm.building_catalog():
		if str(candidate.id)==selected_building:
			definition = candidate
	if definition.is_empty():return
	var illustration: Button=_building_card(selected_building,str(definition.name),_open_townworks,_right,Vector2(0,218))
	illustration.add_theme_font_size_override("font_size",22)
	illustration.badge="✓" if realm.settlements.dawnwatch.buildings.has(selected_building) else ""
	illustration.tooltip_text="Open the construction folio"
	_right.add_child(_body(str(definition.description),18))
	var costs: Array[String]=[]
	for key: String in definition.cost:
		if int(definition.cost[key])>0:costs.append("%d %s" % [definition.cost[key],"timber" if key=="wood" else key])
	_right.add_child(_body("  ·  ".join(costs),17,UI.GOLD))
	_button("BROWSE TOWN WORKS",_open_townworks,_right,38)
	var held: int=realm.settlements.dawnwatch.buildings.size()
	var caption: Label=_body("%d town work%s completed" % [held,"" if held==1 else "s"],14,UI.MUTED)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_right.add_child(caption)
	var preview: Dictionary = Realm.preview_construction(realm,"dawnwatch",selected_building)
	var built: bool = realm.settlements.dawnwatch.buildings.has(selected_building)
	var action_row: HBoxContainer=HBoxContainer.new()
	_right_actions.add_child(action_row)
	var rotate_left: Button = _button("‹",func() -> void: stage.rotate_view(-0.12),action_row,40)
	rotate_left.custom_minimum_size.x=30
	rotate_left.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	rotate_left.tooltip_text="Rotate town view left"
	var build: Button = _button("COMPLETED" if built else "CONSTRUCT",_construct_selected,action_row,40)
	build.name = "ConstructButton"
	build.disabled = not bool(preview.ok)
	var rotate_right: Button = _button("›",func() -> void: stage.rotate_view(0.12),action_row,40)
	rotate_right.custom_minimum_size.x=30
	rotate_right.size_flags_horizontal=Control.SIZE_SHRINK_END
	rotate_right.tooltip_text="Rotate town view right"
	var note: Label=_body("One town work each day · No watches pass" if bool(preview.ok) else str(preview.message),13,UI.MUTED)
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_right_actions.add_child(note)
	stage.set_selection(selected_building,false)

func _open_townworks() -> void:
	var box: VBoxContainer=_open_modal("DAWNREACH · TOWN WORKS",1120)
	var note: Label=_body("Raise your town, one lasting choice at a time.",20,UI.MUTED)
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)
	var grid: GridContainer=GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	box.add_child(grid)
	var selected: Dictionary={}
	for data: Dictionary in Realm.building_catalog():
		var id: String=str(data.id)
		var built: bool=realm.settlements.dawnwatch.buildings.has(id)
		var preview: Dictionary=Realm.preview_construction(realm,"dawnwatch",id)
		var state_text: String="Completed" if built else ("Ready to build" if bool(preview.ok) else "Not available")
		var card: Button=_building_card(id,str(data.name)+"\n"+state_text,func() -> void:
			_select_building(id)
			_open_townworks(),grid,Vector2(0,190 if size.y>=800 else 148))
		card.name="TownWork_"+id
		card.selected=id==selected_building
		card.badge="✓" if built else ""
		card.add_theme_font_size_override("font_size",18)
		card.tooltip_text=str(data.description)+"\n"+str(preview.message)
		if id==selected_building:selected=data
	if selected.is_empty():return
	var selected_panel: PanelContainer=PanelContainer.new()
	selected_panel.add_theme_stylebox_override("panel",UI.paper(11))
	box.add_child(selected_panel)
	var row: HBoxContainer=HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	selected_panel.add_child(row)
	var info: VBoxContainer=VBoxContainer.new()
	info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation",4)
	row.add_child(info)
	info.add_child(UI.heading(str(selected.name),21,UI.OXBLOOD))
	info.add_child(_body(str(selected.description),18))
	var costs: Array[String]=[]
	for key: String in selected.cost:
		if int(selected.cost[key])>0:costs.append("%d %s" % [selected.cost[key],"timber" if key=="wood" else key])
	info.add_child(_body("  ·  ".join(costs),16,UI.GOLD))
	var actions: VBoxContainer=VBoxContainer.new()
	actions.custom_minimum_size.x=204
	row.add_child(actions)
	var report: Dictionary=Realm.preview_construction(realm,"dawnwatch",selected_building)
	var built: bool=realm.settlements.dawnwatch.buildings.has(selected_building)
	var build: Button=_button("COMPLETED" if built else "CONSTRUCT",func() -> void:
		_close_modal()
		_construct_selected(),actions,43)
	build.disabled=not bool(report.ok)
	actions.add_child(_body("One construction each day. No watches pass." if bool(report.ok) else str(report.message),14,UI.MUTED))

func _select_building(id: String) -> void:
	selected_building = id
	_town_sidebar()
	stage.set_selection(id,true)

func _construct_selected() -> void:
	var report: Dictionary = Realm.construct_building(realm,"dawnwatch",selected_building)
	_notice(str(report.message))
	if bool(report.ok):
		stage.reconcile(realm.settlements.dawnwatch,selected_building)
		_refresh_header()
		_town_sidebar()
		_autosave()

func _town_footer() -> void:
	_clear(_footer)
	_footer_buttons.clear()
	for entry: Array in [["hero","HERO · I",_open_inventory],["oaths","OATHS · J",_open_oaths],["realm","REALM",_open_realm],["expedition","EXPEDITION",_open_expedition],["rest","REST · R",_rest],["watch","NEXT DAWN",_advance_dawn]]:
		var texture: Texture2D=Art.portrait() if str(entry[0])=="hero" else Art.symbol(str(entry[0]))
		var button: Button = _painted(str(entry[1]),texture,entry[2],_footer,Vector2(0,78),"wide")
		button.add_theme_font_size_override("font_size",15)
		_footer_buttons[str(entry[0])] = button
	if str(realm.status)=="recovering":_footer_buttons.rest.text = "RECOVER"

func _rest() -> void:
	var report: Dictionary = Realm.recover(realm) if str(realm.status)=="recovering" else Realm.rest(realm)
	_notice(str(report.message))
	if bool(report.ok):
		_refresh_header()
		_town_sidebar()
		_town_footer()
		_autosave()

func _advance_dawn() -> void:
	var report: Dictionary = Realm.advance_to_event(realm,4)
	_notice(str(report.message))
	if bool(report.ok):
		_refresh_header()
		_town_sidebar()
		_autosave()

func _open_modal(title: String, width: float = 780, height: float = 700) -> VBoxContainer:
	if not modal_layer.visible and not action_state.is_empty():
		_paused_before_modal = bool(action_state.paused)
		Action.submit(action_state,{"kind":"pause","paused":true})
	_clear(modal_layer)
	modal_layer.visible = true
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.025,0.025,0.02,0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(shade)
	var centered: CenterContainer = CenterContainer.new()
	centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(centered)
	var panel: PanelContainer = _small_panel(centered,28)
	panel.custom_minimum_size = Vector2(minf(width,size.x-48),minf(height,size.y-64))
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation",9)
	panel.add_child(column)
	var title_row: HBoxContainer = HBoxContainer.new()
	column.add_child(title_row)
	_art_image(title_row,Art.crest(),Vector2(42,44))
	var heading: Label = UI.heading(title,25,UI.OXBLOOD)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	title_row.add_child(heading)
	var close: Button = _button("×",_close_modal,title_row,34)
	close.tooltip_text="Close · Esc"
	close.custom_minimum_size.x=38
	close.size_flags_horizontal=Control.SIZE_SHRINK_END
	close.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	column.add_child(HSeparator.new())
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = minf(height-142,size.y-210)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	modal_content = VBoxContainer.new()
	modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_content.add_theme_constant_override("separation",10)
	scroll.add_child(modal_content)
	return modal_content

func _close_modal() -> void:
	if not modal_layer.visible:
		return
	modal_layer.visible = false
	_clear(modal_layer)
	if not action_state.is_empty() and str(action_state.phase) not in ["finished","invalid"]:
		Action.submit(action_state,{"kind":"pause","paused":_paused_before_modal})
	_update_action_hud()

func _open_expedition() -> void:
	var board: Dictionary=Realm.hunt_board(realm)
	var box: VBoxContainer=_open_modal("THE EXPEDITION LEDGER",1120,760)
	var story: PanelContainer=PanelContainer.new()
	story.add_theme_stylebox_override("panel",UI.paper(12))
	box.add_child(story)
	var row: HBoxContainer=HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	story.add_child(row)
	_art_image(row,Art.symbol("expedition"),Vector2(96,96))
	var text_column: VBoxContainer=VBoxContainer.new()
	text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	text_column.add_child(UI.heading("The Bellworn Vault",23,UI.OXBLOOD))
	text_column.add_child(_body("The original chronicle. Its guardians and treasures persist between visits.",18))
	text_column.add_child(_body("CLEARED" if bool(realm.locations.bell_crypt.cleared) else "STORY EXPEDITION · TWO WATCHES",15,UI.MUTED))
	var story_button: Button=_button("READ THE CHRONICLE",_open_story_expedition,row,42)
	story_button.custom_minimum_size.x=220
	story_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	story_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_section(box,"LOCAL HUNTS · CHOOSE YOUR NEXT REWARD",17)
	box.add_child(_body("Choose one contract. Return with its spoils to earn experience and reveal the next offers.",18,UI.MUTED))
	var offers: HBoxContainer=HBoxContainer.new()
	offers.add_theme_constant_override("separation",12)
	box.add_child(offers)
	for offer: Dictionary in board.offers:
		var contract_id: String=str(offer.id)
		var panel: PanelContainer=PanelContainer.new()
		panel.add_theme_stylebox_override("panel",UI.paper(12))
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		offers.add_child(panel)
		var content: VBoxContainer=VBoxContainer.new()
		content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation",8)
		panel.add_child(content)
		var title: Label=UI.heading(str(offer.name),20,UI.OXBLOOD)
		title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		title.custom_minimum_size.y=48
		content.add_child(title)
		content.add_child(_body("TIER %d · %d FOES · %d WATCHES" % [int(offer.tier),int(offer.remainingEnemies),int(offer.quotedWatches)],14,UI.MUTED))
		var briefing: String=str(offer.get("tacticalBrief",""))
		var description: Label=_body(str(offer.description) if briefing.is_empty() else briefing,17)
		description.custom_minimum_size.y=70
		description.tooltip_text=str(offer.description)
		content.add_child(description)
		content.add_child(HSeparator.new())
		content.add_child(_body("%d experience on completion" % int(offer.effectiveXpReward),17,UI.OXBLOOD))
		for reward: Dictionary in offer.rewardPreview:
			var reward_row: HBoxContainer=HBoxContainer.new()
			reward_row.add_theme_constant_override("separation",8)
			content.add_child(reward_row)
			var icon: Texture2D=Art.symbol("gold") if str(reward.kind)=="gold" else Art.item(Items.make_instance(str(reward.itemId),"board_preview",int(reward.rollSeed)))
			_art_image(reward_row,icon,Vector2(38,38))
			reward_row.add_child(_body(str(reward.name),16,QUALITY.get(str(reward.get("quality","normal")),UI.GOLD)))
		var spacer: Control=Control.new()
		spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
		content.add_child(spacer)
		var label: String="RESUME HUNT" if str(offer.status)=="active" else "TAKE THIS HUNT"
		var depart: Button=_button(label,func()->void:_begin_hunt(contract_id),content,42)
		depart.name="Hunt_"+str(offer.id).replace(":","_")
		depart.disabled=not bool(offer.canEnter)
		depart.tooltip_text=str(offer.completionNotice) if bool(offer.canEnter) else str(offer.lockReason)
		if not bool(offer.canEnter):content.add_child(_body(str(offer.lockReason),14,UI.MUTED))
	box.add_child(_body("Collect your rewards before completing extraction. Uncollected spoils are left behind. Retreat preserves this contract; returning costs two more watches.",16,UI.MUTED))
	if board.offers.is_empty():box.add_child(_body(str(board.lockReason),18,UI.OXBLOOD))

func _begin_hunt(contract_id: String) -> void:
	var report: Dictionary=Realm.begin_hunt(realm,contract_id)
	if not bool(report.ok):
		_notice(str(report.message))
		return
	_close_modal()
	action_state=Action.create(realm.pendingEncounter)
	_show_dungeon()
	_autosave()

func _expedition_name() -> String:
	return str(realm.pendingEncounter.get("locationName","The Bellworn Vault")) if realm.pendingEncounter is Dictionary else "The Bellworn Vault"

func _open_story_expedition() -> void:
	var box: VBoxContainer = _open_modal("THE BELLWORN VAULT",940)
	var row: HBoxContainer=HBoxContainer.new()
	row.add_theme_constant_override("separation",24)
	box.add_child(row)
	var plate: PanelContainer=PanelContainer.new()
	plate.add_theme_stylebox_override("panel",UI.tile())
	row.add_child(plate)
	_art_image(plate,Art.symbol("expedition"),Vector2(240,250))
	var text_column: VBoxContainer=VBoxContainer.new()
	text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation",13)
	row.add_child(text_column)
	text_column.add_child(UI.heading("The bell has no tongue.",23,UI.OXBLOOD))
	text_column.add_child(_body("Still, it rings.",23,UI.OXBLOOD))
	text_column.add_child(_body("Grain wagons lie abandoned on the old road. The tracks lead beneath the ruined watchtower, where something has nested among the buried wardens. The villagers will pay to hear the last of that bell.",20))
	_section(box,"SOLO EXPEDITION · TWO WATCHES",17)
	box.add_child(_body("Enter as Mara alone. Your two companies remain in Dawnreach. Health and Focus carry back with you. Defeat the pack, inspect the spoils, then return to the entrance to leave.",19))
	box.add_child(_body("Click to move or attack · 1–2 class skills · G guard · Shift dodge · Space pause",16,UI.MUTED))
	if bool(realm.locations.bell_crypt.cleared):
		box.add_child(_body("The vault is cleared. Only unclaimed rewards remain.",19,Color("426a3d")))
	var button: Button = _button("ENTER THE VAULT",_begin_expedition,box,48)
	button.disabled = str(realm.status)!="active" or (bool(realm.locations.bell_crypt.cleared) and realm.locations.bell_crypt.claimedRewardIds.size()==4)

func _begin_expedition() -> void:
	var report: Dictionary = Realm.begin_encounter(realm,{"kind":"dungeon","locationId":"bell_crypt"})
	if not bool(report.ok):
		_notice(str(report.message))
		return
	_close_modal()
	action_state = Action.create(realm.pendingEncounter)
	_show_dungeon()
	_autosave()

func _show_dungeon() -> void:
	current_view = "dungeon"
	_interaction.clear()
	_accumulator = 0.0
	_resolution_pending = false
	_last_loot_key = ""
	var dungeon: Node3D = DungeonStage.new()
	dungeon.action_state = action_state
	_replace_stage(dungeon)
	stage.set_sound_enabled(sound_enabled)
	arena_overlay.stage = stage
	arena_overlay.visible = true
	_refresh_header()
	_dungeon_sidebar()
	_dungeon_footer()
	_status.text = _expedition_name()+" · Click to move or attack · Right-click uses your selected skill"
	_update_action_hud()

func _bar(parent: Node, color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 11
	bar.add_theme_stylebox_override("fill",UI.flat(color,color,0))
	parent.add_child(bar)
	return bar

func _dungeon_sidebar() -> void:
	_clear(_right)
	_clear(_right_actions)
	_world_title.text=_expedition_name().to_upper()
	_world_subtitle.text="Solo expedition · The Ashen March"
	var hero_row: HBoxContainer=HBoxContainer.new()
	hero_row.add_theme_constant_override("separation",10)
	_right.add_child(hero_row)
	_portrait(hero_row,72,64)
	var hero_details: VBoxContainer=VBoxContainer.new()
	hero_details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	hero_details.add_theme_constant_override("separation",1)
	hero_row.add_child(hero_details)
	hero_details.add_child(UI.heading("MARA VEYNE",17))
	hero_details.add_child(_body("Level %d · %s" % [realm.hero.level,Identity.class_name_for(realm.hero)],14,UI.MUTED))
	_health_label = _body("Health",17,UI.OXBLOOD)
	_right.add_child(_health_label)
	_health = _bar(_right,Color("8f3f32"))
	_focus_label = _body("Focus",17,UI.SLATE)
	_right.add_child(_focus_label)
	_focus = _bar(_right,Color("477b85"))
	_section(_right,"YOUR OBJECTIVE",15)
	_objective = _body("",19,UI.OXBLOOD)
	_objective.name="ExpeditionObjective"
	_right.add_child(_objective)
	_objective_detail = _body("",15,UI.MUTED)
	_objective_detail.name="ExpeditionObjectiveDetail"
	_right.add_child(_objective_detail)
	_section(_right,"FIELD CHART",14)
	var chart_frame: PanelContainer=PanelContainer.new()
	chart_frame.add_theme_stylebox_override("panel",UI.paper(5))
	_right.add_child(chart_frame)
	_expedition_chart=ExpeditionChart.new()
	_expedition_chart.name="ExpeditionFieldChart"
	_expedition_chart.custom_minimum_size=Vector2(0,120 if size.y<740 else 146)
	_expedition_chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	chart_frame.add_child(_expedition_chart)
	_target_readout=_body("",15,UI.MUTED)
	_target_readout.name="ExpeditionTarget"
	_target_readout.custom_minimum_size.y=38
	_right.add_child(_target_readout)
	_loot_box = VBoxContainer.new()
	_loot_box.name="ExpeditionSpoils"
	_loot_box.add_theme_constant_override("separation",4)
	_right.add_child(_loot_box)
	var return_button: Button=_button("RETURN TO ENTRANCE",_request_exit,_right_actions,40)
	return_button.name="ExpeditionReturn"
	_button("PAUSE · SPACE",_toggle_pause,_right_actions,36)

func _dungeon_footer() -> void:
	_clear(_footer)
	_skill_buttons.clear()
	var index: int = 0
	var allowed: Array=_allowed_skills()
	if not allowed.has(selected_skill):selected_skill=str(allowed[0]) if not allowed.is_empty() else ""
	for id: String in allowed:
		index += 1
		var data: Dictionary = Action.ABILITIES[id]
		var texture: Texture2D=Art.ability(id)
		var button: Button = _painted("%s
%d Focus" % [data.name,data.cost],texture,func() -> void: _select_skill(id),_footer,Vector2(0,78),"wide")
		button.key_hint=str(index)
		button.tooltip_text = "Select for right-click. Press %d to cast immediately toward the cursor." % index
		button.add_theme_font_size_override("font_size",16)
		_skill_buttons[id] = button
	var guard: Button=_painted("GUARD",Art.equipment("main_hand"),_guard,_footer,Vector2(0,78),"wide")
	guard.key_hint="G"
	var dodge: Button=_painted("DODGE",Art.equipment("feet"),_dodge,_footer,Vector2(0,78),"wide")
	dodge.key_hint="⇧"

func _allowed_skills() -> Array:
	var hero: Dictionary=realm.hero if action_state.is_empty() else Action.get_actor(action_state,str(action_state.heroId))
	var definition: Dictionary=Identity.hero_definition(hero)
	var result: Array=[]
	for id: String in Identity.class_skills(str(definition.get("classId",""))):
		if Identity.is_skill_allowed(hero,id):result.append(id)
	return result

func _cast_hotkey(index: int) -> void:
	var allowed: Array=_allowed_skills()
	if index>=0 and index<allowed.size():_cast(str(allowed[index]))

func _select_skill(id: String) -> void:
	if not _allowed_skills().has(id):return
	selected_skill = id
	if id=="ward":
		_cast(id)
	_update_action_hud()

func _mouse_ground() -> Array:
	if not is_instance_valid(stage):
		return [0,0]
	var position: Vector2 = world_container.get_local_mouse_position()
	var point: Variant = stage.ground_point(position)
	if point == null:
		return Action.get_actor(action_state,str(action_state.heroId)).pos if not action_state.is_empty() else [0,0]
	return [point.x,point.z]

func _cast(id: String) -> void:
	if action_state.is_empty():
		return
	_interaction.clear()
	var point: Array = _mouse_ground()
	if id in ["ward","cleave"]:
		var hero: Dictionary = Action.get_actor(action_state,str(action_state.heroId))
		var origin: Vector2 = Vector2(float(hero.pos[0]),float(hero.pos[1]))
		var direction: Vector2 = (Vector2(float(point[0]),float(point[1]))-origin).normalized()
		point = [origin.x+direction.x*2.1,origin.y+direction.y*2.1]
	selected_skill = id
	_send_action({"kind":"cast","ability":id,"pos":point})

func _guard() -> void:
	if action_state.is_empty():
		return
	_interaction.clear()
	var hero: Dictionary = Action.get_actor(action_state,str(action_state.heroId))
	_send_action({"kind":"guard","pos":_mouse_ground(),"guarding":not bool(hero.guarding)})

func _dodge() -> void:
	if action_state.is_empty():
		return
	_interaction.clear()
	_send_action({"kind":"dodge","pos":_mouse_ground()})

func _send_action(command: Dictionary, quiet: bool = false) -> Dictionary:
	var report: Dictionary = Action.submit(action_state,command)
	if not bool(report.ok) and not quiet:
		_notice(str(report.reason))
	elif bool(report.get("queued",false)) and not quiet:
		_notice("Order prepared. Press Space to resume.")
	_update_action_hud()
	return report

func _toggle_pause() -> void:
	if action_state.is_empty():
		return
	_send_action({"kind":"pause","paused":not bool(action_state.paused)})

func _on_world_input(event: InputEvent) -> void:
	if current_view=="town" and not modal_layer.visible and event is InputEventMouseMotion:
		stage.set_hovered(stage.pick_building(event.position))
		return
	if modal_layer.visible or not event is InputEventMouseButton or not event.pressed:
		return
	if current_view=="town":
		if event.button_index==MOUSE_BUTTON_LEFT:
			var id: String = stage.pick_building(event.position)
			if not id.is_empty():
				_select_building(id)
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			stage.rotate_view(-0.06 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 0.06)
		return
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		stage.zoom(-1.0 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0)
		return
	if event.button_index==MOUSE_BUTTON_RIGHT:
		_cast(selected_skill)
		return
	if event.button_index!=MOUSE_BUTTON_LEFT:
		return
	var target: Dictionary = stage.pick(event.position)
	if target.is_empty():
		return
	_interaction.clear()
	match str(target.kind):
		"enemy": _send_action({"kind":"attack","targetId":target.targetId})
		"ground": _send_action({"kind":"move","pos":target.pos})
		"exit": _request_exit()
		"loot": _inspect_loot(str(target.targetId))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode==KEY_ESCAPE:
		if modal_layer.visible:
			_close_modal()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()
		return
	if event.ctrl_pressed and event.keycode==KEY_S:
		save_game()
		get_viewport().set_input_as_handled()
		return
	if modal_layer.visible:
		return
	if event.keycode in [KEY_I,KEY_C]:
		_open_inventory("","character" if event.keycode==KEY_C else "equipment")
		get_viewport().set_input_as_handled()
		return
	if current_view=="town":
		match event.keycode:
			KEY_J: _open_oaths()
			KEY_R: _rest()
	else:
		match event.keycode:
			KEY_1: _cast_hotkey(0)
			KEY_2: _cast_hotkey(1)
			KEY_3: _cast_hotkey(2)
			KEY_4: _cast_hotkey(3)
			KEY_SPACE: _toggle_pause()
			KEY_G: _guard()
			KEY_SHIFT: _dodge()

func _update_action_hud() -> void:
	if action_state.is_empty() or current_view!="dungeon" or not is_instance_valid(_health):
		return
	var hero: Dictionary = Action.get_actor(action_state,str(action_state.heroId))
	_health.max_value = float(hero.maxHp)
	_health.value = float(hero.hp)
	_health_label.text = "Health  %d / %d" % [hero.hp,hero.maxHp]
	_focus.max_value = maxf(1,float(hero.maxMana))
	_focus.value = float(hero.mana)
	_focus_label.text = "Focus  %d / %d" % [hero.mana,hero.maxMana]
	var is_hunt: bool=realm.pendingEncounter is Dictionary and realm.pendingEncounter.has("contractId")
	var guidance: Dictionary=ExpeditionChart.guidance(action_state,is_hunt)
	_objective.text=str(guidance.title)
	_objective_detail.text=str(guidance.detail)
	_expedition_chart.set_state(action_state)
	# Keep the actual reward actions visible when the hunt turns to collection.
	# Combat target space is no longer useful once no live foes remain.
	_expedition_chart.custom_minimum_size.y=104 if str(guidance.phase)=="collect" else (120 if size.y<740 else 146)
	_target_readout.visible=str(guidance.phase)=="combat"
	var target: Dictionary=ExpeditionChart.target_summary(action_state)
	_target_readout.text="TARGET · None selected" if target.is_empty() else "%s · %s\nHealth %d / %d" % [str(target.name),str(target.role),int(target.hp),int(target.maxHp)]
	_target_readout.add_theme_color_override("font_color",UI.MUTED if target.is_empty() else UI.OXBLOOD)
	_pause_label.visible = bool(action_state.paused) and not modal_layer.visible
	_pause_label.position.x = (world_container.size.x-_pause_label.size.x)*0.5
	var index: int = 0
	for id: String in _skill_buttons:
		index += 1
		var data: Dictionary = Action.ABILITIES[id]
		var remaining: float = maxf(0,float(int(hero.cooldowns.get(id,0))-int(action_state.tick))/Action.TICK_RATE)
		_skill_buttons[id].text = "%s\n%s" % [data.name,("%.1f s" % remaining) if remaining>0 else ("%d Focus" % data.cost)]
		_skill_buttons[id].selected=id==selected_skill
	var loot_key: String = JSON.stringify(action_state.lootClaims)+str(action_state.loot.size())
	if loot_key!=_last_loot_key:
		_last_loot_key = loot_key
		_refresh_loot()

func _refresh_loot() -> void:
	_clear(_loot_box)
	for loot: Dictionary in action_state.loot:
		if bool(loot.claimed):
			continue
		var label: String = "%d gold" % int(loot.get("amount",0)) if str(loot.kind)=="gold" else ("Choose a keepsake" if str(loot.kind)=="choice" else str(Items.catalog()[loot.itemId].name))
		var button: Button=_button("Inspect: "+label,func() -> void: _inspect_loot(str(loot.id)),_loot_box,30)
		button.add_theme_font_size_override("font_size",16)
		for state_name: String in ["normal","hover","pressed","hover_pressed"]:
			# Construct the manuscript frame explicitly: its procedural colors
			# are not exported Resource fields and duplicate() loses that ink.
			var style: StyleBox=UI.command(state_name in ["hover","hover_pressed"],state_name in ["pressed","hover_pressed"])
			style.set_content_margin(SIDE_TOP,4)
			style.set_content_margin(SIDE_BOTTOM,4)
			button.add_theme_stylebox_override(state_name,style)

func _inspect_loot(id: String) -> void:
	for loot: Dictionary in action_state.loot:
		if str(loot.id)!=id or bool(loot.claimed):
			continue
		if str(loot.kind)=="choice":
			var box: VBoxContainer = _open_modal("A WARDEN’S KEEPSAKE",720)
			box.add_child(_body("Two treasures lie wrapped in the same weathered sash. The other belongs to the village. Choose one.",21))
			for item_id: String in loot.options:
				var report: Dictionary = Realm.preview_reward(realm,id,item_id)
				if not bool(report.ok):
					continue
				var preview: Dictionary = report.instance
				box.add_child(_body(Items.describe(preview),19,QUALITY.get(preview.quality,UI.INK)))
				_button("CLAIM "+Items.item_name(preview).to_upper(),func() -> void:
					_close_modal()
					_request_loot(id,item_id),box,44)
		else:
			_request_loot(id)
		return

func _request_loot(id: String, choice_id: String = "") -> void:
	for loot: Dictionary in action_state.loot:
		if str(loot.id)==id and not bool(loot.claimed):
			_start_interaction({"kind":"interact","targetId":id,"choiceId":choice_id},loot.pos)
			return

func _request_exit(leave_spoils: bool = false) -> void:
	if action_state.is_empty():
		return
	if not leave_spoils and bool(action_state.objective.completed) and realm.pendingEncounter is Dictionary and realm.pendingEncounter.has("contractId"):
		var unclaimed: Array=[]
		for loot: Dictionary in action_state.loot:
			if not bool(loot.claimed):unclaimed.append(loot)
		if not unclaimed.is_empty():
			_interaction.clear()
			var box: VBoxContainer=_open_modal("SPOILS STILL REMAIN",680)
			box.add_child(_body("Completing this hunt closes its contract. These rewards will be left behind if you leave now.",21))
			for loot: Dictionary in unclaimed:
				box.add_child(_body("%d gold" % int(loot.get("amount",0)) if str(loot.kind)=="gold" else str(Items.catalog()[loot.itemId].name),19,UI.OXBLOOD))
			_button("RETURN FOR THE SPOILS",_close_modal,box,44)
			_button("LEAVE THE SPOILS AND RETURN",func()->void:
				_close_modal()
				_request_exit(true),box,44)
			return
	_start_interaction({"kind":"exit"},action_state.arena.exit)

func _start_interaction(command: Dictionary, position: Array) -> void:
	var hero: Dictionary = Action.get_actor(action_state,str(action_state.heroId))
	var distance: float = Vector2(float(hero.pos[0]),float(hero.pos[1])).distance_to(Vector2(float(position[0]),float(position[1])))
	if distance<=1.65:
		_interaction.clear()
		_send_action(command)
		return
	var report: Dictionary = _send_action({"kind":"move","pos":position})
	if bool(report.ok):
		_interaction = {"command":command.duplicate(true),"pos":position.duplicate()}

func _poll_interaction() -> void:
	if _interaction.is_empty() or bool(action_state.paused):
		return
	var hero: Dictionary = Action.get_actor(action_state,str(action_state.heroId))
	if not hero.action.is_empty():
		return
	var pos: Array = _interaction.pos
	if Vector2(float(hero.pos[0]),float(hero.pos[1])).distance_to(Vector2(float(pos[0]),float(pos[1])))<=1.65:
		var command: Dictionary = _interaction.command.duplicate(true)
		_interaction.clear()
		_send_action(command)

func _physics_process(delta: float) -> void:
	if action_state.is_empty() or _resolution_pending:
		return
	_accumulator += minf(delta,0.25)
	while _accumulator>=Action.STEP:
		_accumulator -= Action.STEP
		_poll_interaction()
		var events: Array = Action.advance(action_state,1)
		stage.show_events(events)
		arena_overlay.show_events(events)
		for event: Dictionary in events:
			if str(event.type)=="loot_claimed":
				_notice("Spoils secured. They will enter your pack when you leave.")
		if str(action_state.phase)=="finished":
			_resolution_pending = true
			_finish_action.call_deferred()
			break
	stage.sync_state(delta)
	_hud_clock += delta
	if _hud_clock>=0.1:
		_hud_clock=0.0
		_update_action_hud()
	_autosave_clock += delta
	if _autosave_clock>=15.0:
		_autosave_clock=0.0
		_autosave()

func _process(delta: float) -> void:
	if _toast_time>0:
		_toast_time-=delta
		toast_label.visible = _toast_time>0

func _finish_action() -> void:
	var was_hunt: bool=realm.pendingEncounter is Dictionary and realm.pendingEncounter.has("contractId")
	var outcome: Dictionary = Action.outcome(action_state)
	var report: Dictionary = Realm.resolve_encounter(realm,str(action_state.encounterId),outcome)
	if not bool(report.ok):
		_notice("The expedition could not be recorded: "+str(report.message))
		return
	_show_town()
	_autosave()
	var box: VBoxContainer = _open_modal("THE ROAD HOME")
	var resolution: String = str(report.resolution)
	box.add_child(_body(("The contract is fulfilled." if was_hunt else "The bell falls silent.") if resolution=="victory" else ("You return to the living." if resolution=="retreat" else "The watch brings you home."),25,UI.OXBLOOD))
	box.add_child(_body("Mara returns with %d Health and %d Focus. Her companies are waiting in Dawnreach." % [realm.hero.hp,realm.hero.mana],20))
	for item: Dictionary in report.loot:
		box.add_child(_body(Items.item_name(item)+" · "+str(item.quality).capitalize(),21,QUALITY.get(item.quality,UI.INK)))
	if int(report.gold)>0:
		box.add_child(_body("%d gold recovered" % report.gold,20,UI.GOLD))
	if int(report.get("xpGained",0))>0:
		box.add_child(_body("%d experience earned" % int(report.xpGained),21,UI.OXBLOOD))
	if int(report.get("levelsGained",0))>0:
		box.add_child(UI.heading("LEVEL %d · %d NEW ATTRIBUTE POINTS" % [int(report.level),int(report.levelsGained)*3],22,UI.OXBLOOD))
		_button("SHAPE YOUR HERO",func()->void:_open_inventory("","character"),box,44)
	if bool(report.recoveryRequired):
		box.add_child(_body("Recovery costs 200 gold and one watch. Your fallen enemies stay fallen.",18))
	_button("INSPECT EQUIPMENT",_open_inventory,box,46)
	if not bool(report.recoveryRequired):_button("BROWSE THE NEXT HUNT",_open_expedition,box,44)
	_button("RETURN TO DAWNREACH",_close_modal,box,42)

func _inventory_slot(parent: Node, slot: String) -> void:
	var instance_id: String=str(realm.hero.equipment.get(slot,""))
	var item: Dictionary=Items.find_instance(realm.hero,instance_id)
	var label: String={"main_hand":"Weapon","off_hand":"Off hand","ring_1":"Ring I","ring_2":"Ring II"}.get(slot,slot.capitalize())
	var button: Button=_painted(label,Art.equipment(slot),func() -> void:
		if not instance_id.is_empty():_open_inventory(instance_id),parent,Vector2(58,58),"slot")
	button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	button.empty_slot=item.is_empty()
	button.tooltip_text=label+" · Empty" if item.is_empty() else Items.describe(item)
	button.disabled=item.is_empty()
	button.badge="" if item.is_empty() else "✓"

func _open_inventory(selected: String = "", page: String = "equipment", preserve_draft: bool = false) -> void:
	if not preserve_draft:
		_attribute_draft.clear()
	if page not in ["character","equipment","sets","traits"]:
		page="character"
	var content: VBoxContainer = _open_modal(str(realm.hero.name).to_upper()+" · HERO FOLIO",1120,780)
	HeroFolio.build(self,content,selected,page)

func _draft_attribute(id: String, amount: int, selected: String = "") -> void:
	var proposed: Dictionary=_attribute_draft.duplicate(true)
	proposed[id]=maxi(0,int(proposed.get(id,0))+amount)
	if int(proposed[id])==0:proposed.erase(id)
	if amount>0:
		var report: Dictionary=Realm.preview_attribute_allocation(realm,proposed)
		if not bool(report.get("ok",false)):
			_notice(str(report.get("message","That allocation is unavailable.")))
			return
	_attribute_draft=proposed
	_open_inventory(selected,"character",true)

func _apply_attribute_draft(revision: int, selected: String = "") -> void:
	var report: Dictionary=Realm.allocate_attributes(realm,_attribute_draft,revision)
	_notice(str(report.get("message","Attributes updated.")))
	if bool(report.get("ok",false)):
		_attribute_draft.clear()
		_autosave()
		_refresh_header()
		if current_view=="town":_town_sidebar()
	_open_inventory(selected,"character",true)

func _reset_attributes(revision: int, selected: String = "") -> void:
	var report: Dictionary=Realm.reset_attributes(realm,revision)
	_notice(str(report.get("message","Attributes reset.")))
	if bool(report.get("ok",false)):
		_attribute_draft.clear()
		_autosave()
		_refresh_header()
		if current_view=="town":_town_sidebar()
	_open_inventory(selected,"character",true)

func _equip_item(instance_id: String, slot: String = "", remove: bool = false) -> void:
	if not action_state.is_empty() or realm.pendingEncounter!=null:
		_notice("Return to town to change your equipment.")
		return
	var report: Dictionary = Items.unequip(realm.hero,slot) if remove else Items.equip(realm.hero,instance_id,slot)
	_notice(str(report.get("message","Equipment changed.")))
	if bool(report.ok):
		_autosave()
		_town_sidebar()
		_open_inventory(instance_id)

func _confirm_item_sale(instance_id: String) -> void:
	var quote: Dictionary=Realm.preview_item_sale(realm,"dawnwatch",instance_id)
	if not bool(quote.get("ok",false)):
		_notice(str(quote.get("message","This item cannot be sold here.")))
		return
	var box: VBoxContainer=_open_modal("AT THE MARKET STALL",680)
	var item: Dictionary=Items.find_instance(realm.hero,instance_id)
	_art_image(box,Art.item(item),Vector2(96,96))
	box.add_child(UI.heading(str(quote.name),23,QUALITY.get(str(item.quality),UI.INK)))
	box.add_child(_body("Sell this item for %d gold? Any fitted runes or gems leave with it." % int(quote.gold),21))
	_button("KEEP THIS ITEM",func()->void:_open_inventory(instance_id),box,44)
	var confirm: Button=_button("SELL FOR %d GOLD" % int(quote.gold),func()->void:_sell_item(instance_id,int(quote.revision)),box,44)
	confirm.name="ConfirmItemSale"

func _sell_item(instance_id: String,revision: int) -> void:
	var report: Dictionary=Realm.sell_item(realm,"dawnwatch",instance_id,revision)
	_notice(str(report.get("message","Sale completed.")))
	if bool(report.get("ok",false)):
		_autosave()
		_refresh_header()
		_town_sidebar()
	_open_inventory()

func _socket_item(base_id: String, material_id: String) -> void:
	if not action_state.is_empty() or realm.pendingEncounter!=null:
		_notice("Return to town to change your sockets.")
		return
	var report: Dictionary = Items.socket(realm.hero,base_id,material_id)
	_notice(str(report.get("message","Socket filled.")))
	if bool(report.ok):
		_autosave()
		_town_sidebar()
		_open_inventory(base_id)

func _open_oaths() -> void:
	var box: VBoxContainer = _open_modal("THE OATH LEDGER",940)
	var intro: Label=_body("A promise has a witness, a deadline, and a cost.",22,UI.MUTED)
	intro.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(intro)
	var index: int=0
	for id: String in Realm.obligation_catalog():
		var definition: Dictionary = Realm.obligation_catalog()[id]
		var panel: PanelContainer=PanelContainer.new()
		panel.add_theme_stylebox_override("panel",UI.paper(14))
		box.add_child(panel)
		var row: HBoxContainer=HBoxContainer.new()
		row.add_theme_constant_override("separation",22)
		panel.add_child(row)
		_art_image(row,Art.symbol("expedition") if index==0 else Art.building("granary"),Vector2(126,150))
		index+=1
		var column: VBoxContainer=VBoxContainer.new()
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",8)
		row.add_child(column)
		column.add_child(UI.heading(str(definition.name),22,UI.OXBLOOD))
		column.add_child(_body(str(definition.description),19))
		var accepted: Dictionary={}
		for oath: Dictionary in realm.obligations:
			if str(oath.definitionId)==id:accepted=oath
		if accepted.is_empty():
			_button("MAKE THIS PROMISE",func() -> void:
				var report: Dictionary=Realm.accept_obligation(realm,id,str(definition.choiceId))
				_notice(str(report.message))
				_refresh_header()
				_autosave()
				_open_oaths(),column,40)
		else:
			var remaining: int=maxi(0,int(accepted.dueWatch)-int(realm.watchIndex)+1)
			column.add_child(_body(str(accepted.status).capitalize()+((" · %d watches remain" % remaining) if str(accepted.status)=="active" else ""),18,Color("426a3d")))

func _open_realm() -> void:
	var box: VBoxContainer = _open_modal("THE ASHEN MARCH",840)
	var effects: Dictionary = Realm.settlement_effects(realm,"dawnwatch")
	box.add_child(_body("Dawnreach",25,UI.OXBLOOD))
	box.add_child(_body("Daily income: %d gold · %d timber · %d ore · %d food\nFood stores: %d / %d\nWoodland stability: %d" % [effects.dailyIncome.gold,effects.dailyIncome.wood,effects.dailyIncome.ore,effects.dailyIncome.food,realm.resources.food,effects.foodCapacity,realm.regions.woodland.stability],20))
	box.add_child(UI.heading("YOUR COMPANIES",22))
	for id: String in realm.expeditionCompanyIds:
		var company: Dictionary = realm.companies[id]
		box.add_child(_body("Dawn Guard" if str(company.type)=="spearman" else "Dawn Archers",20))
		box.add_child(_body("%d soldiers · Waiting at Dawnreach" % int(company.count),17,UI.MUTED))
	box.add_child(UI.heading("THE NEXT WATCHES",22))
	for event: Dictionary in Realm.forecast(realm,5):
		box.add_child(_body(str(event.get("message",event.get("label",event))),18))
	var visible: Array = Realm.get_visible_warbands(realm)
	if not visible.is_empty():
		box.add_child(UI.heading("BORDER REPORTS",22))
		for force: Dictionary in visible:
			box.add_child(_body(str(force.factionName)+": "+str(force.intent),18))
	if bool(effects.trade):
		_button("VISIT THE MARKET",_open_market,box,44)
	box.add_child(UI.heading("RECENT CHRONICLE",22))
	for record: Dictionary in realm.history.slice(maxi(0,realm.history.size()-8)):
		box.add_child(_body(str(record.message),17,UI.MUTED))

func _open_market() -> void:
	var box: VBoxContainer = _open_modal("DAWNREACH MARKET")
	box.add_child(_body("Gold: %d" % realm.resources.gold,23,UI.OXBLOOD))
	for key: String in ["wood","ore","food"]:
		var row: HBoxContainer = HBoxContainer.new()
		box.add_child(row)
		row.add_child(_body("%s: %d" % [key.capitalize(),realm.resources[key]],20))
		var prices: Dictionary = {"wood":45,"ore":55,"food":20}
		_button("BUY · %d G" % int(prices[key]),func() -> void: _trade(key,true),row,42)
		_button("SELL · %d G" % int(int(prices[key])/2),func() -> void: _trade(key,false),row,42)
	box.add_child(UI.heading("THE RUNECARVER",23))
	box.add_child(_body("A finite stock of ordinary bases and socket materials. Purchased materials go into your pack. Select a socketed weapon in Equipment to set a rune; insertion consumes it.",18))
	for entry: Dictionary in Realm.supply_catalog():
		var id: String = str(entry.itemId)
		var stock: int = int(realm.supplyMarket.stock[id])
		var button: Button = _button("%s · %d gold · %d left" % [entry.name,entry.price,stock],func() -> void: _purchase_supply(id),box,40)
		button.disabled=stock<=0 or int(realm.resources.gold)<int(entry.price)
	box.add_child(_body("Hearthguard: Cinder, then Stone.\nWindscar: Cinder, then Gale.\nBoth recipes require the two seats of a Notched Ironblade. Other combinations keep their individual socket bonuses.",18,UI.OXBLOOD))

func _purchase_supply(item_id: String) -> void:
	var report: Dictionary = Realm.purchase_supply_item(realm,"dawnwatch",item_id)
	_notice(str(report.message))
	if bool(report.ok):
		_refresh_header()
		_autosave()
	_open_market()

func _trade(resource: String, buying: bool) -> void:
	var report: Dictionary = Realm.trade(realm,"dawnwatch",resource,1,buying)
	_notice(str(report.message))
	if bool(report.ok):
		_refresh_header()
		_autosave()
	_open_market()

func _notice(message: String) -> void:
	toast_label.text=message
	toast_label.visible=true
	_toast_time=5.0
	_status.text=message

func _setup_audio() -> void:
	_music = AudioStreamPlayer.new()
	_ambience = AudioStreamPlayer.new()
	add_child(_music)
	add_child(_ambience)
	for entry: Array in [[_music,"res://assets/audio/chronicle.ogg",-25.0],[_ambience,"res://assets/audio/forest.ogg",-32.0]]:
		var stream: AudioStreamOggVorbis = load(str(entry[1])).duplicate()
		stream.loop = true
		entry[0].stream = stream
		entry[0].volume_db = float(entry[2])
		if sound_enabled:
			entry[0].play()

func _open_menu() -> void:
	var box: VBoxContainer = _open_modal("DRACONIA",650)
	box.add_child(_body("Oaths of the Carpathians",24,UI.OXBLOOD))
	_button("CONTINUE",_close_modal,box,46)
	_button("SAVE CHRONICLE",func() -> void: save_game(),box,44)
	var load_button: Button = _button("LOAD SAVED CHRONICLE",func() -> void: load_game(SAVE_PATH),box,44)
	load_button.disabled = not FileAccess.file_exists(SAVE_PATH)
	_button("SOUND: "+("ON" if sound_enabled else "OFF"),func() -> void:
		sound_enabled = not sound_enabled
		if current_view=="dungeon" and is_instance_valid(stage):stage.set_sound_enabled(sound_enabled)
		for player: AudioStreamPlayer in [_music,_ambience]:
			if sound_enabled: player.play()
			else: player.stop()
		_open_menu(),box,44)
	_button("NEW CHRONICLE",_confirm_new,box,44)
	_button("CONTROLS & CREDITS",_open_help,box,44)
	_button("SAVE & QUIT",request_quit,box,44)
	box.add_child(_body("Development build · Dawnreach and the Bellworn Vault",16,UI.MUTED))

func _confirm_new() -> void:
	var box: VBoxContainer = _open_modal("BEGIN AGAIN?",640)
	box.add_child(_body("A new chronicle replaces the active autosave. Your manual save remains available from the menu.",21))
	_button("BEGIN A NEW CHRONICLE",func() -> void:
		_close_modal()
		realm=Realm.create_realm(711)
		_show_town()
		_autosave(),box,48)
	_button("KEEP THIS CHRONICLE",_close_modal,box,44)

func _open_help() -> void:
	var box: VBoxContainer = _open_modal("THE TRAVELLER’S GUIDE",820)
	box.add_child(UI.heading("Town",22))
	box.add_child(_body("Choose a town work and press Construct. A completed building appears in its plot immediately. You may build once each day. Rest advances one watch; Next Dawn stops at the next dawn or an oath deadline. The realm uses four watches per day.",19))
	box.add_child(UI.heading("Solo expeditions",22))
	box.add_child(_body("Click the ground to move. Click an enemy to pursue and attack. Right-click casts the selected skill; 1–2 cast Mara’s Oathwarden skills toward the cursor. G toggles a directional guard. Shift dodges toward the cursor. Space pauses combat and lets you prepare one order. Scroll to change camera distance.",19))
	box.add_child(_body("Inspect spoils near a fallen enemy. The hero walks into reach before collecting. Return to the entrance to leave; enemies can interrupt an escape. Equipment changes are made in town. C opens attributes and traits, I opens equipment, J opens oaths, R rests, Ctrl+S saves, and Esc opens the menu.",19))
	box.add_child(UI.heading("Credits",22))
	box.add_child(_body("Original Draconia rules, names and manuscript artwork. Native engine: Godot (MIT). Environment models: Poly Haven, Yughues and Daniel Andersson (CC0). Creature: br-n518 (CC0). Human assets: MakeHuman / MPFB contributors (CC0); motion: Quaternius Universal Animation Library Standard (CC0). Typefaces: Cinzel and EB Garamond (SIL OFL). Music: RandomMind; ambience: Chris Castiglione via Flare (CC0). Full provenance and notices accompany the source project.",17,UI.MUTED))

func _save_document() -> Dictionary:
	return {"schema":"draconia-native-1","realm":Realm.serialize(realm),"action":Action.serialize(action_state) if not action_state.is_empty() else "","selectedBuilding":selected_building,"selectedSkill":selected_skill,"interaction":_interaction.duplicate(true)}

func save_game(notify_user: bool = true, path: String = SAVE_PATH) -> bool:
	var document: Dictionary = _save_document()
	var temporary: String = path+".tmp"
	var file: FileAccess = FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:
		if notify_user: _notice("The chronicle could not be saved.")
		return false
	var stored: bool = file.store_string(JSON.stringify(document))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if not stored or write_error != OK:
		DirAccess.remove_absolute(temporary)
		if notify_user: _notice("The chronicle could not be written completely. Your previous save is unchanged.")
		return false
	var error: Error = DirAccess.rename_absolute(temporary,path)
	if error!=OK:
		if notify_user: _notice("The chronicle could not replace its previous save.")
		return false
	if notify_user: _notice("Chronicle saved.")
	return true

func _autosave() -> void:
	if not qa_no_autosave:
		save_game(false,AUTO_PATH)

func load_game(path: String = SAVE_PATH, notify_user: bool = true) -> bool:
	if not FileAccess.file_exists(path):
		if notify_user: _notice("No saved chronicle was found.")
		return false
	var file: FileAccess = FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>4000000:
		if notify_user: _notice("This chronicle could not be opened.")
		return false
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary or str(data.get("schema",""))!="draconia-native-1" or not data.get("realm") is String or not data.get("action") is String:
		if notify_user: _notice("This chronicle has an unsupported format.")
		return false
	var loaded_realm: Variant = Realm.deserialize(str(data.realm))
	if not loaded_realm is Dictionary:
		if notify_user: _notice("This chronicle failed its integrity check.")
		return false
	var loaded_action: Dictionary = {}
	if loaded_realm.pendingEncounter!=null:
		loaded_action = Action.deserialize(str(data.action),loaded_realm.pendingEncounter)
		if loaded_action.is_empty():
			if notify_user: _notice("The expedition in this chronicle is incomplete or damaged.")
			return false
	elif not str(data.action).is_empty():
		if notify_user: _notice("This chronicle contains an orphaned expedition.")
		return false
	_close_modal()
	realm=loaded_realm
	selected_building=str(data.get("selectedBuilding","granary"))
	if not TownStage.PLOTS.has(selected_building): selected_building="granary"
	selected_skill=str(data.get("selectedSkill","cleave"))
	if not Identity.is_skill_allowed(realm.hero,selected_skill):selected_skill="cleave"
	action_state=loaded_action
	if action_state.is_empty():
		_show_town()
	else:
		_show_dungeon()
		# Movement/action state is authoritative. A pending UI click is deliberately
		# discarded on load; it cannot invent a second pickup or silently leave.
	if notify_user: _notice("Chronicle restored.")
	return true
