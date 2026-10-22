class_name CampaignCore
extends RefCounted
## DRACONIA — original campaign rules. No Heroes III or VCMI source is included.
## All campaign state is JSON-compatible. Public functions mutate only on success.

const VERSION: int = 2
const WIDTH: int = 36
const HEIGHT: int = 26
const MAX_STACKS: int = 7
const RESOURCE_KEYS: Array = ["gold", "wood", "ore", "mercury", "sulfur", "crystal", "gems"]
const TERRAINS: Array = ["grass", "dirt", "water", "forest", "hill", "mountain", "snow"]
const RECRUITABLE: Array = ["spearman", "archer", "swordsman", "knight", "mage", "griffin"]
const GATED_UNITS: Dictionary = {"swordsman": "barracks", "mage": "mageTower", "griffin": "griffinRoost"}
const WARD_IDS: Array = ["dawnwell", "starwell", "oath-stone"]
const TOWN_IDS: Array = ["dawnwatch", "briar-glen", "white-monastery"]

const UNITS: Dictionary = {
	"spearman": {"name": "Oștean", "plural": "Oșteni", "image": "res://assets/animated/spearman.png", "hp": 10, "attack": 4, "defense": 5, "minDamage": 1, "maxDamage": 3, "speed": 4, "shots": 0, "cost": 60, "growth": 14},
	"archer": {"name": "Arcaș", "plural": "Arcași", "image": "res://assets/animated/archer.png", "hp": 10, "attack": 6, "defense": 3, "minDamage": 2, "maxDamage": 3, "speed": 4, "shots": 12, "cost": 100, "growth": 9},
	"swordsman": {"name": "Străjer", "plural": "Străjeri", "image": "res://assets/animated/swordsman.png", "hp": 35, "attack": 10, "defense": 12, "minDamage": 6, "maxDamage": 9, "speed": 5, "shots": 0, "cost": 300, "growth": 4},
	"knight": {"name": "Cavaler", "plural": "Cavaleri", "image": "res://assets/animated/knight.png", "hp": 60, "attack": 12, "defense": 12, "minDamage": 10, "maxDamage": 15, "speed": 7, "shots": 0, "cost": 650, "growth": 2},
	"mage": {"name": "Solomonar", "plural": "Solomonari", "image": "res://assets/animated/mage.png", "hp": 30, "attack": 10, "defense": 7, "minDamage": 7, "maxDamage": 10, "speed": 5, "shots": 8, "cost": 350, "growth": 3},
	"griffin": {"name": "Iele", "plural": "Iele", "image": "res://assets/animated/griffin.png", "hp": 26, "attack": 9, "defense": 9, "minDamage": 5, "maxDamage": 8, "speed": 8, "shots": 0, "cost": 320, "growth": 4, "flying": true},
	"skeleton": {"name": "Strigoi", "plural": "Strigoi", "image": "res://assets/animated/skeleton.png", "hp": 8, "attack": 5, "defense": 4, "minDamage": 1, "maxDamage": 3, "speed": 4, "shots": 0, "cost": 65, "growth": 14},
	"orc": {"name": "Spiriduș Blestemat", "plural": "Spiriduși Blestemați", "image": "res://assets/animated/orc.png", "hp": 20, "attack": 7, "defense": 5, "minDamage": 3, "maxDamage": 5, "speed": 4, "shots": 8, "cost": 160, "growth": 8},
	"wolf": {"name": "Vârcolac", "plural": "Vârcolaci", "image": "res://assets/animated/wolf.png", "hp": 24, "attack": 8, "defense": 6, "minDamage": 4, "maxDamage": 7, "speed": 7, "shots": 0, "cost": 190, "growth": 6},
	"dragon": {"name": "Balaur", "plural": "Balauri", "image": "res://assets/animated/dragon.png", "hp": 170, "attack": 18, "defense": 16, "minDamage": 22, "maxDamage": 32, "speed": 6, "shots": 0, "cost": 2600, "growth": 1, "flying": true}
}

const BUILDINGS: Array = [
	{"id": "townHall", "name": "Sfatul Cetății", "description": "A council of the town adds 400 gold to daily income.", "cost": {"gold": 2000, "wood": 5, "ore": 5}, "requires": [], "effect": {"income": {"gold": 400}}},
	{"id": "barracks", "name": "Curtea Străjerilor", "description": "Train Străjeri. Eight veterans become available immediately.", "cost": {"gold": 1200, "wood": 4, "ore": 4}, "requires": [], "effect": {"unlock": "swordsman", "stock": 8}},
	{"id": "mageTower", "name": "Turnul Solomonarilor", "description": "Recruit Solomonari. Resting at this town restores all mana.", "cost": {"gold": 1800, "wood": 4, "ore": 4, "crystal": 2}, "requires": [], "effect": {"unlock": "mage", "stock": 3}},
	{"id": "griffinRoost", "name": "Poiana Ielelor", "description": "A sacred grove welcomes flying Iele after the woodland oath is restored. Five Iele become available.", "cost": {"gold": 2200, "wood": 6, "ore": 4, "gems": 2}, "requires": ["barracks"], "effect": {"unlock": "griffin", "stock": 5}},
	{"id": "citadel", "name": "Ziduri de Piatră", "description": "Stone walls increase weekly recruitment growth by 50% and daily income by 100 gold.", "cost": {"gold": 2400, "wood": 6, "ore": 8}, "requires": ["barracks"], "effect": {"growthMultiplier": 1.5, "income": {"gold": 100}}},
	{"id": "capital", "name": "Tezaurul Voievodului", "description": "The treasury earns an additional 600 gold every day.", "cost": {"gold": 4500, "wood": 10, "ore": 10}, "requires": ["townHall", "citadel"], "effect": {"income": {"gold": 600}}}
]

const HERO_SKILLS: Array = [
	{"id": "valor", "name": "Vitejie", "description": "+2 hero attack per rank. Your entire army benefits.", "maxRank": 3, "effect": {"attack": 2}},
	{"id": "pathfinding", "name": "Poteci", "description": "+150 daily movement per rank. The extra movement is available immediately.", "maxRank": 3, "effect": {"maxMovement": 150}},
	{"id": "lore", "name": "Solomonărie", "description": "+1 spell power and +4 maximum mana per rank.", "maxRank": 3, "effect": {"power": 1, "maxMana": 4}}
]

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

static func _is_int(value: Variant, minimum: int = 0, maximum: int = 1000000000) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= minimum and number <= maximum

static func _numeric_seed(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return int(value) & 0xffffffff
	var label: String = str(value)
	var seed_number: int = 2166136261
	for index: int in range(label.length()):
		seed_number = ((seed_number ^ label.unicode_at(index)) * 16777619) & 0xffffffff
	return seed_number

static func _in_world(s: Dictionary, x: Variant, y: Variant) -> bool:
	return _is_int(x, 0, int(s.world.w) - 1) and _is_int(y, 0, int(s.world.h) - 1)

static func _log(s: Dictionary, message: String, kind: String = "info") -> String:
	s.log.append({"day": int(s.day), "text": message, "message": message, "type": kind})
	while s.log.size() > 80:
		s.log.pop_front()
	return message

static func _reveal(s: Dictionary, x: int, y: int, radius: int = 6) -> void:
	for yy: int in range(maxi(0, y - radius), mini(int(s.world.h) - 1, y + radius) + 1):
		for xx: int in range(maxi(0, x - radius), mini(int(s.world.w) - 1, x + radius) + 1):
			if (xx - x) * (xx - x) + (yy - y) * (yy - y) <= radius * radius:
				s.revealed[yy][xx] = true

static func _town_stock(monastery: bool = false) -> Dictionary:
	return {"buildings": ["mageTower"] if monastery else [], "stock": {"spearman": 14, "archer": 9, "swordsman": 0, "knight": 2, "mage": 3, "griffin": 0}, "builtDay": 0}

static func _add_object(objects: Array, id: String, kind: String, x: int, y: int, label: String, description: String, image_name: String, extra: Dictionary = {}) -> void:
	var object: Dictionary = {"id": id, "type": kind, "x": x, "y": y, "name": label, "description": description, "image": "res://assets/%s.png" % image_name, "owner": "neutral"}
	object.merge(extra, true)
	objects.append(object)

static func _mark_road(tiles: Array, x: int, y: int) -> void:
	var tile: Dictionary = tiles[y][x]
	if str(tile.terrain) == "water":
		tile.bridge = true
	elif str(tile.terrain) in ["mountain", "forest"]:
		tile.terrain = "snow" if x > 25 and y < 13 else "grass"
	tile.road = true

static func _carve(tiles: Array, first: Array, last: Array) -> void:
	var x: int = int(first[0])
	var y: int = int(first[1])
	_mark_road(tiles, x, y)
	while x != int(last[0]):
		x += 1 if int(last[0]) > x else -1
		_mark_road(tiles, x, y)
	while y != int(last[1]):
		y += 1 if int(last[1]) > y else -1
		_mark_road(tiles, x, y)

static func _make_world(seed_value: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var tiles: Array = []
	for y: int in range(HEIGHT):
		var row: Array = []
		for x: int in range(WIDTH):
			var terrain: String = ("snow" if y < 13 else "dirt") if x > 25 else "grass"
			var roll: float = rng.randf()
			if x < 15 and (sin(float(x) * 0.72) + cos(float(y) * 0.55) > 0.55 or roll < 0.18):
				terrain = "forest"
			if x > 21 and roll < 0.21:
				terrain = "hill"
			if (x > 23 and y < 5 and roll < 0.76) or (x > 29 and y > 17 and roll < 0.66):
				terrain = "mountain"
			var river: int = 16 + roundi(sin(float(y) * 0.33))
			if x == river or x == river + 1:
				terrain = "water"
			if pow(float(x - 5) / 3.7, 2.0) + pow(float(y - 5) / 2.4, 2.0) < 1.0:
				terrain = "water"
			if y == 0 or y == HEIGHT - 1:
				terrain = "forest" if x < 20 else "mountain"
			row.append({"terrain": terrain, "road": false, "bridge": false, "variant": rng.randi_range(0, 3)})
		tiles.append(row)
	var objects: Array = []
	_add_object(objects, "dawnwatch", "town", 6, 16, "Cetatea Zorilor", "Ileana's ancestral keep. Muster your people and restore the three oaths that once sheltered Draconia.", "castle", {"owner": "player", "income": {"gold": 700}})
	_add_object(objects, "briar-glen", "town", 20, 9, "Poiana Corbilor", "A market town under the night host. Free its garrison to gain income and a second recruiting ground.", "castle-elven", {"income": {"gold": 500}, "enemies": [{"type": "skeleton", "count": 16}, {"type": "archer", "count": 8}, {"type": "swordsman", "count": 4}], "rewards": {"gold": 1000, "xp": 400}})
	_add_object(objects, "white-monastery", "town", 23, 20, "Mănăstirea Albă", "The monastery's Solomonari are besieged by Strigoi. Liberation opens their tower and a refuge for restoring mana.", "castle-elven", {"income": {"gold": 450}, "enemies": [{"type": "skeleton", "count": 22}, {"type": "orc", "count": 8}], "rewards": {"gold": 900, "xp": 350}})
	_add_object(objects, "roadward", "enemy", 10, 17, "Prădătorii de la Vad", "Cursed spirits and Vârcolaci threaten the southern ford. A suitable first battle.", "orc", {"owner": "enemy", "threat": "Low", "enemies": [{"type": "orc", "count": 6}, {"type": "wolf", "count": 4}], "rewards": {"gold": 650, "xp": 180}})
	_add_object(objects, "hollow-watch", "enemy", 14, 11, "Straja Fără Somn", "Restless Strigoi stand watch beside the forest crossing.", "skeleton", {"owner": "enemy", "threat": "Moderate", "enemies": [{"type": "skeleton", "count": 20}, {"type": "wolf", "count": 6}], "rewards": {"gold": 850, "xp": 250}})
	_add_object(objects, "ashbound", "enemy", 25, 10, "Ceata Cenușii", "Cursed veterans guard the road into the northern highlands.", "orc", {"owner": "enemy", "threat": "Dangerous", "enemies": [{"type": "orc", "count": 20}, {"type": "wolf", "count": 14}], "rewards": {"gold": 1200, "xp": 500}})
	_add_object(objects, "varcolac-hunt", "enemy", 19, 22, "Haita Lunii Frânte", "A pack of Vârcolaci prowls the monastery road. Night strengthens them until the oaths are restored.", "wolf", {"owner": "enemy", "threat": "Dangerous", "enemies": [{"type": "wolf", "count": 14}], "rewards": {"gold": 950, "xp": 350}})
	_add_object(objects, "ashen-citadel", "enemy", 30, 8, "Cetatea Nopții", "Three broken oaths seal the fortress. Restore every oath, weaken the night host, then defeat its Balauri to free Draconia.", "castle-orc", {"owner": "enemy", "final": true, "threat": "Deadly", "enemies": [{"type": "dragon", "count": 4}, {"type": "orc", "count": 36}, {"type": "skeleton", "count": 51}], "rewards": {"gold": 3000, "xp": 900}})
	_add_object(objects, "oak-sawmill", "mine", 4, 12, "Joagărul Codrului", "Claim the forest sawmill for 2 wood each day.", "sawmill", {"resource": "wood", "income": {"wood": 2}})
	_add_object(objects, "stone-quarry", "mine", 12, 21, "Cariera Pietrei Albe", "Claim the quarry for 2 ore each day.", "mine", {"resource": "ore", "income": {"ore": 2}})
	_add_object(objects, "gold-mine", "mine", 24, 16, "Vâna Voievodului", "An old royal seam yields 300 gold each day.", "mine", {"resource": "gold", "income": {"gold": 300}})
	_add_object(objects, "crystal-mine", "mine", 29, 4, "Peștera de Cleștar", "A highland cavern yields 1 crystal each day.", "mine", {"resource": "crystal", "income": {"crystal": 1}})
	var supplies: Array = [["timber-1", 8, 18, "wood", 5], ["ore-1", 6, 20, "ore", 5], ["gold-1", 9, 14, "gold", 450], ["gold-2", 3, 17, "gold", 350], ["crystal-1", 12, 14, "crystal", 2], ["ore-2", 12, 8, "ore", 4], ["timber-2", 18, 20, "wood", 5], ["gold-3", 22, 18, "gold", 500], ["gems-1", 19, 13, "gems", 3], ["sulfur-1", 24, 12, "sulfur", 3], ["mercury-1", 24, 7, "mercury", 3], ["gold-4", 31, 12, "gold", 600]]
	for entry: Array in supplies:
		var resource: String = str(entry[3])
		var amount: int = int(entry[4])
		var asset: String = resource if resource in ["gold", "wood", "ore", "crystal"] else ("potion" if resource == "mercury" else "crystal")
		_add_object(objects, str(entry[0]), "resource", int(entry[1]), int(entry[2]), resource.capitalize() + " Cache", "Collect %d %s." % [amount, resource], asset, {"resource": resource, "amount": amount, "rewards": {resource: amount}})
	_add_object(objects, "woodland-chest", "chest", 8, 10, "Cufărul Negustorului", "A lost caravan's strongbox: 700 gold and 60 experience.", "chest", {"rewards": {"gold": 700, "xp": 60}})
	_add_object(objects, "highland-chest", "chest", 27, 6, "Comoara din Trecătoare", "A hidden war chest: 1,100 gold and 80 experience.", "chest", {"rewards": {"gold": 1100, "xp": 80}})
	_add_object(objects, "dawnwell", "shrine", 11, 11, "Jurământul Codrului", "Defeat the corrupted guardians and swear the woodland oath. Restore all mana, weaken the fortress, and earn the trust of the Iele.", "well", {"enemies": [{"type": "skeleton", "count": 14}, {"type": "wolf", "count": 4}], "rewards": {"gold": 700, "xp": 300}, "warded": false, "threat": "Moderate"})
	_add_object(objects, "starwell", "shrine", 26, 14, "Jurământul Apelor", "The river oath has fallen to cursed guardians. Restoring it reduces the strength of the night and restores all mana.", "well", {"enemies": [{"type": "orc", "count": 10}, {"type": "mage", "count": 4}], "rewards": {"gold": 900, "xp": 400}, "warded": false, "threat": "Dangerous"})
	_add_object(objects, "oath-stone", "shrine", 28, 5, "Jurământul Pietrei", "Balauri coil around the mountain oath. Restore the final ward to break the seal on Cetatea Nopții.", "monolith", {"enemies": [{"type": "skeleton", "count": 30}, {"type": "dragon", "count": 3}], "rewards": {"gold": 1200, "xp": 550}, "warded": false, "threat": "Deadly"})
	_add_object(objects, "waystone", "obelisk", 13, 6, "Piatra Străbunilor", "Read the ancestral runes to reveal the three oath sites and Cetatea Nopții, and gain 1 spell power.", "monolith")
	var routes: Array = [[[6, 16], [10, 16], [10, 17], [14, 17], [14, 19], [21, 19], [21, 14], [23, 14], [23, 10], [20, 10], [20, 9]], [[6, 16], [6, 10], [13, 10], [13, 9], [20, 9]], [[20, 9], [25, 9], [25, 10], [28, 10], [28, 8], [30, 8]], [[6, 16], [7, 16], [7, 17]], [[21, 19], [23, 19], [23, 20]], [[19, 19], [19, 22]], [[28, 8], [28, 5]]]
	for route: Array in routes:
		for index: int in range(1, route.size()):
			_carve(tiles, route[index - 1], route[index])
	for object: Dictionary in objects:
		var nearest: Array = [6, 16]
		var best: int = 100000
		for y: int in range(1, HEIGHT - 1):
			for x: int in range(1, WIDTH - 1):
				if not bool(tiles[y][x].road):
					continue
				var distance: int = absi(x - int(object.x)) + absi(y - int(object.y))
				if distance < best:
					best = distance
					nearest = [x, y]
		_carve(tiles, nearest, [int(object.x), int(object.y)])
	return {"w": WIDTH, "h": HEIGHT, "tiles": tiles, "objects": objects}

static func create_game(seed_value: Variant = "draconia-oaths") -> Dictionary:
	var seed_number: int = _numeric_seed(seed_value)
	var revealed: Array = []
	for y: int in range(HEIGHT):
		var row: Array = []
		row.resize(WIDTH)
		row.fill(false)
		revealed.append(row)
	var s: Dictionary = {"version": VERSION, "day": 1, "seed": seed_number, "resources": {"gold": 4200, "wood": 12, "ore": 12, "mercury": 3, "sulfur": 3, "crystal": 3, "gems": 3}, "hero": {"name": "Ileana", "title": "Keeper of the Three Oaths", "x": 7, "y": 17, "level": 1, "xp": 0, "attack": 2, "defense": 2, "power": 2, "mana": 24, "maxMana": 24, "movement": 1400, "maxMovement": 1400, "skills": {"valor": 0, "pathfinding": 0, "lore": 0}, "skillPoints": 0}, "army": [{"type": "spearman", "count": 24}, {"type": "archer", "count": 14}, {"type": "knight", "count": 3}], "world": _make_world(seed_number), "towns": {"dawnwatch": _town_stock(), "briar-glen": _town_stock(), "white-monastery": _town_stock(true)}, "revealed": revealed, "log": [], "victory": false, "defeated": false, "wards": [], "corruption": 60, "stats": {"battlesWon": 0, "minesClaimed": 0, "unitsRecruited": 0, "structuresBuilt": 0, "defeats": 0}}
	_reveal(s, int(s.hero.x), int(s.hero.y))
	_log(s, "Ileana raises her banner at Cetatea Zorilor. Restore three oaths to open Cetatea Nopții. Three days of light are followed by two nights; unrestored oaths strengthen the night host.")
	return s

static func tile_at(s: Dictionary, x: Variant, y: Variant) -> Variant:
	return s.world.tiles[int(y)][int(x)] if _in_world(s, x, y) else null

static func object_at(s: Dictionary, x: int, y: int) -> Variant:
	for object: Dictionary in s.world.objects:
		if not bool(object.get("removed", false)) and int(object.x) == x and int(object.y) == y:
			return object
	return null

static func _object_by_id(s: Dictionary, object_id: String, include_removed: bool = false) -> Variant:
	for object: Dictionary in s.world.objects:
		if str(object.id) == object_id and (include_removed or not bool(object.get("removed", false))):
			return object
	return null

static func _guarded(object: Variant) -> bool:
	if not object is Dictionary or bool(object.get("defeated", false)) or str(object.get("owner", "neutral")) == "player":
		return false
	for stack: Dictionary in object.get("enemies", []):
		if int(stack.get("count", 0)) > 0:
			return true
	return false

static func _traversable(tile: Variant) -> bool:
	return tile is Dictionary and str(tile.terrain) != "mountain" and (str(tile.terrain) != "water" or bool(tile.bridge))

static func _step_cost(first: Dictionary, last: Dictionary, diagonal: bool) -> int:
	var cost: int = 100
	if bool(first.road) and bool(last.road):
		cost = 65
	elif str(last.terrain) == "forest":
		cost = 140
	elif str(last.terrain) in ["hill", "snow"]:
		cost = 125
	return floori(float(cost) * (sqrt(2.0) if diagonal else 1.0))

static func find_path(s: Dictionary, tx: int, ty: int) -> Variant:
	if not _in_world(s, tx, ty) or not _traversable(tile_at(s, tx, ty)):
		return null
	var sx: int = int(s.hero.x)
	var sy: int = int(s.hero.y)
	if sx == tx and sy == ty:
		return []
	var start: int = sy * WIDTH + sx
	var target: int = ty * WIDTH + tx
	var costs: Dictionary = {start: 0}
	var previous: Dictionary = {}
	var open: Array = [{"x": sx, "y": sy, "cost": 0}]
	var closed: Dictionary = {}
	var guards: Dictionary = {}
	for object: Dictionary in s.world.objects:
		if not bool(object.get("removed", false)) and _guarded(object):
			guards[int(object.y) * WIDTH + int(object.x)] = true
	while not open.is_empty():
		var best: int = 0
		for index: int in range(1, open.size()):
			if int(open[index].cost) < int(open[best].cost):
				best = index
		var current: Dictionary = open.pop_at(best)
		var current_key: int = int(current.y) * WIDTH + int(current.x)
		if closed.has(current_key):
			continue
		closed[current_key] = true
		if current_key == target:
			var path: Array = []
			var at: int = target
			while at != start:
				if not previous.has(at):
					return null
				var node: Dictionary = previous[at]
				path.append({"x": at % WIDTH, "y": int(at / WIDTH), "cost": int(node.step), "totalCost": int(costs[at])})
				at = int(node.from)
			path.reverse()
			return path
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var x: int = int(current.x) + dx
				var y: int = int(current.y) + dy
				var next: Variant = tile_at(s, x, y)
				if not _traversable(next):
					continue
				var next_key: int = y * WIDTH + x
				if closed.has(next_key) or (guards.has(next_key) and next_key != target):
					continue
				if dx != 0 and dy != 0:
					if not _traversable(tile_at(s, int(current.x) + dx, int(current.y))) or not _traversable(tile_at(s, int(current.x), int(current.y) + dy)):
						continue
					if guards.has(int(current.y) * WIDTH + int(current.x) + dx) or guards.has((int(current.y) + dy) * WIDTH + int(current.x)):
						continue
				var step: int = _step_cost(tile_at(s, int(current.x), int(current.y)), next, dx != 0 and dy != 0)
				var cost: int = int(current.cost) + step
				if cost >= int(costs.get(next_key, 1000000000)):
					continue
				costs[next_key] = cost
				previous[next_key] = {"from": current_key, "step": step}
				open.append({"x": x, "y": y, "cost": cost})
	return null

static func travel(s: Dictionary, tx: int, ty: int) -> Dictionary:
	var path: Variant = find_path(s, tx, ty)
	if path == null:
		return {"ok": false, "message": "That destination is blocked. Find a road or bridge.", "path": [], "event": null}
	var total: int = 0 if path.is_empty() else int(path[-1].totalCost)
	if total > int(s.hero.movement):
		return {"ok": false, "message": "That journey needs %d movement; %d remains. Travel part of the way or end the day." % [total, int(s.hero.movement)], "path": path, "event": null}
	s.hero.movement = int(s.hero.movement) - total
	s.hero.x = tx
	s.hero.y = ty
	for point: Dictionary in path:
		_reveal(s, int(point.x), int(point.y))
	_reveal(s, tx, ty)
	var event: Variant = object_at(s, tx, ty)
	return {"ok": true, "message": "Reached %s." % str(event.name) if event != null else "Travelled %d tiles." % path.size(), "path": path, "event": event}

static func _close_to(s: Dictionary, object: Dictionary) -> bool:
	return maxi(absi(int(s.hero.x) - int(object.x)), absi(int(s.hero.y) - int(object.y))) <= 1

static func _add_resources(s: Dictionary, rewards: Dictionary) -> void:
	for key: String in RESOURCE_KEYS:
		if rewards.has(key):
			s.resources[key] = int(s.resources[key]) + int(rewards[key])

static func _award_xp(s: Dictionary, amount: int) -> void:
	s.hero.xp = int(s.hero.xp) + maxi(0, amount)
	var new_level: int = mini(10, 1 + int(int(s.hero.xp) / 500))
	while int(s.hero.level) < new_level:
		s.hero.level = int(s.hero.level) + 1
		s.hero.attack = int(s.hero.attack) + 1
		s.hero.defense = int(s.hero.defense) + 1
		s.hero.power = int(s.hero.power) + 1
		s.hero.maxMana = int(s.hero.maxMana) + 4
		s.hero.mana = mini(int(s.hero.maxMana), int(s.hero.mana) + 4)
		s.hero.skillPoints = int(s.hero.skillPoints) + 1
		_log(s, "Ileana reaches level %d: +1 attack, defense and spell power, +4 mana, and one skill choice." % int(s.hero.level), "level")

static func get_world_phase(s: Dictionary) -> Dictionary:
	var cycle_day: int = (int(s.day) - 1) % 5 + 1
	var daylight: bool = cycle_day <= 3
	return {"id": "day" if daylight else "night", "label": "Daylight" if daylight else "Nightfall", "cycleDay": cycle_day, "daysRemaining": 4 - cycle_day if daylight else 6 - cycle_day, "description": "Daylight gives your army +2 defense. Three daylight days precede two nights." if daylight else "The night host gains attack from corruption. Victories at night yield 25% more gold and experience."}

static func get_battle_context(s: Dictionary, _object: Dictionary = {}) -> Dictionary:
	var phase: Dictionary = get_world_phase(s)
	var wards: int = s.wards.size()
	var night: bool = str(phase.id) == "night"
	var enemy_bonus: int = ceili(float(s.corruption) / 15.0) if night else 0
	var defense_bonus: int = wards if night else 2
	var attack_bonus: int = int(wards / 2)
	var explanation: String = "%s · %d/3 oaths. Army +%d attack, +%d defense." % [str(phase.label), wards, attack_bonus, defense_bonus]
	if night:
		explanation += " Night host +%d attack; victory gold and experience +25%%." % enemy_bonus
	return {"phase": str(phase.id), "label": str(phase.label), "description": explanation, "attackBonus": attack_bonus, "defenseBonus": defense_bonus, "enemyAttackBonus": enemy_bonus, "enemyDefenseBonus": 0, "healing": 0, "warded": wards > 0, "wards": wards, "corruption": int(s.corruption), "rewardMultiplier": 1.25 if night else 1.0}

static func _weaken_fortress(s: Dictionary) -> void:
	var fortress: Variant = _object_by_id(s, "ashen-citadel", true)
	if fortress == null or bool(fortress.get("defeated", false)):
		return
	var ward_count: int = s.wards.size()
	var caps: Dictionary = {"dragon": 4, "orc": maxi(0, 36 - 3 * ward_count), "skeleton": maxi(0, 51 - 5 * ward_count)}
	var weakened: Array = []
	for stack: Dictionary in fortress.get("enemies", []):
		var count: int = mini(int(stack.count), int(caps.get(str(stack.type), 0)))
		if count > 0:
			weakened.append({"type": str(stack.type), "count": count})
	fortress.enemies = weakened

static func _attune_ward(s: Dictionary, object: Dictionary) -> String:
	if s.wards.has(str(object.id)):
		return "This oath is already restored."
	s.wards.append(str(object.id))
	s.corruption = maxi(0, 60 - 20 * s.wards.size())
	object.warded = true
	object.visited = true
	object.defeated = true
	object.enemies = []
	object.owner = "player"
	s.hero.mana = int(s.hero.maxMana)
	_weaken_fortress(s)
	var message: String = "%s restored (%d/3). All mana restored; corruption falls to %d. The fortress loses 3 cursed spirits and 5 Strigoi." % [str(object.name), s.wards.size(), int(s.corruption)]
	if str(object.id) == "dawnwell":
		message += " Iele will now join you at a sacred grove."
	if s.wards.size() == 3:
		message += " The seal is broken: Cetatea Nopții can now be challenged."
	return _log(s, message, "capture")

static func interact(s: Dictionary, object_id: String) -> Dictionary:
	var found: Variant = _object_by_id(s, object_id)
	if found == null:
		return _failure("There is nothing left to collect here.")
	var object: Dictionary = found
	if not _close_to(s, object):
		return _failure("Move Ileana to this location first.")
	if bool(object.get("final", false)) and not bool(object.get("defeated", false)) and s.wards.size() < 3:
		return _failure("Cetatea Nopții is sealed. Restore all three oaths first (%d/3 restored). The ancestral waystone reveals their locations." % s.wards.size())
	if _guarded(object):
		return {"ok": true, "message": "%s is defended. %s" % [str(object.name), str(get_battle_context(s, object).description)], "event": "battle", "object": object}
	match str(object.type):
		"town":
			if str(object.owner) != "player":
				object.owner = "player"
				if not s.towns.has(str(object.id)):
					s.towns[str(object.id)] = _town_stock(str(object.id) == "white-monastery")
			return {"ok": true, "message": "Welcome to %s." % str(object.name), "event": "town", "object": object}
		"resource", "chest":
			var rewards: Dictionary = object.get("rewards", {})
			_add_resources(s, rewards)
			_award_xp(s, int(rewards.get("xp", 0)))
			object.visited = true
			object.removed = true
			var gains: Array[String] = []
			for key: String in rewards:
				gains.append("%d %s" % [int(rewards[key]), "experience" if key == "xp" else key])
			return {"ok": true, "message": _log(s, "Collected %s." % ", ".join(gains), "reward"), "object": object}
		"mine":
			if str(object.owner) == "player":
				return _failure("%s already flies your banner." % str(object.name))
			object.owner = "player"
			object.visited = true
			s.stats.minesClaimed = int(s.stats.minesClaimed) + 1
			return {"ok": true, "message": _log(s, "%s claimed. Its income arrives at the start of each day." % str(object.name), "capture"), "object": object}
		"shrine":
			if bool(object.get("warded", false)) or s.wards.has(str(object.id)):
				return _failure("This oath is already restored. Its protection is permanent.")
			return {"ok": true, "message": _attune_ward(s, object), "object": object}
		"obelisk":
			if bool(object.get("visited", false)):
				return _failure("You have already read these ancestral runes.")
			object.visited = true
			s.hero.power = int(s.hero.power) + 1
			_reveal(s, 30, 8, 6)
			for ward_id: String in WARD_IDS:
				var ward: Dictionary = _object_by_id(s, ward_id)
				_reveal(s, int(ward.x), int(ward.y), 3)
			return {"ok": true, "message": _log(s, "The ancestral runes reveal all three oaths and Cetatea Nopții. Spell power increases by 1.", "reward"), "object": object}
	return {"ok": true, "message": "%s is secure." % str(object.name), "object": object}

static func _building(building_id: String) -> Variant:
	for definition: Dictionary in BUILDINGS:
		if str(definition.id) == building_id:
			return definition
	return null

static func get_income(s: Dictionary) -> Dictionary:
	var income: Dictionary = {}
	for key: String in RESOURCE_KEYS:
		income[key] = 0
	for object: Dictionary in s.world.objects:
		if str(object.owner) != "player" or bool(object.get("removed", false)):
			continue
		if str(object.type) in ["town", "mine"]:
			var production: Dictionary = object.get("income", {})
			for key: String in RESOURCE_KEYS:
				income[key] = int(income[key]) + int(production.get(key, 0))
		if str(object.type) == "town" and s.towns.has(str(object.id)):
			for building_id: String in s.towns[str(object.id)].buildings:
				var definition: Variant = _building(building_id)
				if definition != null:
					var production: Dictionary = definition.effect.get("income", {})
					for key: String in RESOURCE_KEYS:
						income[key] = int(income[key]) + int(production.get(key, 0))
	return income

static func _unit_unlocked(s: Dictionary, town: Dictionary, unit_type: String) -> bool:
	if GATED_UNITS.has(unit_type) and not town.buildings.has(GATED_UNITS[unit_type]):
		return false
	if unit_type == "griffin" and not s.wards.has("dawnwell"):
		return false
	return true

static func end_turn(s: Dictionary) -> Dictionary:
	var old_phase: String = str(get_world_phase(s).id)
	s.day = int(s.day) + 1
	var income: Dictionary = get_income(s)
	_add_resources(s, income)
	s.hero.movement = int(s.hero.maxMovement)
	var tower: bool = false
	for object: Dictionary in s.world.objects:
		if str(object.type) == "town" and str(object.owner) == "player" and _close_to(s, object) and s.towns[str(object.id)].buildings.has("mageTower"):
			tower = true
	s.hero.mana = int(s.hero.maxMana) if tower else mini(int(s.hero.maxMana), int(s.hero.mana) + 4)
	var weekly: bool = (int(s.day) - 1) % 7 == 0
	if weekly:
		for object: Dictionary in s.world.objects:
			if str(object.type) != "town" or str(object.owner) != "player" or not s.towns.has(str(object.id)):
				continue
			var town: Dictionary = s.towns[str(object.id)]
			var multiplier: float = 1.5 if town.buildings.has("citadel") else 1.0
			for unit_type: String in RECRUITABLE:
				if _unit_unlocked(s, town, unit_type):
					town.stock[unit_type] = int(town.stock.get(unit_type, 0)) + ceili(float(UNITS[unit_type].growth) * multiplier)
	var earned: Array[String] = []
	for key: String in RESOURCE_KEYS:
		if int(income[key]) > 0:
			earned.append("%d %s" % [int(income[key]), key])
	var phase: Dictionary = get_world_phase(s)
	var message: String = "Day %d · %s. Income: %s. Movement restored." % [int(s.day), str(phase.label), ", ".join(earned) if not earned.is_empty() else "none"]
	if weekly:
		message += " A new week brings fresh recruits."
	if old_phase != str(phase.id):
		message += " " + str(get_battle_context(s).description)
	return {"ok": true, "message": _log(s, message, "turn")}

static func _owned_town(s: Dictionary, town_id: String) -> Dictionary:
	var object: Variant = _object_by_id(s, town_id)
	if object == null or str(object.type) != "town" or str(object.owner) != "player" or not s.towns.has(town_id):
		return {"error": "You do not control this town."}
	if not _close_to(s, object):
		return {"error": "Visit the town with Ileana first."}
	return {"object": object, "town": s.towns[town_id]}

static func recruit(s: Dictionary, town_id: String, unit_type: String, count: Variant) -> Dictionary:
	var found: Dictionary = _owned_town(s, town_id)
	if found.has("error"):
		return _failure(str(found.error))
	if not RECRUITABLE.has(unit_type) or not _is_int(count, 1, 10000):
		return _failure("Choose a valid unit and a positive recruitment count.")
	var town: Dictionary = found.town
	var unit: Dictionary = UNITS[unit_type]
	if GATED_UNITS.has(unit_type) and not town.buildings.has(GATED_UNITS[unit_type]):
		return _failure("Build %s before recruiting %s." % [str(_building(str(GATED_UNITS[unit_type])).name), str(unit.plural)])
	if unit_type == "griffin" and not s.wards.has("dawnwell"):
		return _failure("Restore Jurământul Codrului first. The Iele will join only when their woodland oath is safe.")
	if int(town.stock.get(unit_type, 0)) < int(count):
		return _failure("There are not that many recruits available. New recruits arrive each week.")
	var stack: Variant = null
	for candidate: Dictionary in s.army:
		if str(candidate.type) == unit_type:
			stack = candidate
	if stack == null and s.army.size() >= MAX_STACKS:
		return _failure("Your army already has seven different stacks.")
	var total: int = int(unit.cost) * int(count)
	if int(s.resources.gold) < total:
		return _failure("Recruitment costs %d gold. You have %d." % [total, int(s.resources.gold)])
	s.resources.gold = int(s.resources.gold) - total
	town.stock[unit_type] = int(town.stock[unit_type]) - int(count)
	if stack != null:
		stack.count = int(stack.count) + int(count)
	else:
		s.army.append({"type": unit_type, "count": int(count)})
	s.stats.unitsRecruited = int(s.stats.unitsRecruited) + int(count)
	return {"ok": true, "message": _log(s, "Recruited %d %s for %d gold." % [int(count), str(unit.name) if int(count) == 1 else str(unit.plural), total], "recruit")}

static func build(s: Dictionary, town_id: String, building_id: String) -> Dictionary:
	var found: Dictionary = _owned_town(s, town_id)
	if found.has("error"):
		return _failure(str(found.error))
	var definition: Variant = _building(building_id)
	if definition == null:
		return _failure("Unknown building.")
	var town: Dictionary = found.town
	if town.buildings.has(building_id):
		return _failure("This building is already complete.")
	if int(town.builtDay) == int(s.day):
		return _failure("This town has already built today. End the day to build again.")
	for required: String in definition.requires:
		if not town.buildings.has(required):
			return _failure("Build %s first." % str(_building(required).name))
	if building_id == "griffinRoost" and not s.wards.has("dawnwell"):
		return _failure("Restore Jurământul Codrului before dedicating a grove to the Iele.")
	for key: String in definition.cost:
		if int(s.resources[key]) < int(definition.cost[key]):
			return _failure("You need %d %s to build %s." % [int(definition.cost[key]), key, str(definition.name)])
	for key: String in definition.cost:
		s.resources[key] = int(s.resources[key]) - int(definition.cost[key])
	town.buildings.append(building_id)
	town.builtDay = int(s.day)
	if definition.effect.has("unlock"):
		var unit_type: String = str(definition.effect.unlock)
		town.stock[unit_type] = maxi(int(town.stock.get(unit_type, 0)), int(definition.effect.stock))
	s.stats.structuresBuilt = int(s.stats.structuresBuilt) + 1
	return {"ok": true, "message": _log(s, "%s completed in %s." % [str(definition.name), str(found.object.name)], "build")}

static func choose_hero_skill(s: Dictionary, skill_id: String) -> Dictionary:
	var definition: Variant = null
	for skill: Dictionary in HERO_SKILLS:
		if str(skill.id) == skill_id:
			definition = skill
	if definition == null:
		return _failure("Unknown hero skill.")
	if int(s.hero.skillPoints) <= 0:
		return _failure("Earn a new level to gain a skill choice.")
	var rank: int = int(s.hero.skills.get(skill_id, 0))
	if rank >= int(definition.maxRank):
		return _failure("This skill has reached its maximum rank.")
	s.hero.skillPoints = int(s.hero.skillPoints) - 1
	s.hero.skills[skill_id] = rank + 1
	match skill_id:
		"valor":
			s.hero.attack = int(s.hero.attack) + 2
		"pathfinding":
			s.hero.maxMovement = int(s.hero.maxMovement) + 150
			s.hero.movement = int(s.hero.movement) + 150
		"lore":
			s.hero.power = int(s.hero.power) + 1
			s.hero.maxMana = int(s.hero.maxMana) + 4
			s.hero.mana = int(s.hero.mana) + 4
	return {"ok": true, "message": _log(s, "%s rises to rank %d. %s" % [str(definition.name), rank + 1, str(definition.description)], "level")}

static func _normalized_army(value: Variant, allow_empty: bool = true) -> Variant:
	if not value is Array or value.size() > MAX_STACKS:
		return null
	var counts: Dictionary = {}
	for item: Variant in value:
		if not item is Dictionary or not item.get("type") is String or not UNITS.has(str(item.type)) or not _is_int(item.get("count"), 0, 100000):
			return null
		if int(item.count) > 0:
			counts[str(item.type)] = int(counts.get(str(item.type), 0)) + int(item.count)
			if int(counts[str(item.type)]) > 100000:
				return null
	var result: Array = []
	for unit_type: String in counts:
		result.append({"type": unit_type, "count": int(counts[unit_type])})
	return null if not allow_empty and result.is_empty() else result

static func _army_subset(survivors: Array, original: Array) -> bool:
	var before: Dictionary = {}
	for stack: Dictionary in original:
		before[str(stack.type)] = int(before.get(str(stack.type), 0)) + int(stack.count)
	for stack: Dictionary in survivors:
		if int(stack.count) > int(before.get(str(stack.type), 0)):
			return false
	return true

static func resolve_battle(s: Dictionary, object_id: String, result: Dictionary) -> Dictionary:
	var found: Variant = _object_by_id(s, object_id)
	if found == null or not _guarded(found) or not _close_to(s, found):
		return _failure("There is no active encounter at this location.")
	var object: Dictionary = found
	if bool(object.get("final", false)) and s.wards.size() < 3:
		return _failure("All three oaths must be restored before the final battle.")
	var survivors: Variant = _normalized_army(result.get("army"))
	var enemy_remaining: Variant = _normalized_army(result.get("enemyRemaining", []))
	if survivors == null or enemy_remaining == null or not _is_int(result.get("mana"), 0, 500) or not result.get("victory") is bool or not result.get("retreated") is bool:
		return _failure("The battle result is incomplete.")
	if not _army_subset(survivors, s.army) or not _army_subset(enemy_remaining, object.enemies):
		return _failure("The battle result contains invalid reinforcements.")
	var won: bool = bool(result.victory) and not bool(result.retreated) and not survivors.is_empty()
	if bool(result.victory) and not bool(result.retreated) and (survivors.is_empty() or not enemy_remaining.is_empty()):
		return _failure("The reported victory has an invalid surviving army.")
	var context: Dictionary = get_battle_context(s, object)
	s.army = survivors
	s.hero.mana = mini(int(s.hero.maxMana), int(result.mana))
	if won:
		object.defeated = true
		object.visited = true
		object.enemies = []
		s.stats.battlesWon = int(s.stats.battlesWon) + 1
		var rewards: Dictionary = object.get("rewards", {}).duplicate(true)
		var gold: int = floori(float(rewards.get("gold", 0)) * float(context.rewardMultiplier))
		var experience: int = floori(float(rewards.get("xp", 0)) * float(context.rewardMultiplier))
		rewards.gold = gold
		_add_resources(s, rewards)
		_award_xp(s, experience)
		if str(object.type) == "town":
			object.owner = "player"
		elif str(object.type) == "shrine":
			_attune_ward(s, object)
		elif bool(object.get("final", false)):
			object.owner = "player"
			s.victory = true
		else:
			object.removed = true
		var message: String = "Draconia is free! Ileana has restored the three oaths and taken Cetatea Nopții." if bool(object.get("final", false)) else "Victory at %s! Gained %d gold and %d experience%s." % [str(object.name), gold, experience, " (night bonus included)" if str(context.phase) == "night" else ""]
		return {"ok": true, "message": _log(s, message, "victory")}
	if not enemy_remaining.is_empty():
		object.enemies = enemy_remaining
	var fee: int = mini(int(s.resources.gold), 200 if bool(result.retreated) else 350)
	s.resources.gold = int(s.resources.gold) - fee
	var total_loss: bool = s.army.is_empty()
	if total_loss:
		s.army = [{"type": "spearman", "count": 8}, {"type": "archer", "count": 4}]
	s.hero.x = 7
	s.hero.y = 17
	s.hero.movement = 0
	s.defeated = false
	s.stats.defeats = int(s.stats.defeats) + 1
	_reveal(s, 7, 17)
	var message: String = "%s. Ileana returns to Cetatea Zorilor. Recovery costs %d gold; movement is exhausted." % ["Retreat" if bool(result.retreated) else "Defeat", fee]
	message += " The garrison provides 8 Oșteni and 4 Arcași so you can rebuild." if total_loss else " Surviving troops remain with you."
	return {"ok": true, "message": _log(s, message, "defeat")}

static func get_objectives(s: Dictionary) -> Array:
	var mine_claimed: bool = false
	for object: Dictionary in s.world.objects:
		if str(object.type) == "mine" and str(object.owner) == "player":
			mine_claimed = true
	return [{"label": "Claim a mine and recruit reinforcements", "done": mine_claimed and int(s.stats.unitsRecruited) > 0}, {"label": "Restore Jurământul Codrului — earn the Iele's trust", "done": s.wards.has("dawnwell")}, {"label": "Liberate Poiana Corbilor", "done": str(_object_by_id(s, "briar-glen").owner) == "player"}, {"label": "Liberate Mănăstirea Albă", "done": str(_object_by_id(s, "white-monastery").owner) == "player"}, {"label": "Restore Jurământul Apelor", "done": s.wards.has("starwell")}, {"label": "Restore Jurământul Pietrei", "done": s.wards.has("oath-stone")}, {"label": "Take Cetatea Nopții and free Draconia", "done": bool(s.victory)}]

static func serialize(s: Dictionary) -> String:
	return JSON.stringify(s)

static func deserialize(json: String) -> Variant:
	if json.length() > 2000000:
		return null
	var parser: JSON = JSON.new()
	if parser.parse(json) != OK:
		return null
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return null
	var raw: Dictionary = parsed
	if not _is_int(raw.get("version"), 1, VERSION) or not _is_int(raw.get("seed"), 0, 0xffffffff) or not _is_int(raw.get("day"), 1, 100000):
		return null
	var legacy: bool = int(raw.version) == 1
	if not raw.get("resources") is Dictionary or not raw.get("world") is Dictionary or not raw.get("hero") is Dictionary:
		return null
	for key: String in RESOURCE_KEYS:
		if not _is_int(raw.resources.get(key)):
			return null
	var world: Dictionary = raw.world
	if world.get("w") != WIDTH or world.get("h") != HEIGHT or not world.get("tiles") is Array or world.tiles.size() != HEIGHT:
		return null
	for row: Variant in world.tiles:
		if not row is Array or row.size() != WIDTH:
			return null
		for tile: Variant in row:
			if not tile is Dictionary or not TERRAINS.has(tile.get("terrain")) or not tile.get("road") is bool or not tile.get("bridge") is bool or not _is_int(tile.get("variant"), 0, 3):
				return null
	var hero: Dictionary = raw.hero
	if not _is_int(hero.get("x"), 0, WIDTH - 1) or not _is_int(hero.get("y"), 0, HEIGHT - 1):
		return null
	for key: String in ["level", "xp", "attack", "defense", "power", "mana", "maxMana", "movement", "maxMovement"]:
		if not _is_int(hero.get(key)):
			return null
	if int(hero.mana) > int(hero.maxMana) or int(hero.movement) > int(hero.maxMovement) or int(hero.maxMana) > 500 or int(hero.maxMovement) > 10000 or int(hero.maxMovement) < 100 or int(hero.maxMana) < 1 or int(hero.level) < 1 or int(hero.level) > 10:
		return null
	if int(hero.level) != mini(10, 1 + int(int(hero.xp) / 500)) or int(hero.attack) > 1000 or int(hero.defense) > 1000 or int(hero.power) > 1000:
		return null
	var army: Variant = _normalized_army(raw.get("army"), false)
	if army == null:
		return null
	if not raw.get("revealed") is Array or raw.revealed.size() != HEIGHT:
		return null
	for row: Variant in raw.revealed:
		if not row is Array or row.size() != WIDTH:
			return null
		for entry: Variant in row:
			if not entry is bool:
				return null
	if not world.get("objects") is Array or world.objects.size() > 150 or not raw.get("towns") is Dictionary:
		return null
	if not raw.get("victory") is bool or not raw.get("defeated") is bool or not raw.get("stats") is Dictionary:
		return null
	for key: String in ["battlesWon", "minesClaimed", "unitsRecruited", "structuresBuilt", "defeats"]:
		if not _is_int(raw.stats.get(key)):
			return null
	if not raw.get("log") is Array or raw.log.size() > 80:
		return null
	for entry: Variant in raw.log:
		if not entry is Dictionary or not _is_int(entry.get("day"), 1, int(raw.day)) or not entry.get("text") is String or str(entry.text).length() > 1000:
			return null
	var skills: Dictionary = {"valor": 0, "pathfinding": 0, "lore": 0}
	var skill_points: int = int(hero.level) - 1
	var wards: Array = []
	if not legacy:
		if not hero.get("skills") is Dictionary or not _is_int(hero.get("skillPoints"), 0, 9) or not raw.get("wards") is Array or raw.wards.size() > 3:
			return null
		var spent: int = 0
		for key: String in skills:
			if not _is_int(hero.skills.get(key), 0, 3):
				return null
			skills[key] = int(hero.skills[key])
			spent += int(skills[key])
		skill_points = int(hero.skillPoints)
		if spent + skill_points != int(hero.level) - 1:
			return null
		for ward_id: Variant in raw.wards:
			if not ward_id is String or not WARD_IDS.has(ward_id) or wards.has(ward_id):
				return null
			wards.append(str(ward_id))
		if not _is_int(raw.get("corruption"), 0, 60) or int(raw.corruption) != 60 - wards.size() * 20:
			return null
	var clean: Dictionary = create_game(int(raw.seed))
	clean.day = int(raw.day)
	clean.log = []
	clean.wards = wards
	clean.corruption = 60 - wards.size() * 20
	clean.army = army
	clean.revealed = raw.revealed.duplicate(true)
	clean.victory = bool(raw.victory) if not legacy else false
	clean.defeated = false
	for key: String in RESOURCE_KEYS:
		clean.resources[key] = int(raw.resources[key])
	for key: String in ["x", "y", "level", "xp", "attack", "defense", "power", "mana", "maxMana", "movement", "maxMovement"]:
		clean.hero[key] = int(hero[key])
	clean.hero.skills = skills
	clean.hero.skillPoints = skill_points
	for key: String in ["battlesWon", "minesClaimed", "unitsRecruited", "structuresBuilt", "defeats"]:
		clean.stats[key] = int(raw.stats[key])
	# A version-1 save receives the new roads and oath sites; its old map uses a different RNG.
	if not legacy:
		for y: int in range(HEIGHT):
			for x: int in range(WIDTH):
				var tile: Dictionary = world.tiles[y][x]
				clean.world.tiles[y][x] = {"terrain": str(tile.terrain), "road": bool(tile.road), "bridge": bool(tile.bridge), "variant": int(tile.variant)}
	if not _traversable(tile_at(clean, int(clean.hero.x), int(clean.hero.y))):
		if not legacy:
			return null
		clean.hero.x = 7
		clean.hero.y = 17
	var seen: Dictionary = {}
	var new_ids: Array = ["white-monastery", "varcolac-hunt", "oath-stone"]
	for source: Variant in world.objects:
		if not source is Dictionary or not source.get("id") is String or seen.has(str(source.id)):
			return null
		var original: Variant = _object_by_id(clean, str(source.id), true)
		if original == null or (legacy and new_ids.has(str(source.id))) or source.get("x") != original.x or source.get("y") != original.y or source.get("type") != original.type or not ["player", "neutral", "enemy"].has(source.get("owner")):
			return null
		seen[str(source.id)] = true
		for flag: String in ["visited", "removed", "defeated", "warded"]:
			if source.has(flag) and not source[flag] is bool:
				return null
		var enemies: Variant = _normalized_army(source.get("enemies", []))
		if enemies == null:
			return null
		if original.has("enemies") and not _army_subset(enemies, original.enemies):
			return null
		if not original.has("enemies") and not enemies.is_empty():
			return null
		# The former healing wells become guarded oath sites, and the former finale reopens.
		if legacy and (WARD_IDS.has(str(source.id)) or str(source.id) == "ashen-citadel"):
			continue
		for flag: String in ["visited", "removed", "defeated"]:
			if source.has(flag):
				original[flag] = bool(source[flag])
		original.owner = str(source.owner)
		if original.has("enemies"):
			original.enemies = enemies
			if bool(original.get("defeated", false)) and not enemies.is_empty():
				return null
			if not bool(original.get("defeated", false)) and enemies.is_empty():
				return null
			if str(original.type) == "town" and (str(original.owner) == "player") != bool(original.get("defeated", false)):
				return null
			if str(original.type) == "enemy":
				if bool(original.get("final", false)):
					if (str(original.owner) == "player") != bool(original.get("defeated", false)) or bool(original.get("removed", false)):
						return null
				elif str(original.owner) != "enemy" or bool(original.get("removed", false)) != bool(original.get("defeated", false)):
					return null
		if bool(original.get("removed", false)) and not str(original.type) in ["resource", "chest", "enemy"]:
			return null
		if str(original.type) in ["resource", "chest", "obelisk"] and str(original.owner) != "neutral":
			return null
		if str(original.type) in ["resource", "chest"] and bool(original.get("visited", false)) != bool(original.get("removed", false)):
			return null
		if str(original.type) == "shrine":
			var warded: bool = wards.has(str(original.id))
			if bool(source.get("warded", false)) != warded or bool(source.get("defeated", false)) != warded or (str(source.owner) == "player") != warded:
				return null
			original.warded = warded
	var expected: int = clean.world.objects.size() - (new_ids.size() if legacy else 0)
	if seen.size() != expected:
		return null
	for town_id: String in TOWN_IDS:
		if legacy and town_id == "white-monastery":
			continue
		var source: Variant = raw.towns.get(town_id)
		if not source is Dictionary or not source.get("buildings") is Array or source.buildings.size() > BUILDINGS.size() or not _is_int(source.get("builtDay"), 0, int(raw.day)) or not source.get("stock") is Dictionary:
			return null
		var buildings: Array = []
		for building_id: Variant in source.buildings:
			if not building_id is String or _building(str(building_id)) == null or buildings.has(building_id):
				return null
			buildings.append(str(building_id))
		for building_id: String in buildings:
			for required: String in _building(building_id).requires:
				if not buildings.has(required):
					return null
		var stock: Dictionary = {}
		for unit_type: String in RECRUITABLE:
			if not _is_int(source.stock.get(unit_type, 0), 0, 100000):
				return null
			stock[unit_type] = int(source.stock.get(unit_type, 0))
		clean.towns[town_id] = {"buildings": buildings, "builtDay": int(source.builtDay), "stock": stock}
	if str(_object_by_id(clean, "dawnwatch").owner) != "player":
		return null
	var fortress: Dictionary = _object_by_id(clean, "ashen-citadel", true)
	if not legacy and (bool(clean.victory) != bool(fortress.get("defeated", false)) or (bool(clean.victory) and (wards.size() != 3 or str(fortress.owner) != "player"))):
		return null
	_weaken_fortress(clean)
	for entry: Dictionary in raw.log:
		var text: String = str(entry.text).replace("<", "").replace(">", "")
		var kind: String = str(entry.get("type", "info"))
		if not kind in ["info", "level", "reward", "capture", "turn", "recruit", "build", "victory", "defeat"]:
			kind = "info"
		clean.log.append({"day": int(entry.day), "text": text, "message": text, "type": kind})
	if legacy:
		_log(clean, "Your earlier campaign has arrived in Draconia. Army, resources and towns are preserved. Three guarded oaths and the new finale await; unspent level choices are available.")
	return clean
