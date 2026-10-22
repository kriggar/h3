extends SceneTree
## Location changes run through registered realm transactions and the actual
## fixed-step action model. No simulated victory or invented pickup is used.
const Realm = preload("res://game/redesign/realm_rules.gd")
const Hunts = preload("res://game/redesign/hunt_rules.gd")
const Action = preload("res://game/redesign/action_rules.gd")
const Dungeons = preload("res://game/redesign/dungeon_catalog.gd")
const Items = preload("res://game/redesign/item_rules.gd")
const V4_FIXTURE: String = "res://tests/fixtures/dungeons/v4-active-hunt-save.json"

var checks: int = 0
var failures: int = 0
var groups: int = 0
var completed_locations: Array = []

func _initialize() -> void:
	call_deferred("_run_all")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("DUNGEONS FAIL: " + label)
	return condition

func _eq(actual: Variant, expected: Variant, label: String) -> bool:
	var same: bool = Realm._same(actual,expected)
	return _check(same,label+(" [actual=%s expected=%s]" % [str(actual),str(expected)] if not same else ""))

func _run(label: String, test: Callable) -> void:
	groups += 1
	var before: int = failures
	test.call()
	print("DUNGEONS GROUP ",groups," ",label,": ","PASS" if before == failures else "FAIL")

func _run_all() -> void:
	_run("Registered versions preserve rewards, identity and immutable old geometry",_test_registry)
	_run("Three distinct layouts have reachable spawns, combat lanes and extraction",_test_navigation)
	_run("All locations save after real loot, resume deterministically and complete",_test_live_locations)
	_run("Grazing a fence corner still yields a complete single-command extraction",_test_corner_extraction)
	_run("Legacy pending and withdrawn contracts preserve their arena and claims",_test_legacy_contract)
	_run("Authentic version-four action continues from its original runtime",_test_authentic_v4)
	_run("Unregistered layouts, spawns and classes fail closed",_test_corruption)
	print("DUNGEONS_SUMMARY ",JSON.stringify({"groups":groups,"checks":checks,"failures":failures,"completedLocations":completed_locations}))
	quit(0 if failures == 0 else 1)

func _fresh(seed: int = 711) -> Dictionary:
	var state: Dictionary = Realm.create_realm(seed)
	Realm.allocate_attributes(state,{"might":1,"vitality":1,"spirit":1})
	return state

func _v(point: Array) -> Vector2:
	return Vector2(float(point[0]),float(point[1]))

func _hero(action: Dictionary) -> Dictionary:
	return Action.get_actor(action,str(action.heroId))

func _idle(action: Dictionary) -> bool:
	for tick: int in range(180):
		if str(action.phase) == "finished":
			return false
		if _hero(action).action.is_empty() and int(action.tick) >= int(_hero(action).restartUntil):
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
		if _v(_hero(action).pos).distance_to(_v(destination)) < 0.15:
			return true
	return false

func _outer_kill(action: Dictionary) -> bool:
	var scout: Dictionary = action.actors[1]
	if not Action.submit(action,{"kind":"cast","ability":"ward"}).ok or not _idle(action):
		return false
	if not Action.submit(action,{"kind":"attack","targetId":str(scout.id)}).ok:
		return false
	for tick: int in range(900):
		Action.advance(action)
		if int(scout.hp) <= 0:
			return str(action.phase) == "running"
		if str(action.phase) == "finished":
			return false
	return false

func _clear(action: Dictionary) -> bool:
	for tick: int in range(5400):
		if str(action.phase) in ["cleared","finished"]:
			break
		var hero: Dictionary = _hero(action)
		if hero.action.is_empty() and int(action.tick) >= int(hero.restartUntil):
			var target: Dictionary = {}
			var distance: float = INF
			for enemy: Dictionary in action.actors:
				if str(enemy.side) == "enemy" and int(enemy.hp) > 0 and _v(hero.pos).distance_to(_v(enemy.pos)) < distance:
					target = enemy
					distance = _v(hero.pos).distance_to(_v(enemy.pos))
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
		if not _walk(action,loot.pos) or not _idle(action) or not Action.submit(action,{"kind":"interact","targetId":str(loot.id)}).ok:
			return false
		Action.advance(action,10)
		if not bool(loot.get("claimed",false)):
			return false
	return true

func _exit(action: Dictionary) -> bool:
	if not _walk(action,action.arena.exit) or not _idle(action) or not Action.submit(action,{"kind":"exit"}).ok:
		return false
	Action.advance(action,45)
	return not Action.outcome(action).is_empty()

func _test_registry() -> void:
	_eq(Dungeons.LEGACY_ARENA,Realm.CRYPT_ARENA,"frozen catalog arena is exactly the original story contract")
	_check(not Dungeons.LEGACY_ARENA.has("layoutId"),"old action arena gains no metadata keys")
	_eq(Dungeons.arena_for("bell_crypt"),Realm.CRYPT_ARENA,"story vault keeps the old arena")
	for template: Dictionary in Hunts.TEMPLATES:
		_eq(Dungeons.arena_for(str(template.id),1),Realm.CRYPT_ARENA,"all old hunt arenas remain frozen")
		_eq(Dungeons.hero_spawn_for(str(template.id),1),[0,8],"old hero spawn remains unchanged")
	_check(Dungeons.arena_for("invented").is_empty() and Dungeons.arena_for("hollow_kennels",99).is_empty(),"unknown arenas and registry versions cannot be requested")
	_check(Hunts.definition(711,1,0,1,99).is_empty() and Hunts.create_board(711,1,1,[],99).is_empty(),"unknown registry versions cannot generate offers")
	var editable: Dictionary = Dungeons.arena_for("hollow_kennels")
	editable.obstacles[0].rect[0] = 999
	editable.entry[0] = 999
	_check(Dungeons.arena_for("hollow_kennels").obstacles[0].rect[0] != 999 and Dungeons.hero_spawn_for("hollow_kennels")[0] != 999,"presentation copies cannot edit authoritative geometry")
	for seed: int in [0,711,4294967295]:
		for generation: int in [1,7]:
			for tier: int in [1,15,30]:
				for slot: int in range(3):
					var old: Dictionary = Hunts.definition(seed,generation,slot,tier,1)
					var current: Dictionary = Hunts.definition(seed,generation,slot,tier,2)
					for index: int in range(current.enemies.size()):
						current.enemies[index].pos = old.enemies[index].pos.duplicate()
					_eq(current,old,"layout registry changes no enemy stats, class, reward, seed or XP at %d/%d/%d/%d" % [seed,generation,tier,slot])
	var state: Dictionary = _fresh()
	_eq([state.version,state.huntBoard.version],[5,2],"fresh realm uses the current save and location registry")
	var before: String = Realm.serialize(state)
	var view: Dictionary = Realm.hunt_board(state)
	for offer: Dictionary in view.offers:
		_eq(offer.layoutId,Dungeons.layout_id_for(offer.templateId),"board brief references the actual registered location")
		_check(not str(offer.tacticalBrief).is_empty(),"each location has an actionable tactical brief")
	_eq(Realm.serialize(state),before,"location briefs do not mutate the campaign")

func _test_navigation() -> void:
	var layouts: Dictionary = {}
	var bounds: Dictionary = {}
	for slot: int in range(3):
		var state: Dictionary = _fresh()
		if not _check(Realm.begin_hunt(state,str(state.huntBoard.offers[slot].id)).ok,"registered layout departure succeeds"):
			continue
		var encounter: Dictionary = state.pendingEncounter
		var action: Dictionary = Action.create(encounter)
		if not _check(str(action.phase) == "running","registered arena accepts every actor spawn"):
			continue
		layouts[str(action.arena.layoutId)] = true
		bounds[JSON.stringify(action.arena.bounds)] = true
		_eq(encounter.sceneId,action.arena.layoutId,"renderer scene and collision registry agree")
		_eq(_hero(action).pos,action.arena.entry,"new hero physically starts at this location's entry")
		_eq(_hero(action).skills,["cleave","ward"],"all locations preserve Mara's class kit")
		var points: Array = [action.arena.entry,action.arena.exit]
		for enemy: Dictionary in action.actors.slice(1):
			points.append(enemy.pos)
		var detours: int = 0
		for radius: float in [0.42,0.5]:
			for point: Array in points:
				_check(Action._walkable(action,_v(point),radius),"spawn and extraction have actor-radius clearance")
			for start_index: int in range(points.size()):
				for end_index: int in range(points.size()):
					if start_index == end_index:
						continue
					var start: Vector2 = _v(points[start_index])
					var destination: Vector2 = _v(points[end_index])
					var path: Array = Action._path(action,start,destination,radius)
					var valid: bool = not path.is_empty()
					var previous: Vector2 = start
					for step: Array in path:
						valid = valid and Action._line_clear(action,previous,_v(step),radius)
						previous = _v(step)
					valid = valid and previous.distance_to(destination) < 0.001
					_check(valid,"%s connects point %d to %d at radius %.2f without clipping" % [str(action.arena.layoutId),start_index,end_index,radius])
					detours += 1 if path.size() > 1 else 0
		_check(detours > 0,"obstacles produce actual navigable detours rather than an empty reskin")
	_eq(layouts.size(),3,"three offers have three distinct location identities")
	_eq(bounds.size(),3,"locations use three independently sized collision arenas")

func _test_live_locations() -> void:
	for slot: int in range(3):
		var state: Dictionary = _fresh()
		var companies: Dictionary = state.companies.duplicate(true)
		var story: Dictionary = state.locations.bell_crypt.duplicate(true)
		var offer: Dictionary = state.huntBoard.offers[slot].duplicate(true)
		if not _check(Realm.begin_hunt(state,str(offer.id)).ok,"new location opens for live continuation"):
			continue
		var expected_gear: Dictionary = Realm.preview_reward(state,"hunt_gear").instance
		var expected_supply: Dictionary = Realm.preview_reward(state,"hunt_supply").instance
		var action: Dictionary = Action.create(state.pendingEncounter)
		if not _check(_outer_kill(action) and _collect(action,"hunt_supply"),"%s earns the scout pickup through real combat and interaction" % str(offer.name)):
			print("DUNGEONS_COMBAT_DEBUG ",JSON.stringify(Action.snapshot(action)))
			continue
		_eq([action.objective.progress,action.lootClaims.size()],[1,1],"partial save contains an actual kill and exact single physical claim")
		var loaded: Variant = Realm.deserialize(Realm.serialize(state))
		if not _check(loaded != null,"partially played location's realm contract reloads"):
			continue
		_eq(loaded.pendingEncounter,state.pendingEncounter,"live contract retains entry, obstacles, spawns and reward seed")
		var resumed: Dictionary = Action.deserialize(Action.serialize(action),loaded.pendingEncounter)
		if not _check(not resumed.is_empty(),"live action restores its movement, damage and collected loot"):
			continue
		Action.advance(action,37)
		Action.advance(resumed,37)
		_eq(Action.snapshot(resumed),Action.snapshot(action),"continued combat and AI are deterministic after save")
		if not _check(_clear(resumed),"%s remaining pack can be defeated with the actual Oathwarden kit" % str(offer.name)):
			print("DUNGEONS_COMBAT_DEBUG ",JSON.stringify(Action.snapshot(resumed)))
			continue
		if not _check(_collect(resumed) and _exit(resumed),"all physical rewards and extraction are reachable after the clear"):
			continue
		var outcome: Dictionary = Action.outcome(resumed)
		_eq([outcome.resolution,outcome.lootClaims.size()],["victory",3],"new location produces a legal clear and exactly three claims")
		var report: Dictionary = Realm.resolve_encounter(loaded,str(loaded.pendingEncounter.id),outcome)
		if not _check(report.ok,"real result commits through the existing realm ledger"):
			continue
		_eq([loaded.huntBoard.version,loaded.huntBoard.generation,report.xpGained],[2,2,offer.xpReward],"completion refreshes locations and pays the unchanged XP once")
		_eq(Items.find_instance(loaded.hero,str(expected_gear.instanceId)),expected_gear,"saved live combat awards the original gear roll")
		_eq(Items.find_instance(loaded.hero,str(expected_supply.instanceId)),expected_supply,"supply collected before save appears only once")
		_eq(loaded.companies,companies,"new solo locations preserve stationed companies")
		_eq(loaded.locations.bell_crypt,story,"new locations preserve the once-only story ledger")
		_check(Realm.deserialize(Realm.serialize(loaded)) != null,"completed location with inventory and history reloads")
		_check(not Realm.resolve_encounter(loaded,str(outcome.encounterId),outcome).ok,"old callback cannot pay again after a board refresh")
		completed_locations.append({"layoutId":str(resumed.arena.layoutId),"ticks":int(resumed.tick),"hp":int(loaded.hero.hp),"xp":int(loaded.hero.xp)})

func _test_corner_extraction() -> void:
	var state: Dictionary = _fresh(712)
	if not _check(Realm.begin_hunt(state,str(state.huntBoard.offers[0].id)).ok,"corner regression opens the registered Briar hunt"):
		return
	var action: Dictionary = Action.create(state.pendingEncounter)
	# This line clips less than one old 0.12-unit sampling interval of the
	# radius-expanded fence corner. A path must go around that collision.
	var near_corner: Vector2 = Vector2(0.5277202,-5.2160168)
	_check(not Action._line_clear(action,near_corner,Vector2(-8,10),0.42),"a narrow corner intersection cannot be skipped by visibility sampling")
	if not _check(_clear(action),"seed712 starter clears without collecting its loot"):
		return
	_check(_exit(action),"one extraction move routes completely around the fence without retry nudges")
	if not Action.outcome(action).is_empty():
		_eq([Action.outcome(action).resolution,Action.outcome(action).lootClaims.size()],["victory",0],"uncollected physical rewards stay unclaimed on extraction")

func _test_legacy_contract() -> void:
	var idle: Dictionary = _fresh()
	idle.version = 4
	idle.huntBoard = Hunts.create_board(int(idle.seed),1,1,[],1)
	var untouched: Dictionary = idle.huntBoard.duplicate(true)
	var refreshed: Variant = Realm.deserialize(Realm.serialize(idle))
	if _check(refreshed != null,"valid old untouched board loads"):
		_eq([refreshed.version,refreshed.huntBoard.version,refreshed.huntBoard.generation],[5,2,1],"untouched old board exposes new locations without advancing generation")
		for index: int in range(3):
			_eq(refreshed.huntBoard.offers[index].lootRewards,untouched.offers[index].lootRewards,"refresh preserves all prequoted rewards")
			_eq([refreshed.huntBoard.offers[index].seed,refreshed.huntBoard.offers[index].xpReward],[untouched.offers[index].seed,untouched.offers[index].xpReward],"refresh cannot reroll rewards or change XP")
	var edited_idle: Dictionary = idle.duplicate(true)
	edited_idle.huntBoard.offers[0].enemies[0].hp -= 1
	_check(Realm.deserialize(Realm.serialize(edited_idle)) == null,"old board corruption is rejected before an idle-board upgrade")
	var id: String = str(idle.huntBoard.offers[0].id)
	if not _check(Realm.begin_hunt(idle,id).ok,"frozen old registry can still open its exact contract"):
		return
	_eq([idle.pendingEncounter.sceneId,idle.pendingEncounter.heroSnapshot.pos],["bell_crypt",[0,8]],"legacy pending uses its original scene and hero spawn")
	_eq(idle.pendingEncounter.arena,Realm.CRYPT_ARENA,"legacy pending arena has no new keys or walls")
	var loaded: Variant = Realm.deserialize(Realm.serialize(idle))
	if not _check(loaded != null,"old pending hunt migrates before any live action is resumed"):
		return
	_eq([loaded.version,loaded.huntBoard.version],[5,1],"pending hunt keeps its old registry under current save version")
	_eq(loaded.pendingEncounter,idle.pendingEncounter,"migration preserves the full old encounter byte-equivalent")
	var original_preview: Dictionary = Realm.preview_reward(loaded,"hunt_gear")
	var action: Dictionary = Action.create(loaded.pendingEncounter)
	if not _check(_outer_kill(action) and _collect(action,"hunt_supply"),"legacy scout and claim are earned through actual combat"):
		return
	var resumed: Dictionary = Action.deserialize(Action.serialize(action),loaded.pendingEncounter)
	if not _check(not resumed.is_empty() and _exit(resumed),"legacy partial action restores and legally withdraws"):
		return
	var result: Dictionary = Action.outcome(resumed)
	_eq([result.resolution,result.lootClaims.size()],["retreat",1],"old arena withdrawal carries the real single pickup")
	if not _check(Realm.resolve_encounter(loaded,str(loaded.pendingEncounter.id),result).ok,"old arena partial result commits exactly once"):
		return
	var active_board: Dictionary = loaded.huntBoard.duplicate(true)
	var withdrawn: Variant = Realm.deserialize(Realm.serialize(loaded))
	if not _check(withdrawn != null,"legacy active contract with claims survives a second save"):
		return
	_eq(withdrawn.huntBoard,active_board,"active old board is not replaced by new geometry")
	_eq([withdrawn.huntBoard.version,Hunts.contract(withdrawn.huntBoard,id).enemies[0].hp,Hunts.contract(withdrawn.huntBoard,id).claimedRewardIds],[1,0,["hunt_supply"]],"legacy attrition and once-only claim ledger stay intact")
	Realm.rest(withdrawn)
	if not _check(Realm.begin_hunt(withdrawn,id).ok,"same legacy hunt re-enters after an explicit rest"):
		return
	_eq(withdrawn.pendingEncounter.arena,Realm.CRYPT_ARENA,"paid legacy re-entry keeps the original collision contract")
	var next_item: Dictionary = Realm.preview_reward(withdrawn,"hunt_gear").instance.duplicate(true)
	var old_item: Dictionary = original_preview.instance.duplicate(true)
	_check(str(next_item.instanceId) != str(old_item.instanceId),"new attempt has its own reward identity for replay protection")
	next_item.erase("instanceId")
	old_item.erase("instanceId")
	_eq(next_item,old_item,"re-entry cannot reroll an old unclaimed item")
	_check(not Realm.preview_reward(withdrawn,"hunt_supply").ok,"old collected supply is excluded from the next attempt")
	var final_action: Dictionary = Action.create(withdrawn.pendingEncounter)
	_eq([final_action.objective.progress,final_action.lootRewards.size()],[1,2],"old corpse and remaining reward registry resume together")
	if not _check(_clear(final_action) and _collect(final_action) and _exit(final_action),"legacy survivor pack completes and its remaining spoils are reachable"):
		return
	if not _check(Realm.resolve_encounter(withdrawn,str(withdrawn.pendingEncounter.id),Action.outcome(final_action)).ok,"legacy completion uses the authoritative result transaction"):
		return
	_eq([withdrawn.huntBoard.version,withdrawn.huntBoard.generation],[2,2],"only completed old hunt advances to the new location registry")
	_eq(withdrawn.huntBoard.completedHistory[0].claimedRewards.size(),3,"legacy claims are preserved across the board version change")
	_check(Realm.deserialize(Realm.serialize(withdrawn)) != null,"mixed legacy history and current locations reload")
	var old_refreshed: Dictionary = withdrawn.duplicate(true)
	old_refreshed.version = 4
	old_refreshed.huntBoard = Hunts.create_board(int(withdrawn.seed),int(withdrawn.huntBoard.generation),int(withdrawn.huntBoard.tier),withdrawn.huntBoard.completedHistory,1)
	var earned_refresh: Variant = Realm.deserialize(Realm.serialize(old_refreshed))
	if _check(earned_refresh != null,"old idle board with an earned completion history upgrades"):
		_eq([earned_refresh.huntBoard.version,earned_refresh.huntBoard.generation,earned_refresh.huntBoard.tier],[2,withdrawn.huntBoard.generation,withdrawn.huntBoard.tier],"idle migration preserves earned board generation and tier")
		_eq(earned_refresh.huntBoard.completedHistory,withdrawn.huntBoard.completedHistory,"idle migration preserves earned rewards and XP history")

func _test_authentic_v4() -> void:
	if not _check(FileAccess.file_exists(V4_FIXTURE),"authentic previous-build fixture is available"):
		return
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(V4_FIXTURE))
	if not _check(fixture is Dictionary,"previous-build fixture parses"):
		return
	var original: Variant = JSON.parse_string(str(fixture.realm))
	var loaded: Variant = Realm.deserialize(str(fixture.realm))
	if not _check(loaded != null,"genuine version-four pending hunt migrates"):
		return
	_eq(loaded.pendingEncounter,original.pendingEncounter,"genuine old pending action registry is unchanged")
	_eq([loaded.version,loaded.huntBoard.version],[5,1],"genuine old action retains the frozen hunt registry")
	var resumed: Dictionary = Action.deserialize(str(fixture.action),loaded.pendingEncounter)
	var expected: Dictionary = Action.deserialize(str(fixture.expectedContinuation),loaded.pendingEncounter)
	if not _check(not resumed.is_empty() and not expected.is_empty(),"both original active and reference continuation states restore"):
		return
	Action.advance(resumed,int(fixture.continuationTicks))
	_eq(Action.snapshot(resumed),Action.snapshot(expected),"new runtime matches exact old-runtime action continuation")

func _test_corruption() -> void:
	var state: Dictionary = _fresh()
	Realm.begin_hunt(state,str(state.huntBoard.offers[0].id))
	for mutation: String in ["layout","rect","entry","spawn","registry","old_version","reward","class"]:
		var bad: Dictionary = state.duplicate(true)
		match mutation:
			"layout": bad.pendingEncounter.arena.layoutId = "ashen_cellar"
			"rect": bad.pendingEncounter.arena.obstacles[0].rect[0] -= 1
			"entry": bad.pendingEncounter.arena.entry = [0,8]
			"spawn": bad.pendingEncounter.enemies[0].pos = [0,0]
			"registry": bad.huntBoard.version = 1
			"old_version": bad.version = 4
			"reward": bad.pendingEncounter.xpReward += 1
			"class": bad.pendingEncounter.heroSnapshot.skills.append("ember")
		_check(Realm.deserialize(Realm.serialize(bad)) == null,"tampered %s cannot manufacture a registered pending hunt" % mutation)
	var action: Dictionary = Action.create(state.pendingEncounter)
	var before: String = Action.serialize(action)
	_check(not Action.submit(action,{"kind":"cast","ability":"roots","pos":[0,0]}).ok and not Action.submit(action,{"kind":"cast","ability":"ember","pos":[0,0]}).ok,"new locations cannot grant cross-class abilities")
	_eq(Action.serialize(action),before,"rejected cross-class requests do not mutate the action")
	var bad_action: Dictionary = Action.snapshot(action)
	bad_action.arena = Dungeons.arena_for("ashen_watch")
	_check(Action.restore(bad_action,state.pendingEncounter).is_empty(),"a live action cannot substitute another registered location's arena")
	bad_action = Action.snapshot(action)
	bad_action.arena.erase("layoutId")
	_check(Action.restore(bad_action,state.pendingEncounter).is_empty(),"new layout cannot masquerade as an old saved arena")
	var legacy: Dictionary = _fresh()
	legacy.huntBoard = Hunts.create_board(int(legacy.seed),1,1,[],1)
	Realm.begin_hunt(legacy,str(legacy.huntBoard.offers[0].id))
	var legacy_action: Dictionary = Action.create(legacy.pendingEncounter)
	var current_keys: Array = action.keys()
	var legacy_keys: Array = legacy_action.keys()
	current_keys.sort()
	legacy_keys.sort()
	_eq(current_keys,legacy_keys,"new arenas add no top-level Action schema fields")
