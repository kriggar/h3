class_name ItemRules
extends RefCounted
## Original item catalog and bounded, persistent item instances for the action rebuild.
## No external game's names, item formulas, or data tables are used.

const EQUIPMENT_SLOTS: Array[String] = ["head", "chest", "hands", "legs", "feet", "cloak", "main_hand", "off_hand", "amulet", "ring_1", "ring_2"]
const QUALITIES: Array[String] = ["normal", "magic", "rare", "set", "unique"]
const BASE_STATS: Dictionary = {"maxHp":120.0, "maxMana":40.0, "attack":18.0, "armor":2.0, "speed":4.6, "wardBonus":0.0}
const ATTRIBUTE_DEFINITIONS: Array = [
	{"id":"might", "name":"Might", "description":"Each invested point grants 1 Attack to weapon strikes and abilities that scale with Attack.", "effects":{"attack":1.0}, "base":10, "maxInvestment":40},
	{"id":"finesse", "name":"Finesse", "description":"Each invested point grants 0.04 movement speed, helping you reposition and avoid attacks.", "effects":{"speed":0.04}, "base":10, "maxInvestment":40},
	{"id":"vitality", "name":"Vitality", "description":"Each invested point grants 6 maximum Health. Increasing the maximum does not heal current wounds.", "effects":{"maxHp":6.0}, "base":10, "maxInvestment":40},
	{"id":"spirit", "name":"Spirit", "description":"Each invested point grants 2 maximum Focus and 1 additional damage absorption when casting Ward. Increasing the maximum does not restore Focus.", "effects":{"maxMana":2.0, "wardBonus":1.0}, "base":10, "maxInvestment":40}
]

static func attribute_catalog() -> Array:
	return ATTRIBUTE_DEFINITIONS.duplicate(true)

static func attribute_bonuses(hero: Dictionary) -> Dictionary:
	# RealmRules owns point budgets and save validation. ItemRules is the single
	# stat-composition path used by equipment previews and encounter snapshots.
	var bonuses: Dictionary = {}
	var progression: Variant = hero.get("progression", {})
	if not progression is Dictionary or not progression.get("allocations", {}) is Dictionary:
		return bonuses
	var allocations: Dictionary = progression.get("allocations", {})
	for definition: Dictionary in ATTRIBUTE_DEFINITIONS:
		var raw: Variant = allocations.get(str(definition.id), 0)
		if not (raw is int or raw is float) or not is_finite(float(raw)) or float(raw) != floor(float(raw)) or float(raw) < 0.0 or float(raw) > float(definition.maxInvestment):
			continue
		for stat: String in definition.effects:
			bonuses[stat] = float(bonuses.get(stat, 0.0)) + float(definition.effects[stat]) * int(raw)
	return bonuses

static func catalog() -> Dictionary:
	return {
		"traveller_blade": _definition("Wayfarer's Blade", "main_hand", "normal", "traveller_sword", {"attack":0}, "A reliable, balanced sword. Its edge is familiar.", 12),
		"linen_coat": _definition("Roadworn Gambeson", "chest", "normal", "linen_coat", {"armor":1}, "Layers of quilted linen soften a glancing blow.", 8),
		"road_boots": _definition("Wayfarer's Boots", "feet", "normal", "leather_boots", {"maxHp":4}, "Made for wet roads and long journeys.", 6),
		"socketed_blade": _definition("Notched Ironblade", "main_hand", "normal", "iron_sword", {"attack":1}, "Two empty rune seats make this plain blade worth keeping.", 24, 2),
		"oathkeeper_blade": _definition("Vowkeeper", "main_hand", "unique", "vowkeeper_sword", {"attack":3}, "Cleave deals 15% less damage. A successful Cleave grants 8 Ward per enemy struck, up to 24. The strongest Ward replaces weaker protection.", 100, 0, "", ["cleave_ward"]),
		"bellwarden_hood": _definition("Bellworn Cowl", "head", "set", "bellwarden_hood", {"armor":2, "maxMana":4}, "A stitched mark recalls the watch that never abandoned its post.", 35, 0, "bellwarden"),
		"bellwarden_coat": _definition("Bellworn Hauberk", "chest", "set", "bellwarden_coat", {"armor":3, "maxHp":8}, "Dark rings of iron over worn wool.", 48, 0, "bellwarden"),
		"bellwarden_gloves": _definition("Bellworn Grips", "hands", "set", "bellwarden_gloves", {"armor":1, "maxMana":4}, "The palm stitching steadies a warding gesture.", 30, 0, "bellwarden"),
		"bellwarden_greaves": _definition("Bellworn Greaves", "legs", "set", "bellwarden_greaves", {"armor":2, "maxHp":6}, "Flexible plates protect the knee without binding it.", 38, 0, "bellwarden"),
		"bellwarden_boots": _definition("Bellworn Treads", "feet", "set", "bellwarden_boots", {"armor":1, "speed":0.12}, "Quiet boots for the long night watch.", 32, 0, "bellwarden"),
		"mist_amulet": _definition("Mistglass Pendant", "amulet", "magic", "mistglass_amulet", {}, "An imperfect blue stone carries two useful enchantments.", 32, 0, "", [], [{"id":"deep_focus", "stat":"maxMana", "min":6, "max":12}, {"id":"patient_ward", "stat":"wardBonus", "min":2, "max":4}]),
		"sentinel_ring": _definition("Watcher's Knot", "ring", "rare", "sentinel_ring", {}, "A rare ring whose rolled protections can suit a mixed build.", 36, 0, "", [], [{"id":"hardiness", "stat":"maxHp", "min":6, "max":14}, {"id":"iron_skin", "stat":"armor", "min":1, "max":2}, {"id":"quiet_focus", "stat":"maxMana", "min":2, "max":6}]),
		"rune_cinder": _definition("Cinder Rune", "material", "normal", "rune_cinder", {"attack":2}, "Socket: +2 Attack. Recipe order matters.", 10),
		"rune_stone": _definition("Stone Rune", "material", "normal", "rune_stone", {"armor":1}, "Socket: +1 Armor. Recipe order matters.", 10),
		"rune_gale": _definition("Gale Rune", "material", "normal", "rune_gale", {"maxMana":5}, "Socket: +5 maximum Focus. Recipe order matters.", 10),
		"gem_amber": _definition("Cut Amber", "material", "normal", "gem_amber", {"maxHp":5}, "Socket: +5 maximum Health. Gems do not complete rune recipes.", 8)
	}

static func _definition(item_name: String, slot: String, quality: String, equipment_id: String, stats: Dictionary, description: String, value: int, sockets: int = 0, set_id: String = "", traits: Array = [], rolls: Array = []) -> Dictionary:
	return {"name":item_name, "slot":slot, "quality":quality, "equipmentId":equipment_id, "stats":stats, "description":description, "value":value, "socketCapacity":sockets, "setId":set_id, "traits":traits, "rolls":rolls, "requiredLevel":1}

static func recipes() -> Dictionary:
	return {
		"hearthguard":{"name":"Hearthguard", "runes":["rune_cinder", "rune_stone"], "baseIds":["socketed_blade"], "stats":{"armor":2, "wardBonus":4}, "description":"Cinder then Stone in a two-seat Ironblade. Adds 2 Armor and 4 Ward capacity."},
		"windscar":{"name":"Windscar", "runes":["rune_cinder", "rune_gale"], "baseIds":["socketed_blade"], "stats":{"attack":2, "speed":0.2}, "description":"Cinder then Gale in a two-seat Ironblade. Adds 2 Attack and 0.2 movement speed."}
	}

static func set_catalog() -> Dictionary:
	return {"bellwarden":{"name":"The Bellworn Vigil", "pieces":["bellwarden_hood", "bellwarden_coat", "bellwarden_gloves", "bellwarden_greaves", "bellwarden_boots"], "bonuses":{2:{"armor":4, "maxMana":10}, 4:{"wardBonus":8}}, "description":"2 pieces: +4 Armor, +10 maximum Focus. 4 pieces: Ward absorbs 8 additional damage."}}

static func make_instance(item_id: String, instance_id: String, roll_seed: int = 0) -> Dictionary:
	var entries: Dictionary = catalog()
	if not entries.has(item_id) or instance_id.is_empty() or instance_id.length() > 220:
		return {}
	var d: Dictionary = entries[item_id]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = roll_seed
	var affixes: Array = []
	for spec: Dictionary in d.rolls:
		affixes.append({"id":spec.id, "stat":spec.stat, "tier":1, "value":rng.randi_range(int(spec.min), int(spec.max))})
	return {"instanceId":instance_id, "itemId":item_id, "baseId":item_id, "quality":d.quality, "uniqueId":item_id if d.quality == "unique" else "", "setId":d.setId, "equipmentId":d.equipmentId, "slot":d.slot, "requiredLevel":d.requiredLevel, "rollSeed":roll_seed, "affixes":affixes, "sockets":{"capacity":d.socketCapacity, "contents":[]}, "recipeId":"", "identified":true}

static func validate_instance(instance: Variant) -> bool:
	if not instance is Dictionary:
		return false
	var required: Array[String] = ["instanceId", "itemId", "baseId", "quality", "uniqueId", "setId", "equipmentId", "slot", "requiredLevel", "rollSeed", "affixes", "sockets", "recipeId", "identified"]
	for field: String in required:
		if not instance.has(field):
			return false
	if not instance.instanceId is String or not instance.itemId is String or not _integer(instance.rollSeed):
		return false
	var expected: Dictionary = make_instance(instance.itemId, instance.instanceId, int(instance.rollSeed))
	if expected.is_empty():
		return false
	for field: String in ["baseId", "quality", "uniqueId", "setId", "equipmentId", "slot", "requiredLevel"]:
		if instance[field] != expected[field]:
			return false
	if not instance.affixes is Array or instance.affixes.size() != expected.affixes.size():
		return false
	for index: int in range(expected.affixes.size()):
		var affix: Variant = instance.affixes[index]
		var expected_affix: Dictionary = expected.affixes[index]
		if not affix is Dictionary or affix.keys().size() != 4:
			return false
		if affix.get("id", null) != expected_affix.id or affix.get("stat", null) != expected_affix.stat:
			return false
		if not _integer(affix.get("tier", null)) or not _integer(affix.get("value", null)):
			return false
		if int(affix.tier) != int(expected_affix.tier) or int(affix.value) != int(expected_affix.value):
			return false
	if not instance.identified is bool or not instance.sockets is Dictionary:
		return false
	var sockets: Dictionary = instance.sockets
	if sockets.get("capacity", -1) != expected.sockets.capacity or not sockets.get("contents", null) is Array:
		return false
	if sockets.contents.size() > int(sockets.capacity):
		return false
	for content: Variant in sockets.contents:
		if not content is Dictionary or content.keys().size() != 1 or not content.get("itemId", null) is String:
			return false
		if not _is_socket_material(content.itemId):
			return false
	return instance.recipeId is String and instance.recipeId == _recipe_for(instance.itemId, sockets.contents)

static func _integer(value: Variant) -> bool:
	return (value is int) or (value is float and is_finite(value) and value == floor(value) and absf(value) < 9007199254740992.0)

static func _is_socket_material(item_id: String) -> bool:
	return item_id in ["rune_cinder", "rune_stone", "rune_gale", "gem_amber"]

static func _recipe_for(item_id: String, contents: Array) -> String:
	var sequence: Array = []
	for entry: Dictionary in contents:
		sequence.append(entry.itemId)
	var all_recipes: Dictionary = recipes()
	for recipe_id: String in all_recipes:
		var recipe: Dictionary = all_recipes[recipe_id]
		if item_id in recipe.baseIds and sequence == recipe.runes:
			return recipe_id
	return ""

static func item_name(instance: Dictionary) -> String:
	var definition: Dictionary = catalog().get(str(instance.get("itemId", "")), {})
	if definition.is_empty():
		return "Unknown item"
	var recipe_id: String = str(instance.get("recipeId", ""))
	return str(recipes()[recipe_id].name) if recipes().has(recipe_id) else str(definition.name)

static func item_stats(instance: Dictionary) -> Dictionary:
	if not validate_instance(instance):
		return {}
	var entries: Dictionary = catalog()
	var values: Dictionary = entries[instance.itemId].stats.duplicate(true)
	for affix: Dictionary in instance.affixes:
		_add_stats(values, {affix.stat:affix.value})
	for content: Dictionary in instance.sockets.contents:
		_add_stats(values, entries[content.itemId].stats)
	if not str(instance.recipeId).is_empty():
		_add_stats(values, recipes()[instance.recipeId].stats)
	return values

static func _add_stats(target: Dictionary, addition: Dictionary) -> void:
	for stat: String in addition:
		if BASE_STATS.has(stat):
			target[stat] = float(target.get(stat, 0.0)) + float(addition[stat])

static func find_instance(hero: Dictionary, instance_id: String) -> Dictionary:
	for item: Variant in hero.get("inventory", []):
		if item is Dictionary and item.get("instanceId", "") == instance_id:
			return item
	return {}

static func derive_stats(hero: Dictionary) -> Dictionary:
	var result: Dictionary = BASE_STATS.duplicate(true)
	var base: Dictionary = hero.get("baseStats", BASE_STATS)
	for stat: String in BASE_STATS:
		result[stat] = float(base.get(stat, BASE_STATS[stat]))
	_add_stats(result, attribute_bonuses(hero))
	var entries: Dictionary = catalog()
	var traits: Array[String] = []
	var counts: Dictionary = {}
	var equipped: Dictionary = hero.get("equipment", {})
	var seen: Dictionary = {}
	for slot: String in EQUIPMENT_SLOTS:
		var instance_id: String = str(equipped.get(slot, ""))
		if instance_id.is_empty() or seen.has(instance_id):
			continue
		var item: Dictionary = find_instance(hero, instance_id)
		if item.is_empty() or not validate_instance(item) or not slot_matches(str(item.slot), slot):
			continue
		seen[instance_id] = true
		_add_stats(result, item_stats(item))
		var definition: Dictionary = entries[item.itemId]
		for trait_name: String in definition.traits:
			if not traits.has(trait_name):
				traits.append(trait_name)
		if not str(item.setId).is_empty():
			counts[item.setId] = int(counts.get(item.setId, 0)) + 1
	for set_id: String in counts:
		var definition: Dictionary = set_catalog().get(set_id, {})
		for threshold: int in definition.get("bonuses", {}):
			if int(counts[set_id]) >= threshold:
				_add_stats(result, definition.bonuses[threshold])
	# Canonical decimal precision keeps fractional movement bonuses stable when
	# a pending encounter is serialized and its trusted snapshot is rebuilt.
	result["speed"] = float("%.4f" % float(result.speed))
	result["traits"] = traits
	result["sets"] = counts
	result["hp"] = clampf(float(hero.get("hp", result.maxHp)), 0.0, result.maxHp)
	result["mana"] = clampf(float(hero.get("mana", result.maxMana)), 0.0, result.maxMana)
	return result

static func slot_matches(item_slot: String, equipment_slot: String) -> bool:
	return item_slot == equipment_slot or (item_slot == "ring" and equipment_slot in ["ring_1", "ring_2"])

static func _can_change_equipment(hero: Dictionary) -> bool:
	# An allocation preview includes equipment/set totals. A real equipment
	# change therefore invalidates the same optimistic transaction revision.
	if not hero.has("progression"):
		return true
	var progression: Variant = hero.progression
	return progression is Dictionary and _integer(progression.get("revision")) and int(progression.revision) >= 0 and int(progression.revision) < 1000000000

static func _equipment_changed(hero: Dictionary) -> void:
	if hero.get("progression") is Dictionary:
		hero.progression.revision = int(hero.progression.revision) + 1

static func equip(hero: Dictionary, instance_id: String, requested_slot: String = "") -> Dictionary:
	var item: Dictionary = find_instance(hero, instance_id)
	if item.is_empty() or not validate_instance(item):
		return {"ok":false, "message":"That item is not in the pack."}
	if item.slot == "material":
		return {"ok":false, "message":"Runes and gems fit into sockets."}
	if int(hero.get("level", 1)) < int(item.requiredLevel):
		return {"ok":false, "message":"A higher hero level is required."}
	var equipment: Dictionary = hero.get("equipment", {})
	var slot: String = requested_slot
	if slot.is_empty():
		slot = str(item.slot)
		if slot == "ring":
			slot = "ring_1" if str(equipment.get("ring_1", "")).is_empty() else "ring_2"
	if not EQUIPMENT_SLOTS.has(slot) or not slot_matches(str(item.slot), slot):
		return {"ok":false, "message":"That item does not fit this equipment slot."}
	if not str(item.uniqueId).is_empty():
		for other_slot: String in EQUIPMENT_SLOTS:
			var other: Dictionary = find_instance(hero, str(equipment.get(other_slot, "")))
			if other_slot != slot and not other.is_empty() and other.get("uniqueId", "") == item.uniqueId:
				return {"ok":false, "message":"Only one copy of this unique item can be equipped."}
	var changed: bool = str(equipment.get(slot, "")) != instance_id
	if changed and not _can_change_equipment(hero):
		return {"ok":false, "message":"The equipment transaction limit has been reached."}
	if not hero.has("baseStats"):
		hero.baseStats = BASE_STATS.duplicate(true)
	for old_slot: String in EQUIPMENT_SLOTS:
		if str(equipment.get(old_slot, "")) == instance_id:
			equipment[old_slot] = ""
	equipment[slot] = instance_id
	hero.equipment = equipment
	if changed:
		_equipment_changed(hero)
	_apply_derived(hero)
	return {"ok":true, "message":"Equipped " + item_name(item) + ".", "slot":slot, "instanceId":instance_id}

static func unequip(hero: Dictionary, slot: String) -> Dictionary:
	if not EQUIPMENT_SLOTS.has(slot) or str(hero.get("equipment", {}).get(slot, "")).is_empty():
		return {"ok":false, "message":"That equipment slot is empty."}
	if not _can_change_equipment(hero):
		return {"ok":false, "message":"The equipment transaction limit has been reached."}
	hero.equipment[slot] = ""
	_equipment_changed(hero)
	_apply_derived(hero)
	return {"ok":true, "message":"Item returned to the pack."}

static func socket(hero: Dictionary, base_instance_id: String, material_instance_id: String) -> Dictionary:
	var base: Dictionary = find_instance(hero, base_instance_id)
	var material: Dictionary = find_instance(hero, material_instance_id)
	if base.is_empty() or material.is_empty() or not validate_instance(base) or not validate_instance(material):
		return {"ok":false, "message":"Both items must be in the pack."}
	if not _is_socket_material(str(material.itemId)):
		return {"ok":false, "message":"Choose a rune or a cut gem."}
	if base.sockets.contents.size() >= int(base.sockets.capacity):
		return {"ok":false, "message":"That item has no empty socket."}
	if not _can_change_equipment(hero):
		return {"ok":false, "message":"The equipment transaction limit has been reached."}
	base.sockets.contents.append({"itemId":material.itemId})
	base.recipeId = _recipe_for(str(base.itemId), base.sockets.contents)
	var inventory: Array = hero.get("inventory", [])
	for index: int in range(inventory.size() - 1, -1, -1):
		if inventory[index].get("instanceId", "") == material_instance_id:
			inventory.remove_at(index)
	_equipment_changed(hero)
	_apply_derived(hero)
	return {"ok":true, "message":"Socketed " + item_name(material) + (". " + item_name(base) + " is complete." if not str(base.recipeId).is_empty() else "."), "recipeId":base.recipeId}

static func _apply_derived(hero: Dictionary) -> void:
	var values: Dictionary = derive_stats(hero)
	for stat: String in ["maxHp", "maxMana", "attack", "armor", "speed", "wardBonus", "hp", "mana", "traits"]:
		hero[stat] = values[stat]

static func describe(instance: Dictionary) -> String:
	if not validate_instance(instance):
		return "Invalid item."
	var definition: Dictionary = catalog()[instance.itemId]
	var result: String = "%s\n%s %s\n\n%s" % [item_name(instance), str(instance.quality).capitalize(), str(instance.slot).replace("_", " "), definition.description]
	var labels: Dictionary = {"attack":"Attack", "armor":"Armor", "maxHp":"maximum Health", "maxMana":"maximum Focus", "speed":"movement speed", "wardBonus":"Ward capacity"}
	for stat: String in item_stats(instance):
		var value: float = float(item_stats(instance)[stat])
		if not is_zero_approx(value):
			result += "\n+%s %s" % [str(snappedf(value, 0.01)), labels.get(stat, stat)]
	if int(instance.sockets.capacity) > 0:
		result += "\n\nSockets: %d / %d filled" % [instance.sockets.contents.size(), instance.sockets.capacity]
		for content: Dictionary in instance.sockets.contents:
			result += "\n" + str(catalog()[content.itemId].name)
	if not str(instance.setId).is_empty():
		result += "\n\n" + str(set_catalog()[instance.setId].name) + "\n" + str(set_catalog()[instance.setId].description)
	return result
