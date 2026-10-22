class_name AdventureMap
extends Control

signal destination_selected(x: int, y: int, confirm: bool)
signal selection_cleared

const WORLD_SCRIPT: Script = preload("res://game/world_3d.gd")
const PIXELS_PER_UNIT: float = 92.0
const ELEVATION: float = PI / 4.0
const CELL: Vector2 = Vector2(130.107648, 92.0)
var campaign: Dictionary = {}
var camera: Vector2 = Vector2.ZERO
var zoom: float = 1.0
var show_grid: bool = false
var planned_path: Array = []
var selected: Vector2i = Vector2i(-1, -1)
var hover: Vector2i = Vector2i(-1, -1)
var _drag_start: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_distance: float = 0.0
var _time: float = 0.0
var _hero_position: Vector2 = Vector2.ZERO
var _travel_points: Array = []
var _travel_time: float = 0.0
var _travel_start: Vector2 = Vector2.ZERO
var _viewport: SubViewport
var _surface: TextureRect
var _world: Node3D
var _overlay_signature: int = -1
var _camera_signature: Vector3 = Vector3.INF
var _font: Font
var moving: bool = false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_font = load("res://assets/cinzel.ttf") as Font
	_viewport = SubViewport.new()
	_viewport.name = "NativeWorldViewport"
	_viewport.own_world_3d = true
	_viewport.gui_disable_input = true
	_viewport.handle_input_locally = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.positional_shadow_atlas_size = 2048
	add_child(_viewport)
	_world = WORLD_SCRIPT.new()
	_world.name = "CarpathianWorld"
	_viewport.add_child(_world)
	_surface = TextureRect.new()
	_surface.name = "Native3DSurface"
	_surface.show_behind_parent = true
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_surface.stretch_mode = TextureRect.STRETCH_SCALE
	_surface.texture = _viewport.get_texture()
	add_child(_surface)
	resized.connect(_resize_viewport)
	_resize_viewport()
	if not campaign.is_empty():
		_world.set_campaign(campaign)
		_world.set_hero_position(_hero_position, false)

func _resize_viewport() -> void:
	if _viewport == null:
		return
	_viewport.size = Vector2i(maxi(2, roundi(size.x)), maxi(2, roundi(size.y)))
	_camera_signature = Vector3.INF
	_sync_camera()

func _sync_camera() -> void:
	if not is_instance_valid(_world) or _viewport == null:
		return
	var signature: Vector3 = Vector3(camera.x, camera.y, zoom)
	if signature != _camera_signature:
		_world.configure_camera(camera, zoom, Vector2(_viewport.size), PIXELS_PER_UNIT, ELEVATION)
		_camera_signature = signature

func set_campaign(value: Dictionary, recenter: bool = false) -> void:
	campaign = value
	if not moving:
		_hero_position = Vector2(float(value.hero.x), float(value.hero.y))
	if is_instance_valid(_world):
		_world.set_campaign(value)
		_world.set_hero_position(_hero_position, moving)
	if recenter:
		center_hero()
	_overlay_signature = -1
	queue_redraw()

func iso(x: float, y: float) -> Vector2:
	var ground: float = float(_world.walk_height(x, y)) if is_instance_valid(_world) else 0.0
	return Vector2((x - y) * CELL.x * 0.5, (x + y) * CELL.y * 0.5 - ground * cos(ELEVATION) * PIXELS_PER_UNIT)

func tile_to_screen(x: float, y: float) -> Vector2:
	return (iso(x, y) - camera) * zoom + size * 0.5

func screen_to_tile(position: Vector2) -> Vector2i:
	_sync_camera()
	if is_instance_valid(_world):
		return _world.tile_at_screen(position)
	return Vector2i(-1, -1)

func center_hero() -> void:
	if zoom < 0.55:
		zoom = 1.0
	if not campaign.is_empty():
		camera = iso(float(campaign.hero.x), float(campaign.hero.y)) - Vector2(0, 50)
	_sync_camera()
	queue_redraw()

func focus_tile(x: int, y: int) -> void:
	camera = iso(x, y)
	_sync_camera()
	queue_redraw()

func change_zoom(factor: float) -> void:
	zoom = clampf(zoom * factor, 0.28, 2.05)
	_sync_camera()
	queue_redraw()

func fit_world() -> void:
	if campaign.is_empty():
		return
	var w: float = float(campaign.world.w)
	var h: float = float(campaign.world.h)
	camera = iso(w / 2.0 - 0.5, h / 2.0 - 0.5)
	zoom = clampf(minf(size.x / ((w + h) * CELL.x * 0.5 + 140), size.y / ((w + h) * CELL.y * 0.5 + 160)), 0.16, 1.0)
	_sync_camera()
	queue_redraw()

func animate_travel(path: Array, previous: Vector2i) -> void:
	_travel_points = path.duplicate(true)
	_hero_position = Vector2(previous)
	_travel_start = _hero_position
	_travel_time = 0.0
	moving = not _travel_points.is_empty()
	planned_path = []
	if is_instance_valid(_world):
		_world.set_hero_position(_hero_position, moving)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	if moving:
		_travel_time += delta * 5.0
		if _travel_points.is_empty():
			moving = false
		else:
			var target: Dictionary = _travel_points[0]
			var goal: Vector2 = Vector2(float(target.x), float(target.y))
			_hero_position = _travel_start.lerp(goal, minf(_travel_time, 1.0))
			camera = camera.lerp(iso(_hero_position.x, _hero_position.y) - Vector2(0, 40), minf(delta * 4, 1.0))
			if _travel_time >= 1.0:
				_travel_start = goal
				_travel_points.pop_front()
				_travel_time = 0.0
				moving = not _travel_points.is_empty()
		if is_instance_valid(_world):
			_world.set_hero_position(_hero_position, moving)
	_sync_camera()
	if is_instance_valid(_world) and not campaign.is_empty():
		var signature: int = hash([planned_path, selected, hover, show_grid, int(campaign.hero.movement)])
		if signature != _overlay_signature:
			_world.set_overlays(planned_path, selected, hover, show_grid, int(campaign.hero.movement))
			_overlay_signature = signature
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if campaign.is_empty() or moving:
		return
	if event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		if click.button_index == MOUSE_BUTTON_WHEEL_UP and click.pressed:
			change_zoom(1.12)
		elif click.button_index == MOUSE_BUTTON_WHEEL_DOWN and click.pressed:
			change_zoom(1.0 / 1.12)
		elif click.button_index == MOUSE_BUTTON_RIGHT and click.pressed:
			selected = Vector2i(-1, -1)
			planned_path = []
			selection_cleared.emit()
		elif click.button_index == MOUSE_BUTTON_LEFT:
			if click.pressed:
				_drag_start = click.position
				_drag_distance = 0.0
				_dragging = true
				grab_focus()
			else:
				_dragging = false
				if _drag_distance < 7.0:
					var tile: Vector2i = screen_to_tile(click.position)
					if tile.x >= 0 and tile.y >= 0 and tile.x < int(campaign.world.w) and tile.y < int(campaign.world.h):
						var confirm: bool = tile == selected
						selected = tile
						destination_selected.emit(tile.x, tile.y, confirm)
		accept_event()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if _dragging:
			camera -= motion.relative / zoom
			_drag_distance += motion.relative.length()
		else:
			hover = screen_to_tile(motion.position)
		queue_redraw()
	elif event is InputEventMagnifyGesture:
		change_zoom(event.factor)
		accept_event()
	elif event is InputEventPanGesture:
		camera += event.delta * 22.0 / zoom
		queue_redraw()
		accept_event()

func _draw() -> void:
	if not is_instance_valid(_world) or campaign.is_empty() or _font == null:
		return
	for object: Dictionary in campaign.world.objects:
		var x: int = int(object.x)
		var y: int = int(object.y)
		if bool(object.get("removed", false)) or not bool(campaign.revealed[y][x]):
			continue
		if str(object.type) == "enemy" and bool(object.get("defeated", false)):
			continue
		var focused: bool = Vector2i(x, y) == selected or Vector2i(x, y) == hover
		if not focused and (str(object.type) != "town" or zoom < 0.55):
			continue
		var point: Vector2 = tile_to_screen(x, y) + Vector2(0, 37 * zoom + 7)
		var caption: String = str(object.name)
		var font_size: int = 14 if focused else 12
		point.x -= _font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5
		draw_string_outline(_font, point, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.07, 0.08, 0.07, 0.9))
		draw_string(_font, point, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("dfd4ae") if focused else Color("c8c4b0"))
