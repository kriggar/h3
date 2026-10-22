extends SceneTree

const Items = preload("res://game/redesign/item_rules.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	_test_instances()
	_test_equipment()
	_test_sets()
	_test_runes()
	_test_json_roundtrip()
	var report: Dictionary = {"suite":"item_rules", "groups":5, "checks":checks, "failures":failures.size(), "details":failures}
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _hero() -> Dictionary:
	return {"level":1, "hp":90.0, "mana":25.0, "inventory":[], "equipment":{}, "baseStats":Items.BASE_STATS.duplicate(true)}

func _give(hero: Dictionary, item_id: String, instance_id: String, seed_value: int = 42) -> Dictionary:
	var item: Dictionary = Items.make_instance(item_id, instance_id, seed_value)
	hero.inventory.append(item)
	return item

func _test_instances() -> void:
	for item_id: String in Items.catalog():
		var item: Dictionary = Items.make_instance(item_id, "test/" + item_id, 147)
		_check(Items.validate_instance(item), "Every curated definition produces a valid bounded instance: " + item_id)
		_check(item == Items.make_instance(item_id, "test/" + item_id, 147), "Identical identity and seed reproduce exact rolls: " + item_id)
	_check(Items.make_instance("unknown", "bad").is_empty(), "Unknown content cannot create an item")
	_check(not Items.validate_instance({"itemId":"oathkeeper_blade"}), "Partial forged items rejected")
	_check(not Items.validate_instance("not an item"), "Non-dictionary item rejected")
	var rare: Dictionary = Items.make_instance("sentinel_ring", "rare", 17)
	rare.affixes[0].value = 999999
	_check(not Items.validate_instance(rare), "Forged affix outside seeded result rejected")
	var forged: Dictionary = Items.make_instance("oathkeeper_blade", "forge")
	forged.equipmentId = "unregistered_mesh"
	_check(not Items.validate_instance(forged), "Item cannot substitute an arbitrary equipment resource")

func _test_equipment() -> void:
	var hero: Dictionary = _hero()
	_give(hero, "oathkeeper_blade", "blade")
	_give(hero, "sentinel_ring", "ring")
	_check(Items.equip(hero, "blade").ok, "Equip unique sword")
	_check(is_equal_approx(float(hero.attack), 21.0), "Sword bonus applied once to base attack")
	_check(hero.traits == ["cleave_ward"], "Unique trait present in hero snapshot")
	for index: int in range(3):
		Items.equip(hero, "blade")
	_check(is_equal_approx(float(hero.attack), 21.0), "Repeated equip cannot stack stats")
	_check(is_equal_approx(float(hero.hp), 90.0), "Equip never heals current wounds")
	_check(not Items.equip(hero, "blade", "head").ok, "Slot mismatch rejected")
	_check(Items.equip(hero, "ring", "ring_1").ok, "Ring fits first ring slot")
	_check(Items.equip(hero, "ring", "ring_2").ok, "Same ring can move to other ring slot")
	_check(str(hero.equipment.ring_1).is_empty(), "Moving ring clears old slot instead of counting it twice")
	_check(Items.unequip(hero, "main_hand").ok, "Unequip sword")
	_check(is_equal_approx(float(hero.attack), 18.0) and hero.traits.is_empty(), "Unequip removes stats and special effect")
	_check(hero.inventory.size() == 2, "Equipping does not duplicate or delete item instances")

func _test_sets() -> void:
	var hero: Dictionary = _hero()
	_give(hero, "bellwarden_hood", "hood")
	_give(hero, "bellwarden_gloves", "gloves")
	_give(hero, "bellwarden_coat", "coat")
	_give(hero, "bellwarden_greaves", "legs")
	Items.equip(hero, "hood")
	_check(is_equal_approx(float(hero.armor), 4.0), "One piece has only its own armor")
	Items.equip(hero, "gloves")
	_check(is_equal_approx(float(hero.armor), 9.0), "Two distinct set pieces trigger four extra armor")
	_check(is_equal_approx(float(hero.maxMana), 58.0), "Two-piece maximum focus includes items and set once")
	Items.equip(hero, "coat")
	Items.equip(hero, "legs")
	_check(is_equal_approx(float(hero.wardBonus), 8.0), "Four-piece set has actual Ward capacity bonus")
	Items.unequip(hero, "legs")
	_check(is_equal_approx(float(hero.wardBonus), 0.0), "Losing fourth piece removes four-piece bonus")
	Items.unequip(hero, "hands")
	Items.unequip(hero, "chest")
	_check(is_equal_approx(float(hero.armor), 4.0), "Losing second piece removes two-piece bonus")
	_check(is_equal_approx(float(hero.hp), 90.0), "Repeated set changes cannot heal")

func _test_runes() -> void:
	var hero: Dictionary = _hero()
	var blade: Dictionary = _give(hero, "socketed_blade", "base")
	_give(hero, "rune_cinder", "cinder")
	_give(hero, "rune_stone", "stone")
	_give(hero, "gem_amber", "amber")
	_check(Items.socket(hero, "base", "cinder").ok, "First rune fits socket")
	_check(Items.find_instance(hero, "cinder").is_empty(), "Socketed rune consumed exactly once")
	_check(str(blade.recipeId).is_empty(), "Partial recipe grants rune only")
	_check(not Items.socket(hero, "base", "cinder").ok, "Consumed rune cannot be inserted again")
	_check(Items.socket(hero, "base", "stone").ok, "Second rune fits socket")
	_check(blade.recipeId == "hearthguard", "Correct base and ordered recipe produces Hearthguard")
	_check(Items.validate_instance(blade), "Completed recipe remains valid")
	_check(not Items.socket(hero, "base", "amber").ok, "Cannot exceed exact socket capacity")
	_check(not Items.find_instance(hero, "amber").is_empty(), "Failed socket leaves material untouched")
	Items.equip(hero, "base")
	_check(is_equal_approx(float(hero.attack), 21.0) and is_equal_approx(float(hero.armor), 5.0), "Recipe and individual rune effects both apply once")
	_check(is_equal_approx(float(hero.wardBonus), 4.0), "Recipe changes actual Ward capacity")
	var reverse: Dictionary = _hero()
	var reverse_blade: Dictionary = _give(reverse, "socketed_blade", "reverse")
	_give(reverse, "rune_stone", "r1")
	_give(reverse, "rune_cinder", "r2")
	Items.socket(reverse, "reverse", "r1")
	Items.socket(reverse, "reverse", "r2")
	_check(str(reverse_blade.recipeId).is_empty(), "Reversed rune order does not complete recipe")
	_check(Items.validate_instance(reverse_blade), "Unmatched sequence is a legitimate socketed item")
	reverse_blade.recipeId = "hearthguard"
	_check(not Items.validate_instance(reverse_blade), "Forged completed recipe rejected")

func _test_json_roundtrip() -> void:
	var hero: Dictionary = _hero()
	var item: Dictionary = _give(hero, "mist_amulet", "dungeon/loot/amulet", 1009)
	Items.equip(hero, str(item.instanceId))
	var restored: Variant = JSON.parse_string(JSON.stringify(hero))
	_check(restored is Dictionary and Items.validate_instance(restored.inventory[0]), "JSON numeric normalization preserves authentic rolls")
	var before: Dictionary = Items.derive_stats(hero)
	var after: Dictionary = Items.derive_stats(restored)
	_check(before == after, "Save/load preserves current resources and exact equipment effects")
	_check(Items.describe(item).contains("maximum Focus"), "Tooltip describes applied stat")
