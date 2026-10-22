class_name DraconiaArt
extends RefCounted

static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}

static func texture(path: String) -> Texture2D:
	var full: String = path if path.begins_with("res://") else "res://" + path
	if _textures.has(full):
		return _textures[full]
	if ResourceLoader.exists(full):
		_textures[full] = load(full)
		return _textures[full]
	return null

static func manifest() -> Dictionary:
	if _manifest.is_empty() and FileAccess.file_exists("res://assets/animated/animations.json"):
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/animated/animations.json"))
		if value is Dictionary:
			_manifest = value.get("units", {})
	return _manifest

static func unit_data(kind: String) -> Dictionary:
	return manifest().get(kind, {})

static func frame(kind: String, animation: String = "idle", seconds: float = 0.0) -> Dictionary:
	var data: Dictionary = unit_data(kind)
	if data.is_empty():
		return {}
	var states: Dictionary = data.get("states", {})
	var sequence: Dictionary = states.get(animation, states.get("idle", {}))
	var frames: Array = sequence.get("frames", [])
	if frames.is_empty():
		return {}
	var duration: float = 0.0
	for item: Dictionary in frames:
		duration += float(item.get("duration", 150))
	var time: float = fmod(seconds * 1000.0, maxf(1.0, duration)) if bool(sequence.get("loop", true)) else minf(seconds * 1000.0, duration - 0.01)
	for item: Dictionary in frames:
		time -= float(item.get("duration", 150))
		if time < 0.0:
			return item
	return frames.back()

static func unit_texture(kind: String) -> Texture2D:
	var data: Dictionary = unit_data(kind)
	var fr: Dictionary = frame(kind)
	if data.is_empty() or fr.is_empty():
		return null
	var source: Texture2D = texture(str(data.image))
	if source == null:
		return null
	var region: Rect2 = Rect2(float(fr.x), float(fr.y), float(fr.w), float(fr.h))
	var bounds: Array = data.get("contentBounds", [])
	if bounds.size() == 4:
		region.position += Vector2(float(bounds[0]), float(bounds[1]))
		region.size = Vector2(maxf(1.0, float(bounds[2])), maxf(1.0, float(bounds[3])))
	var result: AtlasTexture = AtlasTexture.new()
	result.atlas = source
	result.region = region
	result.filter_clip = true
	return result

static func object_texture(index: int) -> Texture2D:
	var atlas: Texture2D = texture("assets/generated/map-atlas.png")
	if atlas == null:
		return null
	var cell: Vector2 = atlas.get_size() / 4.0
	var result: AtlasTexture = AtlasTexture.new()
	result.atlas = atlas
	result.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
	result.filter_clip = true
	return result

static func atlas_cell(path: String, index: int, columns: int, rows: int) -> Texture2D:
	var source: Texture2D = texture(path)
	if source == null:
		return null
	var cell: Vector2 = source.get_size() / Vector2(columns, rows)
	var result: AtlasTexture = AtlasTexture.new()
	result.atlas = source
	result.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	result.filter_clip = true
	return result

static func ui_icon(index: int) -> Texture2D:
	return atlas_cell("assets/generated/ui-icons-v2.png", index, 4, 4)

static func portrait(kind: String) -> Texture2D:
	var keys: Array[String] = ["spearman", "archer", "swordsman", "knight", "mage", "griffin", "skeleton", "orc", "wolf", "dragon", "ileana", "night-lord"]
	var index: int = keys.find(kind)
	if index >= 0:
		var drawn: Texture2D = atlas_cell("assets/generated/manuscript-portraits.png", index, 4, 3)
		if drawn != null:
			return drawn
	return texture("assets/generated/portrait.png") if kind == "ileana" else unit_texture(kind)

static func vignette(index: int) -> Texture2D:
	return atlas_cell("assets/generated/manuscript-scenes.png", index, 2, 3)

static func draw_unit(canvas: CanvasItem, kind: String, position: Vector2, height: float, seconds: float, animation: String = "idle", tint: Color = Color.WHITE) -> void:
	var data: Dictionary = unit_data(kind)
	var fr: Dictionary = frame(kind, animation, seconds)
	if data.is_empty() or fr.is_empty():
		canvas.draw_circle(position - Vector2(0, height / 3.0), height / 5.0, tint)
		return
	var image: Texture2D = texture(str(data.image))
	if image == null:
		return
	var bounds: Array = data.get("contentBounds", [0, 0, fr.w, fr.h])
	var factor: float = height / maxf(1.0, float(bounds[3]))
	var anchor: Dictionary = data.get("anchor", {"x": float(fr.w) / 2.0, "y": float(fr.h)})
	var rect: Rect2 = Rect2(position - Vector2(float(anchor.x), float(anchor.y)) * factor, Vector2(float(fr.w), float(fr.h)) * factor)
	canvas.draw_texture_rect_region(image, rect, Rect2(float(fr.x), float(fr.y), float(fr.w), float(fr.h)), tint)
