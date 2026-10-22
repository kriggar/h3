class_name BattleScreen
extends Control
## Native 3D tactical presentation. Shared BattleRules remain authoritative.

signal finished(result: Dictionary)

const FIELD_SIZE: Vector2 = Vector2(1120, 660)
const HEX_RADIUS: float = 33.0
const STEP_X: float = 57.15767665
const STEP_Y: float = 49.5
const ORIGIN: Vector2 = Vector2(77, 80)
const INK: Color = Color("eee1c4")
const MUTED: Color = Color("b6aa8d")
const BRONZE: Color = Color("c3a46c")
const PAPER: Color = Color("241f19")
const FIELD_SPACING: float = 2.0

class BattleField extends Control:
	var owner_screen: Control
	func _draw() -> void:
		if is_instance_valid(owner_screen):
			owner_screen._draw_field(self)
	func _gui_input(event: InputEvent) -> void:
		if is_instance_valid(owner_screen):
			owner_screen._field_input(self, event)

var _hero: Dictionary = {}
var _context: Dictionary = {}
var _stacks: Array = []
var _queue: Array = []
var _terrain: Dictionary = {}
var _active: Dictionary = {}
var _reachable: Dictionary = {}
var _round: int = 1
var _mana: int = 0
var _spell_round: int = 0
var _selected_spell: String = ""
var _busy: bool = false
var _auto: bool = false
var _done: bool = false
var _sent: bool = false
var _retreat_confirm: bool = false
var _hover: Vector2i = Vector2i(-1, -1)
var _clock: float = 0.0
var _moving: Dictionary = {}
var _effects: Array = []
var _logs: Array = []
var _textures: Dictionary = {}
var _animations: Dictionary = {}
var _pending_result: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _board: BattleField
var _order_box: HBoxContainer
var _active_label: RichTextLabel
var _target_box: VBoxContainer
var _log_label: RichTextLabel
var _hint_label: Label
var _mana_label: Label
var _round_label: Label
var _buttons: Dictionary = {}
var _ai_timer: Timer
var _help: AcceptDialog
var _heading_font: Font
var _result_layer: Control
var _field_viewport: SubViewport
var _arena: Node3D
var _field_camera: Camera3D
var _unit_models: Dictionary = {}
var _model_parts: Dictionary = {}
var _camera_yaw: float = 0.0
var _camera_zoom: float = 1.0
var _orbiting: bool = false
var _native_size: Vector2i = Vector2i.ZERO
var _location_name: String = ""

func setup(hero: Dictionary, army: Array, enemies: Array, context: Dictionary, location_name: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_hero = hero.duplicate(true)
	_context = context.duplicate(true)
	_location_name = location_name
	theme = DraconiaTheme.make_theme()
	_stacks = BattleRules.make_stacks(army, "player") + BattleRules.make_stacks(enemies, "enemy")
	_terrain = BattleRules.obstacles()
	_mana = maxi(0, int(hero.get("mana", 0)))
	_rng.randomize()
	if ResourceLoader.exists("res://assets/cinzel.ttf"):
		_heading_font = load("res://assets/cinzel.ttf") as Font
	var manifest_path: String = "res://assets/animated/animations.json"
	if FileAccess.file_exists(manifest_path):
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if manifest is Dictionary:
			_animations = manifest.get("units", {})
	_build_ui(location_name)
	_build_3d_field()
	_queue = BattleRules.round_order(_stacks)
	_log("Your oath binds this company. Hold the field.", "round")
	if not str(context.get("description", "")).is_empty():
		_log(str(context.description), "phase")
	_activate()
	set_process(true)
	set_process_unhandled_key_input(true)

func get_state() -> Dictionary:
	return {"round": _round, "mana": _mana, "active": str(_active.get("id", "")), "stacks": _stacks.duplicate(true), "queue": _queue.duplicate(), "auto": _auto, "finished": _done, "busy": _busy, "context": _context.duplicate(true), "selectedSpell": _selected_spell, "result": _pending_result.duplicate(true)}

func _texture(path: String) -> Texture2D:
	var resource_path: String = path if path.begins_with("res://") else "res://" + path
	if _textures.has(resource_path):
		return _textures[resource_path] as Texture2D
	var texture: Texture2D = null
	if ResourceLoader.exists(resource_path):
		texture = load(resource_path) as Texture2D
	_textures[resource_path] = texture
	return texture

func _style(color: Color = PAPER, border: Color = Color("a18a60"), margin: int = 12) -> StyleBox:
	if margin >= 8:
		var frame: DraconiaFrame = DraconiaTheme.parchment(margin) as DraconiaFrame
		frame.fill = color
		frame.edge = border
		frame.ornaments = margin >= 12
		return frame
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

func _label(text: String, font_size: int = 16, color: Color = INK, heading: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", maxi(14, font_size))
	if heading and _heading_font != null:
		label.add_theme_font_override("font", _heading_font)
	return label

func _button(text: String, command_name: String, hint: String = "") -> Button:
	var button: Button = Button.new()
	button.text = text
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(100, 45)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", Color("f3e8cc"))
	button.add_theme_color_override("font_disabled_color", Color("9d927c"))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _style(Color("393026"), Color("8b734c"), 10))
	button.add_theme_stylebox_override("hover", _style(Color("4b3d2b"), Color("bc9a5e"), 10))
	button.add_theme_stylebox_override("pressed", _style(Color("675033"), Color("c3a46c"), 10))
	button.add_theme_stylebox_override("disabled", _style(Color("28251f"), Color("494234"), 10))
	button.pressed.connect(_command.bind(command_name))
	_buttons[command_name] = button
	return button

func _build_ui(location_name: String) -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("171714")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var surround: Panel = Panel.new()
	surround.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surround.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surround.add_theme_stylebox_override("panel", DraconiaTheme.parchment(0))
	add_child(surround)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var root_box: VBoxContainer = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 9)
	margin.add_child(root_box)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	root_box.add_child(header)
	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)
	title_box.add_child(_label(str(ProjectSettings.get_setting("application/config/name", "Draconia — Oaths of the Carpathians")).to_upper(), 11, MUTED, true))
	title_box.add_child(_label(location_name, 26, INK, true))
	var phase_box: VBoxContainer = VBoxContainer.new()
	phase_box.add_child(_label(str(_context.get("label", "Daylight")), 18, Color("d4b77b"), true))
	phase_box.add_child(_label("%d / 3 wards · corruption %d" % [int(_context.get("wards", 0)), int(_context.get("corruption", 60))], 11, MUTED))
	phase_box.tooltip_text = str(_context.get("description", ""))
	header.add_child(phase_box)
	_round_label = _label("ROUND 01", 20, BRONZE, true)
	header.add_child(_round_label)
	var help_button: Button = _button("?", "help", "Battle instructions")
	help_button.custom_minimum_size = Vector2(36, 36)
	header.add_child(help_button)
	var phase_note: Label = _label(str(_context.get("description", "Choose your ground, and protect the company.")), 12, MUTED)
	phase_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(phase_note)
	var order_panel: PanelContainer = PanelContainer.new()
	order_panel.add_theme_stylebox_override("panel", _style(Color("211e18"), Color("706044"), 5))
	root_box.add_child(order_panel)
	var order_row: HBoxContainer = HBoxContainer.new()
	order_row.add_theme_constant_override("separation", 12)
	order_panel.add_child(order_row)
	order_row.add_child(_label("TURN ORDER", 10, MUTED, true))
	_order_box = HBoxContainer.new()
	_order_box.add_theme_constant_override("separation", 4)
	_order_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_row.add_child(_order_box)
	var main_row: HBoxContainer = HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 12)
	root_box.add_child(main_row)
	var field_panel: PanelContainer = PanelContainer.new()
	field_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field_panel.add_theme_stylebox_override("panel", _style(Color("151c18"), Color("a48751"), 2))
	main_row.add_child(field_panel)
	_board = BattleField.new()
	_board.owner_screen = self
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.custom_minimum_size = Vector2(570, 340)
	_board.clip_contents = true
	_board.focus_mode = Control.FOCUS_ALL
	_board.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	field_panel.add_child(_board)
	var side_panel: PanelContainer = PanelContainer.new()
	side_panel.custom_minimum_size.x = 224
	side_panel.add_theme_stylebox_override("panel", _style(Color("27231c"), Color("846e48"), 12))
	main_row.add_child(side_panel)
	var side_box: VBoxContainer = VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 8)
	side_panel.add_child(side_box)
	_active_label = RichTextLabel.new()
	_active_label.bbcode_enabled = true
	_active_label.fit_content = true
	_active_label.scroll_active = false
	_active_label.add_theme_color_override("default_color", INK)
	_active_label.add_theme_font_size_override("normal_font_size", 17)
	_active_label.custom_minimum_size = Vector2(196, 104)
	side_box.add_child(_active_label)
	side_box.add_child(_label("OPPOSING COMPANY", 11, MUTED, true))
	_target_box = VBoxContainer.new()
	_target_box.add_theme_constant_override("separation", 4)
	side_box.add_child(_target_box)
	side_box.add_child(_label("FIELD CHRONICLE", 11, MUTED, true))
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.custom_minimum_size = Vector2(196, 80)
	_log_label.add_theme_color_override("default_color", MUTED)
	_log_label.add_theme_font_size_override("normal_font_size", 15)
	side_box.add_child(_log_label)
	_hint_label = _label("Choose a marked hex to move, or an enemy to attack.", 13, INK)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size.y = 34
	root_box.add_child(_hint_label)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 7)
	root_box.add_child(footer)
	_mana_label = _label("", 14, BRONZE, true)
	_mana_label.custom_minimum_size.x = 130
	_mana_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_mana_label)
	footer.add_child(_button("Oathfire · 5", "arrow", "Deal 20 + 15 × spell power damage. One spell per round."))
	footer.add_child(_button("Mend · 4", "heal", "Heal wounds on living creatures. Does not resurrect casualties."))
	footer.add_child(_button("Wait [W]", "wait", "Move this stack to the end of the round; once per stack each round."))
	footer.add_child(_button("Defend [D]", "defend", "Gain 20% base defence until this stack next acts."))
	footer.add_child(_button("Auto battle [A]", "auto", "Let your captains command the company."))
	footer.add_child(_button("Withdraw", "retreat", "Withdraw your surviving troops to the adventure map."))
	_ai_timer = Timer.new()
	_ai_timer.one_shot = true
	_ai_timer.timeout.connect(_play_ai)
	add_child(_ai_timer)
	_help = AcceptDialog.new()
	_help.title = "Command the company"
	_help.dialog_text = "The highlighted stack acts next. Marked hexes are reachable. Click an enemy to attack; melee troops move into reach when possible.\n\nRanged troops cannot shoot while adjacent to an enemy. Long shots beyond 10 hexes deal half damage. A defending stack retaliates once each round.\n\nWait acts later in the round. Defend adds 20% base defence. Your voivode may cast one spell per round without spending the troop's action.\n\nDaylight and restored wards protect your troops. Unbroken corruption strengthens the enemy at night. The active modifiers appear above the field and in troop statistics.\n\nW: wait  ·  D: defend  ·  A: auto battle\nArrow keys: select hex  ·  Enter: act  ·  Escape: cancel spell"
	_help.min_size = Vector2i(560, 380)
	_help.visibility_changed.connect(_schedule_ai)
	add_child(_help)

func _process(delta: float) -> void:
	_clock += delta
	if is_instance_valid(_board):
		_update_3d_field()
		_board.queue_redraw()
	for index: int in range(_effects.size() - 1, -1, -1):
		var effect: Dictionary = _effects[index]
		if _clock - float(effect.started) > float(effect.duration):
			_effects.remove_at(index)

func _world_point(flat_point: Vector2) -> Vector3:
	var middle: Vector2 = _center(Vector2i(8, 5))
	var x: float = (flat_point.x - middle.x) / STEP_X * FIELD_SPACING
	var z: float = (flat_point.y - middle.y) / STEP_Y * FIELD_SPACING * 0.8660254
	return Vector3(x, _ground_height(x, z), z)

func _ground_height(x: float, z: float) -> float:
	var edge: float = clampf(maxf(absf(x) - 17.0, absf(z) - 10.0), 0.0, 30.0)
	return sin(x * 0.37) * cos(z * 0.29) * 0.09 + sin(x * 0.16 + z * 0.23) * 0.05 + edge * edge * 0.004

func _build_3d_field() -> void:
	_field_viewport = SubViewport.new()
	_field_viewport.name = "TacticalWorld3D"
	_field_viewport.own_world_3d = true
	_field_viewport.size = Vector2i(960, 580)
	_field_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_field_viewport.msaa_3d = Viewport.MSAA_2X
	_board.add_child(_field_viewport)
	_arena = Node3D.new()
	_arena.name = "CarpathianBattlefield"
	_field_viewport.add_child(_arena)
	var night: bool = str(_context.get("phase", "day")) == "night"
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("202c35") if night else Color("657565")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("9aadc4") if night else Color("c5c9c1")
	environment.ambient_light_energy = 0.46 if night else 0.68
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = false
	environment.fog_light_color = Color("3c4954") if night else Color("8d9a8d")
	environment.fog_density = 0.006 if night else 0.0025
	var atmosphere: WorldEnvironment = WorldEnvironment.new()
	atmosphere.environment = environment
	_arena.add_child(atmosphere)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-53, -32, 0)
	sun.light_color = Color("9eb8dd") if night else Color("f2f0e6")
	sun.light_energy = 0.60 if night else 0.72
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.58
	sun.directional_shadow_max_distance = 85.0
	sun.shadow_bias = 0.035
	_arena.add_child(sun)
	_field_camera = Camera3D.new()
	_field_camera.name = "TacticalCamera"
	_field_camera.fov = 42.0
	_field_camera.near = 0.1
	_field_camera.far = 160.0
	_field_camera.current = true
	_arena.add_child(_field_camera)
	_make_ground()
	_make_field_details()
	for stack: Dictionary in _stacks:
		_make_3d_company(stack)
	_update_3d_field()

func _make_ground() -> void:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in range(60):
		for col: int in range(80):
			var x: float = float(col) * 1.5 - 60.0
			var z: float = float(row) * 1.5 - 45.0
			for corner: Vector2 in [Vector2(x, z), Vector2(x, z + 1.5), Vector2(x + 1.5, z), Vector2(x + 1.5, z), Vector2(x, z + 1.5), Vector2(x + 1.5, z + 1.5)]:
				var normal: Vector3 = Vector3(_ground_height(corner.x - 0.1, corner.y) - _ground_height(corner.x + 0.1, corner.y), 0.2, _ground_height(corner.x, corner.y - 0.1) - _ground_height(corner.x, corner.y + 0.1)).normalized()
				surface.set_normal(normal)
				surface.set_uv(corner / 4.0)
				var shade: float = 0.83 + sin(corner.x * 0.4 + corner.y * 0.18) * 0.06
				surface.set_color(Color(shade, shade, shade * 0.97))
				surface.add_vertex(Vector3(corner.x, _ground_height(corner.x, corner.y), corner.y))
	surface.generate_tangents()
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "TexturedHeightfield"
	ground.mesh = surface.commit()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("b2b8a6")
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var diffuse: Texture2D = _texture("assets/models/materials/forrest_ground_01/albedo.jpg")
	if diffuse != null:
		material.albedo_texture = diffuse
		material.normal_enabled = true
		material.normal_texture = _texture("assets/models/materials/forrest_ground_01/normal.jpg")
		material.normal_scale = 0.75
		material.roughness_texture = _texture("assets/models/materials/forrest_ground_01/roughness.jpg")
	else:
		material.albedo_color = Color("535743")
	ground.material_override = material
	var soil: Texture2D = _texture("assets/models/materials/brown_mud_leaves_01/albedo.jpg")
	if diffuse != null and soil != null:
		var shader: Shader = Shader.new()
		shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D ground_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D soil_normal : hint_normal, filter_linear_mipmap, repeat_enable;
varying vec3 terrain_point;
void vertex() { terrain_point = VERTEX; }
void fragment() {
 vec3 woodland = texture(ground_albedo, UV).rgb;
 vec3 trodden = texture(soil_albedo, UV * 0.85).rgb;
 float bend = terrain_point.z + sin(terrain_point.x * 0.13) * 1.6;
 float edge_noise = texture(ground_albedo, UV * 0.27).g * 2.6;
 float clearing = 1.0 - smoothstep(1.0, 3.8, abs(bend) + edge_noise);
 vec3 earth = mix(woodland, trodden, 0.28 + clearing * 0.62);
 ALBEDO = mix(earth, vec3(0.21, 0.19, 0.125), 0.18) * vec3(1.12, 1.10, 0.98);
 NORMAL_MAP = mix(texture(ground_normal, UV).rgb, texture(soil_normal, UV * 0.85).rgb, clearing);
 NORMAL_MAP_DEPTH = 0.55;
 ROUGHNESS = 0.97;
 SPECULAR = 0.12;
}
"""
		var layered: ShaderMaterial = ShaderMaterial.new()
		layered.shader = shader
		layered.set_shader_parameter("ground_albedo", diffuse)
		layered.set_shader_parameter("soil_albedo", soil)
		layered.set_shader_parameter("ground_normal", material.normal_texture)
		layered.set_shader_parameter("soil_normal", _texture("assets/models/materials/brown_mud_leaves_01/normal.jpg"))
		ground.material_override = layered
	_arena.add_child(ground)

func _gather_mesh_parts(node: Node, parent_transform: Transform3D, output: Array) -> void:
	var transform_value: Transform3D = parent_transform
	if node is Node3D:
		transform_value = parent_transform * node.transform
	if node is MeshInstance3D and node.mesh != null:
		var materials: Array = []
		for index: int in range(node.mesh.get_surface_count()):
			materials.append(node.get_active_material(index))
		output.append({"mesh": node.mesh, "transform": transform_value, "materials": materials, "name": str(node.name)})
	for child: Node in node.get_children():
		_gather_mesh_parts(child, transform_value, output)

func _parts_for(path: String) -> Array:
	if _model_parts.has(path):
		return _model_parts[path]
	var result: Array = []
	if ResourceLoader.exists(path):
		var packed: PackedScene = load(path) as PackedScene
		if packed != null:
			var scene: Node = packed.instantiate()
			_gather_mesh_parts(scene, Transform3D.IDENTITY, result)
			scene.free()
	_model_parts[path] = result
	return result

func _place_scanned_model(path: String, variant: int, position_value: Vector3, target_height: float, angle: float = 0.0) -> Node3D:
	var parts: Array = _parts_for(path)
	if parts.is_empty():
		return null
	var part: Dictionary = parts[posmod(variant, parts.size())]
	var mesh: Mesh = part.mesh
	var mesh_transform: Transform3D = part.transform
	var bounds: AABB = mesh_transform * mesh.get_aabb()
	var scale_value: float = target_height / maxf(bounds.size.y, 0.01)
	var container: Node3D = Node3D.new()
	container.name = str(part.name)
	container.position = position_value
	container.rotation.y = angle
	var pivot: Node3D = Node3D.new()
	pivot.scale = Vector3.ONE * scale_value
	pivot.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_value
	container.add_child(pivot)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.transform = mesh_transform
	instance.lod_bias = 0.35
	for index: int in range(part.materials.size()):
		instance.set_surface_override_material(index, part.materials[index])
	pivot.add_child(instance)
	_arena.add_child(container)
	return container

func _make_field_details() -> void:
	# All decorative choices have their own RNG and never consume combat randomness.
	var decoration: RandomNumberGenerator = RandomNumberGenerator.new()
	decoration.seed = 80931
	var rock_path: String = "res://assets/models/rock_moss_set_02/rock_moss_set_02_1k.gltf"
	var tree_path: String = "res://assets/models/fir_sapling/fir_sapling_lod.glb"
	var fortress_backdrop: bool = _location_name.contains("Cetatea") or _location_name.contains("Mănăstirea")
	for hex: Vector2i in _terrain.keys():
		var position_value: Vector3 = _world_point(_center(hex))
		var rock: Node3D = _place_scanned_model(rock_path, decoration.randi_range(0, 6), position_value, decoration.randf_range(0.85, 1.35), decoration.randf_range(0, TAU))
		if rock == null:
			var fallback: MeshInstance3D = MeshInstance3D.new()
			var mesh: SphereMesh = SphereMesh.new()
			mesh.radius = 0.8
			mesh.height = 1.1
			mesh.radial_segments = 8
			mesh.rings = 5
			fallback.mesh = mesh
			fallback.position = position_value + Vector3(0, 0.35, 0)
			var stone: StandardMaterial3D = StandardMaterial3D.new()
			stone.albedo_color = Color("595e50")
			stone.roughness = 1.0
			fallback.material_override = stone
			_arena.add_child(fallback)
	for index: int in range(45):
		var x: float = -28.0 + float(index % 15) * 4.0 + decoration.randf_range(-1.3, 1.3)
		var z: float = -13.5 - float(index / 15) * 5.0 + decoration.randf_range(-1.6, 0)
		if fortress_backdrop and absf(x) < 18.0 and z > -21.0:
			continue
		var selected_tree: String = "res://assets/models/forest/broadleaf.glb" if index % 4 == 0 else tree_path
		_place_scanned_model(selected_tree, index, Vector3(x, _ground_height(x, z), z), decoration.randf_range(7.0, 11.5), decoration.randf_range(0, TAU))
	for side: float in [-1.0, 1.0]:
		for index: int in range(5):
			var x: float = side * decoration.randf_range(20.5, 24.0)
			var z: float = -10.0 + float(index) * 4.6
			_place_scanned_model(tree_path, index, Vector3(x, _ground_height(x, z), z), decoration.randf_range(5.8, 8.4), decoration.randf_range(0, TAU))
	for index: int in range(18):
		var x: float = decoration.randf_range(-26.0, 26.0)
		var z: float = decoration.randf_range(-19.0, -11.5) if index < 12 else decoration.randf_range(11.5, 16.0)
		_place_scanned_model(rock_path, index, Vector3(x, _ground_height(x, z), z), decoration.randf_range(0.5, 1.9), decoration.randf_range(0, TAU))
	if fortress_backdrop:
		var fort_path: String = "res://assets/models/modular_fort_01/modular_fort_01_1k.gltf"
		var fort_parts: Array = _parts_for(fort_path)
		for index: int in range(fort_parts.size()):
			var part_name: String = str(fort_parts[index].name)
			if part_name.ends_with("tower_round"):
				for x: float in [-12.5, 12.5]:
					_place_scanned_model(fort_path, index, Vector3(x, _ground_height(x, -13.0), -13.0), 5.8)
			elif part_name.ends_with("wall_thick_straight_01"):
				for x: float in [-7.0, 7.0]:
					_place_scanned_model(fort_path, index, Vector3(x, _ground_height(x, -13.0), -13.0), 4.5, PI * 0.5)
			elif part_name.ends_with("wall_thin_gate_01"):
				_place_scanned_model(fort_path, index, Vector3(0, _ground_height(0, -13.0), -13.0), 5.0, PI * 0.5)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null

func _make_3d_company(stack: Dictionary) -> void:
	var group: Node3D = Node3D.new()
	group.name = str(stack.id).replace("-", "_")
	_arena.add_child(group)
	_unit_models[str(stack.id)] = group
	var wolf_path: String = "res://assets/models/werewolf/werewolf.glb"
	if str(stack.type) == "wolf" and ResourceLoader.exists(wolf_path):
		var packed: PackedScene = load(wolf_path) as PackedScene
		if packed != null:
			var model: Node3D = packed.instantiate() as Node3D
			var parts: Array = []
			_gather_mesh_parts(model, Transform3D.IDENTITY, parts)
			var player: AnimationPlayer = _find_animation_player(model)
			if not parts.is_empty() and player != null and player.has_animation("idle"):
				var bounds: AABB = parts[0].transform * parts[0].mesh.get_aabb()
				for part: Dictionary in parts.slice(1):
					bounds = bounds.merge(part.transform * part.mesh.get_aabb())
				var factor: float = 3.2 / maxf(bounds.size.y, 0.1)
				var pivot: Node3D = Node3D.new()
				pivot.scale = Vector3.ONE * factor
				pivot.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
				group.add_child(pivot)
				pivot.add_child(model)
				group.rotation.y = PI * 0.5 if str(stack.side) == "player" else -PI * 0.5
				player.speed_scale = 0.0
				player.play("idle")
				group.set_meta("animation_player", player)
				return
			model.free()
	for index: int in range(1):
		var sprite: Sprite3D = Sprite3D.new()
		sprite.name = "Troop%d" % index
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = true
		sprite.double_sided = true
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.alpha_scissor_threshold = 0.25
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.region_enabled = true
		sprite.flip_h = str(stack.side) == "enemy"
		sprite.position = Vector3.ZERO
		group.add_child(sprite)

func _update_field_camera() -> void:
	if not is_instance_valid(_field_camera):
		return
	var aspect: float = float(_field_viewport.size.x) / maxf(float(_field_viewport.size.y), 1.0)
	var distance: float = maxf(29.5, 43.0 / maxf(aspect, 0.8)) * _camera_zoom
	var elevation: float = deg_to_rad(39.0)
	_field_camera.position = Vector3(sin(_camera_yaw) * cos(elevation), sin(elevation), cos(_camera_yaw) * cos(elevation)) * distance
	_field_camera.look_at(Vector3(0, 0, -0.5), Vector3.UP)

func _update_3d_field() -> void:
	if not is_instance_valid(_field_viewport):
		return
	var desired_size: Vector2i = Vector2i(maxi(2, roundi(_board.size.x)), maxi(2, roundi(_board.size.y)))
	if desired_size != _native_size:
		_native_size = desired_size
		_field_viewport.size = desired_size
		_update_field_camera()
	for stack: Dictionary in _stacks:
		var group: Node3D = _unit_models.get(str(stack.id)) as Node3D
		if group == null:
			continue
		group.visible = int(stack.count) > 0 or _death_visible(stack)
		if not group.visible:
			continue
		var flat_position: Vector2 = _center(BattleRules.point(stack))
		if str(_moving.get("id", "")) == str(stack.id):
			var progress: float = clampf((_clock - float(_moving.started)) / float(_moving.duration), 0.0, 1.0)
			flat_position = Vector2(_moving.from).lerp(Vector2(_moving.to), progress)
		group.position = _world_point(flat_position)
		var animation: Dictionary = _animation_data(stack)
		if animation.is_empty():
			continue
		if group.has_meta("animation_player"):
			var player: AnimationPlayer = group.get_meta("animation_player") as AnimationPlayer
			var state_name: String = str(animation.state)
			var clip: String = "run" if state_name == "move" else state_name
			if not player.has_animation(clip):
				clip = "idle"
			var duration: float = player.get_animation(clip).length
			var elapsed: float = maxf(0, _clock - float(stack.get("animStarted", 0)))
			var time_value: float = minf(elapsed, maxf(0, duration - 0.001)) if clip in ["attack", "death"] else fmod(elapsed, maxf(duration, 0.001))
			if str(player.current_animation) != clip:
				player.play(clip)
			player.seek(time_value, true)
			continue
		var metadata: Dictionary = animation.metadata
		var frame: Dictionary = animation.frame
		var anchor: Dictionary = metadata.get("anchor", {"x": float(frame.w) * 0.5, "y": float(frame.h) * 0.8})
		for index: int in range(group.get_child_count()):
			var sprite: Sprite3D = group.get_child(index) as Sprite3D
			sprite.visible = true
			sprite.texture = _texture(str(metadata.image))
			sprite.region_rect = Rect2(float(frame.x), float(frame.y), float(frame.w), float(frame.h))
			sprite.pixel_size = float(metadata.get("drawScale", 0.44)) * 0.035
			sprite.offset = Vector2((float(frame.w) * 0.5 - float(anchor.x)) * (-1.0 if sprite.flip_h else 1.0), float(anchor.y) - float(frame.h) * 0.5)
			sprite.modulate = Color("eee8d6") if str(stack.side) == "player" else Color("e2d3c5")

func _project_world(point: Vector3) -> Vector2:
	return _field_camera.unproject_position(point) if is_instance_valid(_field_camera) else Vector2.ZERO

func screen_position_for_hex(hex: Vector2i) -> Vector2:
	return _project_world(_world_point(_center(hex)))

func hex_at_screen_position(position_value: Vector2) -> Vector2i:
	if not is_instance_valid(_field_camera):
		return Vector2i(-1, -1)
	var origin: Vector3 = _field_camera.project_ray_origin(position_value)
	var direction: Vector3 = _field_camera.project_ray_normal(position_value)
	var intersection: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if not intersection is Vector3:
		return Vector2i(-1, -1)
	var world_position: Vector3 = intersection
	var closest: Vector2i = Vector2i(-1, -1)
	var closest_distance: float = 1.6
	for row: int in range(BattleRules.ROWS):
		for col: int in range(1, BattleRules.COLS - 1):
			var candidate: Vector2i = Vector2i(col, row)
			var point: Vector3 = _world_point(_center(candidate))
			var distance: float = Vector2(point.x, point.z).distance_to(Vector2(world_position.x, world_position.z))
			if distance < closest_distance:
				closest_distance = distance
				closest = candidate
	return closest

func _manual() -> bool:
	return not _done and not _busy and not _auto and not _active.is_empty() and str(_active.side) == "player" and (not is_instance_valid(_help) or not _help.visible)

func _stack_label(stack: Dictionary) -> String:
	var data: Dictionary = BattleRules.unit(str(stack.type))
	return "%d %s" % [int(stack.count), str(data.get("plural", data.get("name", stack.type))) if int(stack.count) != 1 else str(data.get("name", stack.type))]

func _at(p: Vector2i) -> Dictionary:
	for stack: Dictionary in BattleRules.living(_stacks):
		if BattleRules.point(stack) == p:
			return stack
	return {}

func _log(text: String, kind: String = "") -> void:
	_logs.push_front({"text": text, "kind": kind})
	if _logs.size() > 30:
		_logs.resize(30)
	if is_instance_valid(_log_label):
		var lines: PackedStringArray = []
		for entry: Dictionary in _logs.slice(0, 14):
			var color: String = "c3a46c" if str(entry.kind) in ["round", "phase", "magic"] else "baae94"
			lines.append("[color=#%s]%s[/color]" % [color, _bb(str(entry.text))])
		_log_label.text = "\n\n".join(lines)

func _bb(text: String) -> String:
	return text.replace("[", "[lb]")

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _portrait(stack: Dictionary, size_value: int = 38) -> TextureRect:
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(size_value, size_value)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = DraconiaArt.portrait(str(stack.type))
	if portrait.texture != null:
		return portrait
	var animation: Dictionary = _animations.get(str(stack.type), {})
	if not animation.is_empty():
		var frames: Array = animation.get("states", {}).get("idle", {}).get("frames", [])
		if frames.is_empty():
			frames = animation.get("states", {}).get("attack", {}).get("frames", [])
		if not frames.is_empty():
			var frame: Dictionary = frames[0]
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = _texture(str(animation.image))
			var bounds: Array = animation.get("contentBounds", [0, 0, frame.w, frame.h])
			atlas.region = Rect2(float(frame.x) + float(bounds[0]), float(frame.y) + float(bounds[1]), float(bounds[2]), float(bounds[3]))
			portrait.texture = atlas
	if portrait.texture == null:
		portrait.texture = _texture(str(BattleRules.unit(str(stack.type)).get("image", "assets/" + str(stack.type) + ".png")))
	return portrait

func _refresh() -> void:
	if not is_instance_valid(_board):
		return
	_round_label.text = "ROUND %02d" % _round
	_mana_label.text = "OATHPOWER\n%d / %d" % [_mana, int(_hero.get("maxMana", maxi(_mana, 20)))]
	_clear_children(_order_box)
	for index: int in range(_queue.size()):
		var stack: Dictionary = BattleRules.stack_by_id(_stacks, str(_queue[index]))
		if stack.is_empty() or int(stack.count) <= 0:
			continue
		var panel: PanelContainer = PanelContainer.new()
		var friendly: bool = str(stack.side) == "player"
		panel.add_theme_stylebox_override("panel", _style(Color("37352a") if friendly else Color("3b2b24"), BRONZE if index == 0 else Color("5d4e38"), 2))
		panel.tooltip_text = "%s · speed %d" % [_stack_label(stack), int(BattleRules.unit(str(stack.type)).speed)]
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		panel.add_child(row)
		row.add_child(_portrait(stack, 38))
		row.add_child(_label(str(stack.count), 12, INK))
		_order_box.add_child(panel)
	if not _active.is_empty():
		var data: Dictionary = BattleRules.unit(str(_active.type))
		var values: Dictionary = BattleRules.stats(_active, _hero, _context)
		_active_label.text = "[font_size=14][color=#c3a46c]%s[/color][/font_size]\n[font_size=24]%s[/font_size]\n%s\n\nATK %d    DEF %d    SPEED %d\n%s" % ["YOUR COMPANY" if str(_active.side) == "player" else "ENEMY COMPANY", _bb(str(data.get("plural", data.name))), _bb(_stack_label(_active)), int(values.attack), int(values.defense), int(values.speed), ("Ammunition: %d" % int(_active.shots)) if int(data.get("shots", 0)) > 0 else ("Health per creature: %d" % int(data.hp))]
	_clear_children(_target_box)
	for stack: Dictionary in BattleRules.living(_stacks, "player" if _selected_spell == "heal" else "enemy"):
		var button: Button = Button.new()
		button.text = _stack_label(stack)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(196, 30)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", INK)
		button.add_theme_stylebox_override("normal", _style(Color("322c23"), Color("6c5b3e"), 5))
		button.add_theme_stylebox_override("hover", _style(Color("4a3b29"), BRONZE, 5))
		button.disabled = not _manual()
		button.pressed.connect(_act_on_hex.bind(BattleRules.point(stack)))
		_target_box.add_child(button)
	_buttons.wait.disabled = not _manual() or bool(_active.get("waited", false))
	_buttons.defend.disabled = not _manual()
	_buttons.arrow.disabled = not _manual() or _mana < 5 or _spell_round == _round
	_buttons.heal.disabled = not _manual() or _mana < 4 or _spell_round == _round
	_buttons.arrow.text = "Cancel Oathfire" if _selected_spell == "arrow" else "Oathfire · 5"
	_buttons.heal.text = "Cancel Mend" if _selected_spell == "heal" else "Mend · 4"
	_buttons.auto.text = "Take command [A]" if _auto else "Auto battle [A]"
	_buttons.auto.disabled = _done
	_buttons.retreat.disabled = _done or _busy
	_buttons.retreat.text = "Confirm withdrawal" if _retreat_confirm else "Withdraw"
	_update_hint()

func _update_hint() -> void:
	if not is_instance_valid(_hint_label):
		return
	var text: String = "Choose a marked hex to move, or an enemy to attack."
	if _done:
		text = "The field has fallen silent."
	elif _busy:
		text = "The companies clash…"
	elif not _active.is_empty() and str(_active.side) == "enemy":
		text = "Enemy turn · " + _stack_label(_active)
	elif _auto:
		text = "Your captains are commanding the company. Press A to take control."
	elif _selected_spell == "arrow":
		text = "Oathfire prepared · choose an enemy company."
	elif _selected_spell == "heal":
		text = "Mend prepared · choose wounded allies. Fallen troops cannot be revived."
	elif BattleRules.valid_hex(_hover) and not _active.is_empty():
		var target: Dictionary = _at(_hover)
		if not target.is_empty() and str(target.side) != str(_active.side):
			var plan: Dictionary = BattleRules.attack_plan(_stacks, _active, target, _terrain)
			if not plan.is_empty():
				var damage: Vector2i = BattleRules.damage_range(_active, target, _hero, _context, bool(plan.shooting))
				text = "%s %s · %d–%d damage" % ["Shoot" if bool(plan.shooting) else "Attack", _stack_label(target), damage.x, damage.y]
			else:
				text = _stack_label(target) + " are out of reach. Advance or wait."
		elif not target.is_empty():
			text = "%s · %d total health" % [_stack_label(target), int(target.totalHp)]
		elif _reachable.has(_hover):
			text = "Move %d hexes. This ends the company's action." % int(_reachable[_hover].distance)
	_hint_label.text = text

func _center(p: Vector2i) -> Vector2:
	return ORIGIN + Vector2(float(p.x) * STEP_X + float(p.y & 1) * STEP_X * 0.5, float(p.y) * STEP_Y)

func _hex_points(p: Vector2i, inset: float = 0.0) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(6):
		var angle: float = float(index) * PI / 3.0 - PI / 2.0
		points.append(_center(p) + Vector2(cos(angle), sin(angle)) * (HEX_RADIUS - inset))
	return points

func _field_layout(field: Control) -> Dictionary:
	var factor: float = minf(field.size.x / FIELD_SIZE.x, field.size.y / FIELD_SIZE.y)
	return {"scale": factor, "offset": (field.size - FIELD_SIZE * factor) * 0.5}

func _projected_hex(hex: Vector2i, inset: float = 1.0) -> PackedVector2Array:
	var projected: PackedVector2Array = PackedVector2Array()
	for flat_point: Vector2 in _hex_points(hex, inset):
		projected.append(_project_world(_world_point(flat_point) + Vector3(0, 0.035, 0)))
	return projected

func _draw_field(field: Control) -> void:
	field.draw_rect(Rect2(Vector2.ZERO, field.size), Color("17201c"))
	if not is_instance_valid(_field_viewport) or not is_instance_valid(_field_camera):
		return
	field.draw_texture_rect(_field_viewport.get_texture(), Rect2(Vector2.ZERO, field.size), false)
	# The terrain stays visible; command markers appear only for the active host.
	if _manual() and _selected_spell.is_empty():
		for hex: Vector2i in _reachable.keys():
			var marker: Vector2 = screen_position_for_hex(hex)
			field.draw_circle(marker, 2.3, Color(0.88, 0.81, 0.58, 0.40))
	if not _active.is_empty() and int(_active.get("count", 0)) > 0 and not _done:
		var active_ring: PackedVector2Array = _projected_hex(BattleRules.point(_active), 8.0)
		active_ring.append(active_ring[0])
		field.draw_polyline(active_ring, Color(0.88, 0.77, 0.47, 0.76), 2.0, true)
	if BattleRules.valid_hex(_hover) and not _busy and not _done:
		var hovered: PackedVector2Array = _projected_hex(_hover, 1.5)
		var target: Dictionary = _at(_hover)
		var hostile: bool = not target.is_empty() and str(target.side) == "enemy"
		field.draw_colored_polygon(hovered, Color(0.55, 0.20, 0.11, 0.12) if hostile else Color(0.86, 0.77, 0.51, 0.09))
		hovered.append(hovered[0])
		field.draw_polyline(hovered, Color("b68268") if hostile else Color("d9c394"), 1.4, true)
	for stack: Dictionary in _stacks:
		if int(stack.count) <= 0:
			continue
		var group: Node3D = _unit_models.get(str(stack.id)) as Node3D
		var world_position: Vector3 = group.position if group != null else _world_point(_center(BattleRules.point(stack)))
		var base: Vector2 = _project_world(world_position) + Vector2(0, 15)
		var count_text: String = str(stack.count)
		var allegiance: Color = Color("e0d3a4") if str(stack.side) == "player" else Color("ddab91")
		field.draw_line(base + Vector2(-13, 5), base + Vector2(13, 5), Color(0.08, 0.08, 0.06, 0.65), 5.0, true)
		field.draw_line(base + Vector2(-12, 5), base + Vector2(12, 5), allegiance, 1.0, true)
		field.draw_string_outline(ThemeDB.fallback_font, base + Vector2(-24, 0), count_text, HORIZONTAL_ALIGNMENT_CENTER, 48, 17, 4, Color("161914"))
		field.draw_string(ThemeDB.fallback_font, base + Vector2(-24, 0), count_text, HORIZONTAL_ALIGNMENT_CENTER, 48, 17, allegiance)
		if str(stack.id) == str(_active.get("id", "")) or BattleRules.point(stack) == _hover:
			var hp: int = int(BattleRules.unit(str(stack.type)).hp)
			var health: float = float(int(stack.totalHp) - (int(stack.count) - 1) * hp) / float(hp)
			field.draw_line(base + Vector2(-12, 8), base + Vector2(12, 8), Color("262b20"), 2.0)
			field.draw_line(base + Vector2(-12, 8), base + Vector2(-12 + health * 24, 8), Color("abb78a"), 2.0)
	for effect: Dictionary in _effects:
		var progress: float = clampf((_clock - float(effect.started)) / float(effect.duration), 0.0, 1.0)
		if str(effect.kind) in ["bolt", "arrow"]:
			var origin: Vector2 = _project_world(_world_point(effect.from) + Vector3(0, 1.0, 0))
			var destination: Vector2 = _project_world(_world_point(effect.to) + Vector3(0, 1.0, 0))
			var current: Vector2 = origin.lerp(destination, progress)
			var direction: Vector2 = (destination - origin).normalized()
			field.draw_line(current - direction * 23.0, current, Color("f0cea0"), 3.0 if str(effect.kind) == "bolt" else 1.7, true)
			if str(effect.kind) == "bolt":
				field.draw_circle(current, 5.0, Color(0.98, 0.71, 0.30, 0.35))
		elif str(effect.kind) == "heal":
			var center: Vector2 = _project_world(_world_point(effect.position) + Vector3(0, 0.7, 0))
			field.draw_arc(center, 8 + progress * 22, 0, TAU, 32, Color(0.77, 0.83, 0.62, 1.0 - progress), 2.0, true)
		else:
			var position_value: Vector2 = _project_world(_world_point(effect.position) + Vector3(0, 1.8, 0)) + Vector2(-20, -progress * 35)
			var color: Color = effect.get("color", Color("ead5ab"))
			color.a = 1.0 - progress
			field.draw_string_outline(ThemeDB.fallback_font, position_value, str(effect.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 4, Color(0.08, 0.09, 0.07, color.a))
			field.draw_string(ThemeDB.fallback_font, position_value, str(effect.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
	field.draw_string(ThemeDB.fallback_font, Vector2(17, field.size.y - 15), "Wheel: inspect ground  ·  Right-drag: turn camera", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.84, 0.74, 0.76))

func _animation_data(stack: Dictionary, desired: String = "") -> Dictionary:
	var metadata: Dictionary = _animations.get(str(stack.type), {})
	if metadata.is_empty():
		return {}
	var states: Dictionary = metadata.get("states", {})
	var current: String = desired if not desired.is_empty() else str(stack.get("animState", "idle"))
	if not states.has(current):
		current = "idle" if states.has("idle") else str(states.keys()[0]) if not states.is_empty() else ""
	if current.is_empty():
		return {}
	var sequence: Dictionary = states[current]
	var frames: Array = sequence.get("frames", [])
	if frames.is_empty():
		return {}
	var duration: float = 0.0
	for frame: Dictionary in frames:
		duration += float(frame.get("duration", 120))
	var elapsed: float = (_clock - float(stack.get("animStarted", 0.0))) * 1000.0
	var looping: bool = bool(sequence.get("loop", current == "idle" or current == "move"))
	if not looping and elapsed >= duration and current != "death" and states.has("idle") and desired.is_empty():
		return _animation_data(stack, "idle")
	var position: float = fmod(elapsed, maxf(duration, 1.0)) if looping else minf(elapsed, duration - 0.01)
	var chosen: Dictionary = frames.back()
	for frame: Dictionary in frames:
		position -= float(frame.get("duration", 120))
		if position < 0:
			chosen = frame
			break
	return {"metadata": metadata, "frame": chosen, "duration": duration / 1000.0, "state": current}

func _death_visible(stack: Dictionary) -> bool:
	if str(stack.get("animState", "")) != "death":
		return false
	var data: Dictionary = _animation_data(stack, "death")
	return not data.is_empty() and _clock - float(stack.get("animStarted", 0)) <= float(data.duration) + 0.2

func _animate(stack: Dictionary, animation_name: String) -> void:
	stack.animState = animation_name
	stack.animStarted = _clock

func _field_input(field: Control, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_orbiting = event.pressed
			field.accept_event()
			return
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_camera_zoom = clampf(_camera_zoom * (0.90 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.10), 0.65, 1.35)
			_update_field_camera()
			field.accept_event()
			return
	if event is InputEventMouseMotion and _orbiting:
		_camera_yaw = clampf(_camera_yaw - event.relative.x * 0.0045, -0.85, 0.85)
		_update_field_camera()
		field.accept_event()
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventScreenTouch:
		_hover = hex_at_screen_position(event.position)
		# A troop's visible body is also a target; its projected feet still define its hex.
		var best_distance: float = 1000000.0
		for stack: Dictionary in BattleRules.living(_stacks):
			var position_value: Vector3 = _world_point(_center(BattleRules.point(stack)))
			var foot: Vector2 = _project_world(position_value)
			var height: float = 3.6 if str(stack.type) == "dragon" else 2.5
			var head: Vector2 = _project_world(position_value + Vector3(0, height, 0))
			var body: Rect2 = Rect2(Vector2(foot.x - 21, head.y - 4), Vector2(42, maxf(12, foot.y - head.y + 9)))
			var distance: float = event.position.distance_to(foot.lerp(head, 0.5))
			if body.has_point(event.position) and distance < best_distance:
				best_distance = distance
				_hover = BattleRules.point(stack)
		_update_hint()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			field.grab_focus()
			if BattleRules.valid_hex(_hover):
				_act_on_hex(_hover)
			field.accept_event()
		elif event is InputEventScreenTouch and event.pressed:
			if BattleRules.valid_hex(_hover):
				_act_on_hex(_hover)
			field.accept_event()

func _schedule_ai() -> void:
	if not is_instance_valid(_ai_timer):
		return
	_ai_timer.stop()
	if _done or _busy or _active.is_empty() or is_instance_valid(_help) and _help.visible:
		return
	if str(_active.side) == "enemy" or _auto:
		_ai_timer.start(0.26 if _auto else 0.65)

func _activate() -> void:
	if _done:
		return
	var resolution: String = BattleRules.outcome(_stacks)
	if not resolution.is_empty():
		_finish(resolution)
		return
	var valid_order: Array = []
	for stack_id: String in _queue:
		if int(BattleRules.stack_by_id(_stacks, stack_id).get("count", 0)) > 0:
			valid_order.append(stack_id)
	_queue = valid_order
	if _queue.is_empty():
		_round += 1
		for stack: Dictionary in _stacks:
			stack.waited = false
			stack.retaliated = false
		_queue = BattleRules.round_order(_stacks, _round)
		_log("Round %d begins." % _round, "round")
	_active = BattleRules.stack_by_id(_stacks, str(_queue[0]))
	_active.defended = false
	_selected_spell = ""
	_busy = false
	_retreat_confirm = false
	_reachable = BattleRules.movement(_stacks, _active, _terrain)
	_hover = BattleRules.point(_active)
	_refresh()
	_schedule_ai()

func _end_turn() -> void:
	if not _queue.is_empty():
		_queue.pop_front()
	_activate()

func _move_stack(stack: Dictionary, path: Array) -> void:
	if path.is_empty():
		return
	_animate(stack, "move")
	for hex: Vector2i in path:
		var duration: float = 0.11 if _auto else 0.17
		if BattleRules.hex_distance(BattleRules.point(stack), hex) > 1:
			duration *= 2.2
		_moving = {"id": str(stack.id), "from": _center(BattleRules.point(stack)), "to": _center(hex), "started": _clock, "duration": duration}
		await get_tree().create_timer(duration).timeout
		if not is_inside_tree():
			return
		stack.col = hex.x
		stack.row = hex.y
	_moving = {}
	_animate(stack, "idle")

func _strike(attacker: Dictionary, defender: Dictionary, shooting: bool = false, retaliation: bool = false) -> void:
	if int(attacker.count) <= 0 or int(defender.count) <= 0:
		return
	_animate(attacker, "attack")
	var animation: Dictionary = _animation_data(attacker, "attack")
	var windup: float = clampf(float(animation.get("duration", 0.5)) * 0.42, 0.14, 0.32)
	await get_tree().create_timer(windup).timeout
	if shooting:
		attacker.shots = maxi(0, int(attacker.shots) - 1)
		_effects.append({"kind": "arrow", "from": _center(BattleRules.point(attacker)) + Vector2(0, -16), "to": _center(BattleRules.point(defender)) + Vector2(0, -16), "started": _clock, "duration": 0.23})
		await get_tree().create_timer(0.23).timeout
	var report: Dictionary = BattleRules.hit(attacker, defender, _hero, _context, shooting, _rng)
	defender.merge(report.after, true)
	if int(defender.count) <= 0:
		_animate(defender, "death")
	_effects.append({"kind": "text", "text": "−%d" % int(report.damage), "position": _center(BattleRules.point(defender)), "started": _clock, "duration": 0.95, "color": Color("eacba6")})
	_log("%s %s %d damage%s." % [_stack_label(attacker), "retaliate for" if retaliation else "shoot for" if shooting else "deal", int(report.damage), " · %d fallen" % int(report.killed) if int(report.killed) > 0 else ""], "friendly" if str(attacker.side) == "player" else "hostile")
	_refresh()
	await get_tree().create_timer(0.22 if _auto else 0.36).timeout
	if not shooting and not retaliation and int(defender.count) > 0 and not bool(defender.retaliated) and int(attacker.count) > 0:
		defender.retaliated = true
		await _strike(defender, attacker, false, true)

func _act_on_hex(hex: Vector2i) -> void:
	if not _manual():
		return
	var target: Dictionary = _at(hex)
	if not _selected_spell.is_empty():
		if not target.is_empty():
			await _cast_spell(target)
		return
	if not target.is_empty() and str(target.side) != str(_active.side):
		var plan: Dictionary = BattleRules.attack_plan(_stacks, _active, target, _terrain)
		if plan.is_empty():
			_log("That company is out of reach. Advance across the marked hexes.")
			return
		_busy = true
		_refresh()
		await _move_stack(_active, plan.path)
		await _strike(_active, target, bool(plan.shooting))
		_end_turn()
	elif target.is_empty() and _reachable.has(hex):
		_busy = true
		_refresh()
		var path: Array = _reachable[hex].path
		await _move_stack(_active, path)
		_log("%s advance." % _stack_label(_active))
		_end_turn()

func _cast_spell(target: Dictionary, forced: String = "") -> bool:
	var spell: String = forced if not forced.is_empty() else _selected_spell
	var cost: int = 5 if spell == "arrow" else 4
	if _done or _busy or str(_active.get("side", "")) != "player" or _spell_round == _round or _mana < cost:
		return false
	if spell == "arrow" and str(target.side) != "enemy" or spell == "heal" and str(target.side) != "player":
		return false
	if spell == "heal" and BattleRules.healing_amount(target, _hero) <= 0:
		_log("These troops have no wounds to mend. The fallen cannot be resurrected.")
		return false
	_busy = true
	_mana -= cost
	_spell_round = _round
	_selected_spell = ""
	_refresh()
	var center: Vector2 = _center(BattleRules.point(target))
	if spell == "arrow":
		var amount: int = BattleRules.arrow_damage(_hero)
		_effects.append({"kind": "bolt", "from": Vector2(70, FIELD_SIZE.y - 50), "to": center, "started": _clock, "duration": 0.4})
		await get_tree().create_timer(0.4).timeout
		var previous: int = int(target.count)
		target.merge(BattleRules.damaged(target, amount), true)
		if int(target.count) <= 0:
			_animate(target, "death")
		_effects.append({"kind": "text", "text": "−%d" % amount, "position": center, "started": _clock, "duration": 1.0, "color": Color("ead2a5")})
		_log("Oathfire deals %d damage%s." % [amount, " · %d fallen" % (previous - int(target.count)) if previous > int(target.count) else ""], "magic")
	else:
		var amount: int = BattleRules.healing_amount(target, _hero)
		target.totalHp = int(target.totalHp) + amount
		_effects.append({"kind": "heal", "position": center, "started": _clock, "duration": 0.8})
		_effects.append({"kind": "text", "text": "+%d" % amount, "position": center, "started": _clock, "duration": 1.0, "color": Color("d5dfb5")})
		_log("Mend restores %d health to %s." % [amount, str(BattleRules.unit(str(target.type)).get("plural", target.type))], "magic")
	await get_tree().create_timer(0.25).timeout
	_busy = false
	var resolution: String = BattleRules.outcome(_stacks)
	if not resolution.is_empty():
		_finish(resolution)
	else:
		_reachable = BattleRules.movement(_stacks, _active, _terrain)
		_refresh()
		_schedule_ai()
	return true

func _play_ai() -> void:
	if _done or _busy or _active.is_empty() or str(_active.side) == "player" and not _auto:
		return
	if str(_active.side) == "player" and _auto and _spell_round != _round and _mana >= 5:
		var target: Dictionary = BattleRules.spell_target(_stacks)
		if not target.is_empty():
			await _cast_spell(target, "arrow")
			return
	var action: Dictionary = BattleRules.choose_action(_stacks, _active, _hero, _context, _terrain)
	_busy = true
	_refresh()
	if str(action.kind) == "attack":
		await _move_stack(_active, action.path)
		await _strike(_active, BattleRules.stack_by_id(_stacks, str(action.target)), bool(action.shooting))
	elif str(action.kind) == "move":
		await _move_stack(_active, action.path)
		_log("%s advance." % _stack_label(_active))
	else:
		_active.defended = true
		_log("%s hold their ground." % _stack_label(_active))
	_end_turn()

func _command(command_name: String) -> void:
	if command_name == "help":
		_ai_timer.stop()
		_help.popup_centered()
		return
	if _done:
		return
	if command_name == "auto":
		_auto = not _auto
		_selected_spell = ""
		_refresh()
		_schedule_ai()
		return
	if command_name == "retreat" and not _busy:
		if _retreat_confirm:
			_finish("retreat")
		else:
			_retreat_confirm = true
			_log("Press Confirm withdrawal to leave the field with your survivors.")
			_refresh()
		return
	if not _manual():
		return
	if command_name in ["arrow", "heal"]:
		if _spell_round == _round or _mana < (5 if command_name == "arrow" else 4):
			return
		_selected_spell = "" if _selected_spell == command_name else command_name
		_refresh()
	elif command_name == "wait" and not bool(_active.waited):
		_active.waited = true
		_log("%s wait until the end of the round." % _stack_label(_active))
		_queue = BattleRules.wait_order(_queue, str(_active.id))
		_activate()
	elif command_name == "defend":
		_active.defended = true
		_log("%s defend · +20%% base defence." % _stack_label(_active))
		_end_turn()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _done:
		return
	var handled: bool = true
	match event.keycode:
		KEY_W: _command("wait")
		KEY_D: _command("defend")
		KEY_A: _command("auto")
		KEY_ESCAPE:
			_selected_spell = ""
			_refresh()
		KEY_LEFT: _hover.x = maxi(1, _hover.x - 1)
		KEY_RIGHT: _hover.x = mini(15, _hover.x + 1)
		KEY_UP: _hover.y = maxi(0, _hover.y - 1)
		KEY_DOWN: _hover.y = mini(10, _hover.y + 1)
		KEY_ENTER, KEY_KP_ENTER: _act_on_hex(_hover)
		_: handled = false
	if handled:
		_update_hint()
		get_viewport().set_input_as_handled()

func _finish(resolution: String) -> void:
	if _done:
		return
	_done = true
	_busy = false
	_ai_timer.stop()
	_pending_result = BattleRules.result(_stacks, _mana, resolution, _round)
	_refresh()
	_result_layer = Control.new()
	_result_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_result_layer)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.10, 0.11, 0.09, 0.79)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 500
	panel.add_theme_stylebox_override("panel", _style(Color("29231b"), BRONZE, 32))
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	panel.add_child(box)
	var eyebrow: Label = _label("THE FIELD IS YOURS" if resolution == "victory" else "LIVE TO FIGHT AGAIN" if resolution == "retreat" else "THE COMPANY FALLS BACK", 11, BRONZE, true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var title: Label = _label("Victory" if resolution == "victory" else "Withdrawal" if resolution == "retreat" else "Defeat", 46, INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var description: Label = _label("Your company holds the pass. Honour the fallen." if resolution == "victory" else "Your survivors return to the map. Gather strength before the next oath.", 13, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 430
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)
	var summary: Label = _label("%d rounds fought   ·   %d oathpower remains" % [_round, _mana], 16, BRONZE, true)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(summary)
	for stack: Dictionary in _stacks:
		if str(stack.side) != "player":
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.add_child(_portrait(stack, 41))
		var name_label: Label = _label(str(BattleRules.unit(str(stack.type)).get("plural", stack.type)), 14, INK)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_label("%d remain" % int(stack.count), 13, INK))
		row.add_child(_label("−%d lost" % (int(stack.initialCount) - int(stack.count)), 12, Color("bd937b")))
		box.add_child(row)
	var continue_button: Button = Button.new()
	continue_button.text = "Return to the valley"
	continue_button.custom_minimum_size.y = 48
	continue_button.add_theme_color_override("font_color", Color("f3e5c5"))
	continue_button.add_theme_stylebox_override("normal", _style(Color("5b452a"), Color("a58850"), 12))
	continue_button.add_theme_stylebox_override("hover", _style(Color("755b35"), Color("a58850"), 12))
	continue_button.pressed.connect(_continue)
	box.add_child(continue_button)
	continue_button.grab_focus()

func _continue() -> void:
	if _sent:
		return
	_sent = true
	finished.emit(_pending_result.duplicate(true))
	queue_free()
