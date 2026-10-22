extends SceneTree
## Attribute rules and migration, using actual action damage, movement, wards,
## and a legal solo clear. Level-30 boundaries are fixtures, not content claims.
const Realm = preload("res://game/redesign/realm_rules.gd")
const Items = preload("res://game/redesign/item_rules.gd")
const Action = preload("res://game/redesign/action_rules.gd")

var checks: int = 0
var failures: int = 0
var groups: int = 0
var earned: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run_all")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("PROGRESSION FAIL: " + label)
	return condition

func _eq(actual: Variant, expected: Variant, label: String) -> bool:
	var same: bool = Realm._same(actual, expected)
	return _check(same, label + (" [actual=%s expected=%s]" % [str(actual), str(expected)] if not same else ""))

func _run(label: String, test: Callable) -> void:
	groups += 1
	var before: int = failures
	test.call()
	print("PROGRESSION GROUP ", groups, " ", label, ": ", "PASS" if before == failures else "FAIL")

func _run_all() -> void:
	_run("Baseline, public view, and the complete level boundary table", _test_baseline)
	_run("Atomic draft/commit, full stat previews, and no free healing", _test_allocation)
	_run("Rejected drafts, maximum investments, and stale revisions", _test_rejection)
	_run("Equipment/set/socket composition and preview invalidation", _test_equipment)
	_run("Safe-town resets, capped costs, and recovery restrictions", _test_reset)
	_run("XP overflow, multi-level grants, and capped budgets", _test_experience)
	_run("Actual attack, movement, health capacity, and finite ward effects", _test_combat_effects)
	_run("Pending locks and fractional-speed live save continuation", _test_pending)
	_run("Authentic v1 town, earned-equipment, and live-combat migration", _test_migration)
	_run("Malformed progression and derived-cache rejection", _test_malformed)
	_run("Earned crypt XP, level-up, and once-only application", _test_earned)
	print("PROGRESSION_SUMMARY ", JSON.stringify({"groups":groups,"checks":checks,"failures":failures,"earned":earned}))
	quit(0 if failures == 0 else 1)

func _at_level(level: int) -> Dictionary:
	var state: Dictionary = Realm.create_realm(711)
	Realm._grant_experience(state.hero, Realm.experience_for_level(level))
	return state

func _test_baseline() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var view: Dictionary = Realm.progression_view(state)
	_eq([state.version,view.level,view.xp,view.unspent,view.revision], [Realm.VERSION,1,0,3,0], "new campaign begins with one real three-point choice")
	_eq(view.attributes, {"might":10,"finesse":10,"vitality":10,"spirit":10}, "baseline scores do not add duplicate bonuses")
	_eq([state.hero.hp,state.hero.maxHp,state.hero.mana,state.hero.maxMana,state.hero.attack,state.hero.armor,state.hero.speed], [120,124,40,40,18,3,4.6], "existing starter stats and wounds are preserved")
	for field: String in ["level","xp","maxLevel","levelFloorXp","nextLevelXp","xpIntoLevel","xpToNextLevel","levelSpanXp","atCap","unspent","revision","allocations","attributes","canAllocate","lockReason","resetCost"]:
		_check(view.has(field), "public UI contract includes " + field)
	_eq([view.levelFloorXp,view.nextLevelXp,view.xpIntoLevel,view.xpToNextLevel,view.levelSpanXp], [0,100,0,100,100], "XP bar exposes remaining, not cumulative, next-level XP")
	var catalog: Array = Realm.attribute_catalog()
	_eq(catalog.size(), 4, "only four implemented attributes are offered")
	for row: Dictionary in catalog:
		_check(row.has("name") and row.has("description") and row.has("effects") and row.base == 10 and row.maxInvestment == 40, "attribute metadata is usable by the sheet")
	catalog[0].effects.attack = 999
	_eq(Realm.attribute_catalog()[0].effects.attack, 1, "catalog callers cannot mutate shared tuning")
	var last: int = -1
	for level: int in range(1, 31):
		var threshold: int = Realm.experience_for_level(level)
		_check(threshold > last and Realm.level_for_experience(threshold) == level, "level threshold resolves exactly: " + str(level))
		if level > 1:
			_eq(Realm.level_for_experience(threshold - 1), level - 1, "one XP short does not grant level " + str(level))
		last = threshold
	_eq(last, 23200, "level thirty has the agreed cumulative threshold")
	_check(Realm.deserialize(Realm.serialize(state)) != null, "new progression persists from first frame")

func _test_allocation() -> void:
	var state: Dictionary = Realm.create_realm(711)
	state.hero.hp = 47
	state.hero.mana = 9
	var before: String = Realm.serialize(state)
	var preview: Dictionary = Realm.preview_attribute_allocation(state, {"might":1,"vitality":1,"spirit":1})
	if not _check(preview.ok, "legal draft previews"):
		return
	_eq(Realm.serialize(state), before, "preview does not mutate resources, hero, or clock")
	_eq(preview.before, Items.derive_stats(state.hero), "before is the complete item/set stat composition")
	_eq([preview.after.attack,preview.after.maxHp,preview.after.maxMana,preview.after.wardBonus], [19,130,42,1], "each invested score has its supported effect")
	_eq([preview.after.hp,preview.after.mana,preview.pointCost,preview.pointsRemaining], [47,9,3,0], "preview never heals or restores Focus")
	var result: Dictionary = Realm.allocate_attributes(state, {"might":1,"vitality":1,"spirit":1}, int(preview.revision))
	_check(result.ok, "quoted allocation commits")
	_eq(result.after, preview.after, "committed derived totals match the quote exactly")
	_eq([state.hero.hp,state.hero.mana,state.watchIndex,state.resources.gold], [47,9,0,2400], "allocation costs only points")
	_eq([state.hero.progression.unspent,state.hero.progression.revision], [0,1], "budget consumed and quote revision advanced once")
	_check(not Realm.progression_view(state).canAllocate, "empty budget disables further allocation")
	var loaded: Variant = Realm.deserialize(Realm.serialize(state))
	_check(loaded != null, "invested state round-trips")
	if loaded != null:
		_eq(Items.derive_stats(loaded.hero), result.after, "reload preserves all derived totals without applying bonuses twice")

func _test_rejection() -> void:
	var state: Dictionary = Realm.create_realm(711)
	for draft: Dictionary in [{}, {"might":0}, {"might":-1}, {"might":1.5}, {"might":true}, {"might":NAN}, {"luck":1}, {"command":1}, {"might":4}, {"might":41}, {"finesse":INF}]:
		var before: String = Realm.serialize(state)
		_check(not Realm.allocate_attributes(state, draft).ok, "invalid or unaffordable draft rejected: " + str(draft))
		_eq(Realm.serialize(state), before, "rejected allocation leaves state unchanged")
	var quote: Dictionary = Realm.preview_attribute_allocation(state, {"might":1})
	Realm.allocate_attributes(state, {"vitality":1}, int(quote.revision))
	var before: String = Realm.serialize(state)
	_check(not Realm.allocate_attributes(state, {"might":1}, int(quote.revision)).ok, "stale allocation revision rejected")
	_eq(Realm.serialize(state), before, "stale rejection is atomic")
	var capped: Dictionary = _at_level(30)
	_check(Realm.allocate_attributes(capped, {"might":40}).ok, "forty-point individual cap is reachable within total budget")
	before = Realm.serialize(capped)
	_check(not Realm.allocate_attributes(capped, {"might":1}).ok, "already capped score cannot accept another point")
	_eq(Realm.serialize(capped), before, "cap rejection does not spend remaining points")
	_check(Realm.allocate_attributes(capped, {"vitality":40,"spirit":10}).ok, "ninety earned points can be spent across valid scores")
	_eq(capped.hero.progression.unspent, 0, "level thirty total is ninety, not an unbounded budget")

func _test_equipment() -> void:
	var state: Dictionary = Realm.create_realm(711)
	state.hero.hp = 60
	state.hero.mana = 11
	for item_id: String in ["bellwarden_hood","bellwarden_coat","socketed_blade","rune_cinder","rune_stone"]:
		state.hero.inventory.append(Items.make_instance(item_id, "fixture/" + item_id))
	Items.equip(state.hero, "fixture/bellwarden_hood")
	Items.equip(state.hero, "fixture/bellwarden_coat")
	var quote: Dictionary = Realm.preview_attribute_allocation(state, {"spirit":1})
	_eq(quote.before.sets, {"bellwarden":2}, "full preview exposes active set count")
	_eq(quote.after.maxMana - quote.before.maxMana, 2, "attribute and set bonuses compose without multiplying each other")
	_check(Items.equip(state.hero, "fixture/socketed_blade").ok, "actual equipment changes between preview and apply")
	var before: String = Realm.serialize(state)
	_check(not Realm.allocate_attributes(state, {"spirit":1}, int(quote.revision)).ok, "equipment changes invalidate quoted full totals")
	_eq(Realm.serialize(state), before, "equipment-stale rejection is atomic")
	quote = Realm.preview_attribute_allocation(state, {"spirit":1})
	Items.socket(state.hero, "fixture/socketed_blade", "fixture/rune_cinder")
	Items.socket(state.hero, "fixture/socketed_blade", "fixture/rune_stone")
	_check(not Realm.allocate_attributes(state, {"spirit":1}, int(quote.revision)).ok, "socket recipe changes also invalidate the quote")
	quote = Realm.preview_attribute_allocation(state, {"spirit":1})
	_check(Realm.allocate_attributes(state, {"spirit":1}, int(quote.revision)).ok, "fresh quote commits after crafting")
	_eq(state.hero.wardBonus, 5, "one Spirit and real Hearthguard capacity compose")
	var stats: Dictionary = Items.derive_stats(state.hero)
	var revision: int = int(state.hero.progression.revision)
	Items.equip(state.hero, "fixture/socketed_blade")
	_eq(state.hero.progression.revision, revision, "no-op re-equip does not churn quote revisions")
	_eq(Items.derive_stats(state.hero), stats, "re-equip does not stack stats")
	Items.unequip(state.hero, "main_hand")
	_eq(state.hero.wardBonus, 1, "removing recipe leaves the attribute contribution")
	_eq([state.hero.hp,state.hero.mana], [60,11], "set, socket, and equipment changes never restore current pools")
	_check(Realm.deserialize(Realm.serialize(state)) != null, "attribute/set/recipe combination survives strict save validation")

func _test_reset() -> void:
	for level: int in [1,10,11,30]:
		var state: Dictionary = _at_level(level)
		Realm.allocate_attributes(state, {"vitality":1,"spirit":1})
		state.hero.hp = state.hero.maxHp
		state.hero.mana = state.hero.maxMana
		var quote: Dictionary = Realm.preview_attribute_reset(state)
		var expected_cost: int = 0 if level <= 10 else 50 if level == 11 else 1000
		_eq(quote.goldCost, expected_cost, "reset has explicit bounded cost at level " + str(level))
		var gold: int = int(state.resources.gold)
		var result: Dictionary = Realm.reset_attributes(state, int(quote.revision))
		_check(result.ok, "friendly-town reset succeeds at level " + str(level))
		_eq([state.resources.gold,state.hero.progression.unspent,state.hero.progression.resetCount], [gold-expected_cost,level*3,1], "reset refunds only investments and charges once")
		_eq([state.hero.hp,state.hero.maxHp,state.hero.mana,state.hero.maxMana,state.watchIndex], [124,124,40,40,0], "reset clamps lower pools without healing or spending watches")
		var before: String = Realm.serialize(state)
		_check(not Realm.reset_attributes(state).ok, "empty reset cannot charge again")
		_eq(Realm.serialize(state), before, "empty reset leaves state untouched")
		_check(Realm.deserialize(Realm.serialize(state)) != null, "reset count and budget persist")
	var state: Dictionary = _at_level(11)
	Realm.allocate_attributes(state, {"might":1})
	state.resources.gold = 49
	var before: String = Realm.serialize(state)
	_check(not Realm.reset_attributes(state).ok, "unaffordable paid reset rejected")
	_eq(Realm.serialize(state), before, "failed reset never removes invested points")
	state.resources.gold = 100
	state.hero.locationId = "woodlot"
	_check(not Realm.reset_attributes(state).ok, "reset cannot occur away from a town")
	state.hero.locationId = "raven_market"
	_check(not Realm.reset_attributes(state).ok, "hostile town is not a reset service")
	state.hero.locationId = "dawnwatch"
	state.hero.hp = 0
	state.hero.state = "incapacitated"
	state.status = "recovering"
	_check(not Realm.allocate_attributes(state, {"vitality":1}).ok and not Realm.reset_attributes(state).ok, "incapacitation cannot be bypassed through max-health changes")

func _test_experience() -> void:
	var state: Dictionary = Realm.create_realm(711)
	state.hero.hp = 41
	state.hero.mana = 8
	var quote: Dictionary = Realm.preview_attribute_allocation(state, {"might":1})
	var grant: Dictionary = Realm._grant_experience(state.hero, 750)
	_eq([state.hero.level,state.hero.xp,grant.levelsGained,state.hero.progression.unspent], [5,750,4,15], "one legitimate grant can cross several thresholds without losing points")
	_eq([state.hero.hp,state.hero.mana], [41,8], "level gain itself does not heal or refill")
	_check(not Realm.allocate_attributes(state, {"might":1}, int(quote.revision)).ok, "XP changes invalidate a stale point-budget quote")
	var view: Dictionary = Realm.progression_view(state)
	_eq([view.levelFloorXp,view.nextLevelXp,view.xpIntoLevel,view.xpToNextLevel,view.levelSpanXp], [700,1000,50,250,300], "partial-level UI arithmetic has one source of truth")
	grant = Realm._grant_experience(state.hero, 1000000000)
	_eq([grant.gained,grant.overflow,state.hero.xp,state.hero.level,state.hero.progression.unspent], [22450,999977550,23200,30,90], "large award clamps safely and reports discarded overflow")
	view = Realm.progression_view(state)
	_eq([view.atCap,view.xpToNextLevel,view.levelSpanXp], [true,0,0], "capped UI does not divide by a nonexistent next level")
	var before: String = Realm.serialize(state)
	grant = Realm._grant_experience(state.hero, 120)
	_eq([grant.gained,grant.overflow,grant.levelsGained], [0,120,0], "cap cannot mint extra points or levels")
	_eq(Realm.serialize(state), before, "at-cap award has no state mutation")
	_check(not Realm._grant_experience(state.hero, -1).ok, "negative XP rejected")
	state.hero.progression.revision = Realm.MAX_PROGRESS_REVISION
	_check(not Realm.allocate_attributes(state, {"might":1}).ok, "bounded revision cannot overflow on allocation")

func _action(hero: Dictionary, enemies: Array = []) -> Dictionary:
	var copy: Dictionary = hero.duplicate(true)
	copy.pos = [0,0]
	return Action.create({"id":"progression-component","kind":"dungeon","heroSnapshot":copy,"playerCompanies":[],"enemies":enemies,"arena":{"entry":[0,0],"exit":[0,10]},"seed":711})

func _actor(action: Dictionary) -> Dictionary:
	return Action.get_actor(action, str(action.heroId))

func _first_strike(hero: Dictionary) -> int:
	var action: Dictionary = _action(hero, [{"id":"target","type":"wolf","pos":[0,-1.4],"hp":1000,"maxHp":1000,"armor":0,"behavior":"passive"}])
	if not Action.submit(action, {"kind":"attack","targetId":"target"}).ok:
		return -1
	for tick: int in range(90):
		Action.advance(action)
		if int(Action.get_actor(action,"target").hp) < 1000:
			return 1000 - int(Action.get_actor(action,"target").hp)
	return -1

func _test_combat_effects() -> void:
	var base: Dictionary = Realm.create_realm(711)
	var might: Dictionary = Realm.create_realm(711)
	Realm.allocate_attributes(might, {"might":3})
	_eq([_first_strike(base.hero),_first_strike(might.hero)], [18,21], "Might changes actual committed melee damage")
	var finesse: Dictionary = Realm.create_realm(711)
	Realm.allocate_attributes(finesse, {"finesse":3})
	var slow: Dictionary = _action(base.hero)
	var fast: Dictionary = _action(finesse.hero)
	Action.submit(slow, {"kind":"move","pos":[8,0]})
	Action.submit(fast, {"kind":"move","pos":[8,0]})
	Action.advance(slow,30)
	Action.advance(fast,30)
	_check(absf(float(_actor(fast).pos[0])-float(_actor(slow).pos[0])-0.12) < 0.001, "Finesse changes distance traveled in the same thirty real ticks")
	var spirit: Dictionary = Realm.create_realm(711)
	Realm.allocate_attributes(spirit, {"spirit":3})
	slow = _action(base.hero)
	fast = _action(spirit.hero)
	Action.submit(slow, {"kind":"cast","ability":"ward"})
	Action.submit(fast, {"kind":"cast","ability":"ward"})
	Action.advance(slow,6)
	Action.advance(fast,6)
	_eq([_actor(slow).statuses.ward.pool,_actor(fast).statuses.ward.pool], [45,48], "Spirit creates a larger finite ward at the actual cast release")
	var normal_hit: Dictionary = Action._damage(slow,"test",_actor(slow),60,"fire",Vector2(0,-1),false)
	var spirit_hit: Dictionary = Action._damage(fast,"test",_actor(fast),60,"fire",Vector2(0,-1),false)
	_eq([normal_hit.damage,spirit_hit.damage], [15,12], "extra ward capacity actually prevents damage then depletes")
	_check(not _actor(slow).statuses.has("ward") and not _actor(fast).statuses.has("ward"), "Spirit does not create an infinite shield")
	_eq([_actor(fast).mana,_actor(fast).maxMana], [26,46], "extra Focus capacity is carried to combat without free refill")
	var vitality: Dictionary = Realm.create_realm(711)
	Realm.allocate_attributes(vitality, {"vitality":3})
	_eq([vitality.hero.hp,vitality.hero.maxHp], [120,142], "Vitality increases real capacity, preserving wounds")
	Realm.rest(vitality)
	Realm.rest(vitality)
	_eq(_actor(_action(vitality.hero)).hp, 142, "legal safe rest can fill and carry the larger health pool")

func _test_pending() -> void:
	var state: Dictionary = Realm.create_realm(711)
	Realm.allocate_attributes(state, {"finesse":3})
	var opened: Dictionary = Realm.begin_encounter(state, {"kind":"dungeon","locationId":"bell_crypt"})
	if not _check(opened.ok, "fractional-speed hero enters registered expedition"):
		return
	var before: String = Realm.serialize(state)
	_check(not Realm.allocate_attributes(state, {"might":1}).ok and not Realm.reset_attributes(state).ok, "pending encounter locks both transactions")
	_eq(Realm.serialize(state), before, "locked actions cannot mutate the trusted snapshot")
	_check(not Realm.progression_view(state).canAllocate and not str(Realm.progression_view(state).lockReason).is_empty(), "lock is explicit to the sheet")
	var loaded: Variant = Realm.deserialize(before)
	if not _check(loaded != null, "fractional derived speed survives strict pending JSON validation"):
		return
	_eq(loaded.pendingEncounter, state.pendingEncounter, "pending contract survives round-trip exactly")
	var action: Dictionary = Action.create(state.pendingEncounter)
	Action.submit(action, {"kind":"move","pos":[1,8]})
	Action.advance(action,4)
	if OS.get_cmdline_user_args().has("--write-v2-fixture") and int(state.version) == 2:
		var file: FileAccess = FileAccess.open("res://tests/fixtures/progression/v2-invested-combat-save.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"schema":"progression-migration-proof","realm":Realm.serialize(state),"action":Action.serialize(action)}))
	var restored: Dictionary = Action.deserialize(Action.serialize(action), loaded.pendingEncounter)
	if not _check(not restored.is_empty(), "live action state restores against progressed registry"):
		return
	Action.advance(action,15)
	Action.advance(restored,15)
	_eq(Action.snapshot(restored), Action.snapshot(action), "restored fractional-speed movement follows identical continuation")

func _test_migration() -> void:
	for file: String in ["v1-town-save.json","v1-earned-equipment-save.json","v1-combat-save.json"]:
		var shell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/progression/" + file))
		var original: Dictionary = JSON.parse_string(str(shell.realm))
		var loaded: Variant = Realm.deserialize(str(shell.realm))
		if not _check(loaded != null, "authentic native save migrates: " + file):
			continue
		_eq(loaded.version, Realm.VERSION, "migration advances schema once")
		_eq(loaded.hero.level, 2 if int(original.hero.xp) == 120 else 1, "existing earned XP determines level")
		_eq(loaded.hero.progression.unspent, int(loaded.hero.level)*3, "previously earned levels receive their unspent choices")
		for field: String in ["hp","mana","maxHp","maxMana","inventory","equipment","baseStats"]:
			_eq(loaded.hero[field], original.hero[field], "migration preserves " + field + " in " + file)
		_eq(loaded.pendingEncounter, original.pendingEncounter, "legacy pending dictionary is never silently rewritten")
		_eq(loaded.companies, original.companies, "migration keeps companies outside the solo expedition")
		var roundtrip: Variant = Realm.deserialize(Realm.serialize(loaded))
		_check(roundtrip != null, "migrated save can be saved and loaded again")
		if loaded.pendingEncounter != null:
			var action: Dictionary = Action.deserialize(str(shell.action), loaded.pendingEncounter)
			if _check(not action.is_empty(), "original in-progress action restores unchanged"):
				var copy: Dictionary = Action.deserialize(str(shell.action), original.pendingEncounter)
				Action.advance(action,12)
				Action.advance(copy,12)
				_eq(Action.snapshot(action), Action.snapshot(copy), "migration preserves original action continuation")
			_check(not Realm.allocate_attributes(loaded, {"might":1}).ok, "new migration choices cannot rewrite an old pending encounter")

func _test_malformed() -> void:
	var valid: Dictionary = Realm.create_realm(711)
	var corruptions: Array = [
		["extra point",func(s:Dictionary)->void:s.hero.progression.unspent=4],
		["negative investment",func(s:Dictionary)->void:s.hero.progression.allocations.might=-1],
		["fractional investment",func(s:Dictionary)->void:s.hero.progression.allocations.might=0.5],
		["boolean investment",func(s:Dictionary)->void:s.hero.progression.allocations.might=true],
		["unknown attribute",func(s:Dictionary)->void:s.hero.progression.allocations.luck=0],
		["missing attribute",func(s:Dictionary)->void:s.hero.progression.allocations.erase("spirit")],
		["unearned level",func(s:Dictionary)->void:s.hero.level=2],
		["XP beyond cap",func(s:Dictionary)->void:s.hero.xp=23201],
		["negative revision",func(s:Dictionary)->void:s.hero.progression.revision=-1],
		["overflow revision",func(s:Dictionary)->void:s.hero.progression.revision=1000000001],
		["impossible reset count",func(s:Dictionary)->void:s.hero.progression.resetCount=1],
		["forged derived attack",func(s:Dictionary)->void:s.hero.attack=999],
		["forged derived speed",func(s:Dictionary)->void:s.hero.speed=9.9],
		["mixed legacy schema",func(s:Dictionary)->void:s.version=1],
		["future schema",func(s:Dictionary)->void:s.version=99]
	]
	for pair: Array in corruptions:
		var bad: Dictionary = valid.duplicate(true)
		pair[1].call(bad)
		_check(Realm.deserialize(Realm.serialize(bad)) == null, "save rejects " + str(pair[0]))
	_check(Realm.deserialize(Realm.serialize(valid)) != null, "rejections do not poison subsequent valid saves")

func _position(actor: Dictionary) -> Vector2:
	return Vector2(float(actor.pos[0]),float(actor.pos[1]))

func _walk(action: Dictionary, destination: Array) -> bool:
	# A killing strike still owns its recovery frames after clear is declared.
	for tick: int in range(90):
		if _actor(action).action.is_empty() and int(action.tick) >= int(_actor(action).restartUntil):
			break
		Action.advance(action)
	if not Action.submit(action, {"kind":"move","pos":destination}).ok:
		return false
	for tick: int in range(600):
		Action.advance(action)
		if str(action.phase) == "finished":
			return false
		if _position(_actor(action)).distance_to(Vector2(float(destination[0]),float(destination[1]))) < 0.15:
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
				if str(enemy.side) == "enemy" and int(enemy.hp) > 0 and _position(hero).distance_to(_position(enemy)) < distance:
					target = enemy
					distance = _position(hero).distance_to(_position(enemy))
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

func _test_earned() -> void:
	var state: Dictionary = Realm.create_realm(711)
	Realm.allocate_attributes(state, {"might":1,"vitality":1,"spirit":1})
	var companies: Dictionary = state.companies.duplicate(true)
	Realm.begin_encounter(state, {"kind":"dungeon","locationId":"bell_crypt"})
	var action: Dictionary = Action.create(state.pendingEncounter)
	if not _check(_clear(action), "invested starter earns all three deaths through legal commands"):
		return
	if not _check(_walk(action,[0,9]), "survivor returns to the legal exit"):
		return
	_check(Action.submit(action, {"kind":"exit"}).ok, "extraction commits normally")
	Action.advance(action,45)
	var outcome: Dictionary = Action.outcome(action)
	var id: String = str(state.pendingEncounter.id)
	var result: Dictionary = Realm.resolve_encounter(state,id,outcome)
	if not _check(result.ok, "registered earned result applies"):
		return
	_eq([result.xpGained,result.levelsGained,result.level,state.hero.progression.unspent], [120,1,2,3], "actual first clear grants level two and exactly three new points")
	_eq([state.hero.hp,state.hero.mana], [outcome.heroState.hp,outcome.heroState.mana], "level-up does not erase action wounds or spending")
	_eq(state.companies, companies, "solo progression cannot consume or replace the companies")
	var before: String = Realm.serialize(state)
	_check(not Realm.resolve_encounter(state,id,outcome).ok, "duplicate asynchronous result cannot award XP twice")
	_eq(Realm.serialize(state), before, "duplicate result rejection is atomic")
	_check(Realm.deserialize(before) != null, "earned level and unused corpse rewards persist together")
	earned = {"level":int(state.hero.level),"xp":int(state.hero.xp),"unspent":int(state.hero.progression.unspent),"hp":int(state.hero.hp),"mana":int(state.hero.mana),"ticks":int(outcome.elapsedTicks)}
	if not _check(Realm.begin_encounter(state, {"kind":"dungeon","locationId":"bell_crypt"}).ok, "unclaimed physical rewards permit a legal corpse revisit"):
		return
	action = Action.create(state.pendingEncounter)
	_eq(action.phase, "cleared", "persisted slain enemies do not respawn for XP")
	_check(_walk(action,[0,9]), "corpse revisit reaches the exit normally")
	_check(Action.submit(action, {"kind":"exit"}).ok, "revisit exits legally")
	Action.advance(action,45)
	result = Realm.resolve_encounter(state,str(state.pendingEncounter.id),Action.outcome(action))
	_check(result.ok, "legal repeated extraction applies")
	_eq([result.xpGained,result.levelsGained,state.hero.xp,state.hero.progression.unspent], [0,0,120,3], "previously cleared story location cannot be farmed for XP or points")
