class_name HuntRules
extends RefCounted
## Deterministic, bounded contract registry. RealmRules owns travel, inventory,
## XP and result transactions; ActionRules remains the only combat simulator.
const Items = preload("res://game/redesign/item_rules.gd")
const Dungeons = preload("res://game/redesign/dungeon_catalog.gd")
const MAX_GENERATION: int = 1000000
const MAX_ATTEMPTS: int = 10000
const HISTORY_LIMIT: int = 32
const GEAR_POOL: Array = ["socketed_blade","bellwarden_coat","bellwarden_gloves","bellwarden_greaves","bellwarden_boots","mist_amulet","sentinel_ring"]
const MATERIAL_POOL: Array = ["rune_cinder","rune_stone","rune_gale","gem_amber"]
const TEMPLATES: Array = [
	{"id":"hollow_kennels","name":"The Briar Kennels","description":"Clear a small Gloamfang pack and its leaping keeper. A supply cache lies with the outer scout.","baseXp":120,"baseGold":150,"enemies":[["scout",[-3,3],45,8,"melee"],["hound",[3,0],45,8,"melee"],["keeper",[0,-7],100,12,"werewolf"]]},
	{"id":"ashen_watch","name":"The Ashen Watch Cellar","description":"Break a four-beast infestation spread through the ruined watch cellar. Their numbers reward careful positioning.","baseXp":135,"baseGold":165,"enemies":[["scout",[-3,3],36,7,"melee"],["runner",[3,0],36,7,"melee"],["lurker",[-3,-7],40,8,"melee"],["keeper",[3,-9],62,10,"melee"]]},
	{"id":"moonfang_underpass","name":"Moonfang Underpass","description":"Two leaping Gloamfang hunters hold the inner passage. Read their committed leaps before closing for a strike.","baseXp":150,"baseGold":180,"enemies":[["scout",[-3,3],40,7,"melee"],["hunter",[3,-6],70,9,"werewolf"],["keeper",[-3,-9],80,10,"werewolf"]]}
]

static func _seed(value: String) -> int:
	var result: int = 2166136261
	for index: int in range(value.length()):
		result = ((result ^ value.unicode_at(index)) * 16777619) & 0xffffffff
	return result

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum

static func _same(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_finite(float(a)) and is_finite(float(b)) and float(a) == float(b)
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not _same(a[key],b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for index: int in range(a.size()):
			if not _same(a[index],b[index]):
				return false
		return true
	return typeof(a) == typeof(b) and a == b

static func definition(world_seed: int, generation: int, slot: int, tier: int, registry_version: int = Dungeons.CURRENT_REGISTRY_VERSION) -> Dictionary:
	if generation < 1 or generation > MAX_GENERATION or slot < 0 or slot >= TEMPLATES.size() or tier < 1 or tier > 30 or not registry_version in [1, Dungeons.CURRENT_REGISTRY_VERSION]:
		return {}
	var template: Dictionary = TEMPLATES[slot]
	var positions: Dictionary = Dungeons.enemy_positions_for(str(template.id), registry_version)
	var id: String = "hunt:%d:%d:%d" % [world_seed,generation,slot]
	var seed: int = _seed("%s:tier:%d" % [id,tier])
	var enemies: Array = []
	for row: Array in template.enemies:
		var hp: int = roundi(float(row[2]) * (1.0 + 0.045 * float(tier-1)))
		enemies.append({"id":id+":"+str(row[0]),"type":"wolf","behavior":str(row[4]),"pos":row[1].duplicate() if registry_version == 1 else positions[str(row[0])].duplicate(),"hp":hp,"maxHp":hp,"attack":int(row[3])+int((tier-1)/3),"armor":(3 if str(row[4]) == "werewolf" else 0)+int((tier-1)/5),"speed":3.5 if str(row[4]) == "werewolf" else 3.0,"companyId":""})
	# Visible deterministic rotation supplies varied real catalog pieces without
	# a reload/re-entry roll. The once-only story unique and cowl stay excluded.
	var gear: String = str(GEAR_POOL[(generation-1+slot+world_seed%GEAR_POOL.size())%GEAR_POOL.size()])
	var material: String = str(MATERIAL_POOL[(generation-1+slot+world_seed%MATERIAL_POOL.size())%MATERIAL_POOL.size()])
	var gold: int = int(template.baseGold)+20*(tier-1)
	var rewards: Array = [
		{"id":"hunt_gear","kind":"item","itemId":gear,"sourceId":id+":keeper"},
		{"id":"hunt_supply","kind":"item","itemId":material,"sourceId":id+":scout"},
		{"id":"hunt_gold","kind":"gold","amount":gold,"sourceId":id+":keeper"}
	]
	return {"id":id,"slot":slot,"templateId":str(template.id),"name":str(template.name),"description":str(template.description),"tier":tier,"seed":seed,"quotedWatches":2,"xpReward":int(template.baseXp)+25*(tier-1),"goldReward":gold,"enemies":enemies,"lootRewards":rewards,"attempts":0,"lastResolvedAttempt":0,"claimedRewardIds":[],"claimedLoot":[]}

static func create_board(world_seed: int, generation: int = 1, tier: int = 1, history: Array = [], registry_version: int = Dungeons.CURRENT_REGISTRY_VERSION) -> Dictionary:
	if not registry_version in [1, Dungeons.CURRENT_REGISTRY_VERSION]:
		return {}
	var offers: Array = []
	for slot: int in range(TEMPLATES.size()):
		offers.append(definition(world_seed,generation,slot,tier,registry_version))
	return {"version":registry_version,"generation":generation,"tier":tier,"activeContractId":"","offers":offers,"completedHistory":history.duplicate(true)}

static func contract(board: Dictionary, contract_id: String) -> Dictionary:
	for offer: Variant in board.get("offers",[]):
		if offer is Dictionary and str(offer.get("id","")) == contract_id:
			return offer
	return {}

static func attempt_id(offer: Dictionary) -> String:
	return str(offer.id)+":attempt:"+str(int(offer.attempts))

static func reward_seed(world_seed: int, contract_id: String, reward_id: String) -> int:
	return _seed("%d:reward:%s:%s" % [world_seed,contract_id,reward_id])

static func reward_preview(world_seed: int, offer: Dictionary) -> Array:
	var result: Array = []
	for reward: Dictionary in offer.lootRewards:
		if offer.claimedRewardIds.has(str(reward.id)):
			continue
		if str(reward.kind) == "gold":
			result.append({"id":str(reward.id),"kind":"gold","amount":int(reward.amount),"name":"%d gold" % int(reward.amount)})
		else:
			var instance: Dictionary = Items.make_instance(str(reward.itemId),"preview/"+str(offer.id)+"/"+str(reward.id),reward_seed(world_seed,str(offer.id),str(reward.id)))
			result.append({"id":str(reward.id),"kind":"item","itemId":str(reward.itemId),"name":Items.item_name(instance),"quality":str(instance.quality),"stats":Items.item_stats(instance),"rollSeed":int(instance.rollSeed)})
	return result

static func remaining_item_count(offer: Dictionary) -> int:
	var count: int = 0
	for reward: Dictionary in offer.lootRewards:
		if str(reward.kind) != "gold" and not offer.claimedRewardIds.has(str(reward.id)):
			count += 1
	return count

static func completed_board(world_seed: int, board: Dictionary, offer: Dictionary, new_tier: int, watch_index: int, xp_gained: int) -> Dictionary:
	var history: Array = board.completedHistory.duplicate(true)
	history.append({"id":str(offer.id),"generation":int(board.generation),"slot":int(offer.slot),"tier":int(offer.tier),"completedWatch":watch_index,"xpGained":xp_gained,"claimedRewards":offer.claimedRewardIds.duplicate()})
	while history.size() > HISTORY_LIMIT:
		history.pop_front()
	return create_board(world_seed,int(board.generation)+1,new_tier,history)

static func validate_board(board: Variant, world_seed: int, watch_index: int, hero_level: int, pending_contract_id: String = "") -> bool:
	if not board is Dictionary or board.size() != 6 or not _integer(board.get("version"),1,Dungeons.CURRENT_REGISTRY_VERSION) or not _integer(board.get("generation"),1,MAX_GENERATION) or not _integer(board.get("tier"),1,mini(30,hero_level)) or not board.get("activeContractId") is String or not board.get("offers") is Array or board.offers.size() != TEMPLATES.size() or not board.get("completedHistory") is Array:
		return false
	var active: String = str(board.activeContractId)
	var active_found: bool = active.is_empty()
	for slot: int in range(TEMPLATES.size()):
		var value: Variant = board.offers[slot]
		var original: Dictionary = definition(world_seed,int(board.generation),slot,int(board.tier),int(board.version))
		if not value is Dictionary or value.size() != original.size() or not value.get("enemies") is Array or value.enemies.size() != original.enemies.size() or not value.get("claimedRewardIds") is Array or not value.get("claimedLoot") is Array or not _integer(value.get("attempts"),0,MAX_ATTEMPTS) or not _integer(value.get("lastResolvedAttempt"),0,int(value.attempts)):
			return false
		var live: bool = str(original.id) == pending_contract_id
		if int(value.attempts) != int(value.lastResolvedAttempt)+(1 if live else 0):
			return false
		if str(original.id) == active:
			active_found = true
			if int(value.attempts) < 1:
				return false
		elif int(value.attempts) != 0 or live:
			return false
		var reset: Dictionary = value.duplicate(true)
		for index: int in range(original.enemies.size()):
			if not value.enemies[index] is Dictionary or not _integer(value.enemies[index].get("hp"),0,int(original.enemies[index].maxHp)):
				return false
			if int(value.attempts) == 0 and int(value.enemies[index].hp) != int(original.enemies[index].hp):
				return false
			reset.enemies[index].hp = int(original.enemies[index].hp)
		var seen: Dictionary = {}
		if value.claimedRewardIds.size() != value.claimedLoot.size() or value.claimedRewardIds.size() > original.lootRewards.size():
			return false
		for index: int in range(value.claimedRewardIds.size()):
			var reward_id: Variant = value.claimedRewardIds[index]
			if not reward_id is String or seen.has(reward_id):
				return false
			seen[reward_id] = true
			var registered: Dictionary = {}
			for reward: Dictionary in original.lootRewards:
				if str(reward.id) == reward_id:
					registered = reward
			if registered.is_empty() or not value.claimedLoot[index] is String:
				return false
			var claim: String = str(value.claimedLoot[index])
			var prefix: String = str(original.id)+":attempt:"
			var parts: PackedStringArray = claim.trim_prefix(prefix).split("/")
			if not claim.begins_with(prefix) or parts.size() != 2 or not parts[0].is_valid_int() or not _integer(int(parts[0]),1,int(value.lastResolvedAttempt)) or str(parts[1]) != reward_id:
				return false
			for actor: Dictionary in value.enemies:
				if str(actor.id) == str(registered.sourceId) and int(actor.hp) > 0:
					return false
		reset.attempts = 0
		reset.lastResolvedAttempt = 0
		reset.claimedRewardIds = []
		reset.claimedLoot = []
		if not _same(reset,original):
			return false
	if not active_found or (not pending_contract_id.is_empty() and pending_contract_id != active):
		return false
	var expected_count: int = mini(HISTORY_LIMIT,int(board.generation)-1)
	if board.completedHistory.size() != expected_count:
		return false
	for index: int in range(expected_count):
		var entry: Variant = board.completedHistory[index]
		var generation: int = int(board.generation)-expected_count+index
		if not entry is Dictionary or entry.size() != 7 or not _integer(entry.get("generation"),generation,generation) or not _integer(entry.get("slot"),0,2) or not _integer(entry.get("tier"),1,hero_level) or not _integer(entry.get("completedWatch"),0,watch_index) or not entry.get("claimedRewards") is Array:
			return false
		var original: Dictionary = definition(world_seed,generation,int(entry.slot),int(entry.tier))
		if str(entry.get("id","")) != str(original.id) or not _integer(entry.get("xpGained"),0,int(original.xpReward)) or entry.claimedRewards.size() > 3:
			return false
		var seen: Dictionary = {}
		for reward_id: Variant in entry.claimedRewards:
			if not reward_id is String or not ["hunt_gear","hunt_supply","hunt_gold"].has(reward_id) or seen.has(reward_id):
				return false
			seen[reward_id] = true
		if index > 0 and int(entry.completedWatch) < int(board.completedHistory[index-1].completedWatch):
			return false
	return true
