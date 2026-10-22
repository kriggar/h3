extends Control
## The native Godot application: adventure, towns, progression, saves and combat.

const SAVE_PATH: String = "user://draconia-save.json"
const SETTINGS_PATH: String = "user://draconia-settings.json"
var state: Dictionary = {}
var world: AdventureMap
var resource_row: HBoxContainer
var date_label: Label
var phase_label: Label
var hero_box: VBoxContainer
var quest_box: VBoxContainer
var army_row: HBoxContainer
var mini: TextureRect
var end_button: Button
var status: Label
var selection: PanelContainer
var modal_layer: Control
var title_layer: Control
var battle: BattleScreen
var toast_label: Label
var toast_timer: float = 0.0
var busy: bool = false
var sound_enabled: bool = false
var audio_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var _import_callback: JavaScriptObject
var _selected: Vector2i = Vector2i(-1, -1)
var _has_save: bool = false
var _town_tab: int = 0

func _ready() -> void:
	theme = DraconiaTheme.make_theme()
	state = CampaignCore.create_game()
	if FileAccess.file_exists(SAVE_PATH):
		var saved: Variant = CampaignCore.deserialize(FileAccess.get_file_as_string(SAVE_PATH))
		if saved is Dictionary:
			state = saved
			_has_save = true
	if FileAccess.file_exists(SETTINGS_PATH):
		var settings: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if settings is Dictionary:
			sound_enabled = bool(settings.get("sound", false))
	_build_shell()
	_refresh(true)
	_show_title()
	set_process(true)

func _process(delta: float) -> void:
	if toast_timer > 0:
		toast_timer -= delta
		toast_label.modulate.a = minf(1.0, toast_timer * 2.0)
		if toast_timer <= 0:
			toast_label.visible = false

func _clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _panel(parent: Node, margin: int = 16, dark: bool = false) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme = theme
	var frame: DraconiaFrame = DraconiaTheme.parchment(margin) as DraconiaFrame
	if dark:
		frame.fill = DraconiaTheme.DARK
	panel.add_theme_stylebox_override("panel", frame)
	parent.add_child(panel)
	return panel

func _paper_panel(parent: Node, margin: int = 14) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme = DraconiaTheme.page_theme()
	panel.add_theme_stylebox_override("panel", DraconiaTheme.paper(margin))
	parent.add_child(panel)
	return panel

func _paper_ink(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is Label:
		var color: Color = node.get_theme_color("font_color")
		if color == DraconiaTheme.MUTED or color == Color("c4a17e"):
			node.add_theme_color_override("font_color", Color("786449"))
		elif color == Color("b4c895"):
			node.add_theme_color_override("font_color", Color("4b6038"))
		elif color == Color("e2a47c"):
			node.add_theme_color_override("font_color", Color("92472e"))
	for child: Node in node.get_children():
		_paper_ink(child)

func _build_shell() -> void:
	var shell: VBoxContainer = VBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation", 0)
	add_child(shell)
	var top: PanelContainer = _panel(shell, 5, true)
	var top_row: HBoxContainer = HBoxContainer.new()
	top.add_child(top_row)
	var brand: Button = DraconiaTheme.button("D R A C O N I A", _show_menu, Vector2(235, 37))
	brand.icon = DraconiaArt.texture("assets/generated/ui-crest-v2.png")
	brand.expand_icon = true
	brand.add_theme_constant_override("icon_max_width", 34)
	brand.add_theme_font_override("font", load("res://assets/cinzel.ttf"))
	brand.add_theme_font_size_override("font_size", 19)
	brand.add_theme_stylebox_override("normal", DraconiaTheme.flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 6))
	brand.add_theme_color_override("font_color", Color("e5d4ab"))
	top_row.add_child(brand)
	var subtitle: Label = DraconiaTheme.body("OATHS OF THE CARPATHIANS", 11, Color("b9b397"))
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(subtitle)
	for spec: Array in [["Chronicle", _show_journal], ["Grimoire", _show_spells], ["Save", _manual_save], ["Menu", _show_menu]]:
		top_row.add_child(DraconiaTheme.button(str(spec[0]), spec[1], Vector2(83, 36)))
	var resources_panel: PanelContainer = _panel(shell, 9)
	var resource_layout: HBoxContainer = HBoxContainer.new()
	resources_panel.add_child(resource_layout)
	resource_row = HBoxContainer.new()
	resource_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_layout.add_child(resource_row)
	date_label = DraconiaTheme.heading("", 15)
	resource_layout.add_child(date_label)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	shell.add_child(body)
	var map_area: Control = Control.new()
	map_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_area.clip_contents = true
	body.add_child(map_area)
	world = AdventureMap.new()
	world.name = "AdventureMap"
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_area.add_child(world)
	world.destination_selected.connect(_select_destination)
	world.selection_cleared.connect(_clear_selection)
	var map_heading: VBoxContainer = VBoxContainer.new()
	map_heading.position = Vector2(25, 22)
	map_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_heading.add_theme_constant_override("separation", 3)
	map_area.add_child(map_heading)
	var map_title: Label = DraconiaTheme.heading("The Veiled Marches", 27, Color("f4e7c7"))
	map_title.add_theme_color_override("font_shadow_color", Color("142018"))
	map_title.add_theme_constant_override("shadow_offset_x", 2)
	map_title.add_theme_constant_override("shadow_offset_y", 2)
	map_heading.add_child(map_title)
	phase_label = DraconiaTheme.body("", 13, Color("e7ddbe"))
	phase_label.add_theme_color_override("font_shadow_color", Color("152019"))
	phase_label.add_theme_constant_override("shadow_offset_y", 2)
	map_heading.add_child(phase_label)
	var controls: HBoxContainer = HBoxContainer.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.position = Vector2(-315, -59)
	map_area.add_child(controls)
	controls.add_child(DraconiaTheme.button("−", func() -> void: world.change_zoom(1.0 / 1.18), Vector2(36, 33)))
	controls.add_child(DraconiaTheme.button("+", func() -> void: world.change_zoom(1.18), Vector2(36, 33)))
	controls.add_child(DraconiaTheme.button("Hero", func() -> void: world.center_hero(), Vector2(58, 33)))
	controls.add_child(DraconiaTheme.button("World", func() -> void: world.fit_world(), Vector2(58, 33)))
	controls.add_child(DraconiaTheme.button("Grid", _toggle_grid, Vector2(52, 33)))
	var hint: Label = DraconiaTheme.body("Click to plan · Click again to travel · Drag to explore · Wheel to zoom", 11, Color("e4dcc2"))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 18
	hint.offset_top = -26
	hint.offset_bottom = -6
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_area.add_child(hint)
	selection = _paper_panel(map_area, 20)
	selection.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	selection.offset_left = 20
	selection.offset_right = 390
	selection.offset_top = -350
	selection.offset_bottom = -42
	selection.visible = false
	var sidebar: PanelContainer = _panel(body, 15)
	sidebar.custom_minimum_size.x = 278
	var side_scroll: ScrollContainer = ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(side_scroll)
	var side: VBoxContainer = VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 13)
	side_scroll.add_child(side)
	var known_world: HBoxContainer = HBoxContainer.new()
	side.add_child(known_world)
	var known_label: Label = DraconiaTheme.heading("THE KNOWN WORLD", 13)
	known_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	known_world.add_child(known_label)
	known_world.add_child(DraconiaTheme.button("↗", func() -> void: world.fit_world(), Vector2(28, 26)))
	mini = TextureRect.new()
	mini.custom_minimum_size = Vector2(232, 130)
	mini.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mini.stretch_mode = TextureRect.STRETCH_SCALE
	mini.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mini.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mini.gui_input.connect(_minimap_input)
	side.add_child(mini)
	hero_box = VBoxContainer.new()
	side.add_child(hero_box)
	side.add_child(HSeparator.new())
	quest_box = VBoxContainer.new()
	side.add_child(quest_box)
	var town_button: Button = DraconiaTheme.button("Visit settlement", _nearest_town)
	town_button.tooltip_text = "Recruit and construct while Ileana is next to a settlement."
	side.add_child(town_button)
	var bottom: PanelContainer = _panel(shell, 10)
	var command: HBoxContainer = HBoxContainer.new()
	bottom.add_child(command)
	var army_box: VBoxContainer = VBoxContainer.new()
	army_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command.add_child(army_box)
	army_box.add_child(DraconiaTheme.heading("THE HOST OF DRACONIA", 12))
	army_row = HBoxContainer.new()
	army_row.add_theme_constant_override("separation", 7)
	army_box.add_child(army_row)
	end_button = DraconiaTheme.button("END DAY\nRest & replenish  ·  E", _end_day, Vector2(242, 94))
	end_button.icon = DraconiaArt.ui_icon(7)
	end_button.expand_icon = true
	end_button.add_theme_constant_override("icon_max_width", 43)
	end_button.add_theme_font_override("font", load("res://assets/cinzel.ttf"))
	end_button.add_theme_font_size_override("font_size", 16)
	command.add_child(end_button)
	var status_box: PanelContainer = _panel(shell, 5, true)
	var status_row: HBoxContainer = HBoxContainer.new()
	status_box.add_child(status_row)
	status = DraconiaTheme.body("Your chronicle begins at Cetatea Zorilor.", 11, Color("c9c4aa"))
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(status)
	var help: Button = DraconiaTheme.button("How to play", _show_help, Vector2(90, 24))
	help.add_theme_font_size_override("font_size", 11)
	status_row.add_child(help)
	toast_label = DraconiaTheme.body("", 15, Color("f3e8c9"))
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -380
	toast_label.offset_right = 380
	toast_label.offset_top = 133
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	toast_label.add_theme_constant_override("shadow_outline_size", 7)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.visible = false
	add_child(toast_label)
	audio_player = AudioStreamPlayer.new()
	audio_player.volume_db = -20
	add_child(audio_player)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -21
	add_child(music_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.volume_db = -27
	add_child(ambience_player)
	for item: Array in [[music_player, "res://assets/audio/chronicle.ogg"], [ambience_player, "res://assets/audio/forest.ogg"]]:
		if ResourceLoader.exists(str(item[1])):
			var stream: AudioStreamOggVorbis = load(str(item[1])).duplicate()
			stream.loop = true
			item[0].stream = stream

func _refresh(recenter: bool = false) -> void:
	world.set_campaign(state, recenter)
	var income: Dictionary = CampaignCore.get_income(state)
	_clear(resource_row)
	for resource_index: int in range(CampaignCore.RESOURCE_KEYS.size()):
		var key: String = CampaignCore.RESOURCE_KEYS[resource_index]
		var chip: HBoxContainer = HBoxContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_theme_constant_override("separation", 7)
		chip.tooltip_text = "%s: %d  ·  Daily income +%d" % [key.capitalize(), int(state.resources[key]), int(income[key])]
		resource_row.add_child(chip)
		var icon: TextureRect = TextureRect.new()
		icon.texture = DraconiaArt.ui_icon(resource_index)
		icon.custom_minimum_size = Vector2(34, 34)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chip.add_child(icon)
		var numbers: VBoxContainer = VBoxContainer.new()
		numbers.add_theme_constant_override("separation", 0)
		numbers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		numbers.custom_minimum_size.x = 62
		chip.add_child(numbers)
		var resource_name: Label = DraconiaTheme.body(key.capitalize(), 11, DraconiaTheme.MUTED)
		resource_name.autowrap_mode = TextServer.AUTOWRAP_OFF
		numbers.add_child(resource_name)
		numbers.add_child(DraconiaTheme.heading(str(int(state.resources[key])), 18))
	var phase: Dictionary = CampaignCore.get_world_phase(state)
	date_label.text = "Day %d  ·  Week %d" % [int(state.day), 1 + int((int(state.day) - 1) / 7)]
	phase_label.text = "%s  ·  %d oaths restored  ·  Corruption %d%%" % [str(phase.label), state.wards.size(), int(state.corruption)]
	phase_label.tooltip_text = str(CampaignCore.get_battle_context(state).description)
	_clear(hero_box)
	var hero_row: HBoxContainer = HBoxContainer.new()
	hero_box.add_child(hero_row)
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = DraconiaArt.portrait("ileana")
	portrait.custom_minimum_size = Vector2(82, 110)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero_row.add_child(portrait)
	var hero_info: VBoxContainer = VBoxContainer.new()
	hero_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_row.add_child(hero_info)
	hero_info.add_child(DraconiaTheme.heading(str(state.hero.name), 22))
	hero_info.add_child(DraconiaTheme.body("Oathkeeper  ·  Level %d" % int(state.hero.level), 12, DraconiaTheme.MUTED))
	hero_info.add_child(DraconiaTheme.body("Attack %d   Defense %d\nPower %d   XP %d" % [int(state.hero.attack), int(state.hero.defense), int(state.hero.power), int(state.hero.xp)], 12))
	_add_meter(hero_box, "Movement", int(state.hero.movement), int(state.hero.maxMovement), Color("697c50"))
	_add_meter(hero_box, "Mana", int(state.hero.mana), int(state.hero.maxMana), Color("577585"))
	if int(state.hero.get("skillPoints", 0)) > 0:
		hero_box.add_child(DraconiaTheme.button("Choose a skill  (%d)" % int(state.hero.skillPoints), _show_skills, Vector2(0, 32)))
	_clear(quest_box)
	quest_box.add_child(DraconiaTheme.heading("THE THREE OATHS", 17))
	quest_box.add_child(DraconiaTheme.body("Break the night’s hold. Restore the ancestral oaths, then challenge Cetatea Nopții.", 12, DraconiaTheme.MUTED))
	for objective: Dictionary in CampaignCore.get_objectives(state):
		var label: Label = DraconiaTheme.body(("✓  " if bool(objective.done) else "◦  ") + str(objective.label), 12, Color("a3bc83") if bool(objective.done) else DraconiaTheme.INK)
		quest_box.add_child(label)
	_clear(army_row)
	for index: int in range(7):
		var cell: Button = Button.new()
		cell.custom_minimum_size = Vector2(84, 86)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		army_row.add_child(cell)
		if index < state.army.size():
			var stack: Dictionary = state.army[index]
			var unit: Dictionary = CampaignCore.UNITS[str(stack.type)]
			cell.icon = DraconiaArt.portrait(str(stack.type))
			cell.expand_icon = true
			cell.add_theme_constant_override("icon_max_width", 63)
			cell.add_theme_font_override("font", load("res://assets/cinzel.ttf"))
			cell.add_theme_font_size_override("font_size", 20)
			cell.text = str(stack.count)
			cell.tooltip_text = "%d %s · Attack %d · Defense %d · Damage %d–%d" % [int(stack.count), str(unit.plural), int(unit.attack), int(unit.defense), int(unit.minDamage), int(unit.maxDamage)]
			cell.pressed.connect(_show_unit.bind(str(stack.type), int(stack.count)))
		else:
			cell.text = "—"
			cell.disabled = true
	end_button.disabled = busy or is_instance_valid(battle)
	end_button.text = "END DAY\n%s  ·  E" % ("A new week tomorrow" if int(state.day) % 7 == 0 else ("Night approaches" if int(phase.cycleDay) == 3 else ("Dawn approaches" if int(phase.cycleDay) == 5 else "Rest & replenish")))
	_update_minimap()

func _add_meter(parent: Node, name_text: String, value: int, maximum: int, color: Color) -> void:
	parent.add_child(DraconiaTheme.body("%s                         %d / %d" % [name_text, value, maximum], 11))
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size.y = 7
	bar.show_percentage = false
	bar.max_value = maximum
	bar.value = value
	bar.add_theme_stylebox_override("fill", DraconiaTheme.flat(color, color, 0))
	parent.add_child(bar)

func _update_minimap() -> void:
	var w: int = int(state.world.w)
	var h: int = int(state.world.h)
	var image: Image = Image.create(w * 3, h * 3, false, Image.FORMAT_RGB8)
	var colors: Dictionary = {"grass": Color("6a794c"), "forest": Color("30432c"), "water": Color("395b66"), "dirt": Color("8b7755"), "mountain": Color("77776c"), "hill": Color("767849"), "snow": Color("c7c6b7")}
	for y: int in range(h):
		for x: int in range(w):
			var color: Color = colors.get(str(state.world.tiles[y][x].terrain), Color("5b6846"))
			if not bool(state.revealed[y][x]):
				color = Color("222a22")
			image.fill_rect(Rect2i(x * 3, y * 3, 3, 3), color)
	for obj: Dictionary in state.world.objects:
		if not bool(obj.get("removed", false)) and bool(state.revealed[int(obj.y)][int(obj.x)]):
			var color: Color = Color("d4b664") if str(obj.owner) == "player" else Color("b95d46") if not obj.get("enemies", []).is_empty() else Color("b6b49b")
			image.fill_rect(Rect2i(int(obj.x) * 3, int(obj.y) * 3, 3, 3), color)
	image.fill_rect(Rect2i(int(state.hero.x) * 3, int(state.hero.y) * 3, 3, 3), Color("fff2a1"))
	mini.texture = ImageTexture.create_from_image(image)

func _minimap_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = event.position / mini.size
		world.focus_tile(clampi(int(point.x * float(state.world.w)), 0, int(state.world.w) - 1), clampi(int(point.y * float(state.world.h)), 0, int(state.world.h) - 1))

func _toast(message: String, error: bool = false) -> void:
	status.text = message
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", Color("f4bd9e") if error else Color("f3e8c9"))
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	toast_timer = 5.0

func _clear_selection() -> void:
	selection.visible = false
	_selected = Vector2i(-1, -1)
	world.selected = Vector2i(-1, -1)
	world.planned_path = []

func _select_destination(x: int, y: int, confirm: bool = false) -> void:
	if busy or is_instance_valid(battle) or is_instance_valid(modal_layer):
		return
	if confirm and _selected == Vector2i(x, y):
		_travel_to_selected()
		return
	_selected = Vector2i(x, y)
	world.selected = _selected
	var path: Variant = CampaignCore.find_path(state, x, y)
	world.planned_path = path if path is Array else []
	var object: Variant = CampaignCore.object_at(state, x, y)
	var known: bool = bool(state.revealed[y][x])
	_clear(selection)
	var box: VBoxContainer = VBoxContainer.new()
	selection.add_child(box)
	var head: HBoxContainer = HBoxContainer.new()
	box.add_child(head)
	var title: String = str(object.name) if known and object != null else ("Unexplored country" if not known else str(state.world.tiles[y][x].terrain).capitalize())
	var label: Label = DraconiaTheme.heading(title, 17)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(label)
	head.add_child(DraconiaTheme.button("×", _clear_selection, Vector2(26, 26)))
	if known and object != null:
		var illustration_index: int = 5 if str(object.type) == "town" else (0 if str(object.type) == "mine" else 3 if str(object.id) == "dawnwell" else 4 if str(object.id) == "ashen-citadel" else 2)
		_illustration(box, illustration_index, 86)
	box.add_child(DraconiaTheme.body(str(object.get("description", "")) if known and object != null else "Follow the old roads to reveal the lands beyond your banner.", 12))
	var cost: int = 0 if path == null or path.is_empty() else int(path[-1].totalCost)
	var near: bool = object != null and maxi(absi(x - int(state.hero.x)), absi(y - int(state.hero.y))) <= 1
	box.add_child(DraconiaTheme.body("Movement: %d / %d available" % [cost, int(state.hero.movement)] if path != null else "This terrain cannot be crossed.", 12))
	var action: Button = DraconiaTheme.button("Visit location" if near else ("Travel as far as possible" if cost > int(state.hero.movement) else "Travel here"), _travel_to_selected, Vector2(0, 36))
	action.disabled = (path == null and not near) or (not near and cost > 0 and int(state.hero.movement) <= 0)
	box.add_child(action)
	selection.visible = true
	_paper_ink.call_deferred(selection)
	_sound(440.0, 0.08)

func _travel_to_selected() -> void:
	if _selected.x < 0 or busy or is_instance_valid(battle):
		return
	var object: Variant = CampaignCore.object_at(state, _selected.x, _selected.y)
	if object != null and maxi(absi(_selected.x - int(state.hero.x)), absi(_selected.y - int(state.hero.y))) <= 1:
		_handle_interaction(str(object.id))
		return
	var path: Variant = CampaignCore.find_path(state, _selected.x, _selected.y)
	if path == null:
		_toast("This destination is blocked.", true)
		return
	var destination: Vector2i = _selected
	if not path.is_empty() and int(path[-1].totalCost) > int(state.hero.movement):
		var affordable: Array = path.filter(func(step: Dictionary) -> bool: return int(step.totalCost) <= int(state.hero.movement))
		if affordable.is_empty():
			_toast("No movement remains. End the day to rest.", true)
			return
		destination = Vector2i(int(affordable[-1].x), int(affordable[-1].y))
	var previous: Vector2i = Vector2i(int(state.hero.x), int(state.hero.y))
	var result: Dictionary = CampaignCore.travel(state, destination.x, destination.y)
	if not bool(result.ok):
		_toast(str(result.message), true)
		return
	busy = true
	_clear_selection()
	_refresh()
	world.animate_travel(result.path, previous)
	while is_instance_valid(world) and world.moving:
		await get_tree().process_frame
	busy = false
	_refresh()
	_save()
	_sound(330.0, 0.11)
	if result.event is Dictionary:
		_handle_interaction(str(result.event.id))
	else:
		_toast(str(result.message))

func _handle_interaction(object_id: String) -> void:
	var result: Dictionary = CampaignCore.interact(state, object_id)
	_clear_selection()
	_refresh()
	if not bool(result.ok):
		_toast(str(result.message), true)
		return
	_save()
	match str(result.get("event", "")):
		"town": _show_town(object_id)
		"battle": _show_encounter(result.object)
		_: _toast(str(result.message))

func _end_day() -> void:
	if busy or is_instance_valid(battle) or is_instance_valid(modal_layer) or is_instance_valid(title_layer):
		return
	var result: Dictionary = CampaignCore.end_turn(state)
	_clear_selection()
	_refresh()
	_save()
	_toast(str(result.message))
	_sound(261.63, 0.25)

func _toggle_grid() -> void:
	world.show_grid = not world.show_grid
	world.queue_redraw()

func _close_modal() -> void:
	if is_instance_valid(modal_layer):
		remove_child(modal_layer)
		modal_layer.queue_free()
	modal_layer = null
	world.grab_focus()

func _modal(title: String, width: float = 760, height: float = 620) -> VBoxContainer:
	_close_modal()
	modal_layer = Control.new()
	modal_layer.name = "ModalLayer"
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal_layer)
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0.06, 0.08, 0.06, 0.74)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(veil)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	var panel: PanelContainer = _panel(center, 29)
	panel.custom_minimum_size = Vector2(minf(width, size.x - 60), minf(height, size.y - 70))
	var layout: VBoxContainer = VBoxContainer.new()
	panel.add_child(layout)
	var header: HBoxContainer = HBoxContainer.new()
	layout.add_child(header)
	var label: Label = DraconiaTheme.heading(title, 25)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(label)
	var close: Button = DraconiaTheme.button("×", _close_modal, Vector2(34, 34))
	header.add_child(close)
	layout.add_child(HSeparator.new())
	var page: PanelContainer = _paper_panel(layout, 16)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var body: VBoxContainer = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	_paper_ink.call_deferred(page)
	close.grab_focus()
	return body

func _show_title() -> void:
	if is_instance_valid(title_layer):
		return
	_close_modal()
	title_layer = Control.new()
	title_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(title_layer)
	var panorama: TextureRect = TextureRect.new()
	panorama.texture = DraconiaArt.texture("assets/generated/landscape.png")
	panorama.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panorama.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panorama.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_layer.add_child(panorama)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.06, 0.27)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(dim)
	var left: VBoxContainer = VBoxContainer.new()
	left.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	left.offset_left = 60
	left.offset_right = 620
	left.offset_top = -230
	left.offset_bottom = 245
	left.add_theme_constant_override("separation", 16)
	title_layer.add_child(left)
	var title: Label = DraconiaTheme.heading("DRACONIA", 68, Color("f4e7c8"))
	title.add_theme_color_override("font_shadow_color", Color("152019"))
	title.add_theme_constant_override("shadow_offset_y", 3)
	left.add_child(title)
	left.add_child(DraconiaTheme.heading("OATHS OF THE CARPATHIANS", 19, Color("e3cda2")))
	var card: PanelContainer = _panel(left, 28)
	var story: VBoxContainer = VBoxContainer.new()
	story.add_theme_constant_override("separation", 15)
	card.add_child(story)
	story.add_child(DraconiaTheme.heading("The forest remembers.", 23))
	story.add_child(DraconiaTheme.body("The old oaths are broken. Vârcolaci prowl the mountain roads, strigoi gather beneath the ruined fortress, and the iele have withdrawn into the ancient woods.\n\nLead Ileana’s host across Draconia. Rebuild its settlements, win the trust of its spirits, and restore the three oaths before confronting the lord of the night.", 16))
	story.add_child(DraconiaTheme.button("CONTINUE CHRONICLE" if _has_save else "BEGIN YOUR CHRONICLE", _begin, Vector2(0, 49)))
	var actions: HBoxContainer = HBoxContainer.new()
	story.add_child(actions)
	var help_button: Button = DraconiaTheme.button("How to play", _show_help)
	help_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(help_button)
	var credits: Button = DraconiaTheme.button("Credits", _show_credits)
	credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(credits)
	left.add_child(DraconiaTheme.body("A native Godot strategy chronicle  ·  Single player  ·  Autosave", 12, Color("d5d0b9")))

func _begin() -> void:
	_close_modal()
	if is_instance_valid(title_layer):
		remove_child(title_layer)
		title_layer.queue_free()
	title_layer = null
	_refresh(true)
	_save()
	_toast("Visit Cetatea Zorilor beside Ileana to recruit. Read the ancestral waystone to reveal the three oaths.")
	_sound(392.0, 0.22)
	_apply_audio_setting()

func _show_menu() -> void:
	if busy or is_instance_valid(battle):
		return
	var box: VBoxContainer = _modal("The Chronicle", 520, 540)
	box.add_child(DraconiaTheme.body("Day %d · Level %d · %d/3 oaths · %d victories" % [int(state.day), int(state.hero.level), state.wards.size(), int(state.stats.battlesWon)]))
	box.add_child(DraconiaTheme.button("Return to Draconia", _close_modal))
	box.add_child(DraconiaTheme.button("Save progress", _manual_save))
	box.add_child(DraconiaTheme.button("Export save file", _export_save))
	box.add_child(DraconiaTheme.button("Import save file", _import_save))
	box.add_child(DraconiaTheme.button("Sound: " + ("on" if sound_enabled else "off"), _toggle_sound))
	box.add_child(DraconiaTheme.button("Start a new chronicle", _confirm_new))
	box.add_child(DraconiaTheme.button("Credits & licenses", _show_credits))
	box.add_child(DraconiaTheme.button("How to play", _show_help))

func _confirm_new() -> void:
	var box: VBoxContainer = _modal("Begin again?", 520, 340)
	box.add_child(DraconiaTheme.body("This begins a new campaign and replaces the active autosave. Export your current chronicle first if you want to return to it."))
	box.add_child(DraconiaTheme.button("Export current save", _export_save))
	box.add_child(DraconiaTheme.button("Begin a new chronicle", func() -> void:
		state = CampaignCore.create_game()
		_clear_selection()
		_close_modal()
		_refresh(true)
		_save()
		_toast("A new chronicle begins.")))
	box.add_child(DraconiaTheme.button("Keep playing", _close_modal))

func _manual_save() -> void:
	if _save():
		_toast("Chronicle saved. Your progress also saves after every completed action.")

func _save() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		_toast("The save could not be written. Export a save file from the menu.", true)
		return false
	file.store_string(CampaignCore.serialize(state))
	file.flush()
	file.close()
	var error: Error = DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	if error != OK:
		_toast("The save could not be committed. Export a save file from the menu.", true)
		return false
	_has_save = true
	return true

func _export_save() -> void:
	var text: String = CampaignCore.serialize(state)
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), "Draconia-Day-%d.json" % int(state.day), "application/json")
		_toast("Save file downloaded.")
	else:
		var dialog: FileDialog = FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.json ; Draconia save"])
		dialog.current_file = "Draconia-Day-%d.json" % int(state.day)
		dialog.use_native_dialog = true
		add_child(dialog)
		dialog.file_selected.connect(func(path: String) -> void:
			var target: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			if target:
				target.store_string(text)
				target.close()
				_toast("Save file exported.")
			else:
				_toast("That location could not be written.", true)
			dialog.queue_free())
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered_ratio(0.7)

func _import_save() -> void:
	if OS.has_feature("web"):
		_import_callback = JavaScriptBridge.create_callback(_web_import_received)
		var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		window.draconiaImportCallback = _import_callback
		JavaScriptBridge.eval("(()=>{const f=document.createElement('input');f.type='file';f.accept='.json,application/json';f.onchange=async()=>{const q=f.files[0];if(q&&q.size<=2000000)window.draconiaImportCallback(await q.text());else if(q)window.draconiaImportCallback('');};f.click();})()", true)
	else:
		var dialog: FileDialog = FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.json ; Draconia save"])
		dialog.use_native_dialog = true
		add_child(dialog)
		dialog.file_selected.connect(func(path: String) -> void:
			_load_text(FileAccess.get_file_as_string(path))
			dialog.queue_free())
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered_ratio(0.7)

func _web_import_received(arguments: Array) -> void:
	if not arguments.is_empty():
		_load_text(str(arguments[0]))

func _load_text(text: String) -> void:
	var value: Variant = CampaignCore.deserialize(text)
	if not value is Dictionary:
		_toast("This is not a valid Draconia save. Your current progress is unchanged.", true)
		return
	state = value
	_close_modal()
	_clear_selection()
	_refresh(true)
	_save()
	_toast("Chronicle restored: day %d." % int(state.day))

func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"sound": sound_enabled}))
		file.close()
	_sound(392.0, 0.18)
	_apply_audio_setting()
	_show_menu()

func _apply_audio_setting() -> void:
	for player: AudioStreamPlayer in [music_player, ambience_player]:
		if not is_instance_valid(player) or player.stream == null:
			continue
		if sound_enabled:
			if not player.playing:
				player.play()
		else:
			player.stop()

func _sound(frequency: float, duration: float) -> void:
	if not sound_enabled or not is_instance_valid(audio_player):
		return
	var sample_rate: int = 22050
	var count: int = int(sample_rate * duration)
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(count * 2)
	for i: int in range(count):
		var t: float = float(i) / sample_rate
		var fade: float = pow(1.0 - float(i) / maxf(1, count), 2.0) * minf(1, t * 100)
		var sample: int = int((sin(TAU * frequency * t) + 0.25 * sin(TAU * frequency * 2 * t)) * fade * 10000)
		samples.encode_s16(i * 2, sample)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = samples
	audio_player.stream = stream
	audio_player.play()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if is_instance_valid(battle):
		return
	var key: InputEventKey = event
	if key.keycode == KEY_ESCAPE:
		if is_instance_valid(modal_layer):
			_close_modal()
		elif selection.visible:
			_clear_selection()
		elif not is_instance_valid(title_layer):
			_show_menu()
	elif key.keycode == KEY_S and (key.ctrl_pressed or key.meta_pressed):
		_manual_save()
	elif not is_instance_valid(modal_layer) and not is_instance_valid(title_layer):
		match key.keycode:
			KEY_E: _end_day()
			KEY_H: world.center_hero()
			KEY_G: _toggle_grid()
			KEY_J: _show_journal()
			KEY_T: _nearest_town()
			KEY_PLUS, KEY_EQUAL: world.change_zoom(1.15)
			KEY_MINUS: world.change_zoom(1.0 / 1.15)
			KEY_LEFT: world.camera.x -= 80 / world.zoom
			KEY_RIGHT: world.camera.x += 80 / world.zoom
			KEY_UP: world.camera.y -= 80 / world.zoom
			KEY_DOWN: world.camera.y += 80 / world.zoom
	get_viewport().set_input_as_handled()

func _show_help() -> void:
	var box: VBoxContainer = _modal("An Oathkeeper’s Guide", 780, 720)
	for section: Array in [["1 · Prepare the host", "Visit Cetatea Zorilor next to Ileana. Recruit troops, build the barracks or council, and preserve some gold for reinforcements. You may construct one building in each town per day."], ["2 · Follow the roads", "Click a map tile to inspect a route; click it again or use the travel button to go there. Long journeys move as far as today’s allowance permits. Drag to pan, use the wheel to zoom, and H to find Ileana. Read the ancestral waystone to reveal the oath sites."], ["3 · Make the land your ally", "Collect resources and claim mines for daily income. Town recruits replenish every seven days. Restore the woodland oath to welcome the Iele into a sacred grove. Captured towns provide income and recruitment."], ["4 · Choose when to fight", "Three daylight turns alternate with two night turns. Daylight protects your army. Night strengthens the enemy, but victory yields 25% more gold and experience. Each restored oath permanently reduces corruption and weakens the final garrison."], ["5 · Command the battle", "Select a reachable hex to move. Click an enemy to attack, or use the target list. Archers fire from range; adjacent foes block shooting. Wait acts later in the round; Defend raises defense. Cast one hero spell each round. Heal repairs surviving units without bringing back the fallen. Auto battle is optional."], ["6 · Fulfil the chronicle", "Restore all three guarded oaths to unseal Cetatea Nopții. Level up Ileana and choose skills, then confront the Balaur host. Defeat returns you home with a recovery penalty, so the chronicle remains playable. Autosave preserves each completed action; export a save for a portable backup."]]:
		box.add_child(DraconiaTheme.heading(str(section[0]), 18))
		box.add_child(DraconiaTheme.body(str(section[1]), 15))
	box.add_child(DraconiaTheme.body("Keys: E end day · H find hero · G grid · T settlements · J chronicle · Esc back · Ctrl/Cmd+S save. Combat shortcuts are shown on its buttons.", 13, DraconiaTheme.MUTED))

func _show_journal() -> void:
	var box: VBoxContainer = _modal("The Chronicle of Ileana", 760, 680)
	_illustration(box, 5, 145)
	box.add_child(DraconiaTheme.body("%d battles won  ·  %d troops recruited  ·  %d mines claimed  ·  %d recoveries" % [int(state.stats.battlesWon), int(state.stats.unitsRecruited), int(state.stats.minesClaimed), int(state.stats.defeats)], 13, DraconiaTheme.MUTED))
	for i: int in range(state.log.size() - 1, -1, -1):
		var entry: Dictionary = state.log[i]
		box.add_child(DraconiaTheme.heading("DAY %d" % int(entry.day), 12))
		box.add_child(DraconiaTheme.body(str(entry.get("text", entry.get("message", ""))), 14))
		box.add_child(HSeparator.new())

func _show_spells() -> void:
	var box: VBoxContainer = _modal("The Solomonar’s Grimoire", 780, 720)
	_illustration(box, 4, 205)
	box.add_child(DraconiaTheme.body("Ileana commands %d / %d mana and %d spell power. Cast once per battle round, without spending a troop action." % [int(state.hero.mana), int(state.hero.maxMana), int(state.hero.power)]))
	box.add_child(DraconiaTheme.heading("Săgeata Focului", 23))
	box.add_child(DraconiaTheme.body("Oathfire · 5 mana. Deal 20 + 15 × spell power damage to a chosen enemy stack. Use it to remove dangerous ranged enemies before they act."))
	box.add_child(DraconiaTheme.heading("Descântec de Vindecare", 23))
	box.add_child(DraconiaTheme.body("Mend · 4 mana. Restore up to 30 + 10 × spell power health to a surviving friendly stack. Fallen creatures remain fallen; cast before a damaged stack loses its last wounded fighter."))
	box.add_child(DraconiaTheme.heading("Rest and renewal", 20))
	box.add_child(DraconiaTheme.body("Ending a day restores 4 mana. A restored oath replenishes all mana. Resting beside a town with a Solomonar tower also restores the full reserve."))

func _show_skills() -> void:
	var box: VBoxContainer = _modal("Ileana’s Path", 650, 540)
	box.add_child(DraconiaTheme.body("%d skill choices available. Each skill has three ranks." % int(state.hero.skillPoints)))
	for skill: Dictionary in CampaignCore.HERO_SKILLS:
		var rank: int = int(state.hero.skills.get(str(skill.id), 0))
		box.add_child(DraconiaTheme.heading("%s  ·  %d / %d" % [str(skill.name), rank, int(skill.maxRank)], 21))
		box.add_child(DraconiaTheme.body(str(skill.description)))
		var button: Button = DraconiaTheme.button("Learn " + str(skill.name), _learn_skill.bind(str(skill.id)))
		button.disabled = int(state.hero.skillPoints) <= 0 or rank >= int(skill.maxRank)
		box.add_child(button)

func _learn_skill(skill_id: String) -> void:
	var result: Dictionary = CampaignCore.choose_hero_skill(state, skill_id)
	_refresh()
	_save()
	_show_skills()
	_toast(str(result.message), not bool(result.ok))

func _show_unit(kind: String, count: int) -> void:
	var unit: Dictionary = CampaignCore.UNITS[kind]
	var box: VBoxContainer = _modal(str(unit.name), 580, 480)
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = DraconiaArt.portrait(kind)
	portrait.custom_minimum_size = Vector2(180, 160)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(portrait)
	box.add_child(DraconiaTheme.body("%d in this company\n\nAttack %d · Defense %d · Health %d\nDamage %d–%d per creature · Speed %d\n%s\nRecruitment cost: %d gold" % [count, int(unit.attack), int(unit.defense), int(unit.hp), int(unit.minDamage), int(unit.maxDamage), int(unit.speed), "%d ranged shots per battle" % int(unit.shots) if int(unit.shots) > 0 else ("Flying movement" if bool(unit.get("flying", false)) else "Melee fighter"), int(unit.cost)], 16))

func _object_by_id(id: String) -> Dictionary:
	for obj: Dictionary in state.world.objects:
		if str(obj.id) == id:
			return obj
	return {}

func _illustration(parent: Node, index: int, height: float = 176.0) -> void:
	var art: Texture2D = DraconiaArt.vignette(index)
	if art == null:
		return
	var frame: PanelContainer = _panel(parent, 9)
	var picture: TextureRect = TextureRect.new()
	picture.texture = art
	picture.custom_minimum_size = Vector2(0, height)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(picture)

func _nearest_town() -> void:
	for obj: Dictionary in state.world.objects:
		if str(obj.type) == "town" and str(obj.owner) == "player" and maxi(absi(int(obj.x) - int(state.hero.x)), absi(int(obj.y) - int(state.hero.y))) <= 1:
			_show_town(str(obj.id))
			return
	var box: VBoxContainer = _modal("Settlements of Draconia", 640, 490)
	box.add_child(DraconiaTheme.body("Ileana must visit a settlement to recruit or construct. Select a known settlement to find it on the map."))
	for obj: Dictionary in state.world.objects:
		if str(obj.type) == "town" and bool(state.revealed[int(obj.y)][int(obj.x)]):
			box.add_child(DraconiaTheme.heading(str(obj.name), 21))
			box.add_child(DraconiaTheme.body("Your settlement" if str(obj.owner) == "player" else "Held by the night host", 14))
			box.add_child(DraconiaTheme.button("Locate on map", _locate.bind(int(obj.x), int(obj.y))))

func _locate(x: int, y: int) -> void:
	_close_modal()
	world.focus_tile(x, y)
	_select_destination(x, y)

func _show_town(id: String) -> void:
	var town: Dictionary = state.towns.get(id, {})
	var location: Dictionary = _object_by_id(id)
	if town.is_empty() or location.is_empty():
		_toast("This settlement is unavailable.", true)
		return
	var box: VBoxContainer = _modal(str(location.name), 1040, 790)
	var panorama: TextureRect = TextureRect.new()
	panorama.texture = DraconiaArt.vignette(2 if _town_tab == 0 else 1)
	if panorama.texture == null:
		panorama.texture = DraconiaArt.texture("assets/generated/landscape.png")
	panorama.custom_minimum_size = Vector2(0, 210)
	panorama.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panorama.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(panorama)
	box.add_child(DraconiaTheme.body("Treasury: %d gold · %d timber · %d ore     |     %s" % [int(state.resources.gold), int(state.resources.wood), int(state.resources.ore), "A building was completed today" if int(town.builtDay) == int(state.day) else "One construction available today"], 13))
	var tabs: HBoxContainer = HBoxContainer.new()
	box.add_child(tabs)
	tabs.add_child(DraconiaTheme.button("Recruit the host", func() -> void: _town_tab = 0; _show_town(id)))
	tabs.add_child(DraconiaTheme.button("Develop the settlement", func() -> void: _town_tab = 1; _show_town(id)))
	if _town_tab == 0:
		var grid: GridContainer = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		box.add_child(grid)
		for kind: String in CampaignCore.RECRUITABLE:
			var unit: Dictionary = CampaignCore.UNITS[kind]
			var card: PanelContainer = _paper_panel(grid, 12)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.custom_minimum_size.x = 255
			var column: VBoxContainer = VBoxContainer.new()
			card.add_child(column)
			column.add_child(DraconiaTheme.heading(str(unit.plural), 19))
			var picture: TextureRect = TextureRect.new()
			picture.texture = DraconiaArt.portrait(kind)
			picture.custom_minimum_size = Vector2(0, 118)
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			column.add_child(picture)
			var available: int = int(town.stock.get(kind, 0))
			column.add_child(DraconiaTheme.body("%d gold each · %d available\nAttack %d · Defense %d · HP %d" % [int(unit.cost), available, int(unit.attack), int(unit.defense), int(unit.hp)], 13))
			var unlocked: bool = (not CampaignCore.GATED_UNITS.has(kind) or town.buildings.has(CampaignCore.GATED_UNITS.get(kind))) and (kind != "griffin" or state.wards.has("dawnwell"))
			if not unlocked:
				column.add_child(DraconiaTheme.body("Requires its dwelling" + (" and woodland oath" if kind == "griffin" else ""), 12, Color("c4a17e")))
			var quantity: SpinBox = SpinBox.new()
			quantity.min_value = 1
			quantity.max_value = maxi(1, mini(available, int(int(state.resources.gold) / int(unit.cost))))
			quantity.value = quantity.max_value
			quantity.step = 1
			quantity.editable = unlocked and available > 0
			column.add_child(quantity)
			var recruit_button: Button = DraconiaTheme.button("Recruit", _recruit.bind(id, kind, quantity))
			recruit_button.disabled = not unlocked or available == 0 or int(state.resources.gold) < int(unit.cost)
			column.add_child(recruit_button)
		box.add_child(DraconiaTheme.body("New recruits arrive on days 8, 15, 22… Stone walls increase weekly growth by 50%.", 12, DraconiaTheme.MUTED))
	else:
		for building: Dictionary in CampaignCore.BUILDINGS:
			var line: PanelContainer = _paper_panel(box, 14)
			var row: HBoxContainer = HBoxContainer.new()
			line.add_child(row)
			var craft: TextureRect = TextureRect.new()
			craft.texture = DraconiaArt.vignette(4 if str(building.id) == "mageTower" else 3 if str(building.id) == "griffinRoost" else 1)
			craft.custom_minimum_size = Vector2(118, 79)
			craft.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			craft.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			row.add_child(craft)
			var description: VBoxContainer = VBoxContainer.new()
			description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(description)
			description.add_child(DraconiaTheme.heading(str(building.name), 19))
			description.add_child(DraconiaTheme.body(str(building.description), 13))
			var costs: Array[String] = []
			var can_afford: bool = true
			for key: String in building.cost:
				costs.append("%d %s" % [int(building.cost[key]), key])
				can_afford = can_afford and int(state.resources.get(key, 0)) >= int(building.cost[key])
			description.add_child(DraconiaTheme.body(" · ".join(costs), 12, DraconiaTheme.MUTED))
			var present: bool = town.buildings.has(str(building.id))
			var requirements: bool = true
			for required: String in building.requires:
				requirements = requirements and town.buildings.has(required)
			var construct: Button = DraconiaTheme.button("Completed" if present else "Construct", _construct.bind(id, str(building.id)), Vector2(125, 42))
			construct.disabled = present or not requirements or not can_afford or int(town.builtDay) == int(state.day)
			if not requirements:
				construct.tooltip_text = "Build the prerequisites first: " + ", ".join(building.requires)
			row.add_child(construct)

func _recruit(town_id: String, kind: String, amount: SpinBox) -> void:
	var result: Dictionary = CampaignCore.recruit(state, town_id, kind, int(amount.value))
	_refresh()
	_save()
	_show_town(town_id)
	_toast(str(result.message), not bool(result.ok))
	_sound(523.25, 0.12)

func _construct(town_id: String, building_id: String) -> void:
	var result: Dictionary = CampaignCore.build(state, town_id, building_id)
	_refresh()
	_save()
	_show_town(town_id)
	_toast(str(result.message), not bool(result.ok))

func _army_value(army: Array) -> int:
	var value: int = 0
	for stack: Dictionary in army:
		value += int(stack.count) * int(CampaignCore.UNITS[str(stack.type)].cost)
	return value

func _show_encounter(object: Dictionary) -> void:
	var box: VBoxContainer = _modal(str(object.name), 720, 570)
	_illustration(box, 3 if str(object.id) == "dawnwell" else 4 if bool(object.get("final", false)) else 2, 148)
	box.add_child(DraconiaTheme.body(str(object.description), 17))
	box.add_child(DraconiaTheme.body(str(CampaignCore.get_battle_context(state, object).description), 14, DraconiaTheme.MUTED))
	var ratio: float = float(_army_value(object.enemies)) / maxf(1.0, float(_army_value(state.army)))
	var assessment: String = "Favourable" if ratio < 0.55 else ("An even contest" if ratio < 1.15 else ("A dangerous host" if ratio < 1.8 else "Overwhelming — reinforce first"))
	box.add_child(DraconiaTheme.heading(assessment, 21, Color("b4c895") if ratio < 1.15 else Color("e2a47c")))
	box.add_child(DraconiaTheme.body("Army-value estimate; terrain, spells and tactics can change the outcome.", 12, DraconiaTheme.MUTED))
	var enemies: HBoxContainer = HBoxContainer.new()
	box.add_child(enemies)
	for stack: Dictionary in object.enemies:
		var column: VBoxContainer = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		enemies.add_child(column)
		var portrait: TextureRect = TextureRect.new()
		portrait.texture = DraconiaArt.portrait(str(stack.type))
		portrait.custom_minimum_size = Vector2(100, 110)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		column.add_child(portrait)
		var label: Label = DraconiaTheme.body("%d %s" % [int(stack.count), str(CampaignCore.UNITS[str(stack.type)].plural)], 15)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
	box.add_child(DraconiaTheme.button("LEAD THE HOST INTO BATTLE", _start_battle.bind(str(object.id)), Vector2(0, 48)))
	box.add_child(DraconiaTheme.button("Withdraw from this encounter", _close_modal))

func _start_battle(object_id: String) -> void:
	if is_instance_valid(battle):
		return
	var gate: Dictionary = CampaignCore.interact(state, object_id)
	if not bool(gate.ok) or str(gate.get("event", "")) != "battle":
		_toast(str(gate.message), true)
		return
	var object: Dictionary = gate.object
	_close_modal()
	_save()
	busy = true
	end_button.disabled = true
	battle = BattleScreen.new()
	battle.name = "BattleScreen"
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(battle)
	battle.finished.connect(_battle_finished.bind(object_id))
	battle.setup(state.hero.duplicate(true), state.army.duplicate(true), object.enemies.duplicate(true), CampaignCore.get_battle_context(state, object), str(object.name))

func _battle_finished(result: Dictionary, object_id: String) -> void:
	var outcome: Dictionary = CampaignCore.resolve_battle(state, object_id, result)
	if is_instance_valid(battle):
		remove_child(battle)
		battle.queue_free()
	battle = null
	busy = false
	_refresh(true)
	_save()
	_toast(str(outcome.message), not bool(outcome.ok))
	if bool(state.victory):
		_show_victory()
	elif int(state.hero.skillPoints) > 0:
		_show_skills()

func _show_victory() -> void:
	var box: VBoxContainer = _modal("Draconia remembers your oath.", 790, 660)
	var scene: TextureRect = TextureRect.new()
	scene.texture = DraconiaArt.texture("assets/generated/landscape.png")
	scene.custom_minimum_size = Vector2(0, 215)
	scene.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	box.add_child(scene)
	box.add_child(DraconiaTheme.body("The three oaths are whole again. The iele return to their groves, lamps burn in the villages, and the roads belong to the living. Ileana’s banner rises over Cetatea Nopții.\n\nYour chronicle is complete. You may continue exploring, export this victorious save, or begin a new chronicle.", 18))
	box.add_child(DraconiaTheme.heading("%d days · Level %d · %d victories" % [int(state.day), int(state.hero.level), int(state.stats.battlesWon)], 22))
	box.add_child(DraconiaTheme.button("Keep exploring Draconia", _close_modal))
	box.add_child(DraconiaTheme.button("Export the victorious chronicle", _export_save))

func _show_credits() -> void:
	var box: VBoxContainer = _modal("The Making of Draconia", 760, 650)
	box.add_child(DraconiaTheme.heading("An original Romanian fantasy chronicle", 21))
	box.add_child(DraconiaTheme.body("Design and native Godot implementation created for this project. The landscape, battlefield, map objects, terrain textures, parchment, and Ileana portrait were generated specifically for Draconia. The world is fictional and draws on Romanian folklore; it is not a historical reconstruction."))
	box.add_child(DraconiaTheme.heading("Animated characters", 21))
	box.add_child(DraconiaTheme.body("Animation art: Clint Bellanger, Justin Nichol and the Flare contributors — CC BY-SA 3.0. Werewolf model, textures and animations: br-n518 — CC0. Exact authors, source URLs, source files, licenses, and the animation manifest are included in assets/animated/ and the source project. The animation sheets contain genuine frame sequences."))
	box.add_child(DraconiaTheme.heading("Technology & typography", 21))
	box.add_child(DraconiaTheme.body("Godot Engine 4.7.2, MIT license. Cinzel typeface by Natanael Gama, SIL Open Font License. Music: The Bard’s Tale by RandomMind — CC0. Bird ambience: Chris Castiglione (alienistcog) via Flare — CC0. Unit and map rules are original implementations. No Heroes III executable, artwork, music, or Manor Lords game asset is distributed in this game."))
	box.add_child(DraconiaTheme.heading("This build", 21))
	box.add_child(DraconiaTheme.body("One complete single-player campaign, three settlements, ten creature types, ten guarded encounters, three oaths, tactical combat, town construction, recruitment, hero growth and saves. This is the first playable release of Draconia. Additional factions, heroes, scenarios and deeper content remain part of its development target."))
	box.add_child(DraconiaTheme.button("Godot Engine licenses", func() -> void: OS.shell_open("https://godotengine.org/license/")))
