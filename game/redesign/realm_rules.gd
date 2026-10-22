class_name RealmRules
extends RefCounted
## Isolated action-campaign state. The legacy CampaignCore is deliberately untouched.
## All mutations validate before commitment. The scene never owns costs or rewards.

const RULESET: String = "draconia_action_v1"
const VERSION: int = 5
const Identity = preload("res://game/redesign/hero_identity.gd")
const Hunts = preload("res://game/redesign/hunt_rules.gd")
const Dungeons = preload("res://game/redesign/dungeon_catalog.gd")
const MAX_LEVEL: int = 30
const POINTS_PER_LEVEL: int = 3
const MAX_ATTRIBUTE_INVESTMENT: int = 40
const ATTRIBUTE_IDS: Array = ["might", "finesse", "vitality", "spirit"]
const MAX_PROGRESS_REVISION: int = 1000000000
const WATCHES: Array = ["dawn", "afternoon", "dusk", "night"]
const RESOURCES: Array = ["gold", "wood", "ore", "food"]
const EQUIPMENT_SLOTS: Array = ["head", "chest", "hands", "legs", "feet", "cloak", "main_hand", "off_hand", "amulet", "ring_1", "ring_2"]
const ITEM_RULES_PATH: String = "res://game/redesign/item_rules.gd"
const MAX_SAVE_BYTES: int = 2000000
const SUPPLY_STOCK: Dictionary = {"socketed_blade":2,"rune_cinder":4,"rune_stone":4,"rune_gale":4,"gem_amber":4}
const BUILDINGS: Array = [
	{"id": "granary", "name": "Granary", "plotId": "grain_yard", "modelKey": "granary", "prerequisites": [], "cost": {"gold": 600, "wood": 5, "ore": 0}, "durationWatches": 0, "completion": "immediate", "exclusiveGroup": "", "effects": {"dailyIncome": {"food": 2}, "foodCapacity": 24}, "description": "Store 24 more provisions and produce 2 extra food each dawn."},
	{"id": "barracks", "name": "Training Yard", "plotId": "training_yard", "modelKey": "barracks", "prerequisites": [], "cost": {"gold": 800, "wood": 4, "ore": 4}, "durationWatches": 0, "completion": "immediate", "exclusiveGroup": "", "effects": {"dailyRecruitment": 2, "garrisonCapacity": 2}, "description": "Two trained recruits join the town's available pool each dawn. Garrison capacity increases by two companies."},
	{"id": "market", "name": "Market", "plotId": "market_square", "modelKey": "market", "prerequisites": ["granary"], "cost": {"gold": 900, "wood": 5, "ore": 2}, "durationWatches": 0, "completion": "immediate", "exclusiveGroup": "", "effects": {"dailyIncome": {"gold": 100}, "trade": true}, "description": "Earn 100 additional gold each dawn and exchange supplies at the market."},
	{"id": "smithy", "name": "Smithy", "plotId": "forge_yard", "modelKey": "smithy", "prerequisites": ["barracks"], "cost": {"gold": 1000, "wood": 3, "ore": 6}, "durationWatches": 0, "completion": "immediate", "exclusiveGroup": "", "effects": {"expeditionArmor": 1}, "description": "Prepared armor grants Mara Veyne +1 armor in expeditions departing from this town."},
	{"id": "shrine", "name": "Oath Hall", "plotId": "oath_court", "modelKey": "shrine", "prerequisites": ["granary"], "cost": {"gold": 750, "wood": 2, "ore": 3}, "durationWatches": 0, "completion": "immediate", "exclusiveGroup": "", "effects": {"restHealing": 20, "restMana": 8}, "description": "A watch of safe rest restores 20 additional health and 8 additional Focus."},
	{"id": "palisade", "name": "Palisade", "plotId": "perimeter", "modelKey": "palisade", "prerequisites": [], "cost": {"gold": 650, "wood": 8, "ore": 2}, "durationWatches": 0, "completion": "immediate", "exclusiveGroup": "", "effects": {"approachDelayWatches": 1, "garrisonCapacity": 1}, "description": "A hostile approach must spend one additional watch at the palisade. Garrison capacity increases by one company."},
	{"id": "wharf", "name": "Wharf", "plotId": "riverside", "modelKey": "wharf", "prerequisites": ["market"], "cost": {"gold": 900, "wood": 6, "ore": 3}, "durationWatches": 0, "completion": "immediate", "exclusiveGroup": "riverside", "effects": {"dailyIncome": {"gold": 80, "food": 1}}, "description": "River trade yields 80 gold and 1 food each dawn. Uses the same plot as the water gate."},
	{"id": "water_gate", "name": "Water Gate", "plotId": "riverside", "modelKey": "water_gate", "prerequisites": ["palisade"], "cost": {"gold": 1100, "wood": 4, "ore": 6}, "durationWatches": 0, "completion": "immediate", "exclusiveGroup": "riverside", "effects": {"approachDelayWatches": 1, "garrisonCapacity": 2}, "description": "Adds a second watch to hostile approaches and room for two more garrison companies. Excludes a wharf."}
]
const CRYPT_ACTORS: Array = [
	{"id": "crypt_wolf_1", "type": "wolf", "behavior": "melee", "pos": [-3, 3], "hp": 45, "maxHp": 45, "attack": 8, "armor": 0, "speed": 3.0, "companyId": ""},
	{"id": "crypt_wolf_2", "type": "wolf", "behavior": "melee", "pos": [3, 0], "hp": 45, "maxHp": 45, "attack": 8, "armor": 0, "speed": 3.0, "companyId": ""},
	{"id": "crypt_alpha", "type": "wolf", "behavior": "werewolf", "pos": [0, -7], "hp": 100, "maxHp": 100, "attack": 12, "armor": 3, "speed": 3.5, "companyId": ""}
]
const CRYPT_ARENA: Dictionary = {"bounds": [-10, -12, 10, 12], "obstacles": [{"rect": [-10, -3, 8, 0.9]}, {"rect": [2, -3, 8, 0.9]}, {"rect": [-6, 2, 1.4, 1.4]}, {"rect": [4.6, 2, 1.4, 1.4]}], "entry": [0, 9], "exit": [0, 10]}
const CRYPT_REWARDS: Array = [
	{"id": "crypt_weapon", "kind": "item", "itemId": "oathkeeper_blade", "sourceId": "crypt_alpha"},
	{"id": "crypt_set", "kind": "item", "itemId": "bellwarden_hood", "sourceId": "crypt_alpha"},
	{"id": "crypt_choice", "kind": "choice", "options": ["mist_amulet", "sentinel_ring"], "sourceId": "crypt_alpha"},
	{"id": "crypt_gold", "kind": "gold", "amount": 240, "sourceId": "crypt_alpha"}
]
const OBLIGATIONS: Dictionary = {
	"bell_oath": {"id": "bell_oath", "name": "Silence the Bell", "choiceId": "recover", "durationWatches": 12, "regionId": "woodland", "condition": "crypt_extracted", "reward": {"gold": 180}, "stabilityReward": 5, "stabilityPenalty": 8, "description": "Return alive from the cleared Bellworn Vault by the end of the twelfth watch after accepting. Earn 180 gold and restore 5 woodland stability."},
	"granary_oath": {"id": "granary_oath", "name": "Bread Before Winter", "choiceId": "build", "durationWatches": 8, "regionId": "woodland", "condition": "granary_built", "reward": {"food": 4}, "stabilityReward": 4, "stabilityPenalty": 6, "description": "Complete the granary within eight watches. The village contributes 4 food and gains 4 stability."}
}
const FACTION_NAMES: Dictionary = {"zorilor": "Ashen Crown", "codru": "Thornweald Court", "nori": "Cloudspire Conclave", "fara_zori": "Vesper Court", "luna_franta": "Gloamfang Clans", "arama": "Emberhorn Dominion", "ape": "Reedbound League", "hotar": "Ironroad Compact", "deepcairn": "Deepcairn Pact"}

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

static func _integer(value: Variant, low: int = 0, high: int = 1000000000) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= low and number <= high

static func _same(first: Variant, second: Variant) -> bool:
	# JSON restores all numbers as floats; dictionary equality otherwise rejects valid saves.
	if (first is int or first is float) and (second is int or second is float):
		return is_finite(float(first)) and is_finite(float(second)) and float(first) == float(second)
	if first is Dictionary and second is Dictionary:
		if first.size() != second.size():
			return false
		for key: Variant in first:
			if not second.has(key) or not _same(first[key], second[key]):
				return false
		return true
	if first is Array and second is Array:
		if first.size() != second.size():
			return false
		for index: int in range(first.size()):
			if not _same(first[index], second[index]):
				return false
		return true
	return typeof(first) == typeof(second) and first == second

static func _seed(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return int(value) & 0xffffffff
	var result: int = 2166136261
	for index: int in range(str(value).length()):
		result = ((result ^ str(value).unicode_at(index)) * 16777619) & 0xffffffff
	return result

static func _commit(target: Dictionary, source: Dictionary) -> void:
	target.clear()
	target.merge(source, true)

static func _record(state: Dictionary, kind: String, message: String, detail: Dictionary = {}) -> void:
	state.history.append({"watchIndex": int(state.watchIndex), "kind": kind, "message": message, "detail": detail.duplicate(true)})
	while state.history.size() > 160:
		state.history.pop_front()

static func _locked(state: Dictionary) -> bool:
	return state.get("pendingEncounter") != null or str(state.get("status", "active")) != "active"

static func experience_for_level(level: int) -> int:
	# Cumulative, original tuning: 100, 150, 200, ... XP between levels.
	var steps: int = clampi(level, 1, MAX_LEVEL) - 1
	return 100 * steps + 25 * steps * (steps - 1)

static func level_for_experience(experience: int) -> int:
	var level: int = 1
	while level < MAX_LEVEL and experience >= experience_for_level(level + 1):
		level += 1
	return level

static func _new_progression(level: int) -> Dictionary:
	return {"version":1, "allocations":{"might":0, "finesse":0, "vitality":0, "spirit":0}, "unspent":clampi(level, 1, MAX_LEVEL) * POINTS_PER_LEVEL, "revision":0, "resetCount":0}

static func _apply_fixed_identity(hero: Dictionary) -> void:
	# The current campaign has one implemented protagonist. A future new-run
	# selector can choose a different registered hero; no in-run identity swap.
	var definition: Dictionary = Identity.hero_definition("ileana")
	for key: String in ["classId", "raceId", "factionId"]:
		hero[key] = str(definition[key])
	hero["name"] = str(definition.name)
	hero["skills"] = Identity.class_skills(str(definition.classId))

static func _fixed_identity_valid(hero: Dictionary) -> bool:
	if str(hero.get("id", "")) != "ileana" or not Identity.identity_valid(hero):
		return false
	var definition: Dictionary = Identity.hero_definition(hero)
	if str(definition.get("canonicalId", "")) != "mara_veyne":
		return false
	for key: String in ["classId", "raceId", "factionId"]:
		if not hero.get(key) is String or str(hero[key]) != str(definition[key]):
			return false
	return _same(hero.get("skills"), Identity.class_skills(str(definition.classId)))

static func _valid_progression(hero: Dictionary) -> bool:
	if not _integer(hero.get("xp"), 0, experience_for_level(MAX_LEVEL)) or not _integer(hero.get("level"), 1, MAX_LEVEL) or int(hero.level) != level_for_experience(int(hero.xp)):
		return false
	var raw: Variant = hero.get("progression")
	if not raw is Dictionary or raw.size() != 5 or not _integer(raw.get("version"), 1, 1) or not raw.get("allocations") is Dictionary or raw.allocations.size() != ATTRIBUTE_IDS.size():
		return false
	if not _integer(raw.get("unspent"), 0, MAX_LEVEL * POINTS_PER_LEVEL) or not _integer(raw.get("revision"), 0, MAX_PROGRESS_REVISION) or not _integer(raw.get("resetCount"), 0, int(raw.revision)):
		return false
	var spent: int = 0
	for attribute: String in ATTRIBUTE_IDS:
		if not _integer(raw.allocations.get(attribute), 0, MAX_ATTRIBUTE_INVESTMENT):
			return false
		spent += int(raw.allocations[attribute])
	return spent + int(raw.unspent) == int(hero.level) * POINTS_PER_LEVEL

static func attribute_catalog() -> Array:
	return _items().attribute_catalog()

static func _progression_lock_reason(state: Dictionary) -> String:
	if not state.get("hero") is Dictionary or not _valid_progression(state.hero):
		return "Hero progression is unavailable or inconsistent."
	if state.get("pendingEncounter") != null:
		return "Finish the current expedition before changing attributes."
	if str(state.get("status", "")) != "active" or str(state.hero.get("state", "")) != "alive" or int(state.hero.get("hp", 0)) <= 0:
		return "Recover at a friendly refuge before changing attributes."
	if int(state.hero.progression.revision) >= MAX_PROGRESS_REVISION:
		return "The progression transaction limit has been reached."
	return ""

static func _attribute_reset_cost(level: int) -> int:
	return 0 if level <= 10 else mini(1000, 50 * (level - 10))

static func progression_view(state: Dictionary) -> Dictionary:
	var reason: String = _progression_lock_reason(state)
	if not state.get("hero") is Dictionary or not _valid_progression(state.hero):
		return {"ok":false, "message":reason, "canAllocate":false, "lockReason":reason}
	var hero: Dictionary = state.hero
	var level: int = int(hero.level)
	var floor_xp: int = experience_for_level(level)
	var next_xp: int = experience_for_level(mini(MAX_LEVEL, level + 1))
	var attributes: Dictionary = {}
	for attribute: String in ATTRIBUTE_IDS:
		attributes[attribute] = 10 + int(hero.progression.allocations[attribute])
	return {"ok":true, "level":level, "xp":int(hero.xp), "maxLevel":MAX_LEVEL, "levelFloorXp":floor_xp, "nextLevelXp":next_xp, "xpIntoLevel":int(hero.xp) - floor_xp, "xpToNextLevel":next_xp - int(hero.xp), "levelSpanXp":next_xp - floor_xp, "atCap":level == MAX_LEVEL, "unspent":int(hero.progression.unspent), "revision":int(hero.progression.revision), "allocations":hero.progression.allocations.duplicate(true), "attributes":attributes, "canAllocate":reason.is_empty() and int(hero.progression.unspent) > 0, "lockReason":reason if not reason.is_empty() else ("Earn another level to gain attribute points." if int(hero.progression.unspent) == 0 else ""), "resetCost":_attribute_reset_cost(level)}

static func preview_attribute_allocation(state: Dictionary, changes: Dictionary) -> Dictionary:
	var reason: String = _progression_lock_reason(state)
	if not reason.is_empty():
		return _failure(reason)
	var hero: Dictionary = state.hero
	var next: Dictionary = hero.duplicate(true)
	var cost: int = 0
	for raw_key: Variant in changes:
		if not raw_key is String or not ATTRIBUTE_IDS.has(raw_key) or not _integer(changes[raw_key], 0, MAX_ATTRIBUTE_INVESTMENT):
			return _failure("Choose whole, nonnegative points in the four supported attributes.")
		var attribute: String = str(raw_key)
		var points: int = int(changes[attribute])
		if int(next.progression.allocations[attribute]) + points > MAX_ATTRIBUTE_INVESTMENT:
			return _failure("No attribute can receive more than 40 invested points.")
		next.progression.allocations[attribute] = int(next.progression.allocations[attribute]) + points
		cost += points
	if cost <= 0:
		return _failure("Add at least one point to your draft allocation.")
	if cost > int(hero.progression.unspent):
		return _failure("The draft spends more attribute points than are available.")
	next.progression.unspent = int(next.progression.unspent) - cost
	return {"ok":true, "message":"Allocate %d attribute point%s. Current Health and Focus will not increase." % [cost, "" if cost == 1 else "s"], "before":_items().derive_stats(hero), "after":_items().derive_stats(next), "pointCost":cost, "pointsRemaining":int(next.progression.unspent), "revision":int(hero.progression.revision)}

static func allocate_attributes(state: Dictionary, changes: Dictionary, expected_revision: int = -1) -> Dictionary:
	var preview: Dictionary = preview_attribute_allocation(state, changes)
	if not bool(preview.ok):
		return preview
	if expected_revision >= 0 and expected_revision != int(preview.revision):
		return _failure("The hero changed after this preview. Review the allocation again.")
	var next: Dictionary = state.duplicate(true)
	for attribute: String in changes:
		next.hero.progression.allocations[attribute] = int(next.hero.progression.allocations[attribute]) + int(changes[attribute])
	next.hero.progression.unspent = int(preview.pointsRemaining)
	next.hero.progression.revision = int(next.hero.progression.revision) + 1
	_items()._apply_derived(next.hero)
	_record(next, "attributes", "Attribute points committed. Current Health and Focus are unchanged.", {"changes":changes.duplicate(true), "pointCost":int(preview.pointCost)})
	_commit(state, next)
	return {"ok":true, "message":"Attribute points committed.", "before":preview.before, "after":_items().derive_stats(state.hero), "pointCost":int(preview.pointCost), "pointsRemaining":int(state.hero.progression.unspent), "revision":int(state.hero.progression.revision), "progression":progression_view(state)}

static func preview_attribute_reset(state: Dictionary) -> Dictionary:
	var reason: String = _progression_lock_reason(state)
	if not reason.is_empty():
		return _failure(reason)
	var location: String = str(state.hero.get("locationId", ""))
	if not state.get("settlements") is Dictionary or not state.settlements.get(location) is Dictionary or str(state.settlements[location].get("owner", "")) != "zorilor":
		return _failure("Reset attributes while staying in a friendly town.")
	var refunded: int = int(state.hero.level) * POINTS_PER_LEVEL - int(state.hero.progression.unspent)
	if refunded <= 0:
		return _failure("No invested attribute points need resetting.")
	var cost: int = _attribute_reset_cost(int(state.hero.level))
	if not state.get("resources") is Dictionary or not _integer(state.resources.get("gold"), 0, 100000000) or int(state.resources.gold) < cost:
		return _failure("There is not enough gold for this attribute reset.")
	var hero: Dictionary = state.hero.duplicate(true)
	for attribute: String in ATTRIBUTE_IDS:
		hero.progression.allocations[attribute] = 0
	hero.progression.unspent = int(hero.level) * POINTS_PER_LEVEL
	return {"ok":true, "message":"Return %d invested points for %d gold. Current Health and Focus may be clamped to the lower maximum; neither is restored." % [refunded, cost], "before":_items().derive_stats(state.hero), "after":_items().derive_stats(hero), "goldCost":cost, "refundedPoints":refunded, "pointsRemaining":int(hero.progression.unspent), "revision":int(state.hero.progression.revision)}

static func reset_attributes(state: Dictionary, expected_revision: int = -1) -> Dictionary:
	var preview: Dictionary = preview_attribute_reset(state)
	if not bool(preview.ok):
		return preview
	if expected_revision >= 0 and expected_revision != int(preview.revision):
		return _failure("The hero changed after this preview. Review the reset again.")
	var next: Dictionary = state.duplicate(true)
	next.resources.gold = int(next.resources.gold) - int(preview.goldCost)
	for attribute: String in ATTRIBUTE_IDS:
		next.hero.progression.allocations[attribute] = 0
	next.hero.progression.unspent = int(preview.pointsRemaining)
	next.hero.progression.revision = int(next.hero.progression.revision) + 1
	next.hero.progression.resetCount = int(next.hero.progression.resetCount) + 1
	_items()._apply_derived(next.hero)
	_record(next, "attribute_reset", "Attribute investments reset at a friendly town.", {"goldCost":int(preview.goldCost), "refundedPoints":int(preview.refundedPoints)})
	_commit(state, next)
	return {"ok":true, "message":"Attribute investments reset. No realm time passed.", "before":preview.before, "after":_items().derive_stats(state.hero), "goldCost":int(preview.goldCost), "refundedPoints":int(preview.refundedPoints), "pointsRemaining":int(state.hero.progression.unspent), "revision":int(state.hero.progression.revision), "progression":progression_view(state)}

static func _grant_experience(hero: Dictionary, amount: int) -> Dictionary:
	# Only registered, validated outcome code calls this authority helper.
	# There is deliberately no UI-facing arbitrary-XP transaction.
	if not _valid_progression(hero) or not _integer(amount, 0, 1000000000):
		return _failure("Experience cannot be applied to inconsistent progression.")
	var gained: int = mini(amount, experience_for_level(MAX_LEVEL) - int(hero.xp))
	if gained > 0 and int(hero.progression.revision) >= MAX_PROGRESS_REVISION:
		return _failure("The progression transaction limit has been reached.")
	var old_level: int = int(hero.level)
	hero.xp = int(hero.xp) + gained
	hero.level = level_for_experience(int(hero.xp))
	var levels: int = int(hero.level) - old_level
	hero.progression.unspent = int(hero.progression.unspent) + levels * POINTS_PER_LEVEL
	if gained > 0:
		hero.progression.revision = int(hero.progression.revision) + 1
	return {"ok":true, "requested":amount, "gained":gained, "overflow":amount - gained, "levelsGained":levels, "fromLevel":old_level, "level":int(hero.level), "unspent":int(hero.progression.unspent), "atCap":int(hero.level) == MAX_LEVEL}

static func _company(id: String, unit_type: String, count: int, hp: int, owner: String) -> Dictionary:
	var health: Array = []
	for index: int in range(count):
		health.append(hp)
	return {"id": id, "type": unit_type, "familyId": unit_type, "promotionId": "base", "owner": owner, "count": count, "maxCount": 12, "memberMaxHp": hp, "memberHp": health, "wounded": 0, "experience": 0, "standingOrder": "protect"}

static func create_realm(seed_value: Variant = 711, setup: Dictionary = {}) -> Dictionary:
	var equipment: Dictionary = {}
	for slot: String in EQUIPMENT_SLOTS:
		equipment[slot] = ""
	var hero: Dictionary = {"id": "ileana", "name": "Mara Veyne", "level": 1, "xp": 0, "hp": 120, "maxHp": 120, "mana": 40, "maxMana": 40, "resolve": 100, "maxResolve": 100, "attack": 18, "armor": 2, "speed": 4.6, "state": "alive", "locationId": "dawnwatch", "inventory": [], "equipment": equipment, "baseStats": {"maxHp": 120, "maxMana": 40, "attack": 18, "armor": 2, "speed": 4.6}}
	if setup.get("hero") is Dictionary:
		for key: String in setup.hero:
			if hero.has(key) and key != "id":
				hero[key] = setup.hero[key].duplicate(true) if setup.hero[key] is Array or setup.hero[key] is Dictionary else setup.hero[key]
	hero.xp = clampi(int(hero.xp), 0, experience_for_level(MAX_LEVEL))
	hero.level = level_for_experience(int(hero.xp))
	hero["progression"] = _new_progression(int(hero.level))
	_apply_fixed_identity(hero)
	var item_rules: Variant = _items()
	if item_rules != null and not (setup.get("hero") is Dictionary and setup.hero.has("inventory")):
		for entry: Array in [["traveller_blade", "start/blade", "main_hand"], ["linen_coat", "start/coat", "chest"], ["road_boots", "start/boots", "feet"]]:
			var instance: Dictionary = item_rules.make_instance(str(entry[0]), str(entry[1]), 0)
			if _valid_item(instance):
				hero.inventory.append(instance)
				item_rules.equip(hero, str(entry[1]), str(entry[2]))
	if item_rules != null:
		item_rules._apply_derived(hero)
	# Starter gear is part of creation, before any player-visible quote exists.
	hero.progression.revision = 0
	var companies: Dictionary = {
		"company:dawn_guard": _company("company:dawn_guard", "spearman", 6, 20, "zorilor"),
		"company:dawn_archers": _company("company:dawn_archers", "archer", 4, 16, "zorilor"),
		"company:court_watch": _company("company:court_watch", "wolf", 3, 45, "fara_zori"),
		"company:moon_hunt": _company("company:moon_hunt", "wolf", 2, 45, "luna_franta")
	}
	var settlements: Dictionary = {
		"dawnwatch": {"id": "dawnwatch", "name": "Dawnreach", "owner": "zorilor", "regionId": "woodland", "buildings": {}, "lastConstructionDay": -1, "garrisonCompanyIds": [], "recruitStock": 8, "stability": 85, "baseIncome": {"gold": 250, "wood": 1, "ore": 1, "food": 2}, "baseFoodCapacity": 40},
		"raven_market": {"id": "raven_market", "name": "Bellwatch", "owner": "fara_zori", "regionId": "river", "buildings": {}, "lastConstructionDay": -1, "garrisonCompanyIds": [], "recruitStock": 4, "stability": 70, "baseIncome": {"gold": 120}, "baseFoodCapacity": 30},
		"wolf_den": {"id": "wolf_den", "name": "Moonfang Camp", "owner": "luna_franta", "regionId": "highland", "buildings": {}, "lastConstructionDay": -1, "garrisonCompanyIds": [], "recruitStock": 4, "stability": 65, "baseIncome": {"gold": 95}, "baseFoodCapacity": 30}
	}
	var state: Dictionary = {
		"ruleset": RULESET, "version": VERSION, "seed": _seed(seed_value), "watchIndex": 0, "lastDawnDay": 1, "status": "active", "hero": hero, "companies": companies, "expeditionCompanyIds": ["company:dawn_guard", "company:dawn_archers"], "resources": {"gold": 2400, "wood": 16, "ore": 14, "food": 24}, "settlements": settlements,
		"locations": {
			"dawnwatch": {"id": "dawnwatch", "name": "Dawnreach", "kind": "town", "owner": "zorilor", "regionId": "woodland", "income": {}, "garrisonCompanyIds": []},
			"bell_crypt": {"id": "bell_crypt", "name": "The Bellworn Vault", "englishName": "The Bellworn Vault", "kind": "dungeon", "owner": "neutral", "regionId": "woodland", "quotedWatches": 2, "cleared": false, "visited": false, "enemies": CRYPT_ACTORS.duplicate(true), "claimedRewardIds": [], "income": {}, "garrisonCompanyIds": []},
			"woodlot": {"id": "woodlot", "name": "Borderwood Sawmill", "kind": "mine", "owner": "neutral", "regionId": "woodland", "income": {"wood": 2}, "garrisonCompanyIds": []},
			"ford_mine": {"id": "ford_mine", "name": "Fordstone Quarry", "kind": "mine", "owner": "neutral", "regionId": "river", "income": {"ore": 2}, "garrisonCompanyIds": []},
			"raven_market": {"id": "raven_market", "name": "Bellwatch", "kind": "town", "owner": "fara_zori", "regionId": "river", "income": {}, "garrisonCompanyIds": []},
			"wolf_den": {"id": "wolf_den", "name": "Moonfang Camp", "kind": "town", "owner": "luna_franta", "regionId": "highland", "income": {}, "garrisonCompanyIds": []}
		},
		"routes": {"home_crypt": {"from": "dawnwatch", "to": "bell_crypt", "watches": 1}, "home_wood": {"from": "dawnwatch", "to": "woodlot", "watches": 2}, "wood_ford": {"from": "woodlot", "to": "ford_mine", "watches": 2}, "ford_court": {"from": "ford_mine", "to": "raven_market", "watches": 2}, "ford_den": {"from": "ford_mine", "to": "wolf_den", "watches": 3}},
		"rivals": {
			"fara_zori": {"id": "fara_zori", "status": "active", "attitude": -35, "policy": "secure_frontier", "resources": {"gold": 480, "wood": 0, "ore": 0, "food": 12}, "stock": 3, "recruited": 3, "spentRecruitment": 570, "homeId": "raven_market", "nextCompanySerial": 2, "force": {"id": "force:court", "companyIds": ["company:court_watch"], "locationId": "raven_market", "goalId": "", "route": [], "edgeProgress": 0, "mobilizedWatch": 12, "lastActedWatch": -1, "intent": "Muster at the bell watch; then secure an unclaimed resource site."}},
			"luna_franta": {"id": "luna_franta", "status": "active", "attitude": -45, "policy": "secure_frontier", "resources": {"gold": 270, "wood": 0, "ore": 0, "food": 10}, "stock": 3, "recruited": 2, "spentRecruitment": 380, "homeId": "wolf_den", "nextCompanySerial": 2, "force": {"id": "force:moon", "companyIds": ["company:moon_hunt"], "locationId": "wolf_den", "goalId": "", "route": [], "edgeProgress": 0, "mobilizedWatch": 16, "lastActedWatch": -1, "intent": "Gather at the hunting camp; then claim a frontier resource site."}}
		},
		"obligations": [], "agreements": [], "regions": {"woodland": {"stability": 80}, "river": {"stability": 60}, "highland": {"stability": 40}}, "turn": {"id": "watch:0", "phase": "complete", "remainingArmyIds": []}, "pendingEncounter": null, "history": [], "encounterSerial": 0, "claimedLoot": [], "resolvedEncounters": {}, "recoveries": 0,
		"supplyMarket":{"serial":0,"stock":SUPPLY_STOCK.duplicate()}
	}
	state["huntBoard"] = Hunts.create_board(int(state.seed),1,int(hero.level))
	_record(state, "begin", "Mara Veyne arrives at Dawnreach. The Bellworn Vault is a solo expedition; her companies remain outside.")
	return state

static func calendar(state: Dictionary) -> Dictionary:
	var index: int = int(state.watchIndex)
	return {"watchIndex": index, "day": int(index / 4) + 1, "watch": str(WATCHES[index % 4]), "watchOfDay": index % 4, "label": "Day %d · %s" % [int(index / 4) + 1, str(WATCHES[index % 4]).capitalize()]}

static func building_catalog() -> Array:
	return BUILDINGS.duplicate(true)

static func _building(building_id: String) -> Dictionary:
	for definition: Dictionary in BUILDINGS:
		if str(definition.id) == building_id:
			return definition
	return {}

static func settlement_effects(state: Dictionary, settlement_id: String) -> Dictionary:
	if not state.settlements.has(settlement_id):
		return {}
	var town: Dictionary = state.settlements[settlement_id]
	var result: Dictionary = {"dailyIncome": town.baseIncome.duplicate(true), "foodCapacity": int(town.baseFoodCapacity), "dailyRecruitment": 0, "garrisonCapacity": 2, "expeditionArmor": 0, "restHealing": 30, "restMana": 12, "approachDelayWatches": 0, "trade": false}
	for building_id: String in town.buildings:
		var definition: Dictionary = _building(building_id)
		if definition.is_empty() or str(town.buildings[building_id].stage) != "complete":
			continue
		for key: String in definition.effects:
			if key == "dailyIncome":
				for resource: String in definition.effects.dailyIncome:
					result.dailyIncome[resource] = int(result.dailyIncome.get(resource, 0)) + int(definition.effects.dailyIncome[resource])
			elif key == "trade":
				result.trade = true
			else:
				result[key] = int(result.get(key, 0)) + int(definition.effects[key])
	return result

static func preview_construction(state: Dictionary, settlement_id: String, building_id: String) -> Dictionary:
	if _locked(state):
		return _failure("Resolve the current expedition or recovery before building.")
	if not state.settlements.has(settlement_id) or str(state.settlements[settlement_id].owner) != "zorilor":
		return _failure("You do not govern this settlement.")
	var definition: Dictionary = _building(building_id)
	if definition.is_empty():
		return _failure("Unknown building.")
	var town: Dictionary = state.settlements[settlement_id]
	if town.buildings.has(building_id):
		return _failure("This building is already complete.")
	if int(town.lastConstructionDay) == int(calendar(state).day):
		return _failure("This settlement has already built today. Another construction becomes available at dawn.")
	for prerequisite: String in definition.prerequisites:
		if not town.buildings.has(prerequisite):
			return _failure("Build %s first." % str(_building(prerequisite).name))
	for other_id: String in town.buildings:
		if str(_building(other_id).plotId) == str(definition.plotId):
			return _failure("This plot is occupied by %s. The riverside choices are exclusive." % str(_building(other_id).name))
	for resource: String in definition.cost:
		if int(state.resources.get(resource, 0)) < int(definition.cost[resource]):
			return _failure("%s requires %d %s; you have %d." % [str(definition.name), int(definition.cost[resource]), resource, int(state.resources.get(resource, 0))])
	return {"ok": true, "message": "Complete immediately. Uses this settlement's construction for today; no watches pass.", "definition": definition.duplicate(true), "cost": definition.cost.duplicate(true), "effects": definition.effects.duplicate(true), "plotId": str(definition.plotId), "modelKey": str(definition.modelKey)}

static func construct_building(state: Dictionary, settlement_id: String, building_id: String) -> Dictionary:
	var preview: Dictionary = preview_construction(state, settlement_id, building_id)
	if not bool(preview.ok):
		return preview
	for resource: String in preview.cost:
		state.resources[resource] = int(state.resources[resource]) - int(preview.cost[resource])
	var built: Dictionary = {"stage": "complete", "builtWatch": int(state.watchIndex), "level": 1}
	state.settlements[settlement_id].buildings[building_id] = built
	state.settlements[settlement_id].lastConstructionDay = int(calendar(state).day)
	_evaluate_obligations(state, false)
	var message: String = "%s completed in %s." % [str(preview.definition.name), str(state.settlements[settlement_id].name)]
	_record(state, "construction", message, {"settlementId": settlement_id, "buildingId": building_id, "cost": preview.cost})
	preview.merge({"message": message, "settlementId": settlement_id, "buildingId": building_id, "buildingState": built.duplicate(true)}, true)
	return preview

static func obligation_catalog() -> Dictionary:
	return OBLIGATIONS.duplicate(true)

static func accept_obligation(state: Dictionary, definition_id: String, choice_id: String) -> Dictionary:
	if _locked(state):
		return _failure("Resolve the current expedition or recovery first.")
	if not OBLIGATIONS.has(definition_id) or str(OBLIGATIONS[definition_id].choiceId) != choice_id:
		return _failure("That oath or choice is not registered.")
	for existing: Dictionary in state.obligations:
		if str(existing.definitionId) == definition_id:
			return _failure("This promise has already been recorded. It cannot be accepted again to reset its deadline.")
	if state.obligations.size() >= 5:
		return _failure("Resolve an existing promise before accepting another.")
	var definition: Dictionary = OBLIGATIONS[definition_id]
	var obligation: Dictionary = {"id": "oath:" + definition_id, "definitionId": definition_id, "choiceId": choice_id, "acceptedWatch": int(state.watchIndex), "dueWatch": int(state.watchIndex) + int(definition.durationWatches) - 1, "status": "active", "resolvedWatch": -1}
	state.obligations.append(obligation)
	_evaluate_obligations(state, false)
	_record(state, "oath", "%s accepted. Due at the end of watch %d." % [str(definition.name), int(obligation.dueWatch)], {"obligationId": str(obligation.id)})
	return {"ok": true, "message": str(definition.description), "obligation": obligation.duplicate(true)}

static func _evaluate_obligations(state: Dictionary, closing_watch: bool) -> void:
	for obligation: Dictionary in state.obligations:
		if str(obligation.status) != "active":
			continue
		var definition: Dictionary = OBLIGATIONS[str(obligation.definitionId)]
		var fulfilled: bool = bool(state.locations.bell_crypt.cleared) if str(definition.condition) == "crypt_extracted" else state.settlements.dawnwatch.buildings.has("granary")
		if fulfilled and int(state.watchIndex) <= int(obligation.dueWatch):
			obligation.status = "fulfilled"
			obligation.resolvedWatch = int(state.watchIndex)
			for resource: String in definition.reward:
				state.resources[resource] = int(state.resources[resource]) + int(definition.reward[resource])
			state.regions[str(definition.regionId)].stability = mini(100, int(state.regions[str(definition.regionId)].stability) + int(definition.stabilityReward))
			_record(state, "oath_fulfilled", "%s fulfilled. Its promised reward is paid once." % str(definition.name), {"obligationId": str(obligation.id)})
		elif closing_watch and int(state.watchIndex) >= int(obligation.dueWatch):
			obligation.status = "broken"
			obligation.resolvedWatch = int(state.watchIndex)
			state.regions[str(definition.regionId)].stability = maxi(0, int(state.regions[str(definition.regionId)].stability) - int(definition.stabilityPenalty))
			_record(state, "oath_broken", "%s was not fulfilled by its declared deadline." % str(definition.name), {"obligationId": str(obligation.id)})

static func _income(state: Dictionary, owner: String) -> Dictionary:
	var income: Dictionary = {"gold": 0, "wood": 0, "ore": 0, "food": 0}
	for town_id: String in state.settlements:
		if str(state.settlements[town_id].owner) != owner:
			continue
		var effect: Dictionary = settlement_effects(state, town_id)
		for resource: String in RESOURCES:
			income[resource] = int(income[resource]) + int(effect.dailyIncome.get(resource, 0))
	for location: Dictionary in state.locations.values():
		if str(location.owner) == owner and str(location.kind) == "mine":
			for resource: String in RESOURCES:
				income[resource] = int(income[resource]) + int(location.income.get(resource, 0))
	return income

static func _dawn(state: Dictionary) -> Dictionary:
	var day: int = int(calendar(state).day)
	if int(state.lastDawnDay) >= day:
		return {}
	state.lastDawnDay = day
	var income: Dictionary = _income(state, "zorilor")
	var capacity: int = 0
	for town_id: String in state.settlements:
		var town: Dictionary = state.settlements[town_id]
		var effect: Dictionary = settlement_effects(state, town_id)
		if str(town.owner) == "zorilor":
			capacity += int(effect.foodCapacity)
			town.recruitStock = mini(10000, int(town.recruitStock) + int(effect.dailyRecruitment))
	for resource: String in RESOURCES:
		state.resources[resource] = int(state.resources[resource]) + int(income[resource])
	if capacity > 0:
		state.resources.food = mini(capacity, int(state.resources.food))
	var debt_paid: int = mini(int(state.get("recoveryDebt", 0)), int(state.resources.gold))
	if debt_paid > 0:
		state.resources.gold = int(state.resources.gold) - debt_paid
		state.recoveryDebt = int(state.recoveryDebt) - debt_paid
	for faction_id: String in state.rivals:
		var faction: Dictionary = state.rivals[faction_id]
		if str(faction.status) != "active":
			continue
		var production: Dictionary = _income(state, faction_id)
		for resource: String in RESOURCES:
			faction.resources[resource] = int(faction.resources[resource]) + int(production[resource])
		if (day - 1) % 7 == 0:
			faction.stock = mini(1000, int(faction.stock) + 4)
		# Actual paid reinforcement occurs only at its recruiting base, never in the field.
		if str(faction.force.locationId) == str(faction.homeId) and faction.force.route.is_empty() and int(faction.stock) > 0 and int(faction.resources.gold) >= 190 and str(state.locations[str(faction.homeId)].owner) == faction_id:
			var company: Dictionary = state.companies[str(faction.force.companyIds[0])]
			if int(company.count) < 6:
				faction.resources.gold = int(faction.resources.gold) - 190
				faction.stock = int(faction.stock) - 1
				faction.recruited = int(faction.recruited) + 1
				faction.spentRecruitment = int(faction.spentRecruitment) + 190
				company.count = int(company.count) + 1
				company.memberHp.append(int(company.memberMaxHp))
	_record(state, "dawn", "Dawn production settled once for day %d." % day, {"income": income, "recoveryDebtPaid": debt_paid})
	return income

static func _path(state: Dictionary, origin: String, destination: String) -> Array:
	if origin == destination:
		return [origin]
	var open: Array = [origin]
	var prior: Dictionary = {origin: ""}
	while not open.is_empty():
		var current: String = str(open.pop_front())
		for route: Dictionary in state.routes.values():
			var next: String = str(route.to) if str(route.from) == current else (str(route.from) if str(route.to) == current else "")
			if next.is_empty() or prior.has(next):
				continue
			prior[next] = current
			if next == destination:
				var result: Array = [next]
				while str(prior[next]) != "":
					next = str(prior[next])
					result.push_front(next)
				return result
			open.append(next)
	return []

static func _edge_cost(state: Dictionary, origin: String, destination: String) -> int:
	for route: Dictionary in state.routes.values():
		if (str(route.from) == origin and str(route.to) == destination) or (str(route.to) == origin and str(route.from) == destination):
			return int(route.watches)
	return 1000000

static func _rival_watch(state: Dictionary) -> void:
	for faction_id: String in state.rivals:
		var faction: Dictionary = state.rivals[faction_id]
		var force: Dictionary = faction.force
		if str(faction.status) != "active" or int(force.lastActedWatch) == int(state.watchIndex):
			continue
		force.lastActedWatch = int(state.watchIndex)
		if int(state.watchIndex) < int(force.mobilizedWatch):
			continue
		if force.route.is_empty():
			var target: String = ""
			var best_distance: int = 1000000
			for location_id: String in state.locations:
				var location: Dictionary = state.locations[location_id]
				if str(location.kind) != "mine" or str(location.owner) != "neutral":
					continue
				var route: Array = _path(state, str(force.locationId), location_id)
				if not route.is_empty() and route.size() < best_distance:
					target = location_id
					best_distance = route.size()
			if target.is_empty():
				force.intent = "Hold the secured frontier. No further assault is ordered in this opening slice."
				continue
			force.goalId = target
			force.route = _path(state, str(force.locationId), target)
			force.edgeProgress = 0
			force.intent = "Secure " + str(state.locations[target].name)
		if force.route.size() > 1:
			force.edgeProgress = int(force.edgeProgress) + 1
			if int(force.edgeProgress) >= _edge_cost(state, str(force.route[0]), str(force.route[1])):
				force.route.pop_front()
				force.locationId = str(force.route[0])
				force.edgeProgress = 0
		if force.route.size() <= 1 and str(force.locationId) == str(force.goalId):
			var location: Dictionary = state.locations[str(force.locationId)]
			# An unopposed claim is not a combat result. Defended captures await action integration.
			if str(location.owner) == "neutral" and location.garrisonCompanyIds.is_empty() and str(state.hero.locationId) != str(location.id):
				location.owner = faction_id
				location["claimedWatch"] = int(state.watchIndex)
				if _observed(state, str(location.id)):
					_record(state, "capture", "%s claimed %s without opposition." % [str(FACTION_NAMES[faction_id]), str(location.name)], {"locationId": str(location.id), "factionId": faction_id})
			force.route = []
			force.goalId = ""

static func _observed(state: Dictionary, location_id: String) -> bool:
	var route: Array = _path(state, str(state.hero.locationId), location_id)
	if not route.is_empty() and route.size() <= 2:
		return true
	for town_id: String in state.settlements:
		if str(state.settlements[town_id].owner) == "zorilor":
			route = _path(state, town_id, location_id)
			if not route.is_empty() and route.size() <= 2:
				return true
	return false

static func get_visible_warbands(state: Dictionary) -> Array:
	var result: Array = []
	for faction_id: String in state.rivals:
		var faction: Dictionary = state.rivals[faction_id]
		var force: Dictionary = faction.force
		if str(faction.status) != "active" or not _observed(state, str(force.locationId)):
			continue
		var visible_companies: Array = []
		for company_id: String in force.companyIds:
			var company: Dictionary = state.companies[company_id]
			visible_companies.append({"id": company_id, "type": str(company.type), "count": int(company.count)})
		result.append({"id": str(force.id), "factionId": faction_id, "factionName": str(FACTION_NAMES[faction_id]), "locationId": str(force.locationId), "companies": visible_companies, "intent": str(force.intent), "observedWatch": int(state.watchIndex)})
	return result

static func advance_watch(state: Dictionary) -> Dictionary:
	if _locked(state):
		return _failure("Resolve the current encounter or recovery before advancing realm time.")
	_evaluate_obligations(state, true)
	state.watchIndex = int(state.watchIndex) + 1
	state.turn = {"id": "watch:%d" % int(state.watchIndex), "phase": "advancing", "remainingArmyIds": []}
	var income: Dictionary = _dawn(state) if int(state.watchIndex) % 4 == 0 else {}
	_rival_watch(state)
	state.turn.phase = "complete"
	var message: String = str(calendar(state).label)
	_record(state, "watch", message)
	return {"ok": true, "message": message, "report": {"calendar": calendar(state), "income": income}, "pendingEncounter": null}

static func forecast(state: Dictionary, limit: int = 3) -> Array:
	var rows: Array = []
	if state.pendingEncounter != null:
		rows.append({"priority": 0, "watchIndex": int(state.watchIndex), "kind": "encounter", "message": "Resolve the current expedition before another watch can pass."})
	if str(state.status) == "recovering":
		rows.append({"priority": 0, "watchIndex": int(state.watchIndex), "kind": "recovery", "message": "Mara Veyne needs recovery at a friendly refuge."})
	for obligation: Dictionary in state.obligations:
		if str(obligation.status) == "active":
			rows.append({"priority": 1, "watchIndex": int(obligation.dueWatch), "kind": "obligation", "message": "%s is due at the end of %s." % [str(OBLIGATIONS[str(obligation.definitionId)].name), _watch_label(int(obligation.dueWatch))]})
	var next_dawn: int = int((int(state.watchIndex) / 4) + 1) * 4
	rows.append({"priority": 3, "watchIndex": next_dawn, "kind": "dawn", "message": "Next dawn: production, available recruits and a new construction allowance."})
	for force: Dictionary in get_visible_warbands(state):
		rows.append({"priority": 2, "watchIndex": int(state.watchIndex) + 1, "kind": "rival", "message": "%s: %s" % [str(force.factionName), str(force.intent)]})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.priority) < int(b.priority) if int(a.priority) != int(b.priority) else int(a.watchIndex) < int(b.watchIndex))
	return rows.slice(0, clampi(limit, 0, 3))

static func _watch_label(index: int) -> String:
	return "day %d %s" % [int(index / 4) + 1, str(WATCHES[index % 4])]

static func advance_to_event(state: Dictionary, max_watches: int = 4) -> Dictionary:
	if _locked(state) or not _integer(max_watches, 1, 40):
		return _failure("Choose one to forty watches after resolving the current encounter.")
	var advanced: int = 0
	while advanced < max_watches:
		for obligation: Dictionary in state.obligations:
			if str(obligation.status) == "active" and int(obligation.dueWatch) <= int(state.watchIndex):
				return {"ok": true, "message": "Stopped before closing a watch with an oath deadline.", "advancedWatches": advanced, "reason": "deadline", "pendingEncounter": null}
		var result: Dictionary = advance_watch(state)
		if not bool(result.ok):
			return result
		advanced += 1
		if int(state.watchIndex) % 4 == 0:
			return {"ok": true, "message": str(calendar(state).label), "advancedWatches": advanced, "reason": "dawn", "pendingEncounter": null}
	return {"ok": true, "message": str(calendar(state).label), "advancedWatches": advanced, "reason": "limit", "pendingEncounter": null}

static func rest(state: Dictionary, settlement_id: String = "dawnwatch") -> Dictionary:
	if _locked(state) or not state.settlements.has(settlement_id) or str(state.settlements[settlement_id].owner) != "zorilor" or str(state.hero.locationId) != settlement_id:
		return _failure("Rest at a friendly town after resolving the current encounter.")
	var effect: Dictionary = settlement_effects(state, settlement_id)
	state.hero.hp = mini(int(state.hero.maxHp), int(state.hero.hp) + int(effect.restHealing))
	state.hero.mana = mini(int(state.hero.maxMana), int(state.hero.mana) + int(effect.restMana))
	var result: Dictionary = advance_watch(state)
	result.message = "A watch of safe rest restored health and Focus. " + str(result.message)
	return result

static func trade(state: Dictionary, settlement_id: String, resource: String, amount: int, buying: bool = true) -> Dictionary:
	if _locked(state) or not state.settlements.has(settlement_id) or str(state.settlements[settlement_id].owner) != "zorilor" or str(state.hero.locationId) != settlement_id or not bool(settlement_effects(state, settlement_id).trade):
		return _failure("Visit a friendly completed market to trade.")
	var prices: Dictionary = {"wood": 45, "ore": 55, "food": 20}
	if not prices.has(resource) or not _integer(amount, 1, 1000):
		return _failure("Choose a positive amount of wood, ore or food.")
	var value: int = int(prices[resource]) * amount if buying else int(int(prices[resource]) / 2) * amount
	if buying and int(state.resources.gold) < value:
		return _failure("There is not enough gold for this purchase.")
	if not buying and int(state.resources[resource]) < amount:
		return _failure("You do not have those supplies to sell.")
	state.resources.gold = int(state.resources.gold) + (-value if buying else value)
	state.resources[resource] = int(state.resources[resource]) + (amount if buying else -amount)
	_record(state, "trade", "%s %d %s for %d gold." % ["Bought" if buying else "Sold", amount, resource, value])
	return {"ok": true, "message": "Trade completed.", "gold": value}

static func dungeon_catalog() -> Array:
	return [{"id": "bell_crypt", "name": "The Bellworn Vault", "englishName": "The Bellworn Vault", "kind": "dungeon", "quotedWatches": 2, "solo": true, "objective": "Clear the crypt, inspect its spoils, then leave through an exit.", "stakes": "Mara Veyne's health and Focus persist. Companies remain outside. Every reward can be claimed once."}]

static func supply_catalog() -> Array:
	var entries: Dictionary = _items().catalog()
	var result: Array = []
	for item_id: String in SUPPLY_STOCK:
		result.append({"itemId":item_id,"name":str(entries[item_id].name),"price":int(entries[item_id].value)*5,"initialStock":int(SUPPLY_STOCK[item_id])})
	return result

static func purchase_supply_item(state: Dictionary, settlement_id: String, item_id: String) -> Dictionary:
	if _locked(state) or not state.settlements.has(settlement_id) or str(state.settlements[settlement_id].owner)!="zorilor" or str(state.hero.locationId)!=settlement_id or not bool(settlement_effects(state,settlement_id).trade):
		return _failure("Visit your completed market to buy crafting supplies.")
	if not SUPPLY_STOCK.has(item_id):
		return _failure("This merchant does not stock that item.")
	if not state.get("supplyMarket") is Dictionary or int(state.supplyMarket.stock.get(item_id,0))<=0:
		return _failure("The merchant has no more of this item.")
	if state.hero.inventory.size()>=128:
		return _failure("Your pack has no room for another item.")
	var item_rules: Variant = _items()
	var price: int = int(item_rules.catalog()[item_id].value)*5
	if int(state.resources.gold)<price:
		return _failure("You need %d gold for this purchase." % price)
	var serial: int = int(state.supplyMarket.serial)+1
	var instance: Dictionary = item_rules.make_instance(item_id,"market:%d:%d" % [int(state.seed),serial],0)
	if not _valid_item(instance):
		return _failure("This supply item is not available.")
	state.resources.gold=int(state.resources.gold)-price
	state.supplyMarket.serial=serial
	state.supplyMarket.stock[item_id]=int(state.supplyMarket.stock[item_id])-1
	state.hero.inventory.append(instance)
	var message: String = "%s purchased for %d gold." % [item_rules.item_name(instance),price]
	_record(state,"purchase",message,{"itemId":item_id,"instanceId":instance.instanceId,"price":price})
	return {"ok":true,"message":message,"instance":instance.duplicate(true),"price":price}

static func preview_item_sale(state: Dictionary, settlement_id: String, instance_id: String) -> Dictionary:
	if _locked(state) or not state.settlements.has(settlement_id) or str(state.settlements[settlement_id].owner) != "zorilor" or str(state.hero.locationId) != settlement_id or not bool(settlement_effects(state,settlement_id).trade):
		return _failure("Sell unequipped items while visiting a friendly town's completed Market.")
	var rules: Variant = _items()
	var instance: Dictionary = rules.find_instance(state.hero,instance_id)
	if instance.is_empty() or not rules.validate_instance(instance):
		return _failure("That item is not in the pack.")
	for equipped_id: Variant in state.hero.equipment.values():
		if str(equipped_id) == instance_id:
			return _failure("Unequip the item before selling it.")
	var value: int = int(rules.catalog()[str(instance.itemId)].value)
	if int(state.resources.gold)+value > 100000000 or not rules._can_change_equipment(state.hero):
		return _failure("The bounded transaction limit would be exceeded.")
	return {"ok":true,"message":"Sell %s for %d gold. Its claimed reward will remain claimed." % [str(rules.item_name(instance)),value],"instanceId":instance_id,"name":str(rules.item_name(instance)),"gold":value,"revision":int(state.hero.progression.revision)}

static func sell_item(state: Dictionary, settlement_id: String, instance_id: String, expected_revision: int = -1) -> Dictionary:
	var preview: Dictionary = preview_item_sale(state,settlement_id,instance_id)
	if not bool(preview.ok):
		return preview
	if expected_revision >= 0 and expected_revision != int(preview.revision):
		return _failure("The pack changed after this sale preview. Review the item again.")
	var next: Dictionary = state.duplicate(true)
	for index: int in range(next.hero.inventory.size()):
		if str(next.hero.inventory[index].instanceId) == instance_id:
			next.hero.inventory.remove_at(index)
			break
	next.resources.gold = int(next.resources.gold)+int(preview.gold)
	_items()._equipment_changed(next.hero)
	_record(next,"item_sale",str(preview.message),{"instanceId":instance_id,"gold":int(preview.gold)})
	_commit(state,next)
	return {"ok":true,"message":str(preview.message),"gold":int(preview.gold),"instanceId":instance_id,"revision":int(state.hero.progression.revision)}

static func _items() -> Variant:
	return load(ITEM_RULES_PATH) if ResourceLoader.exists(ITEM_RULES_PATH) else null

static func _hero_snapshot(state: Dictionary, origin: String) -> Dictionary:
	var hero: Dictionary = state.hero.duplicate(true)
	var item_rules: Variant = _items()
	if item_rules != null and item_rules.has_method("derive_stats"):
		var stats: Variant = item_rules.derive_stats(hero)
		if stats is Dictionary:
			for key: String in ["maxHp", "maxMana", "attack", "armor", "speed", "wardBonus", "traits", "hp", "mana"]:
				if stats.has(key):
					hero[key] = stats[key]
	if state.settlements.has(origin):
		hero.armor = int(hero.armor) + int(settlement_effects(state, origin).expeditionArmor)
	hero.hp = mini(int(hero.hp), int(hero.maxHp))
	hero.mana = mini(int(hero.mana), int(hero.maxMana))
	hero["pos"] = [0, 8]
	return hero

static func begin_encounter(state: Dictionary, request: Dictionary) -> Dictionary:
	if _locked(state):
		return _failure("An expedition or recovery is already pending.")
	if str(request.get("kind", "")) != "dungeon" or str(request.get("locationId", "")) != "bell_crypt":
		return _failure("This encounter is not registered in the current action slice.")
	if bool(state.locations.bell_crypt.cleared) and state.locations.bell_crypt.claimedRewardIds.size() == CRYPT_REWARDS.size():
		return _failure("The Bellworn Vault is cleared and its rewards are claimed. They cannot be farmed.")
	if int(state.hero.hp) <= 0:
		return _failure("Mara Veyne must recover before entering a dungeon.")
	var origin: String = str(state.hero.locationId)
	if not state.settlements.has(origin) or str(state.settlements[origin].owner) != "zorilor":
		return _failure("Prepare this expedition from a friendly town.")
	var next: Dictionary = state.duplicate(true)
	var hero: Dictionary = _hero_snapshot(next, origin)
	next.hero.locationId = "bell_crypt"
	var quoted: int = int(next.locations.bell_crypt.quotedWatches)
	var committed_watch: int = int(next.watchIndex)
	for index: int in range(quoted):
		var transition: Dictionary = advance_watch(next)
		if not bool(transition.ok) or transition.get("pendingEncounter") != null:
			return _failure("A realm event blocks this expedition. Resolve that event before departure.")
	next.encounterSerial = int(next.encounterSerial) + 1
	var encounter_id: String = "bell_crypt:%d:%d" % [int(next.seed), int(next.encounterSerial)]
	var rewards: Array = []
	for reward: Dictionary in CRYPT_REWARDS:
		if not next.locations.bell_crypt.claimedRewardIds.has(str(reward.id)):
			rewards.append(reward.duplicate(true))
	var encounter: Dictionary = {"id": encounter_id, "encounterId": encounter_id, "kind": "dungeon", "initiator": "player", "interactive": true, "locationId": "bell_crypt", "locationName": "The Bellworn Vault", "originLocationId": origin, "committedWatch": committed_watch, "quotedWatches": quoted, "returnWatchId": str(next.turn.id), "heroSnapshot": hero, "playerCompanies": [], "stationedCompanyIds": next.expeditionCompanyIds.duplicate(), "enemies": next.locations.bell_crypt.enemies.duplicate(true), "lootRewards": rewards, "objective": {"type": "dungeon_clear"}, "objectiveDefinitionId": "bell_crypt_clear", "stakesDefinitionId": "bell_crypt_extraction", "sceneId": "bell_crypt", "seed": _seed("%d:%s" % [int(next.seed), encounter_id]), "context": {"watch": str(calendar(next).watch), "regionId": "woodland", "weather": "clear"}, "arena": CRYPT_ARENA.duplicate(true)}
	next.pendingEncounter = encounter
	next.locations.bell_crypt.visited = true
	_record(next, "expedition", "Mara Veyne enters the Bellworn Vault alone. Two realm watches are committed; her companies remain outside.", {"encounterId": encounter_id, "quotedWatches": quoted})
	_commit(state, next)
	return {"ok": true, "message": "Solo expedition begun. Clear the crypt, collect its rewards, then extract.", "pendingEncounter": encounter.duplicate(true)}

static func serialize(state: Dictionary) -> String:
	return JSON.stringify(state)

static func _hunt_board_valid(state: Dictionary) -> bool:
	if str(state.get("ruleset","")) != RULESET or not _integer(state.get("version"),4,VERSION):
		return false
	# Version 4 only ever wrote the frozen registry. Validate it before any
	# migration so edited old saves cannot opt into unregistered geometry.
	if int(state.version) == 4 and (not state.get("huntBoard") is Dictionary or not _integer(state.huntBoard.get("version"),1,1)):
		return false
	var pending_id: String = str(state.pendingEncounter.get("contractId","")) if state.get("pendingEncounter") is Dictionary else ""
	return Hunts.validate_board(state.get("huntBoard"),int(state.get("seed",0)),int(state.get("watchIndex",0)),int(state.get("hero",{}).get("level",1)),pending_id)

static func _hunt_entry_reason(state: Dictionary, offer: Dictionary) -> String:
	if not _hunt_board_valid(state) or offer.is_empty():
		return "This hunt contract is not registered on the current board."
	if _locked(state) or int(state.hero.hp) <= 0:
		return "Finish the current expedition or recovery before taking a hunt."
	var origin: String = str(state.hero.locationId)
	if not state.settlements.has(origin) or str(state.settlements[origin].owner) != "zorilor":
		return "Prepare a hunt while staying in a friendly town."
	if not str(state.huntBoard.activeContractId).is_empty() and str(state.huntBoard.activeContractId) != str(offer.id):
		return "Resume the active contract before choosing another hunt."
	if int(offer.attempts) >= Hunts.MAX_ATTEMPTS or int(state.huntBoard.generation) >= Hunts.MAX_GENERATION:
		return "The bounded contract archive is full."
	if state.hero.inventory.size()+Hunts.remaining_item_count(offer) > 128:
		return "Make room in the pack for this contract's remaining item rewards before departure."
	return ""

static func hunt_board(state: Dictionary) -> Dictionary:
	if not _hunt_board_valid(state):
		return {"generation":0,"activeContractId":"","canChoose":false,"lockReason":"The hunt board is unavailable.","offers":[]}
	var offers: Array = []
	for offer: Dictionary in state.huntBoard.offers:
		var reason: String = _hunt_entry_reason(state,offer)
		var remaining: int = 0
		for actor: Dictionary in offer.enemies:
			remaining += 1 if int(actor.hp) > 0 else 0
		offers.append({"id":str(offer.id),"name":str(offer.name),"description":str(offer.description),"tier":int(offer.tier),"quotedWatches":int(offer.quotedWatches),"xpReward":int(offer.xpReward),"effectiveXpReward":mini(int(offer.xpReward),experience_for_level(MAX_LEVEL)-int(state.hero.xp)),"goldReward":int(offer.goldReward),"rewardPreview":Hunts.reward_preview(int(state.seed),offer),"status":"active" if str(state.huntBoard.activeContractId) == str(offer.id) else "offered","remainingEnemies":remaining,"enemyCount":offer.enemies.size(),"attempts":int(offer.attempts),"canEnter":reason.is_empty(),"lockReason":reason,"completionNotice":"Completing and leaving this contract forfeits any spoils you did not collect. Retreat preserves the same enemies and unclaimed rewards; re-entry costs another two watches."})
		offers.back()["templateId"] = str(offer.templateId)
		offers.back()["layoutId"] = Dungeons.layout_id_for(str(offer.templateId),int(state.huntBoard.version))
		offers.back()["tacticalBrief"] = Dungeons.briefing_for(str(offer.templateId),int(state.huntBoard.version))
	var any_available: bool = false
	for offer: Dictionary in offers:
		any_available = any_available or bool(offer.canEnter)
	var reason: String = "" if any_available else str(offers[0].lockReason) if not offers.is_empty() else "No contracts are available."
	return {"generation":int(state.huntBoard.generation),"activeContractId":str(state.huntBoard.activeContractId),"canChoose":any_available and str(state.huntBoard.activeContractId).is_empty(),"lockReason":reason,"offers":offers,"completedHistory":state.huntBoard.completedHistory.duplicate(true),"packSlotsFree":128-state.hero.inventory.size()}

static func begin_hunt(state: Dictionary, contract_id: String) -> Dictionary:
	var offer: Dictionary = Hunts.contract(state.get("huntBoard",{}),contract_id)
	var reason: String = _hunt_entry_reason(state,offer)
	if not reason.is_empty():
		return _failure(reason)
	var next: Dictionary = state.duplicate(true)
	var selected: Dictionary = Hunts.contract(next.huntBoard,contract_id)
	var origin: String = str(next.hero.locationId)
	var hero: Dictionary = _hero_snapshot(next,origin)
	hero.pos = Dungeons.hero_spawn_for(str(selected.templateId),int(next.huntBoard.version))
	var committed_watch: int = int(next.watchIndex)
	var quoted: int = int(selected.quotedWatches)
	next.hero.locationId = contract_id
	for index: int in range(quoted):
		var transition: Dictionary = advance_watch(next)
		if not bool(transition.ok) or transition.get("pendingEncounter") != null:
			return _failure("A realm event blocks this departure. Resolve it before entering the hunt.")
	next.huntBoard.activeContractId = contract_id
	selected.attempts = int(selected.attempts)+1
	var id: String = Hunts.attempt_id(selected)
	var rewards: Array = []
	for reward: Dictionary in selected.lootRewards:
		if not selected.claimedRewardIds.has(str(reward.id)):
			rewards.append(reward.duplicate(true))
	var encounter: Dictionary = {"id":id,"encounterId":id,"kind":"dungeon","initiator":"player","interactive":true,"contractId":contract_id,"locationId":contract_id,"locationName":str(selected.name),"originLocationId":origin,"committedWatch":committed_watch,"quotedWatches":quoted,"returnWatchId":str(next.turn.id),"heroSnapshot":hero,"playerCompanies":[],"stationedCompanyIds":next.expeditionCompanyIds.duplicate(),"enemies":selected.enemies.duplicate(true),"lootRewards":rewards,"objective":{"type":"dungeon_clear"},"objectiveDefinitionId":"hunt_clear","stakesDefinitionId":"hunt_extraction","sceneId":Dungeons.layout_id_for(str(selected.templateId),int(next.huntBoard.version)),"seed":int(selected.seed),"xpReward":int(selected.xpReward),"context":{"watch":str(calendar(next).watch),"regionId":"woodland","weather":"clear","contractTier":int(selected.tier)},"arena":Dungeons.arena_for(str(selected.templateId),int(next.huntBoard.version))}
	next.pendingEncounter = encounter
	_record(next,"hunt_departure","Mara Veyne enters %s alone. Two watches are committed; this contract's losses and unclaimed rewards persist on withdrawal." % str(selected.name),{"contractId":contract_id,"encounterId":id,"attempt":int(selected.attempts)})
	_commit(state,next)
	return {"ok":true,"message":"Hunt begun. Collect the spoils you want before completing extraction; uncollected spoils are forfeited on completion.","pendingEncounter":encounter.duplicate(true)}

static func _encounter_record(state: Dictionary, pending: Dictionary) -> Dictionary:
	if pending.has("contractId"):
		return Hunts.contract(state.get("huntBoard",{}),str(pending.contractId))
	return state.get("locations",{}).get("bell_crypt",{}) if str(pending.get("locationId","")) == "bell_crypt" else {}

static func _encounter_rewards(state: Dictionary, pending: Dictionary) -> Array:
	return _encounter_record(state,pending).get("lootRewards",[]) if pending.has("contractId") else CRYPT_REWARDS

static func _encounter_claims(state: Dictionary, pending: Dictionary) -> Array:
	return _encounter_record(state,pending).get("claimedLoot",[]) if pending.has("contractId") else state.get("claimedLoot",[])

static func _expected_encounter_id(state: Dictionary, pending: Dictionary) -> String:
	var record: Dictionary = _encounter_record(state,pending)
	return Hunts.attempt_id(record) if pending.has("contractId") and not record.is_empty() else "bell_crypt:%d:%d" % [int(state.seed),int(state.encounterSerial)]

static func preview_reward(state: Dictionary, reward_id: String, item_id: String = "") -> Dictionary:
	# The reward belongs to the location, not to an encounter attempt. Re-entering
	# changes combat's seed and claim ID, but must never reroll an unclaimed item.
	if not state.get("pendingEncounter") is Dictionary or not _integer(state.get("seed"), 0, 0xffffffff):
		return {"ok": false, "reason": "There is no registered expedition reward to inspect."}
	var pending: Dictionary = state.pendingEncounter
	var location_id: String = str(pending.get("locationId", ""))
	var record: Dictionary = _encounter_record(state,pending)
	if record.is_empty() or str(pending.get("kind", "")) != "dungeon" or not pending.get("lootRewards") is Array:
		return {"ok": false, "reason": "This expedition has no registered reward table."}
	var encounter_id: String = _expected_encounter_id(state,pending)
	if str(pending.get("id", "")) != encounter_id or str(pending.get("encounterId", "")) != encounter_id:
		return {"ok": false, "reason": "The reward does not belong to the current expedition."}
	if not record.get("claimedRewardIds") is Array:
		return {"ok": false, "reason": "The reward claim registry is unavailable."}
	var claim_id: String = encounter_id + "/" + reward_id
	if record.claimedRewardIds.has(reward_id) or _encounter_claims(state,pending).has(claim_id):
		return {"ok": false, "reason": "This reward has already been claimed."}
	var registered: Dictionary = {}
	for reward: Dictionary in _encounter_rewards(state,pending):
		if str(reward.id) == reward_id:
			registered = reward
			break
	var available: bool = false
	for reward: Variant in pending.lootRewards:
		if reward is Dictionary and str(reward.get("id", "")) == reward_id and _same(reward, registered):
			available = true
			break
	if registered.is_empty() or not available:
		return {"ok": false, "reason": "This reward is not registered for the current expedition."}
	if str(registered.kind) == "gold":
		if not item_id.is_empty():
			return {"ok": false, "reason": "A gold reward has no item choice."}
		return {"ok": true, "gold": int(registered.amount), "reason": ""}
	var selected: String = item_id
	if str(registered.kind) == "item" and selected.is_empty():
		selected = str(registered.itemId)
	var allowed: Array = registered.options if str(registered.kind) == "choice" else [str(registered.itemId)]
	if not allowed.has(selected):
		return {"ok": false, "reason": "Choose one of this reward's registered items."}
	var rules: Variant = _items()
	if rules == null or not rules.has_method("catalog") or not rules.catalog().has(selected):
		return {"ok": false, "reason": "The registered item catalogue is unavailable for this reward."}
	var roll_seed: int = _seed("%d:reward:%s:%s" % [int(state.seed), location_id, reward_id])
	var instance: Variant = rules.make_instance(selected, claim_id + "/" + selected, roll_seed)
	if not instance is Dictionary or not _valid_item(instance):
		return {"ok": false, "reason": "The item catalogue could not create a valid reward instance."}
	return {"ok": true, "instance": instance.duplicate(true), "reason": ""}

static func _valid_item(instance: Dictionary) -> bool:
	var rules: Variant = _items()
	if rules == null or not rules.has_method("validate_instance"):
		return false
	var result: Variant = rules.validate_instance(instance)
	return result if result is bool else bool(result.get("ok", false)) if result is Dictionary else false

static func _validated_outcome(state: Dictionary, encounter_id: String, outcome: Dictionary) -> Dictionary:
	if state.get("pendingEncounter") == null or not state.pendingEncounter is Dictionary:
		return _failure("There is no pending encounter to resolve.")
	var pending: Dictionary = state.pendingEncounter
	if encounter_id != str(pending.id) or str(outcome.get("encounterId", "")) != encounter_id or state.resolvedEncounters.has(encounter_id):
		return _failure("This result does not belong to the pending encounter, or was already applied.")
	if not _valid_pending(state):
		return _failure("The pending encounter no longer matches its registered contract.")
	var record: Dictionary = _encounter_record(state,pending)
	if pending.has("contractId") and int(record.lastResolvedAttempt) >= int(record.attempts):
		return _failure("This hunt attempt was already applied.")
	if not _integer(outcome.get("schemaVersion"), 1, 1) or str(outcome.get("kind", "")) != "dungeon" or str(pending.kind) != "dungeon":
		return _failure("Unsupported action result schema or encounter kind.")
	var resolution: String = str(outcome.get("resolution", ""))
	if not resolution in ["victory", "defeat", "retreat", "partial"] or not _integer(outcome.get("elapsedTicks"), 1, 10000000):
		return _failure("The encounter has no valid final resolution.")
	for field: String in ["companySurvivors", "enemySurvivors", "casualties", "lootClaims"]:
		if not outcome.get(field) is Array:
			return _failure("The result is missing its survivor or claim arrays.")
	if not outcome.companySurvivors.is_empty() or not outcome.casualties.is_empty():
		return _failure("A solo dungeon cannot report company casualties or reinforcements.")
	if not outcome.get("heroState") is Dictionary or not outcome.get("objective") is Dictionary:
		return _failure("The hero and objective states are required.")
	var hero: Dictionary = outcome.heroState
	for key: String in ["hp", "maxHp", "mana", "maxMana"]:
		if not _integer(hero.get(key), 0, 100000):
			return _failure("Invalid hero health or Focus in the action result.")
	if int(hero.maxHp) != int(pending.heroSnapshot.maxHp) or int(hero.maxMana) != int(pending.heroSnapshot.maxMana) or int(hero.hp) > int(hero.maxHp) or int(hero.mana) > int(hero.maxMana):
		return _failure("The result cannot change the committed hero resource limits.")
	if (resolution == "defeat") != (int(hero.hp) == 0):
		return _failure("Hero survival and the reported outcome disagree.")
	var source_actors: Dictionary = {}
	for actor: Dictionary in pending.enemies:
		source_actors[str(actor.id)] = actor
	var survivors: Dictionary = {}
	for value: Variant in outcome.enemySurvivors:
		if not value is Dictionary:
			return _failure("An enemy survivor record is malformed.")
		var actor_id: String = str(value.get("id", ""))
		if not source_actors.has(actor_id) or survivors.has(actor_id):
			return _failure("An enemy survivor has an unknown or duplicate identity.")
		var original: Dictionary = source_actors[actor_id]
		if not _integer(value.get("hp"), 1, int(original.hp)) or not _integer(value.get("maxHp"), int(original.maxHp), int(original.maxHp)) or str(value.get("type", "")) != str(original.type) or str(value.get("companyId", "")) != str(original.companyId):
			return _failure("An enemy cannot be reinforced, revived or renamed by a result.")
		survivors[actor_id] = int(value.hp)
	var objective: Dictionary = outcome.objective
	if str(objective.get("type", "")) != "dungeon_clear" or not objective.get("completed") is bool or not objective.get("extracted") is bool or not _integer(objective.get("target"), source_actors.size(), source_actors.size()) or not _integer(objective.get("progress"), 0, source_actors.size()):
		return _failure("The objective does not match the registered crypt.")
	if int(objective.progress) != source_actors.size() - survivors.size() or bool(objective.completed) != survivors.is_empty():
		return _failure("Objective progress does not agree with the actual enemy survivors.")
	if resolution == "victory" and (not bool(objective.completed) or not bool(objective.extracted)):
		return _failure("Dungeon victory requires clearing the crypt and legal extraction.")
	if resolution == "defeat" and bool(objective.extracted):
		return _failure("An incapacitated hero cannot report successful extraction.")
	if resolution in ["retreat", "partial"] and not bool(objective.extracted):
		return _failure("A surviving withdrawal must leave through a legal exit.")
	var rewards: Dictionary = {}
	for reward: Dictionary in pending.lootRewards:
		rewards[str(reward.id)] = reward
	var seen_rewards: Dictionary = {}
	var items: Array = []
	var claims: Array = []
	var gold: int = 0
	if outcome.lootClaims.size() > rewards.size():
		return _failure("The result claims more rewards than this encounter contains.")
	for value: Variant in outcome.lootClaims:
		if not value is Dictionary:
			return _failure("A reward claim is malformed.")
		var reward_id: String = str(value.get("rewardId", ""))
		var claim_id: String = encounter_id + "/" + reward_id
		if not rewards.has(reward_id) or seen_rewards.has(reward_id) or str(value.get("claimId", "")) != claim_id or _encounter_claims(state,pending).has(claim_id) or record.claimedRewardIds.has(reward_id):
			return _failure("That reward is unknown, duplicated or already claimed.")
		var reward: Dictionary = rewards[reward_id]
		if survivors.has(str(reward.sourceId)):
			return _failure("A reward cannot be claimed while its source still survives.")
		seen_rewards[reward_id] = true
		if str(reward.kind) == "gold":
			if str(value.get("kind", "")) != "gold" or not _integer(value.get("amount"), int(reward.amount), int(reward.amount)):
				return _failure("A currency claim does not match its registered amount.")
			var preview: Dictionary = preview_reward(state, reward_id)
			if not bool(preview.ok):
				return _failure(str(preview.reason))
			gold += int(preview.gold)
		else:
			var item_id: String = str(value.get("itemId", ""))
			var allowed: Array = reward.options if str(reward.kind) == "choice" else [str(reward.itemId)]
			var instance_id: String = claim_id + "/" + item_id
			if str(value.get("kind", "")) != "item" or not allowed.has(item_id) or str(value.get("instanceId", "")) != instance_id:
				return _failure("The item is not one of this reward's registered choices.")
			var preview: Dictionary = preview_reward(state, reward_id, item_id)
			if not bool(preview.ok):
				return _failure(str(preview.reason))
			var instance: Dictionary = preview.instance
			for owned: Dictionary in state.hero.inventory:
				if str(owned.get("instanceId", "")) == instance_id:
					return _failure("This item instance is already owned.")
			items.append(instance)
		claims.append({"claimId": claim_id, "rewardId": reward_id})
	if state.hero.inventory.size() + items.size() > 128:
		return _failure("The persistent inventory capacity would be exceeded.")
	if int(state.resources.gold)+gold > 100000000:
		return _failure("The persistent gold limit would be exceeded.")
	return {"ok": true, "message": "Valid action outcome.", "resolution": resolution, "survivors": survivors, "items": items, "claims": claims, "gold": gold}

static func resolve_encounter(state: Dictionary, encounter_id: String, outcome: Dictionary) -> Dictionary:
	var valid: Dictionary = _validated_outcome(state, encounter_id, outcome)
	if not bool(valid.ok):
		return valid
	var next: Dictionary = state.duplicate(true)
	var pending: Dictionary = next.pendingEncounter
	var hunt: bool = pending.has("contractId")
	var record: Dictionary = _encounter_record(next,pending)
	var experience: Dictionary = {"ok":true, "gained":0, "overflow":0, "levelsGained":0, "level":int(next.hero.level)}
	next.hero.hp = int(outcome.heroState.hp)
	next.hero.maxHp = int(outcome.heroState.maxHp)
	next.hero.mana = int(outcome.heroState.mana)
	next.hero.maxMana = int(outcome.heroState.maxMana)
	next.hero.locationId = str(pending.originLocationId)
	# Deliberately do not write expeditionCompanyIds or any company from a solo result.
	for actor: Dictionary in record.enemies:
		actor.hp = int(valid.survivors.get(str(actor.id), 0))
	for claim: Dictionary in valid.claims:
		_encounter_claims(next,pending).append(str(claim.claimId))
		record.claimedRewardIds.append(str(claim.rewardId))
	for instance: Dictionary in valid.items:
		next.hero.inventory.append(instance.duplicate(true))
	next.resources.gold = int(next.resources.gold) + int(valid.gold)
	if str(valid.resolution) == "victory":
		if hunt or not bool(record.cleared):
			experience = _grant_experience(next.hero, int(record.xpReward) if hunt else 120)
			if not bool(experience.ok):
				return experience
			if not hunt:
				record.cleared = true
		next.hero.state = "alive"
	elif str(valid.resolution) == "defeat":
		next.hero.state = "incapacitated"
		next.status = "recovering" if str(next.settlements[str(pending.originLocationId)].owner) == "zorilor" else "defeated"
	else:
		next.hero.state = "alive"
	if hunt:
		record.lastResolvedAttempt = int(record.attempts)
		if str(valid.resolution) == "victory":
			next.huntBoard = Hunts.completed_board(int(next.seed),next.huntBoard,record,int(next.hero.level),int(next.watchIndex),int(experience.gained))
	else:
		next.resolvedEncounters[encounter_id] = {"watchIndex": int(next.watchIndex), "resolution": str(valid.resolution)}
	next.pendingEncounter = null
	_evaluate_obligations(next, false)
	var message: String = "Expedition %s. Health, Focus and actual enemy losses are preserved; the companies outside are unchanged." % str(valid.resolution)
	if int(experience.levelsGained) > 0:
		message += " Level %d reached; %d attribute points earned." % [int(next.hero.level), int(experience.levelsGained) * POINTS_PER_LEVEL]
	if hunt and str(valid.resolution) == "victory":
		message += " The contract is complete; three new hunts are available. Uncollected spoils were forfeited."
	_record(next, "encounter", message, {"encounterId": encounter_id, "resolution": str(valid.resolution), "lootCount": valid.items.size(), "gold": int(valid.gold), "xpGained":int(experience.gained), "levelsGained":int(experience.levelsGained)})
	_commit(state, next)
	return {"ok": true, "message": message, "resolution": str(valid.resolution), "loot": valid.items.duplicate(true), "gold": int(valid.gold), "pendingEncounter": null, "recoveryRequired": str(state.status) == "recovering", "xpGained":int(experience.gained), "levelsGained":int(experience.levelsGained), "level":int(state.hero.level),"huntCompleted":hunt and str(valid.resolution) == "victory","huntGeneration":int(state.huntBoard.generation)}

static func recover(state: Dictionary) -> Dictionary:
	if state.pendingEncounter != null or str(state.status) != "recovering" or str(state.hero.state) != "incapacitated":
		return _failure("No recovery is pending.")
	var town_id: String = str(state.hero.locationId)
	if not state.settlements.has(town_id) or str(state.settlements[town_id].owner) != "zorilor":
		return _failure("There is no friendly refuge here.")
	var payment: int = mini(200, int(state.resources.gold))
	state.resources.gold = int(state.resources.gold) - payment
	state["recoveryDebt"] = int(state.get("recoveryDebt", 0)) + 200 - payment
	state.hero.hp = maxi(1, int(int(state.hero.maxHp) / 3))
	state.hero.mana = 0
	state.hero.state = "alive"
	state.status = "active"
	state.recoveries = int(state.recoveries) + 1
	var result: Dictionary = advance_watch(state)
	result.message = "Recovery at the refuge costs 200 gold and one watch. Any unpaid amount is recorded as civic debt; no company is recreated."
	_record(state, "recovery", str(result.message), {"paid": payment, "debt": int(state.get("recoveryDebt", 0))})
	return result

static func get_realm_overview(state: Dictionary) -> Dictionary:
	var town_views: Array = []
	for town_id: String in state.settlements:
		var town: Dictionary = state.settlements[town_id]
		if str(town.owner) == "zorilor":
			town_views.append({"id": town_id, "name": str(town.name), "owner": str(town.owner), "buildings": town.buildings.duplicate(true), "lastConstructionDay": int(town.lastConstructionDay), "effects": settlement_effects(state, town_id), "recruitStock": int(town.recruitStock)})
	return {"calendar": calendar(state), "resources": state.resources.duplicate(true), "towns": town_views, "regions": state.regions.duplicate(true), "obligations": state.obligations.duplicate(true), "forecast": forecast(state), "visibleWarbands": get_visible_warbands(state), "status": str(state.status)}

static func deserialize(text: String) -> Variant:
	if text.length() > MAX_SAVE_BYTES:
		return null
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK:
		return null
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return null
	var raw: Dictionary = parsed
	if str(raw.get("ruleset", "")) != RULESET or not _integer(raw.get("version"), 1, VERSION) or not _integer(raw.get("seed"), 0, 0xffffffff) or not _integer(raw.get("watchIndex"), 0, 4000000):
		return null
	var source_version: int = int(raw.version)
	for key: String in ["hero", "companies", "resources", "settlements", "locations", "routes", "rivals", "regions", "turn", "resolvedEncounters"]:
		if not raw.get(key) is Dictionary:
			return null
	for key: String in ["expeditionCompanyIds", "obligations", "agreements", "history", "claimedLoot"]:
		if not raw.get(key) is Array:
			return null
	if not raw.has("pendingEncounter") or not _integer(raw.get("lastDawnDay"), int(int(raw.watchIndex) / 4) + 1, int(int(raw.watchIndex) / 4) + 1) or not str(raw.get("status", "")) in ["active", "recovering", "defeated"] or not _integer(raw.get("encounterSerial"), 0, 1000000) or not _integer(raw.get("recoveries"), 0, 1000000) or not _integer(raw.get("recoveryDebt", 0), 0, 100000000):
		return null
	var clean: Dictionary = create_realm(int(raw.seed))
	if not raw.get("supplyMarket") is Dictionary or raw.supplyMarket.size()!=2 or not raw.supplyMarket.get("stock") is Dictionary or raw.supplyMarket.stock.size()!=SUPPLY_STOCK.size() or not _integer(raw.supplyMarket.get("serial"),0,18):
		return null
	var purchased_total: int = 0
	for item_id: String in SUPPLY_STOCK:
		if not _integer(raw.supplyMarket.stock.get(item_id),0,int(SUPPLY_STOCK[item_id])):
			return null
		purchased_total+=int(SUPPLY_STOCK[item_id])-int(raw.supplyMarket.stock[item_id])
	if int(raw.supplyMarket.serial)!=purchased_total:
		return null
	if not _same(raw.routes, clean.routes) or raw.locations.size() != clean.locations.size() or raw.settlements.size() != clean.settlements.size() or raw.rivals.size() != clean.rivals.size() or raw.companies.size() != clean.companies.size() or not raw.agreements.is_empty():
		return null
	for resource: String in RESOURCES:
		if not _integer(raw.resources.get(resource), 0, 100000000):
			return null
	if raw.resources.size() != RESOURCES.size():
		return null
	var hero: Dictionary = raw.hero
	var hunt_location: bool = source_version >= 4 and raw.pendingEncounter is Dictionary and str(raw.pendingEncounter.get("contractId","")) == str(hero.get("locationId","")) and str(hero.get("locationId","")).begins_with("hunt:")
	if str(hero.get("id", "")) != "ileana" or not hero.get("name") is String or str(hero.name).length() > 80 or (not clean.locations.has(str(hero.get("locationId", ""))) and not hunt_location) or not hero.get("inventory") is Array or hero.inventory.size() > 128 or not hero.get("equipment") is Dictionary or not hero.get("baseStats") is Dictionary:
		return null
	for key: String in ["hp", "maxHp", "mana", "maxMana", "resolve", "maxResolve", "attack", "armor", "xp"]:
		if not _integer(hero.get(key), 0, 100000):
			return null
	if not _integer(hero.get("level"), 1, 100) or int(hero.maxHp) < 1 or int(hero.hp) > int(hero.maxHp) or int(hero.mana) > int(hero.maxMana) or int(hero.resolve) > int(hero.maxResolve) or not (hero.get("speed") is int or hero.get("speed") is float) or not is_finite(float(hero.speed)) or float(hero.speed) < 0.1 or float(hero.speed) > 20:
		return null
	if str(hero.get("state", "")) not in ["alive", "incapacitated"] or (str(hero.state) == "incapacitated") != (int(hero.hp) == 0) or (str(raw.status) == "active" and str(hero.state) != "alive"):
		return null
	for key: String in ["maxHp", "maxMana", "attack", "armor"]:
		if not _integer(hero.baseStats.get(key), 0, 100000):
			return null
	if not (hero.baseStats.get("speed") is int or hero.baseStats.get("speed") is float) or not is_finite(float(hero.baseStats.speed)) or float(hero.baseStats.speed) < 0.1 or float(hero.baseStats.speed) > 20.0:
		return null
	if source_version == 1:
		if hero.has("progression"):
			return null
	elif not _valid_progression(hero):
		return null
	if source_version < 3:
		for key: String in ["classId", "raceId", "factionId", "heroId", "skills"]:
			if hero.has(key):
				return null
	elif not _fixed_identity_valid(hero):
		return null
	if source_version < 4:
		if raw.has("huntBoard"):
			return null
	elif not _hunt_board_valid(raw):
		return null
	var inventory_ids: Dictionary = {}
	for instance: Variant in hero.inventory:
		if not instance is Dictionary or not _valid_item(instance):
			return null
		var instance_id: String = str(instance.get("instanceId", ""))
		if instance_id.is_empty() or inventory_ids.has(instance_id):
			return null
		inventory_ids[instance_id] = instance
	var equipped: Dictionary = {}
	var item_rules: Variant = _items()
	if hero.equipment.size() != EQUIPMENT_SLOTS.size():
		return null
	for slot: String in EQUIPMENT_SLOTS:
		if not hero.equipment.get(slot) is String:
			return null
		var instance_id: String = str(hero.equipment[slot])
		if not instance_id.is_empty():
			if not inventory_ids.has(instance_id) or equipped.has(instance_id) or item_rules == null or not item_rules.slot_matches(str(inventory_ids[instance_id].slot), slot):
				return null
			equipped[instance_id] = true
	if source_version >= 2:
		var derived: Dictionary = item_rules.derive_stats(hero)
		for key: String in ["maxHp", "maxMana", "attack", "armor", "speed", "wardBonus", "traits"]:
			if not _same(hero.get(key), derived.get(key)):
				return null
	var containers: Dictionary = {}
	if raw.expeditionCompanyIds.size() > 6:
		return null
	for company_id: Variant in raw.expeditionCompanyIds:
		if not company_id is String or not raw.companies.has(company_id) or not raw.companies[company_id] is Dictionary or containers.has(company_id) or str(raw.companies[company_id].get("owner", "")) != "zorilor":
			return null
		containers[company_id] = "expedition"
	for company_id: String in raw.companies:
		if not clean.companies.has(company_id) or not raw.companies[company_id] is Dictionary:
			return null
		var company: Dictionary = raw.companies[company_id]
		var original: Dictionary = clean.companies[company_id]
		for field: String in ["id", "type", "familyId", "promotionId", "owner", "memberMaxHp", "maxCount"]:
			if not _same(company.get(field), original[field]):
				return null
		if not _integer(company.get("count"), 0, int(company.maxCount)) or not _integer(company.get("wounded"), 0, int(company.maxCount)) or not _integer(company.get("experience"), 0, 10000000) or not company.get("memberHp") is Array or company.memberHp.size() != int(company.count) or not str(company.get("standingOrder", "")) in ["protect", "hold", "attack", "follow"]:
			return null
		for hp: Variant in company.memberHp:
			if not _integer(hp, 1, int(company.memberMaxHp)):
				return null
	for town_id: String in raw.settlements:
		if not clean.settlements.has(town_id) or not raw.settlements[town_id] is Dictionary:
			return null
		var town: Dictionary = raw.settlements[town_id]
		var original: Dictionary = clean.settlements[town_id]
		for field: String in ["id", "name", "regionId", "baseIncome", "baseFoodCapacity"]:
			if not _same(town.get(field), original[field]):
				return null
		if not FACTION_NAMES.has(str(town.get("owner", ""))) or not town.get("buildings") is Dictionary or not town.get("garrisonCompanyIds") is Array or not _integer(town.get("lastConstructionDay"), -1, int(int(raw.watchIndex) / 4) + 1) or not _integer(town.get("recruitStock"), 0, 10000) or not _integer(town.get("stability"), 0, 100):
			return null
		var plots: Dictionary = {}
		var build_days: Dictionary = {}
		var latest_day: int = -1
		for building_id: String in town.buildings:
			var definition: Dictionary = _building(building_id)
			var built: Variant = town.buildings[building_id]
			if definition.is_empty() or not built is Dictionary or str(built.get("stage", "")) != "complete" or not _integer(built.get("level"), 1, 1) or not _integer(built.get("builtWatch"), 0, int(raw.watchIndex)) or plots.has(str(definition.plotId)):
				return null
			var day: int = int(int(built.builtWatch) / 4) + 1
			if build_days.has(str(day)):
				return null
			build_days[str(day)] = true
			plots[str(definition.plotId)] = true
			latest_day = maxi(latest_day, day)
			for prerequisite: String in definition.prerequisites:
				if not town.buildings.has(prerequisite) or not town.buildings[prerequisite] is Dictionary or not _integer(town.buildings[prerequisite].get("builtWatch"), 0, int(raw.watchIndex)) or int(town.buildings[prerequisite].builtWatch) >= int(built.builtWatch):
					return null
		if int(town.lastConstructionDay) != latest_day:
			return null
		for company_id: Variant in town.garrisonCompanyIds:
			if not company_id is String or not raw.companies.has(company_id) or containers.has(company_id) or str(raw.companies[company_id].owner) != str(town.owner):
				return null
			containers[company_id] = town_id
	for location_id: String in raw.locations:
		if not clean.locations.has(location_id) or not raw.locations[location_id] is Dictionary:
			return null
		var location: Dictionary = raw.locations[location_id]
		var original: Dictionary = clean.locations[location_id]
		for field: String in ["id", "name", "kind", "regionId", "income"]:
			if not _same(location.get(field), original[field]):
				return null
		if not (str(location.get("owner", "")) == "neutral" or FACTION_NAMES.has(str(location.get("owner", "")))) or not location.get("garrisonCompanyIds") is Array:
			return null
		if str(location.kind) == "town" and (str(location.owner) != str(raw.settlements[location_id].owner) or location.garrisonCompanyIds != raw.settlements[location_id].garrisonCompanyIds):
			return null
		if str(location.kind) != "town":
			for company_id: Variant in location.garrisonCompanyIds:
				if not company_id is String or not raw.companies.has(company_id) or containers.has(company_id) or str(raw.companies[company_id].owner) != str(location.owner):
					return null
				containers[company_id] = location_id
		if location_id == "bell_crypt":
			if not location.get("cleared") is bool or not location.get("visited") is bool or not _integer(location.get("quotedWatches"), 2, 2) or not location.get("enemies") is Array or location.enemies.size() != CRYPT_ACTORS.size() or not location.get("claimedRewardIds") is Array or location.claimedRewardIds.size() > CRYPT_REWARDS.size():
				return null
			for index: int in range(CRYPT_ACTORS.size()):
				if not location.enemies[index] is Dictionary:
					return null
				var actor: Dictionary = location.enemies[index].duplicate(true)
				if not _integer(actor.get("hp"), 0, int(CRYPT_ACTORS[index].maxHp)):
					return null
				if bool(location.cleared) and int(actor.hp) != 0:
					return null
				actor.hp = int(CRYPT_ACTORS[index].hp)
				if not _same(actor, CRYPT_ACTORS[index]):
					return null
			var claimed_rewards: Dictionary = {}
			for reward_id: Variant in location.claimedRewardIds:
				if not reward_id is String or claimed_rewards.has(reward_id) or not ["crypt_weapon", "crypt_set", "crypt_choice", "crypt_gold"].has(reward_id):
					return null
				claimed_rewards[reward_id] = true
	for faction_id: String in raw.rivals:
		if not clean.rivals.has(faction_id) or not raw.rivals[faction_id] is Dictionary:
			return null
		var faction: Dictionary = raw.rivals[faction_id]
		var original: Dictionary = clean.rivals[faction_id]
		if str(faction.get("id", "")) != faction_id or str(faction.get("status", "")) not in ["active", "defeated"] or str(faction.get("policy", "")) != "secure_frontier" or str(faction.get("homeId", "")) != str(original.homeId) or not _integer(faction.get("attitude"), -100, 100) or not faction.get("resources") is Dictionary or not faction.get("force") is Dictionary or not _integer(faction.get("stock"), 0, 1000) or not _integer(faction.get("recruited"), 0, 100000) or not _integer(faction.get("spentRecruitment"), 0, 100000000) or int(faction.spentRecruitment) != int(faction.recruited) * 190:
			return null
		for resource: String in RESOURCES:
			if not _integer(faction.resources.get(resource), 0, 100000000):
				return null
		var force: Dictionary = faction.force
		if str(force.get("id", "")) != str(original.force.id) or not clean.locations.has(str(force.get("locationId", ""))) or not force.get("companyIds") is Array or force.companyIds.is_empty() or force.companyIds.size() > 6 or not force.get("route") is Array or force.route.size() > clean.locations.size() or not _integer(force.get("edgeProgress"), 0, 100) or not _integer(force.get("mobilizedWatch"), int(original.force.mobilizedWatch), int(original.force.mobilizedWatch)) or not _integer(force.get("lastActedWatch"), -1, int(raw.watchIndex)) or not force.get("intent") is String or str(force.intent).length() > 240:
			return null
		if not str(force.get("goalId", "")).is_empty() and not clean.locations.has(str(force.goalId)):
			return null
		for index: int in range(force.route.size()):
			if not force.route[index] is String or not clean.locations.has(force.route[index]) or (index > 0 and _edge_cost(clean, str(force.route[index - 1]), str(force.route[index])) > 100):
				return null
		if not force.route.is_empty() and str(force.route[0]) != str(force.locationId):
			return null
		if force.route.size() > 1 and int(force.edgeProgress) >= _edge_cost(clean, str(force.route[0]), str(force.route[1])):
			return null
		for company_id: Variant in force.companyIds:
			if not company_id is String or not raw.companies.has(company_id) or containers.has(company_id) or str(raw.companies[company_id].owner) != faction_id:
				return null
			containers[company_id] = str(force.id)
	if containers.size() != raw.companies.size():
		return null
	for region_id: String in ["woodland", "river", "highland"]:
		if not raw.regions.get(region_id) is Dictionary or not _integer(raw.regions[region_id].get("stability"), 0, 100):
			return null
	if raw.obligations.size() > 5 or raw.history.size() > 160 or raw.claimedLoot.size() > CRYPT_REWARDS.size() or raw.resolvedEncounters.size() > int(raw.encounterSerial):
		return null
	var oath_ids: Dictionary = {}
	for value: Variant in raw.obligations:
		if not value is Dictionary or not OBLIGATIONS.has(str(value.get("definitionId", ""))):
			return null
		var definition: Dictionary = OBLIGATIONS[str(value.definitionId)]
		if str(value.get("id", "")) != "oath:" + str(value.definitionId) or oath_ids.has(str(value.id)) or str(value.get("choiceId", "")) != str(definition.choiceId) or not _integer(value.get("acceptedWatch"), 0, int(raw.watchIndex)) or not _integer(value.get("dueWatch"), int(value.acceptedWatch) + int(definition.durationWatches) - 1, int(value.acceptedWatch) + int(definition.durationWatches) - 1) or not str(value.get("status", "")) in ["active", "fulfilled", "broken"] or not _integer(value.get("resolvedWatch"), -1, int(raw.watchIndex)):
			return null
		if str(value.status) == "active" and (int(value.resolvedWatch) != -1 or int(value.dueWatch) < int(raw.watchIndex)):
			return null
		if str(value.status) == "fulfilled" and (int(value.resolvedWatch) < int(value.acceptedWatch) or int(value.resolvedWatch) > int(value.dueWatch)):
			return null
		if str(value.status) == "broken" and int(value.resolvedWatch) != int(value.dueWatch):
			return null
		oath_ids[str(value.id)] = true
	for entry: Variant in raw.history:
		if not entry is Dictionary or not _integer(entry.get("watchIndex"), 0, int(raw.watchIndex)) or not entry.get("message") is String or str(entry.message).length() > 1000 or not entry.get("kind") is String or not entry.get("detail") is Dictionary:
			return null
	var claim_ids: Dictionary = {}
	for claim_id: Variant in raw.claimedLoot:
		if not claim_id is String or str(claim_id).length() > 180 or claim_ids.has(claim_id):
			return null
		var parts: PackedStringArray = str(claim_id).split("/")
		if parts.size() != 2 or not raw.resolvedEncounters.has(str(parts[0])) or not raw.locations.bell_crypt.claimedRewardIds.has(str(parts[1])):
			return null
		claim_ids[claim_id] = true
	if raw.claimedLoot.size() != raw.locations.bell_crypt.claimedRewardIds.size():
		return null
	for encounter_id: String in raw.resolvedEncounters:
		var record: Variant = raw.resolvedEncounters[encounter_id]
		if not record is Dictionary or not encounter_id.begins_with("bell_crypt:%d:" % int(raw.seed)) or not _integer(record.get("watchIndex"), 0, int(raw.watchIndex)) or str(record.get("resolution", "")) not in ["victory", "defeat", "retreat", "partial"]:
			return null
	if str(raw.turn.get("id", "")) != "watch:%d" % int(raw.watchIndex) or str(raw.turn.get("phase", "")) != "complete" or not raw.turn.get("remainingArmyIds") is Array or not raw.turn.remainingArmyIds.is_empty():
		return null
	if raw.pendingEncounter != null:
		if not raw.pendingEncounter is Dictionary or not _valid_pending(raw):
			return null
	elif str(hero.locationId) == "bell_crypt" or str(hero.locationId).begins_with("hunt:"):
		return null
	if source_version == 1:
		# Validate the original save and pending contract before migration. Keep
		# that contract exactly unchanged so a live v1 ActionRules save remains
		# restorable. Unspent points cannot alter it while the encounter is locked.
		hero.xp = mini(int(hero.xp), experience_for_level(MAX_LEVEL))
		hero.level = level_for_experience(int(hero.xp))
		hero["progression"] = _new_progression(int(hero.level))
		item_rules._apply_derived(hero)
	if source_version < 3:
		# Campaign identity is canonicalized outside the trusted old encounter.
		# Its already-created ActionRules registry remains byte-for-byte intact.
		_apply_fixed_identity(hero)
	if source_version < 4:
		raw["huntBoard"] = Hunts.create_board(int(raw.seed),1,int(hero.level))
	elif int(raw.huntBoard.version) == 1 and str(raw.huntBoard.activeContractId).is_empty():
		# Only an untouched board may change locations. Withdrawn, defeated and
		# pending contracts retain their old spawns, arena and claim ledger until
		# completion; their next board is generated from the current registry.
		raw["huntBoard"] = Hunts.create_board(int(raw.seed),int(raw.huntBoard.generation),int(raw.huntBoard.tier),raw.huntBoard.completedHistory)
	if source_version < VERSION:
		raw.version = VERSION
	return raw.duplicate(true)

static func _valid_pending(state: Dictionary) -> bool:
	var pending: Dictionary = state.pendingEncounter
	if pending.has("contractId"):
		return _valid_hunt_pending(state)
	var expected_id: String = "bell_crypt:%d:%d" % [int(state.seed), int(state.encounterSerial)]
	if str(pending.get("id", "")) != expected_id or str(pending.get("encounterId", "")) != expected_id or state.resolvedEncounters.has(expected_id) or str(pending.get("kind", "")) != "dungeon" or str(pending.get("locationId", "")) != "bell_crypt" or str(state.hero.locationId) != "bell_crypt" or not state.settlements.has(str(pending.get("originLocationId", ""))) or not _integer(pending.get("quotedWatches"), 2, 2) or not _integer(pending.get("committedWatch"), 0, int(state.watchIndex)) or int(pending.committedWatch) + 2 != int(state.watchIndex):
		return false
	if pending.get("playerCompanies") != [] or pending.get("stationedCompanyIds") != state.expeditionCompanyIds or not _same(pending.get("enemies"), state.locations.bell_crypt.enemies) or not pending.get("heroSnapshot") is Dictionary or not pending.get("lootRewards") is Array:
		return false
	var expected: Dictionary = _hero_snapshot(state, str(pending.originLocationId))
	for key: String in ["id", "hp", "maxHp", "mana", "maxMana", "attack", "armor", "speed", "inventory", "equipment", "traits", "wardBonus", "pos"]:
		if not _same(pending.heroSnapshot.get(key), expected.get(key)):
			return false
	var has_identity: bool = false
	for key: String in ["classId", "raceId", "factionId", "heroId", "skills"]:
		has_identity = has_identity or pending.heroSnapshot.has(key)
	if has_identity:
		if not _fixed_identity_valid(pending.heroSnapshot):
			return false
		for key: String in ["classId", "raceId", "factionId", "skills", "level", "xp", "progression"]:
			if not _same(pending.heroSnapshot.get(key), expected.get(key)):
				return false
	var rewards: Array = []
	for reward: Dictionary in CRYPT_REWARDS:
		if not state.locations.bell_crypt.claimedRewardIds.has(str(reward.id)):
			rewards.append(reward)
	if not _same(pending.lootRewards, rewards) or not _integer(pending.get("seed"), _seed("%d:%s" % [int(state.seed), expected_id]), _seed("%d:%s" % [int(state.seed), expected_id])) or str(pending.get("objectiveDefinitionId", "")) != "bell_crypt_clear" or str(pending.get("stakesDefinitionId", "")) != "bell_crypt_extraction" or pending.get("objective") != {"type": "dungeon_clear"}:
		return false
	if not _same(pending.get("arena"), CRYPT_ARENA) or not _same(pending.get("context"), {"watch": str(calendar(state).watch), "regionId": "woodland", "weather": "clear"}) or str(pending.get("sceneId", "")) != "bell_crypt" or str(pending.get("returnWatchId", "")) != str(state.turn.id):
		return false
	return true

static func _valid_hunt_pending(state: Dictionary) -> bool:
	if not _hunt_board_valid(state):
		return false
	var pending: Dictionary = state.pendingEncounter
	var offer: Dictionary = _encounter_record(state,pending)
	if offer.is_empty():
		return false
	var id: String = Hunts.attempt_id(offer)
	if str(pending.get("id","")) != id or str(pending.get("encounterId","")) != id or str(pending.get("kind","")) != "dungeon" or str(pending.get("initiator","")) != "player" or pending.get("interactive") != true or str(pending.get("locationId","")) != str(offer.id) or str(state.hero.locationId) != str(offer.id) or str(pending.get("locationName","")) != str(offer.name) or not state.settlements.has(str(pending.get("originLocationId",""))) or not _integer(pending.get("quotedWatches"),int(offer.quotedWatches),int(offer.quotedWatches)) or not _integer(pending.get("committedWatch"),0,int(state.watchIndex)) or int(pending.committedWatch)+int(offer.quotedWatches) != int(state.watchIndex):
		return false
	if pending.get("playerCompanies") != [] or pending.get("stationedCompanyIds") != state.expeditionCompanyIds or not _same(pending.get("enemies"),offer.enemies) or not pending.get("heroSnapshot") is Dictionary or not pending.get("lootRewards") is Array or not _fixed_identity_valid(pending.heroSnapshot):
		return false
	var expected: Dictionary = _hero_snapshot(state,str(pending.originLocationId))
	expected.pos = Dungeons.hero_spawn_for(str(offer.templateId),int(state.huntBoard.version))
	for key: String in ["id","hp","maxHp","mana","maxMana","attack","armor","speed","inventory","equipment","traits","wardBonus","pos","classId","raceId","factionId","skills","level","xp","progression"]:
		if not _same(pending.heroSnapshot.get(key),expected.get(key)):
			return false
	var rewards: Array = []
	for reward: Dictionary in offer.lootRewards:
		if not offer.claimedRewardIds.has(str(reward.id)):
			rewards.append(reward)
	if not _same(pending.lootRewards,rewards) or not _integer(pending.get("seed"),int(offer.seed),int(offer.seed)) or not _integer(pending.get("xpReward"),int(offer.xpReward),int(offer.xpReward)) or str(pending.get("objectiveDefinitionId","")) != "hunt_clear" or str(pending.get("stakesDefinitionId","")) != "hunt_extraction" or not _same(pending.get("objective"),{"type":"dungeon_clear"}):
		return false
	return _same(pending.get("arena"),Dungeons.arena_for(str(offer.templateId),int(state.huntBoard.version))) and _same(pending.get("context"),{"watch":str(calendar(state).watch),"regionId":"woodland","weather":"clear","contractTier":int(offer.tier)}) and str(pending.get("sceneId","")) == Dungeons.layout_id_for(str(offer.templateId),int(state.huntBoard.version)) and str(pending.get("returnWatchId","")) == str(state.turn.id)
