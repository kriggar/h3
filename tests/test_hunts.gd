extends SceneTree
## Repeated contracts use the real action engine, physical pickups, and legal
## extraction. Capacity/corruption cases are explicitly bounded fixtures.
const Realm = preload("res://game/redesign/realm_rules.gd")
const Hunts = preload("res://game/redesign/hunt_rules.gd")
const Action = preload("res://game/redesign/action_rules.gd")
const Items = preload("res://game/redesign/item_rules.gd")
const Dungeons = preload("res://game/redesign/dungeon_catalog.gd")

var groups: int = 0
var checks: int = 0
var failures: int = 0
var earned_templates: Array = []
var earned_route: Dictionary = {}
var pending_proof: Dictionary = {}
var outcome_proof: Dictionary = {}
var retreat_proof: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run_all")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("HUNTS FAIL: " + label)
	return condition

func _eq(actual: Variant, expected: Variant, label: String) -> bool:
	var same: bool = Realm._same(actual,expected)
	return _check(same,label+(" [actual=%s expected=%s]" % [str(actual),str(expected)] if not same else ""))

func _run(label: String, test: Callable) -> void:
	groups += 1
	var before: int = failures
	test.call()
	print("HUNTS GROUP ",groups," ",label,": ","PASS" if before == failures else "FAIL")

func _run_all() -> void:
	_run("Three deterministic offers, real catalogue rewards, read-only forecasts",_test_board)
	_run("Quoted departure, solo locks, native action and save continuation",_test_departure)
	_run("All three contracts earned through combat, pickup and extraction",_test_templates)
	_run("Actual wounded retreat, persistent corpse loot and same-contract return",_test_retreat)
	_run("Actual defeat, refuge recovery and persistent hunt attrition",_test_defeat)
	_run("Bounded market sales, stale quotes, pack reservation and exact capacity",_test_capacity_sales)
	_run("Registered outcome authority and malformed-state rejection",_test_malformed)
	_run("Authentic v1/v2/v3 migrations preserve committed expeditions",_test_migration)
	_run("Earned repeat-contract progression to level thirty and bounded history",_test_level_route)
	print("HUNTS_SUMMARY ",JSON.stringify({"groups":groups,"checks":checks,"failures":failures,"templates":earned_templates,"earnedRoute":earned_route}))
	quit(0 if failures == 0 else 1)

func _fresh(seed: int = 711) -> Dictionary:
	var state: Dictionary = Realm.create_realm(seed)
	Realm.allocate_attributes(state,{"might":1,"vitality":1,"spirit":1})
	return state

func _story(state: Dictionary) -> Dictionary:
	return {"location":state.locations.bell_crypt.duplicate(true),"serial":state.encounterSerial,"resolved":state.resolvedEncounters.duplicate(true),"claims":state.claimedLoot.duplicate()}

func _player_companies(state: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id: String in state.companies:
		if str(state.companies[id].owner) == "zorilor":
			result[id] = state.companies[id].duplicate(true)
	return result

func _test_board() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var before: String = Realm.serialize(state)
	var board: Dictionary = Realm.hunt_board(state)
	_eq([board.generation,board.activeContractId,board.canChoose,board.offers.size(),board.packSlotsFree],[1,"",true,3,125],"initial board has three available registered choices")
	_eq(board,Realm.hunt_board(Realm.create_realm(711)),"same world has exactly the same registered offers")
	_eq(board.offers[0].name,"The Briar Kennels","current readable name is used without changing its stable template ID")
	var ids: Dictionary = {}
	for offer: Dictionary in board.offers:
		ids[str(offer.id)] = true
		_check(offer.canEnter and offer.quotedWatches == 2 and offer.tier == 1 and offer.attempts == 0,"each initial contract advertises its real cost and tier")
		_eq(offer.rewardPreview.size(),3,"each offer quotes two actual items and one fixed currency reward")
		for reward: Dictionary in offer.rewardPreview:
			if str(reward.kind) == "item":
				_check(Items.catalog().has(str(reward.itemId)) and not ["oathkeeper_blade","bellwarden_hood"].has(str(reward.itemId)),"repeat rewards use real catalogue entries without farming story-exclusive pieces")
	_eq(ids.size(),3,"offers have separate persistent contract identities")
	_eq(Realm.serialize(state),before,"board and reward previews do not spend time or mutate state")
	board.offers[0].rewardPreview.clear()
	_eq(Realm.hunt_board(state).offers[0].rewardPreview.size(),3,"returned UI data cannot mutate the registry")
	_check(Realm.deserialize(before) != null,"fresh current-version board round-trips")
	state.hero.locationId = "woodlot"
	board = Realm.hunt_board(state)
	_check(not board.canChoose and not board.offers[0].canEnter and not str(board.lockReason).is_empty(),"board-level availability agrees with per-offer physical-town requirements")
	state.hero.locationId = "dawnwatch"
	var seen: Dictionary = {}
	for generation: int in range(1,8):
		var definition: Dictionary = Hunts.definition(711,generation,0,1)
		seen[str(definition.lootRewards[0].itemId)] = true
	_eq(seen.size(),7,"seven generations rotate across all seven curated gear entries")
	_check(Hunts.definition(711,1,3,1).is_empty() and Hunts.definition(711,1,0,31).is_empty(),"unknown template slots and tiers cannot manufacture a registry")

func _test_departure() -> void:
	var state: Dictionary = _fresh()
	var companies: Dictionary = state.companies.duplicate(true)
	var story: Dictionary = _story(state)
	var id: String = str(Realm.hunt_board(state).offers[1].id)
	var before: String = Realm.serialize(state)
	_check(not Realm.begin_hunt(state,"invented-contract").ok,"unknown contract cannot start")
	_eq(Realm.serialize(state),before,"invalid departure is atomic")
	if not _check(Realm.begin_hunt(state,id).ok,"registered contract starts from the friendly town"):
		return
	_eq([state.watchIndex,state.hero.locationId,state.huntBoard.activeContractId],[2,id,id],"two committed watches and one active contract")
	_eq(state.pendingEncounter.playerCompanies,[],"six-company system sends no companies into a solo hunt")
	_eq(state.companies,companies,"stationed companies are unchanged")
	_eq(_story(state),story,"hunt departure leaves the once-only story ledger untouched")
	_eq(state.pendingEncounter.heroSnapshot.skills,["cleave","ward"],"hunt uses Mara's actual fixed Oathwarden kit")
	_eq(state.pendingEncounter.arena,Dungeons.arena_for("ashen_watch",2),"visible walls and collisions use this contract's registered arena")
	before = Realm.serialize(state)
	_check(not Realm.begin_hunt(state,id).ok and not Realm.begin_encounter(state,{"kind":"dungeon","locationId":"bell_crypt"}).ok,"neither another hunt nor the story replaces a pending action")
	_check(not Realm.advance_watch(state).ok and not Realm.allocate_attributes(state,{"might":1}).ok,"action time and progression remain locked")
	_eq(Realm.serialize(state),before,"pending rejections have no side effects")
	var loaded: Variant = Realm.deserialize(before)
	if not _check(loaded != null,"pending hunt saves and reloads"):
		return
	_eq(loaded.pendingEncounter,state.pendingEncounter,"same attempt, seed, rewards and snapshot resume")
	var action: Dictionary = Action.create(state.pendingEncounter)
	_eq(action.phase,"running","real ActionRules accepts the registered contract")
	_check(Action.submit(action,{"kind":"move","pos":[0,6]}).ok,"actual action command begins")
	Action.advance(action,9)
	var resumed: Dictionary = Action.deserialize(Action.serialize(action),loaded.pendingEncounter)
	if _check(not resumed.is_empty(),"live actor state resumes against its immutable hunt registry"):
		Action.advance(action,19)
		Action.advance(resumed,19)
		_eq(Action.snapshot(resumed),Action.snapshot(action),"live movement, AI and resource continuation remain deterministic")
	_eq(state.watchIndex,2,"action ticks do not silently consume realm time")

func _actor(action: Dictionary) -> Dictionary:
	return Action.get_actor(action,str(action.heroId))

func _pos(actor: Dictionary) -> Vector2:
	return Vector2(float(actor.pos[0]),float(actor.pos[1]))

func _idle(action: Dictionary) -> bool:
	for tick: int in range(180):
		if str(action.phase) == "finished":
			return false
		if _actor(action).action.is_empty() and int(action.tick) >= int(_actor(action).restartUntil):
			return true
		Action.advance(action)
	return false

func _walk(action: Dictionary, destination: Array) -> bool:
	if not _idle(action) or not Action.submit(action,{"kind":"move","pos":destination}).ok:
		return false
	for tick: int in range(900):
		Action.advance(action)
		if str(action.phase) == "finished":
			return false
		if _pos(_actor(action)).distance_to(Vector2(float(destination[0]),float(destination[1]))) < 0.15:
			return true
	return false

func _clear(action: Dictionary) -> bool:
	for tick: int in range(5400):
		if str(action.phase) in ["cleared","finished"]:
			break
		var hero: Dictionary = _actor(action)
		if hero.action.is_empty() and int(action.tick) >= int(hero.restartUntil):
			var target: Dictionary = {}
			var distance: float = INF
			for enemy: Dictionary in action.actors:
				if str(enemy.side) == "enemy" and int(enemy.hp) > 0 and _pos(hero).distance_to(_pos(enemy)) < distance:
					target = enemy
					distance = _pos(hero).distance_to(_pos(enemy))
			if target.is_empty():
				break
			var command: Dictionary = {"kind":"attack","targetId":str(target.id)}
			if int(hero.mana) >= 14 and not hero.statuses.has("ward") and int(hero.cooldowns.get("ward",0)) <= int(action.tick):
				command = {"kind":"cast","ability":"ward"}
			elif distance < 2.4 and int(hero.mana) >= 12 and int(hero.cooldowns.get("cleave",0)) <= int(action.tick):
				command = {"kind":"cast","ability":"cleave","pos":target.pos}
			Action.submit(action,command)
		Action.advance(action)
	return str(action.phase) == "cleared"

func _collect(action: Dictionary, reward_id: String = "") -> bool:
	for loot: Dictionary in action.loot:
		if bool(loot.get("claimed",false)) or (not reward_id.is_empty() and str(loot.id) != reward_id):
			continue
		if not _walk(action,loot.pos) or not _idle(action):
			return false
		if not Action.submit(action,{"kind":"interact","targetId":str(loot.id)}).ok:
			return false
		Action.advance(action,10)
		if not bool(loot.get("claimed",false)):
			return false
	return true

func _exit(action: Dictionary) -> bool:
	if not _walk(action,action.arena.exit) or not _idle(action):
		return false
	if not Action.submit(action,{"kind":"exit"}).ok:
		return false
	Action.advance(action,45)
	return not Action.outcome(action).is_empty()

func _earned_hunt(state: Dictionary, slot: int, collect: bool = true) -> Dictionary:
	var offer: Dictionary = Realm.hunt_board(state).offers[slot]
	var opened: Dictionary = Realm.begin_hunt(state,str(offer.id))
	if not bool(opened.ok):
		return {"ok":false,"message":opened.message}
	var action: Dictionary = Action.create(state.pendingEncounter)
	if not _clear(action):
		return {"ok":false,"message":"actual combat did not clear","phase":action.phase,"tick":action.tick,"hero":_actor(action)}
	if collect and not _collect(action):
		return {"ok":false,"message":"physical pickup failed","tick":action.tick}
	if not _exit(action):
		return {"ok":false,"message":"legal extraction failed","tick":action.tick}
	var outcome: Dictionary = Action.outcome(action)
	var pending: Dictionary = state.duplicate(true)
	var report: Dictionary = Realm.resolve_encounter(state,str(state.pendingEncounter.id),outcome)
	return {"ok":bool(report.ok),"message":report.message,"outcome":outcome,"pending":pending,"report":report,"offer":offer,"ticks":int(action.tick)}

func _test_templates() -> void:
	for slot: int in range(3):
		var state: Dictionary = _fresh()
		var story: Dictionary = _story(state)
		var companies: Dictionary = state.companies.duplicate(true)
		var report: Dictionary = _earned_hunt(state,slot)
		if not _check(bool(report.ok),"starter actually completes template %d: %s" % [slot,str(report.message)]):
			print("HUNTS_BOT_FAILURE ",JSON.stringify(report))
			continue
		_eq(report.outcome.resolution,"victory","real clear plus exit produces completion")
		_eq([report.report.xpGained,state.hero.xp,state.hero.level,state.hero.progression.unspent],[report.offer.xpReward,report.offer.xpReward,2,3],"registered tier XP gives level two and three new choices once")
		_eq([state.hero.hp,state.hero.mana],[report.outcome.heroState.hp,report.outcome.heroState.mana],"level gain retains actual injuries and Focus spent")
		_eq([state.hero.inventory.size(),state.resources.gold],[5,2400+int(report.offer.goldReward)],"two picked-up items and exact registered gold reach town")
		_eq([state.huntBoard.generation,state.huntBoard.tier,state.huntBoard.activeContractId],[2,2,""],"completed return registers a fresh tier-two board")
		_eq(state.huntBoard.completedHistory[0].claimedRewards.size(),3,"bounded history records all three physically claimed rewards")
		_eq(_story(state),story,"earned hunt does not clear, reroll or claim the story vault")
		_eq(state.companies,companies,"solo victory preserves all stationed companies")
		_eq([state.hero.locationId,state.watchIndex],["dawnwatch",2],"return restores town location without extra hidden watch cost")
		for reward_id: String in ["hunt_gear","hunt_supply"]:
			var preview: Dictionary = Realm.preview_reward(report.pending,reward_id)
			_eq(Items.find_instance(state.hero,str(preview.instance.instanceId)),preview.instance,"earned item is byte-equivalent to registered pending preview")
		var before: String = Realm.serialize(state)
		_check(not Realm.resolve_encounter(state,str(report.outcome.encounterId),report.outcome).ok,"delayed duplicate callback cannot pay twice")
		_check(not Realm.begin_hunt(state,str(report.offer.id)).ok,"completed contract identity is no longer enterable")
		_eq(Realm.serialize(state),before,"completed replay rejections are atomic")
		_check(Realm.deserialize(before) != null,"earned board, gear, level and history all reload")
		earned_templates.append({"name":str(report.offer.name),"ticks":report.ticks,"hp":state.hero.hp,"mana":state.hero.mana,"xp":state.hero.xp})
		if slot == 0:
			pending_proof = report.pending.duplicate(true)
			outcome_proof = report.outcome.duplicate(true)
	# A completed extraction deliberately closes its uncollected rewards.
	var state: Dictionary = _fresh(712)
	var report: Dictionary = _earned_hunt(state,0,false)
	if _check(report.ok,"actual no-pickup clear and extraction is supported"):
		_eq([state.hero.inventory.size(),report.report.gold,state.huntBoard.completedHistory[0].claimedRewards.size()],[3,0,0],"uncollected spoils are never silently awarded")
		_check(not Realm.begin_hunt(state,str(report.offer.id)).ok,"uncollected spoils cannot revive a completed contract")
	else:
		print("HUNTS_NO_PICKUP_FAILURE ",JSON.stringify(report))

func _outer_kill(action: Dictionary) -> bool:
	var scout: Dictionary = action.actors[1]
	Action.submit(action,{"kind":"cast","ability":"ward"})
	_idle(action)
	if not Action.submit(action,{"kind":"attack","targetId":str(scout.id)}).ok:
		return false
	for tick: int in range(900):
		Action.advance(action)
		if int(scout.hp) <= 0:
			return str(action.phase) == "running"
		if str(action.phase) == "finished":
			return false
	return false

func _test_retreat() -> void:
	var state: Dictionary = _fresh()
	var id: String = str(Realm.hunt_board(state).offers[0].id)
	Realm.begin_hunt(state,id)
	var seed: int = int(state.pendingEncounter.seed)
	var attempt: String = str(state.pendingEncounter.id)
	var preview: Dictionary = Realm.preview_reward(state,"hunt_gear")
	var companies: Dictionary = state.companies.duplicate(true)
	var action: Dictionary = Action.create(state.pendingEncounter)
	if not _check(_outer_kill(action),"outer scout dies through a real ward and weapon strikes"):
		return
	if not _check(_collect(action,"hunt_supply"),"scout supply is reached and physically collected while inner foes remain"):
		return
	if not _check(_exit(action),"wounded hero legally withdraws without clearing the pack"):
		print("HUNTS_RETREAT_DEBUG ",JSON.stringify(Action.snapshot(action)))
		return
	var result: Dictionary = Action.outcome(action)
	_eq([result.resolution,result.lootClaims.size(),result.enemySurvivors.size()],["retreat",1,2],"actual withdrawal carries one pickup and two survivors")
	if not _check(Realm.resolve_encounter(state,attempt,result).ok,"real partial hunt transaction applies"):
		return
	_eq([state.hero.xp,state.huntBoard.generation,state.huntBoard.activeContractId,state.hero.inventory.size()],[0,1,id,4],"withdrawal keeps the active contract and pickup but earns no clear XP")
	_eq(state.companies,companies,"withdrawal never converts empty solo survivor list into army losses")
	_eq(Hunts.contract(state.huntBoard,id).enemies[0].hp,0,"actual corpse remains dead in persistent registry")
	var before: String = Realm.serialize(state)
	_check(not Realm.begin_hunt(state,str(state.huntBoard.offers[1].id)).ok,"another offer cannot replace an unfinished contract")
	_eq(Realm.serialize(state),before,"unfinished-offer rejection is atomic")
	var loaded: Variant = Realm.deserialize(before)
	if not _check(loaded != null,"withdrawal with claimed corpse supply reloads"):
		return
	retreat_proof = loaded.duplicate(true)
	_eq(loaded.huntBoard,state.huntBoard,"all casualties, attempts and claim IDs persist")
	var watch: int = int(loaded.watchIndex)
	if not _check(Realm.begin_hunt(loaded,id).ok,"same contract permits an explicitly paid return"):
		return
	_eq([loaded.watchIndex,loaded.pendingEncounter.seed],[watch+2,seed],"re-entry spends two watches and keeps the registered combat seed")
	_check(str(loaded.pendingEncounter.id) != attempt,"attempt identity changes to reject stale asynchronous results")
	var again: Dictionary = Realm.preview_reward(loaded,"hunt_gear")
	_eq([again.instance.rollSeed,again.instance.affixes],[preview.instance.rollSeed,preview.instance.affixes],"withdrawal and reload cannot reroll the unclaimed item")
	_check(not Realm.preview_reward(loaded,"hunt_supply").ok,"claimed supply cannot reappear under the new attempt ID")
	var resumed: Dictionary = Action.create(loaded.pendingEncounter)
	_eq([resumed.objective.progress,resumed.lootRewards.size()],[1,2],"real action loads the corpse and omits the already claimed reward")
	_check(not Realm.resolve_encounter(loaded,attempt,result).ok,"old callback is rejected during a newer attempt")

func _test_defeat() -> void:
	var state: Dictionary = _fresh(713)
	var id: String = str(Realm.hunt_board(state).offers[0].id)
	Realm.begin_hunt(state,id)
	var action: Dictionary = Action.create(state.pendingEncounter)
	if not _check(_outer_kill(action) and _collect(action,"hunt_supply"),"defeat route first earns a real scout kill and item pickup"):
		return
	_idle(action)
	Action.submit(action,{"kind":"guard","guarding":false})
	# The new kennel layout separates the yards beyond the inner pack's aggro
	# range. Approach the living hound legally before waiting for actual defeat.
	if not _check(Action.submit(action,{"kind":"move","pos":action.actors[2].pos}).ok,"unprotected hero approaches the surviving hound"):
		return
	for tick: int in range(3600):
		if str(action.phase) == "finished":
			break
		Action.advance(action)
	var outcome: Dictionary = Action.outcome(action)
	if not _check(not outcome.is_empty() and str(outcome.resolution) == "defeat","remaining enemies actually incapacitate the idle hero"):
		return
	if not _check(Realm.resolve_encounter(state,str(state.pendingEncounter.id),outcome).ok,"actual defeat applies once"):
		return
	_eq([state.status,state.hero.hp,state.hero.xp,state.hero.inventory.size()],["recovering",0,0,4],"defeat retains collected supply but grants no XP or free healing")
	_eq(Hunts.contract(state.huntBoard,id).enemies[0].hp,0,"enemy killed before defeat remains dead")
	_check(not Realm.begin_hunt(state,id).ok,"incapacitation cannot be bypassed with another entry")
	_check(Realm.deserialize(Realm.serialize(state)) != null,"defeat and active hunt save together")
	var gold: int = int(state.resources.gold)
	_check(Realm.recover(state).ok,"normal refuge recovery remains available")
	_eq([state.status,state.hero.hp,state.resources.gold],["active",int(state.hero.maxHp)/3,gold-200],"recovery charges its real fee and restores only a third of health")
	_check(Realm.begin_hunt(state,id).ok,"recovered hero can resume the same surviving pack")
	_eq(Action.create(state.pendingEncounter).objective.progress,1,"recovery never respawns the defeated scout")

func _market(state: Dictionary) -> bool:
	return bool(Realm.construct_building(state,"dawnwatch","granary").ok) and bool(Realm.advance_to_event(state,4).ok) and bool(Realm.construct_building(state,"dawnwatch","market").ok)

func _test_capacity_sales() -> void:
	var state: Dictionary = _fresh()
	_check(not Realm.preview_item_sale(state,"dawnwatch","start/blade").ok,"no seller exists before an actual market is built")
	if not _check(_market(state),"market is constructed through legal costs and days"):
		return
	_check(not Realm.preview_item_sale(state,"dawnwatch","start/blade").ok,"currently equipped item cannot be sold")
	var purchase: Dictionary = Realm.purchase_supply_item(state,"dawnwatch","rune_cinder")
	var id: String = str(purchase.instance.instanceId)
	var before: String = Realm.serialize(state)
	var quote: Dictionary = Realm.preview_item_sale(state,"dawnwatch",id)
	_check(bool(quote.ok),"unequipped merchant rune receives a real sale quote")
	_eq([quote.instanceId,quote.name,quote.gold],[id,"Cinder Rune",10],"sale quote exposes stable ID, readable name and fixed catalog value")
	_eq(Realm.serialize(state),before,"sale preview does not mutate pack or purse")
	Items.unequip(state.hero,"feet")
	before = Realm.serialize(state)
	_check(not Realm.sell_item(state,"dawnwatch",id,int(quote.revision)).ok,"equipment revision invalidates a stale sale confirmation")
	_eq(Realm.serialize(state),before,"stale sale leaves both item and money intact")
	var gold: int = int(state.resources.gold)
	var watch: int = int(state.watchIndex)
	quote = Realm.preview_item_sale(state,"dawnwatch",id)
	_check(Realm.sell_item(state,"dawnwatch",id,int(quote.revision)).ok,"current quote commits once")
	_eq([state.resources.gold,state.watchIndex,Items.find_instance(state.hero,id).is_empty()],[gold+10,watch,true],"sale removes one instance, pays exact value, spends no watch")
	_check(int(purchase.price) > int(quote.gold),"buy/sell route cannot multiply gold")
	before = Realm.serialize(state)
	_check(not Realm.sell_item(state,"dawnwatch",id).ok,"sold instance cannot be sold twice")
	_eq(Realm.serialize(state),before,"duplicate sale is atomic")
	# Synthetic but fully valid item instances isolate the finite pack boundary.
	while state.hero.inventory.size() < 128:
		state.hero.inventory.append(Items.make_instance("rune_stone","capacity/"+str(state.hero.inventory.size()),0))
	_check(Realm.deserialize(Realm.serialize(state)) != null,"bounded 128-item capacity fixture itself validates")
	var contract_id: String = str(Realm.hunt_board(state).offers[0].id)
	before = Realm.serialize(state)
	_check(not Realm.begin_hunt(state,contract_id).ok,"full pack blocks entry before paying watches")
	_eq(Realm.serialize(state),before,"failed reservation is atomic")
	_check(Realm.sell_item(state,"dawnwatch","capacity/127").ok,"first sale makes one slot")
	_check(not Realm.begin_hunt(state,contract_id).ok,"one free slot cannot accept two remaining item rewards")
	_check(Realm.sell_item(state,"dawnwatch","capacity/126").ok,"second sale makes the exact reserved capacity")
	Items.equip(state.hero,"start/boots")
	var run: Dictionary = _earned_hunt(state,0)
	if not _check(run.ok,"real combat and pickup transaction fits the exactly reserved two slots"):
		return
	_eq(state.hero.inventory.size(),128,"both earned rewards commit at the exact inventory bound")
	_check(Realm.deserialize(Realm.serialize(state)) != null,"full earned pack reloads")
	var reward: Dictionary = run.report.loot[0]
	var ledger: Dictionary = _story(state)
	var history: Array = state.huntBoard.completedHistory.duplicate(true)
	_check(Realm.sell_item(state,"dawnwatch",str(reward.instanceId)).ok,"earned item can make space for the next hunt")
	_eq([_story(state),state.huntBoard.completedHistory],[ledger,history],"sale cannot unclaim a story or completed-contract reward")
	_check(Realm.sell_item(state,"dawnwatch","capacity/124").ok,"second sale reserves room for both next rewards")
	_check(Realm.begin_hunt(state,str(Realm.hunt_board(state).offers[0].id)).ok,"next contract starts after its full capacity is available")
	_check(not Realm.preview_item_sale(state,"dawnwatch","capacity/125").ok,"merchant is unavailable during an active expedition")

func _test_malformed() -> void:
	if not _check(not pending_proof.is_empty() and not outcome_proof.is_empty(),"authority tests use an actually earned action result"):
		return
	var cases: Array = [
		["unknown encounter",func(o:Dictionary)->void:o.encounterId="invented"],
		["invented XP payload is ignored",func(o:Dictionary)->void:o.xp=999999],
		["wrong objective",func(o:Dictionary)->void:o.objective.type="invented"],
		["unearned extraction",func(o:Dictionary)->void:o.objective.extracted=false],
		["hero limit",func(o:Dictionary)->void:o.heroState.maxHp+=1],
		["foreign company loss",func(o:Dictionary)->void:o.casualties=[{"id":"company:dawn_guard","count":1}]],
		["unregistered reward",func(o:Dictionary)->void:o.lootClaims[0].rewardId="crypt_weapon"],
		["substituted item",func(o:Dictionary)->void:o.lootClaims[0].itemId="oathkeeper_blade"],
		["duplicate reward",func(o:Dictionary)->void:o.lootClaims.append(o.lootClaims[0].duplicate(true))]
	]
	for pair: Array in cases:
		var state: Dictionary = pending_proof.duplicate(true)
		var outcome: Dictionary = outcome_proof.duplicate(true)
		pair[1].call(outcome)
		var before: String = Realm.serialize(state)
		var report: Dictionary = Realm.resolve_encounter(state,str(state.pendingEncounter.id),outcome)
		if str(pair[0]) == "invented XP payload is ignored":
			_check(report.ok and int(report.xpGained) == int(pending_proof.pendingEncounter.xpReward),"result cannot choose its XP award")
		else:
			_check(not report.ok,"authority rejects "+str(pair[0]))
			_eq(Realm.serialize(state),before,"failed outcome is atomic: "+str(pair[0]))
	var corruptions: Array = [
		["unknown board key",func(s:Dictionary)->void:s.huntBoard.cheat=true],
		["future board version",func(s:Dictionary)->void:s.huntBoard.version=999],
		["missing offer",func(s:Dictionary)->void:s.huntBoard.offers.pop_back()],
		["forged tier",func(s:Dictionary)->void:s.huntBoard.tier=30],
		["forged XP",func(s:Dictionary)->void:s.huntBoard.offers[0].xpReward=999],
		["forged seed",func(s:Dictionary)->void:s.huntBoard.offers[0].seed+=1],
		["forged reward",func(s:Dictionary)->void:s.huntBoard.offers[0].lootRewards[0].itemId="oathkeeper_blade"],
		["reinforced actor",func(s:Dictionary)->void:s.huntBoard.offers[0].enemies[0].hp+=1],
		["changed actor attack",func(s:Dictionary)->void:s.huntBoard.offers[0].enemies[0].attack=1],
		["claimed living source",func(s:Dictionary)->void:s.huntBoard.offers[0].claimedRewardIds=["hunt_supply"]],
		["unknown active contract",func(s:Dictionary)->void:s.huntBoard.activeContractId="invented"],
		["skipped attempt",func(s:Dictionary)->void:s.huntBoard.offers[0].attempts+=1],
		["already-resolved pending attempt",func(s:Dictionary)->void:s.huntBoard.offers[0].lastResolvedAttempt=1],
		["changed registered XP",func(s:Dictionary)->void:s.pendingEncounter.xpReward=999],
		["changed registered seed",func(s:Dictionary)->void:s.pendingEncounter.seed+=1],
		["unknown origin",func(s:Dictionary)->void:s.pendingEncounter.originLocationId="missing"],
		["different geometry",func(s:Dictionary)->void:s.pendingEncounter.arena.obstacles=[]],
		["another hero kit",func(s:Dictionary)->void:s.pendingEncounter.heroSnapshot.skills=["ember"]],
		["unearned generation",func(s:Dictionary)->void:s.huntBoard.generation=2],
		["legacy version mixed with board",func(s:Dictionary)->void:s.version=3]
	]
	for pair: Array in corruptions:
		var state: Dictionary = pending_proof.duplicate(true)
		pair[1].call(state)
		_check(Realm.deserialize(Realm.serialize(state)) == null,"save rejects "+str(pair[0]))
		var before: String = Realm.serialize(state)
		_check(not Realm.resolve_encounter(state,str(state.pendingEncounter.id),outcome_proof).ok,"live authority rejects corrupt registry: "+str(pair[0]))
		_eq(Realm.serialize(state),before,"corrupt registry never partially commits")
	if not retreat_proof.is_empty():
		var revived: Dictionary = retreat_proof.duplicate(true)
		revived.huntBoard.offers[0].enemies[0].hp=1
		_check(Realm.deserialize(Realm.serialize(revived)) == null,"claimed corpse source cannot be resurrected in a save")
		var duplicate: Dictionary = retreat_proof.duplicate(true)
		duplicate.huntBoard.offers[0].claimedRewardIds.append("hunt_supply")
		duplicate.huntBoard.offers[0].claimedLoot.append(duplicate.huntBoard.offers[0].claimedLoot[0])
		_check(Realm.deserialize(Realm.serialize(duplicate)) == null,"duplicate persistent claim is rejected")
	_check(Realm.deserialize(Realm.serialize(pending_proof)) != null,"rejections do not poison a valid pending save")

func _test_migration() -> void:
	for filename: String in ["v1-town-save.json","v1-earned-equipment-save.json","v1-combat-save.json","v2-invested-combat-save.json","v2-legacy-ember-save.json","v3-oathwarden-combat-save.json"]:
		var shell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/progression/"+filename))
		var original: Dictionary = JSON.parse_string(str(shell.realm))
		var state: Variant = Realm.deserialize(str(shell.realm))
		if not _check(state != null,"authentic prior save migrates: "+filename):
			continue
		_eq(state.version,Realm.VERSION,"migration advances to the current hunt schema")
		_eq(state.pendingEncounter,original.pendingEncounter,"old committed snapshot is untouched: "+filename)
		_eq([state.huntBoard.generation,state.huntBoard.tier,state.huntBoard.offers.size()],[1,state.hero.level,3],"migration registers one fresh board at earned current level")
		_eq(_story(state),_story(original),"migration never changes story claims or enemy losses")
		_eq([state.hero.hp,state.hero.mana,state.hero.inventory],[original.hero.hp,original.hero.mana,original.hero.inventory],"migration preserves wounds, Focus and equipment")
		_check(Realm.deserialize(Realm.serialize(state)) != null,"migrated board saves again")
		if state.pendingEncounter != null:
			var action: Dictionary = Action.deserialize(str(shell.action),state.pendingEncounter)
			if _check(not action.is_empty(),"old live action still restores against exact original registry"):
				Action.advance(action,12)
				_check(str(action.phase) in ["running","cleared","finished"],"committed action continues after realm migration")

func _rest_full(state: Dictionary) -> bool:
	for watch: int in range(32):
		if int(state.hero.hp) == int(state.hero.maxHp) and int(state.hero.mana) == int(state.hero.maxMana):
			return true
		if not bool(Realm.rest(state).ok):
			return false
	return false

func _upgrade_earned_gear(state: Dictionary) -> void:
	for item: Dictionary in state.hero.inventory.duplicate(true):
		if str(item.slot) == "material":
			continue
		var current: Dictionary = Items.derive_stats(state.hero)
		var probe: Dictionary = state.hero.duplicate(true)
		if not Items.equip(probe,str(item.instanceId)).ok:
			continue
		var proposed: Dictionary = Items.derive_stats(probe)
		var before: float = float(current.attack)*4.0+float(current.armor)*3.0+float(current.maxHp)*0.1+float(current.maxMana)*0.1+float(current.wardBonus)*0.2
		var after: float = float(proposed.attack)*4.0+float(proposed.armor)*3.0+float(proposed.maxHp)*0.1+float(proposed.maxMana)*0.1+float(proposed.wardBonus)*0.2
		if after > before:
			Items.equip(state.hero,str(item.instanceId))

func _test_level_route() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var original_story: Dictionary = _story(state)
	var original_companies: Dictionary = _player_companies(state)
	var runs: int = 0
	var total_ticks: int = 0
	var total_xp: int = 0
	var levels_seen: Dictionary = {1:true}
	var templates_seen: Dictionary = {}
	var health_min: int = 100000
	while int(state.hero.level) < 30 and runs < 100:
		var points: int = int(state.hero.progression.unspent)/3
		if points > 0 and not _check(Realm.allocate_attributes(state,{"might":points,"vitality":points,"spirit":points}).ok,"earned route spends its current three-point level budget"):
			return
		_upgrade_earned_gear(state)
		if not _check(_rest_full(state),"earned route rests through actual watches before the next contract"):
			return
		var run: Dictionary = _earned_hunt(state,runs%3)
		if not _check(bool(run.ok),"actual successive contract %d clears at level %d: %s" % [runs+1,int(state.hero.level),str(run.message)]):
			print("HUNTS_ROUTE_FAILURE ",JSON.stringify(run))
			return
		runs += 1
		total_ticks += int(run.ticks)
		total_xp += int(run.report.xpGained)
		health_min = mini(health_min,int(state.hero.hp))
		levels_seen[int(state.hero.level)] = true
		templates_seen[str(run.offer.name)] = true
		var restored: Variant = Realm.deserialize(Realm.serialize(state))
		if not _check(restored != null,"earned generation %d survives complete save validation" % int(state.huntBoard.generation)):
			return
		state = restored
		if runs%10 == 0:
			print("HUNTS_ROUTE_PROGRESS ",JSON.stringify({"runs":runs,"level":state.hero.level,"xp":state.hero.xp,"inventory":state.hero.inventory.size()}))
	_eq([state.hero.level,state.hero.xp,total_xp],[30,23200,23200],"actual completed contracts alone reach the deterministic cap")
	_eq(templates_seen.size(),3,"earned route uses all three real actor layouts")
	_eq(state.huntBoard.completedHistory.size(),Hunts.HISTORY_LIMIT,"old completion history is trimmed to its explicit bound")
	_eq(int(state.huntBoard.completedHistory[0].generation),int(state.huntBoard.generation)-Hunts.HISTORY_LIMIT,"history retains the newest consecutive generations")
	_eq(_story(state),original_story,"level-thirty route leaves once-only story untouched")
	_eq(_player_companies(state),original_companies,"all repeated solo hunts preserve both stationed player companies while rival recruitment continues")
	var points: int = int(state.hero.progression.unspent)/3
	_check(Realm.allocate_attributes(state,{"might":points,"vitality":points,"spirit":points}).ok,"last earned level budget is spendable")
	_eq(state.hero.progression.allocations,{"might":30,"finesse":0,"vitality":30,"spirit":30},"ninety earned choices respect independent attribute caps")
	_rest_full(state)
	var capped: Dictionary = _earned_hunt(state,0,false)
	if _check(capped.ok,"one more actual contract remains playable at maximum level"):
		_eq([capped.report.xpGained,capped.report.levelsGained,state.hero.xp,state.hero.progression.unspent],[0,0,23200,0],"at-cap completion refreshes contracts without minting XP or points")
		_check(Realm.deserialize(Realm.serialize(state)) != null,"zero-award completion history validates at the cap")
	earned_route = {"runsToLevel30":runs,"extraCapRun":bool(capped.ok),"level":state.hero.level,"xp":state.hero.xp,"actionTicks":total_ticks,"watchIndex":state.watchIndex,"inventory":state.hero.inventory.size(),"minReturnHealth":health_min,"historyEntries":state.huntBoard.completedHistory.size(),"templates":templates_seen.keys(),"scope":"Repeated real commands in three curated arena layouts; not a full campaign or production balance claim."}
