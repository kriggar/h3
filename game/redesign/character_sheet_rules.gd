extends RefCounted
## Read-only character-sheet projections. ItemRules remains the equipment authority.

const Items = preload("res://game/redesign/item_rules.gd")
const STAT_ORDER: Array[String] = ["attack", "armor", "maxHp", "maxMana", "wardBonus", "speed"]
const STAT_LABELS: Dictionary = {"attack":"Attack", "armor":"Armor", "maxHp":"Maximum health", "maxMana":"Maximum Focus", "wardBonus":"Additional Ward", "speed":"Movement speed"}

static func compare_equipment(hero: Dictionary, instance_id: String, requested_slot: String = "") -> Dictionary:
	var instance: Dictionary = Items.find_instance(hero, instance_id)
	if instance.is_empty():
		return {"ok":false,"message":"Select an item from your pack."}
	var projected: Dictionary = hero.duplicate(true)
	var before: Dictionary = Items.derive_stats(hero)
	var report: Dictionary = Items.equip(projected, instance_id, requested_slot)
	if not bool(report.ok):
		return report
	var slot: String = str(report.slot)
	var previous: String = str(hero.equipment.get(slot,""))
	var after: Dictionary = Items.derive_stats(projected)
	var rows: Array = []
	for stat: String in STAT_ORDER:
		var from: float = float(before.get(stat,0.0))
		var to: float = float(after.get(stat,0.0))
		if not is_equal_approx(from,to):
			rows.append({"stat":stat,"label":STAT_LABELS[stat],"before":from,"after":to,"delta":to-from})
	var gained: Array = []
	var lost: Array = []
	for trait_id: String in after.traits:
		if not before.traits.has(trait_id):gained.append(trait_id)
	for trait_id: String in before.traits:
		if not after.traits.has(trait_id):lost.append(trait_id)
	return {"ok":true,"slot":slot,"alreadyEquipped":previous==instance_id,"replaces":Items.find_instance(hero,previous).duplicate(true),"rows":rows,"setsBefore":before.sets.duplicate(true),"setsAfter":after.sets.duplicate(true),"gainedTraits":gained,"lostTraits":lost,"before":before,"after":after}

static func format_value(value: float, stat: String = "") -> String:
	return "%.2f" % value if stat=="speed" else str(int(round(value)))

static func set_progress(hero: Dictionary) -> Array:
	var result: Array = []
	var derived: Dictionary = Items.derive_stats(hero)
	for set_id: String in Items.set_catalog():
		var definition: Dictionary = Items.set_catalog()[set_id]
		var owned: Array = []
		var equipped: Array = []
		for item: Dictionary in hero.get("inventory",[]):
			if str(item.get("setId",""))!=set_id:continue
			if not owned.has(str(item.itemId)):owned.append(str(item.itemId))
			if hero.equipment.values().has(str(item.instanceId)) and not equipped.has(str(item.itemId)):
				equipped.append(str(item.itemId))
		if owned.is_empty():continue
		var thresholds: Array = []
		for threshold: Variant in definition.bonuses:
			thresholds.append({"pieces":int(threshold),"active":int(derived.sets.get(set_id,0))>=int(threshold),"stats":definition.bonuses[threshold].duplicate(true)})
		thresholds.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return int(a.pieces)<int(b.pieces))
		result.append({"id":set_id,"name":str(definition.name),"total":definition.pieces.size(),"owned":owned,"equipped":equipped,"thresholds":thresholds,"description":str(definition.description)})
	return result
