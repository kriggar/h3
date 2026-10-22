extends Control
## Read-only field notes drawn from the current action snapshot. Neither the
## chart nor its guidance creates commands, reveals foes, or changes rewards.

const UI = preload("res://game/redesign/manuscript_theme.gd")
const HERO_INK: Color = Color("34494d")
const EXIT_INK: Color = Color("4c6747")
const LOOT_INK: Color = Color("956321")

var action_state: Dictionary = {}
var _font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load("res://assets/ebgaramond.ttf") as Font
	resized.connect(queue_redraw)

func set_state(state: Dictionary) -> void:
	action_state = state
	queue_redraw()

static func hero_actor(state: Dictionary) -> Dictionary:
	for actor: Dictionary in state.get("actors", []):
		if str(actor.get("id", "")) == str(state.get("heroId", "")):
			return actor
	return {}

static func guidance(state: Dictionary, is_hunt: bool) -> Dictionary:
	var objective: Dictionary = state.get("objective", {})
	var total: int = maxi(0, int(objective.get("target", 0)))
	var defeated: int = clampi(int(objective.get("progress", 0)), 0, total)
	var unclaimed: int = 0
	for loot: Dictionary in state.get("loot", []):
		if not bool(loot.get("claimed", false)):
			unclaimed += 1
	if not bool(objective.get("completed", false)):
		return {"phase":"combat", "title":"Defeat the pack" if is_hunt else "Defeat the vault guardians", "detail":"%d of %d foes defeated" % [defeated, total], "remainingFoes":total-defeated, "unclaimedSpoils":unclaimed}
	if unclaimed > 0:
		return {"phase":"collect", "title":"Gather the spoils", "detail":"1 unclaimed reward remains" if unclaimed==1 else "%d unclaimed rewards remain" % unclaimed, "remainingFoes":0, "unclaimedSpoils":unclaimed}
	return {"phase":"extract", "title":"Return to Dawnreach", "detail":"Hunt complete. Leave by the entrance seal." if is_hunt else "Vault cleared. Leave by the entrance seal.", "remainingFoes":0, "unclaimedSpoils":0}

static func target_summary(state: Dictionary) -> Dictionary:
	if str(state.get("phase", "running")) != "running":
		return {}
	var hero: Dictionary = hero_actor(state)
	if hero.is_empty() or int(hero.get("hp", 0)) <= 0:
		return {}
	var target_id: String = str(hero.get("targetId", ""))
	for actor: Dictionary in state.get("actors", []):
		if str(actor.get("id", "")) != target_id or bool(actor.get("isHero", false)) or str(actor.get("side", "enemy")) == "player" or int(actor.get("hp", 0)) <= 0:
			continue
		var role: String = "Leaping hunter" if str(actor.get("behavior", "melee")) == "werewolf" else "Melee prowler"
		var actor_name: String = str(actor.get("displayName", actor.get("name", "Vaultfang" if target_id=="crypt_alpha" else "Gloamfang")))
		return {"id":target_id, "name":actor_name, "role":role, "hp":int(actor.hp), "maxHp":int(actor.maxHp)}
	return {}

static func movement_destination(state: Dictionary) -> Array:
	if str(state.get("phase", "running")) not in ["running", "cleared"]:
		return []
	var hero: Dictionary = hero_actor(state)
	if hero.is_empty() or int(hero.get("hp", 0)) <= 0 or not str(hero.get("targetId", "")).is_empty():
		return []
	var path: Array = hero.get("path", [])
	return path.back().duplicate() if not path.is_empty() else []

static func map_markers(state: Dictionary) -> Array:
	var markers: Array = []
	var hero: Dictionary = hero_actor(state)
	if not hero.is_empty() and int(hero.get("hp", 0)) > 0:
		markers.append({"kind":"hero", "pos":hero.pos.duplicate()})
	var arena: Dictionary = state.get("arena", {})
	if arena.has("exit"):
		markers.append({"kind":"exit", "pos":arena.exit.duplicate()})
	for loot: Dictionary in state.get("loot", []):
		if not bool(loot.get("claimed", false)):
			markers.append({"kind":"loot", "pos":loot.pos.duplicate()})
	return markers

static func fitted_map_rect(bounds: Array, available: Rect2) -> Rect2:
	var extent: Vector2 = Vector2(float(bounds[2])-float(bounds[0]), float(bounds[3])-float(bounds[1]))
	if extent.x <= 0 or extent.y <= 0 or available.size.x <= 0 or available.size.y <= 0:
		return Rect2(available.position, Vector2.ZERO)
	var scale_value: float = minf(available.size.x/extent.x, available.size.y/extent.y)
	var fitted: Vector2 = extent*scale_value
	return Rect2(available.position+(available.size-fitted)*0.5, fitted)

static func map_point(position: Array, bounds: Array, rect: Rect2) -> Vector2:
	var fraction: Vector2 = Vector2((float(position[0])-float(bounds[0]))/maxf(0.001, float(bounds[2])-float(bounds[0])), (float(position[1])-float(bounds[1]))/maxf(0.001, float(bounds[3])-float(bounds[1])))
	return rect.position+fraction*rect.size

func _diamond(center: Vector2, radius: float, color: Color, filled: bool) -> void:
	var points: PackedVector2Array = PackedVector2Array([center+Vector2(0,-radius), center+Vector2(radius,0), center+Vector2(0,radius), center+Vector2(-radius,0)])
	if filled:
		draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		draw_polyline(points, color, 1.6, true)

func _draw() -> void:
	if action_state.is_empty() or _font == null:
		return
	var arena: Dictionary = action_state.get("arena", {})
	var bounds: Array = arena.get("bounds", [-10.0,-12.0,10.0,12.0])
	var legend_width: float = 82.0
	var available: Rect2 = Rect2(Vector2(10,8), Vector2(maxf(1,size.x-legend_width-24), maxf(1,size.y-16)))
	var rect: Rect2 = fitted_map_rect(bounds, available)
	if rect.size == Vector2.ZERO:
		return
	draw_rect(rect, Color(0.40,0.31,0.19,0.08))
	draw_rect(rect, UI.MUTED, false, 1.3)
	for obstacle: Dictionary in arena.get("obstacles", []):
		if obstacle.has("rect"):
			var footprint: Array = obstacle.rect
			var first: Vector2 = map_point([footprint[0],footprint[1]], bounds, rect)
			var last: Vector2 = map_point([float(footprint[0])+float(footprint[2]),float(footprint[1])+float(footprint[3])], bounds, rect)
			var shape: Rect2 = Rect2(first,last-first).intersection(rect)
			draw_rect(shape, Color("857354"))
			draw_rect(shape, UI.INK, false, 1.0)
		elif obstacle.has("pos") and obstacle.has("radius"):
			var point: Vector2 = map_point(obstacle.pos, bounds, rect)
			var radius: float = float(obstacle.radius)*rect.size.x/maxf(0.001,float(bounds[2])-float(bounds[0]))
			draw_circle(point,radius,Color("857354"))
	var markers: Array = map_markers(action_state)
	# Draw the hero last so overlapping loot or an entry seal cannot hide her.
	for marker: Dictionary in markers:
		if str(marker.kind) == "hero":
			continue
		var point: Vector2 = map_point(marker.pos,bounds,rect)
		if str(marker.kind)=="exit":
			_diamond(point,5.0,EXIT_INK,false)
		else:
			_diamond(point,3.7,LOOT_INK,true)
	for marker: Dictionary in markers:
		if str(marker.kind)=="hero":
			var point: Vector2 = map_point(marker.pos,bounds,rect)
			draw_circle(point,4.8,UI.IVORY)
			draw_circle(point,3.2,HERO_INK)
	var legend_x: float = size.x-legend_width+2
	var legend_y: float = maxf(27.0,size.y*0.5-19)
	draw_string(_font,Vector2(legend_x,17),"N ↑",HORIZONTAL_ALIGNMENT_LEFT,legend_width-4,14,UI.MUTED)
	draw_circle(Vector2(legend_x+4,legend_y-4),3.2,HERO_INK)
	draw_string(_font,Vector2(legend_x+16,legend_y),"Mara",HORIZONTAL_ALIGNMENT_LEFT,legend_width-18,14,UI.INK)
	_diamond(Vector2(legend_x+4,legend_y+19),4.5,EXIT_INK,false)
	draw_string(_font,Vector2(legend_x+16,legend_y+23),"Entrance",HORIZONTAL_ALIGNMENT_LEFT,legend_width-18,14,UI.INK)
	_diamond(Vector2(legend_x+4,legend_y+42),3.8,LOOT_INK,true)
	draw_string(_font,Vector2(legend_x+16,legend_y+46),"Spoils",HORIZONTAL_ALIGNMENT_LEFT,legend_width-18,14,UI.INK)
