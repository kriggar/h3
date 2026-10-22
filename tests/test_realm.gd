extends SceneTree
## Tests the isolated realm's actual rules and real ActionRules outcome handoff.
## Component fixtures are not described as complete campaign playthroughs.

const Realm = preload("res://game/redesign/realm_rules.gd")
const Action = preload("res://game/redesign/action_rules.gd")
const Items = preload("res://game/redesign/item_rules.gd")

var checks: int = 0
var failures: int = 0
var groups: int = 0
var earned_run: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run_all")

func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("REALM FAIL: " + message)
	return condition

func _eq(actual: Variant, expected: Variant, message: String) -> bool:
	var same: bool = Realm._same(actual, expected)
	return _check(same, message + (" [actual=%s expected=%s]" % [str(actual), str(expected)] if not same else ""))

func _run(label: String, test: Callable) -> void:
	groups += 1
	var before: int = failures
	test.call()
	print("REALM GROUP ", groups, " ", label, ": ", "PASS" if failures == before else "FAIL")

func _run_all() -> void:
	_run("One protagonist, registered companies, real starter equipment", _test_initial)
	_run("Four watches and exactly one dawn settlement", _test_clock)
	_run("Atomic visible construction and persisted daily limit", _test_building)
	_run("Prerequisites, market and exclusive riverside plot", _test_riverside)
	_run("Inclusive oath deadlines, fulfilment and once-only rewards", _test_oaths)
	_run("Advance-to-event and bounded forecast", _test_forecast)
	_run("Paid rival recruitment and legal frontier claims", _test_rivals)
	_run("Safe rest and building effects", _test_rest)
	_run("Solo encounter locks and pending-save continuation", _test_pending)
	_run("Real entrance withdrawal preserves companies and enemies", _test_retreat)
	_run("Read-only registered reward previews and persistent corpse rolls", _test_reward_preview)
	_run("Earned crypt clear, physical loot, extraction and atomic application", _test_earned_crypt)
	_run("Strict malformed-state rejection", _test_malformed)
	_run("Finite paid crafting market, real socket route and saved stock", _test_supply_market)
	print("REALM_SUMMARY ", JSON.stringify({"groups": groups, "checks": checks, "failures": failures, "earnedRun": earned_run}))
	quit(0 if failures == 0 else 1)

func _test_supply_market() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var before: String = Realm.serialize(state)
	_check(not Realm.purchase_supply_item(state,"dawnwatch","rune_cinder").ok,"crafting merchant requires completed market")
	_eq(Realm.serialize(state),before,"unavailable merchant has no side effects")
	Realm.construct_building(state,"dawnwatch","granary")
	Realm.advance_to_event(state,4)
	Realm.construct_building(state,"dawnwatch","market")
	var gold: int = int(state.resources.gold)
	var purchased: Array = []
	for item_id: String in ["socketed_blade","rune_cinder","rune_stone"]:
		var report: Dictionary = Realm.purchase_supply_item(state,"dawnwatch",item_id)
		_check(bool(report.ok),"legal market purchase "+item_id)
		purchased.append(report.instance.instanceId)
	_eq(state.resources.gold,gold-220,"base and two runes cost actual catalog prices")
	_check(Items.socket(state.hero,str(purchased[0]),str(purchased[1])).ok,"purchased Cinder can be consumed into bought base")
	_check(Items.socket(state.hero,str(purchased[0]),str(purchased[2])).ok,"purchased Stone completes actual ordered recipe")
	_eq(Items.find_instance(state.hero,str(purchased[0])).recipeId,"hearthguard","merchant route creates Hearthguard without injected loot")
	_check(Items.equip(state.hero,str(purchased[0])).ok,"crafted weapon equips legally")
	var loaded: Variant = Realm.deserialize(Realm.serialize(state))
	_check(loaded!=null,"crafted equipment and shop reload together")
	if loaded!=null:
		_eq(loaded.supplyMarket,state.supplyMarket,"purchase serial and finite stock round-trip")
		_eq(Items.find_instance(loaded.hero,str(purchased[0])).recipeId,"hearthguard","saved recipe remains earned")
	Realm.purchase_supply_item(state,"dawnwatch","socketed_blade")
	before=Realm.serialize(state)
	_check(not Realm.purchase_supply_item(state,"dawnwatch","socketed_blade").ok,"finite base stock depletes")
	_check(not Realm.purchase_supply_item(state,"dawnwatch","oathkeeper_blade").ok,"merchant cannot manufacture unique rewards")
	_eq(Realm.serialize(state),before,"depleted and forbidden purchases are atomic")
	var corrupt: Dictionary = state.duplicate(true)
	corrupt.supplyMarket.stock.socketed_blade=2
	_check(Realm.deserialize(Realm.serialize(corrupt))==null,"restored stock without matching serial rejected")
	corrupt=state.duplicate(true)
	corrupt.supplyMarket.serial=-1
	_check(Realm.deserialize(Realm.serialize(corrupt))==null,"negative purchase serial rejected")
	Realm.begin_encounter(state,{"kind":"dungeon","locationId":"bell_crypt"})
	before=Realm.serialize(state)
	_check(not Realm.purchase_supply_item(state,"dawnwatch","gem_amber").ok,"merchant unavailable during live expedition")
	_eq(Realm.serialize(state),before,"locked merchant rejection is atomic")

func _test_initial() -> void:
	var state: Dictionary = Realm.create_realm(711)
	_eq(state, Realm.create_realm(711), "seeded initial state is deterministic")
	_eq(state.hero.name, "Mara Veyne", "current display canon is applied")
	_eq(state.hero.id, "ileana", "stable sole protagonist ID is retained internally")
	_check(not state.has("heroes"), "no second playable hero collection exists")
	_check(state.expeditionCompanyIds.size() <= 6, "expedition has at most six company cards")
	_eq(state.hero.inventory.size(), 3, "starter equipment contains three real catalog instances")
	for instance: Dictionary in state.hero.inventory:
		_check(Items.validate_instance(instance), "starter item validates: " + str(instance.itemId))
	_eq(state.hero.equipment.main_hand, "start/blade", "starter blade is equipped by persistent ID")
	_eq(state.hero.baseStats.attack, 18, "base attack is retained separately from equipped stats")
	_eq(state.resources, {"gold": 2400, "wood": 16, "ore": 14, "food": 24}, "initial economy matches the briefing")
	var restored: Variant = Realm.deserialize(Realm.serialize(state))
	_check(restored != null, "new initial realm saves and reloads")
	if restored != null:
		_eq(restored.hero.inventory, state.hero.inventory, "full starter item schema survives JSON")
		_eq(restored, state, "initial JSON roundtrip preserves complete state")

func _test_clock() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var gold: int = int(state.resources.gold)
	for index: int in range(1, 4):
		_check(Realm.advance_watch(state).ok, "watch transition is accepted")
		_eq(state.watchIndex, index, "single authoritative watch counter advances once")
		_eq(state.resources.gold, gold, "afternoon/dusk/night do not repeat dawn income")
		_eq(Realm.calendar(state).day, 1, "first three transitions remain on day one")
	_check(Realm.advance_watch(state).ok, "next dawn accepted")
	_eq(Realm.calendar(state).watch, "dawn", "fourth transition is dawn")
	_eq(Realm.calendar(state).day, 2, "fourth transition begins day two")
	_eq(state.resources.gold, gold + 250, "dawn income pays once")
	_eq(state.lastDawnDay, 2, "dawn commit marker persists")
	var reloaded: Variant = Realm.deserialize(Realm.serialize(state))
	_check(reloaded != null, "dawn state reloads")
	if reloaded != null:
		Realm.advance_watch(reloaded)
		_eq(reloaded.resources.gold, state.resources.gold, "loading cannot repeat dawn settlement")

func _test_building() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var before: String = Realm.serialize(state)
	var preview: Dictionary = Realm.preview_construction(state, "dawnwatch", "granary")
	_check(preview.ok, "granary is affordable on day one")
	_eq(Realm.serialize(state), before, "preview has no mutation")
	_eq(preview.plotId, "grain_yard", "stable plot exposed to native renderer")
	_eq(preview.modelKey, "granary", "stable model key exposed")
	var bought: Dictionary = Realm.construct_building(state, "dawnwatch", "granary")
	_check(bought.ok, "granary purchase commits")
	_eq(state.watchIndex, 0, "purchase spends no realm time")
	_eq(state.resources.gold, 1800, "exact gold cost deducted")
	_eq(state.resources.wood, 11, "exact timber cost deducted")
	_eq(state.settlements.dawnwatch.buildings.granary.stage, "complete", "actual completed state immediately exists for visible model")
	_eq(state.settlements.dawnwatch.lastConstructionDay, 1, "one-per-day marker recorded")
	before = Realm.serialize(state)
	_check(not Realm.construct_building(state, "dawnwatch", "granary").ok, "duplicate building rejected")
	_check(not Realm.construct_building(state, "dawnwatch", "barracks").ok, "second construction same day rejected")
	_eq(Realm.serialize(state), before, "rejected purchases do not deduct or alter state")
	var reloaded: Variant = Realm.deserialize(before)
	_check(reloaded != null, "built town persists")
	if reloaded != null:
		_check(not Realm.construct_building(reloaded, "dawnwatch", "barracks").ok, "reload cannot bypass daily construction")
	Realm.advance_to_event(state, 4)
	_check(Realm.construct_building(state, "dawnwatch", "barracks").ok, "next dawn restores allowance")
	_eq(state.resources.food, 28, "completed granary adds its real food production at dawn")
	var stock: int = int(state.settlements.dawnwatch.recruitStock)
	Realm.advance_to_event(state, 4)
	_eq(state.settlements.dawnwatch.recruitStock, stock + 2, "barracks changes real recruitment pool")

func _test_riverside() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var before: String = Realm.serialize(state)
	_check(not Realm.construct_building(state, "dawnwatch", "smithy").ok, "smithy requires training yard")
	_check(not Realm.construct_building(state, "unknown", "granary").ok, "unknown settlement rejected")
	_check(not Realm.construct_building(state, "dawnwatch", "invented").ok, "unknown building rejected")
	_eq(Realm.serialize(state), before, "all prerequisite rejections atomic")
	Realm.construct_building(state, "dawnwatch", "granary")
	Realm.advance_to_event(state, 4)
	_check(Realm.construct_building(state, "dawnwatch", "market").ok, "market prerequisite is real completed granary")
	Realm.advance_to_event(state, 4)
	_check(Realm.construct_building(state, "dawnwatch", "wharf").ok, "wharf builds on exclusive river plot")
	Realm.advance_to_event(state, 4)
	_check(Realm.trade(state, "dawnwatch", "wood", 5).ok, "real market buys needed building supplies")
	_check(Realm.construct_building(state, "dawnwatch", "palisade").ok, "palisade built from earned income and purchased supplies")
	Realm.advance_to_event(state, 4)
	before = Realm.serialize(state)
	var denied: Dictionary = Realm.construct_building(state, "dawnwatch", "water_gate")
	_check(not denied.ok and str(denied.message).contains("plot"), "wharf excludes water gate even after its prerequisites")
	_eq(Realm.serialize(state), before, "exclusive choice rejection atomic")
	_eq(Realm.settlement_effects(state, "dawnwatch").approachDelayWatches, 1, "palisade's approach effect is declared once")
	_check(Realm.deserialize(before) != null, "earned multi-building town reloads")

func _test_oaths() -> void:
	var state: Dictionary = Realm.create_realm(711)
	_check(Realm.accept_obligation(state, "granary_oath", "build").ok, "registered oath accepted")
	_eq(state.obligations[0].dueWatch, 7, "eight-watch oath includes watch seven")
	Realm.construct_building(state, "dawnwatch", "granary")
	_eq(state.obligations[0].status, "fulfilled", "actual required construction fulfils oath")
	_eq(state.resources.food, 28, "oath pays exactly its registered reward")
	_eq(state.regions.woodland.stability, 84, "fulfilled promise affects its own region")
	var before: String = Realm.serialize(state)
	_check(not Realm.accept_obligation(state, "granary_oath", "build").ok, "completed oath cannot be replayed for reward")
	_eq(Realm.serialize(state), before, "oath replay is atomic")
	var overdue: Dictionary = Realm.create_realm(712)
	Realm.accept_obligation(overdue, "granary_oath", "build")
	for index: int in range(7):
		Realm.advance_watch(overdue)
	_eq(overdue.obligations[0].status, "active", "oath remains achievable during its due watch")
	Realm.advance_watch(overdue)
	_eq(overdue.obligations[0].status, "broken", "oath fails only when due watch closes")
	_eq(overdue.obligations[0].resolvedWatch, 7, "breach records closing watch, not next dawn")
	_eq(overdue.regions.woodland.stability, 74, "one stated breach penalty applied")
	Realm.advance_watch(overdue)
	_eq(overdue.regions.woodland.stability, 74, "breach does not repeat every watch")
	_check(Realm.deserialize(Realm.serialize(overdue)) != null, "breached promise reloads with consequence")

func _test_forecast() -> void:
	var state: Dictionary = Realm.create_realm(711)
	Realm.accept_obligation(state, "granary_oath", "build")
	Realm.accept_obligation(state, "bell_oath", "recover")
	_check(Realm.forecast(state, 100).size() <= 3, "forecast respects three-entry attention budget")
	var report: Dictionary = Realm.advance_to_event(state, 20)
	_eq(report.advancedWatches, 4, "harmless watches advance together")
	_eq(report.reason, "dawn", "important dawn boundary surfaced")
	Realm.advance_to_event(state, 20)
	_eq(state.watchIndex, 7, "advance-to-event stops before an unfulfilled deadline closes")
	_eq(state.obligations[0].status, "active", "stop preserves an actionable oath")
	var before: String = Realm.serialize(state)
	_check(not Realm.advance_to_event(state, 0).ok, "invalid fast-forward rejected")
	_eq(Realm.serialize(state), before, "invalid fast-forward atomic")

func _test_rivals() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var twin: Dictionary = Realm.create_realm(711)
	for index: int in range(4):
		Realm.advance_watch(state)
		Realm.advance_watch(twin)
	_eq(state.rivals.fara_zori.resources.gold, 410, "rival pays 190 from its actual 480+120 treasury")
	_eq(state.rivals.fara_zori.stock, 2, "rival recruitment consumes finite stock")
	_eq(state.companies["company:court_watch"].count, 4, "paid recruit joins company only at home")
	_eq(state.rivals.fara_zori.spentRecruitment, 760, "recruitment ledger includes actual expenditure")
	_eq(Realm.get_visible_warbands(state), [], "distant rival forces do not leak through fog")
	for index: int in range(20):
		Realm.advance_watch(state)
		Realm.advance_watch(twin)
	_eq(state, twin, "rival decisions and economy reproduce from seed/actions")
	_check(str(state.locations.ford_mine.owner) != "neutral", "real force reaches and claims a frontier mine")
	_check(str(state.locations.woodlot.owner) != "neutral", "second rival can claim another frontier site")
	_check(int(state.rivals.fara_zori.resources.ore) > 0, "claimed mine pays its owner on a later dawn")
	_check(state.companies["company:court_watch"].count <= 6, "field force cannot recruit infinitely away from base")
	_check(Realm.deserialize(Realm.serialize(state)) != null, "moved rival forces/economy reload")
	for sighting: Dictionary in Realm.get_visible_warbands(state):
		_check(not sighting.has("resources") and not sighting.has("stock"), "visible card omits private enemy economy")

func _test_rest() -> void:
	var state: Dictionary = Realm.create_realm(711)
	# A deliberately injured component fixture checks rest math, not campaign progress.
	state.hero.hp = 30
	state.hero.mana = 0
	_check(Realm.rest(state).ok, "safe rest is an actual one-watch action")
	_eq(state.watchIndex, 1, "rest advances same authoritative clock")
	_eq(state.hero.hp, 60, "ordinary town rest heals its declared amount")
	_eq(state.hero.mana, 12, "ordinary town rest restores declared Focus")
	Realm.construct_building(state, "dawnwatch", "granary")
	Realm.advance_to_event(state, 4)
	Realm.construct_building(state, "dawnwatch", "shrine")
	state.hero.hp = 20
	state.hero.mana = 0
	Realm.rest(state)
	_eq(state.hero.hp, 70, "completed oath hall changes actual rest healing")
	_eq(state.hero.mana, 20, "completed oath hall changes actual Focus recovery")

func _test_pending() -> void:
	var state: Dictionary = Realm.create_realm(711)
	var companies: Dictionary = state.companies.duplicate(true)
	var opened: Dictionary = Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"})
	_check(opened.ok, "registered solo expedition starts")
	_eq(state.watchIndex, 2, "exact quoted two-watch cost committed")
	_eq(state.pendingEncounter.playerCompanies, [], "no company enters solo dungeon")
	_eq(state.companies, companies, "stationed companies remain intact at entrance")
	_eq(state.pendingEncounter.heroSnapshot.id, "ileana", "one protagonist enters")
	_eq(state.pendingEncounter.heroSnapshot.name, "Mara Veyne", "display name reaches action snapshot")
	_eq(state.pendingEncounter.arena, Realm.CRYPT_ARENA, "native scene and action share the registered wall and column geometry")
	var before: String = Realm.serialize(state)
	_check(not Realm.advance_watch(state).ok, "cannot advance realm time during action encounter")
	_check(not Realm.construct_building(state, "dawnwatch", "granary").ok, "pending transaction locks construction")
	_check(not Realm.accept_obligation(state, "bell_oath", "recover").ok, "pending transaction locks oath mutation")
	_check(not Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"}).ok, "duplicate encounter cannot replace transaction")
	_eq(Realm.serialize(state), before, "all locked actions leave state identical")
	var restored: Variant = Realm.deserialize(before)
	_check(restored != null, "pending encounter saves and reloads")
	if restored != null:
		_eq(restored.pendingEncounter, state.pendingEncounter, "resume uses same snapshot/seed/loot IDs")
		var action: Dictionary = Action.create(restored.pendingEncounter)
		_eq(action.phase, "running", "actual ActionRules accepts persisted realm payload")
		_eq(action.actors.size(), 4, "solo action contains one hero and three registered enemies")
		_check(not Action.submit(action, {"kind": "move", "pos": [-5, -2.6]}).ok, "rendered dividing wall is impassable to actual movement")
		_check(not Action.submit(action, {"kind": "move", "pos": [-5.3, 2.7]}).ok, "rendered column is impassable to actual movement")
		_check(Action.submit(action, {"kind": "move", "pos": [0, -4]}).ok, "center doorway remains a legal route into the inner chamber")

func _test_retreat() -> void:
	var state: Dictionary = Realm.create_realm(919)
	Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"})
	var preview_before: Dictionary = Realm.preview_reward(state, "crypt_choice", "mist_amulet")
	var combat_seed: int = int(state.pendingEncounter.seed)
	var companies: Dictionary = state.companies.duplicate(true)
	var action: Dictionary = Action.create(state.pendingEncounter)
	_check(Action.submit(action, {"kind": "exit"}).ok, "real exit action begins at entrance")
	Action.advance(action, 45)
	var result: Dictionary = Action.outcome(action)
	if not _check(not result.is_empty(), "actual exit completes without injected result"):
		return
	_eq(result.resolution, "retreat", "uncleared dungeon exit is retreat")
	var id: String = str(state.pendingEncounter.id)
	_check(Realm.resolve_encounter(state, id, result).ok, "realm accepts actual action withdrawal")
	_eq(state.companies, companies, "empty solo survivors do not erase any company")
	_eq(state.locations.bell_crypt.enemies[0].hp, result.enemySurvivors[0].hp, "actual remaining enemy health persists")
	_eq(state.hero.hp, result.heroState.hp, "actual protagonist damage persists")
	_eq(state.hero.locationId, "dawnwatch", "withdrawal returns to recorded origin")
	_eq(state.watchIndex, 2, "action duration does not spend another watch")
	var before: String = Realm.serialize(state)
	_check(not Realm.resolve_encounter(state, id, result).ok, "duplicate asynchronous callback rejected")
	_eq(Realm.serialize(state), before, "duplicate callback cannot pay or mutate")
	_check(Realm.deserialize(before) != null, "withdrawal state reloads")
	_check(Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"}).ok, "legal revisit after actual withdrawal begins a new expedition")
	var preview_after: Dictionary = Realm.preview_reward(state, "crypt_choice", "mist_amulet")
	_check(int(state.pendingEncounter.seed) != combat_seed, "revisit still receives its separate combat seed")
	_eq(preview_after.instance.rollSeed, preview_before.instance.rollSeed, "reward roll seed is independent of encounter serial")
	_eq(preview_after.instance.affixes, preview_before.instance.affixes, "retreat and re-entry cannot reroll a previewed item")
	_check(str(preview_after.instance.instanceId) != str(preview_before.instance.instanceId), "new attempt retains its unique registered claim identity")

func _test_reward_preview() -> void:
	var state: Dictionary = Realm.create_realm(711)
	_check(not Realm.preview_reward({}, "crypt_weapon").ok, "empty state cannot manufacture a reward preview")
	_check(not Realm.preview_reward(state, "crypt_weapon").ok, "town without a pending expedition has no reward preview")
	Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"})
	var before: String = Realm.serialize(state)
	var first: Dictionary = Realm.preview_reward(state, "crypt_choice", "sentinel_ring")
	_check(first.ok and Items.validate_instance(first.instance), "choice preview is a real valid rolled item instance")
	_check(Realm.preview_reward(state, "crypt_weapon").ok, "fixed reward defaults to its registered item")
	_eq(Realm.preview_reward(state, "crypt_gold").gold, 240, "currency preview uses the exact registered amount")
	_check(not Realm.preview_reward(state, "crypt_choice").ok, "choice reward requires an explicit option")
	_check(not Realm.preview_reward(state, "crypt_choice", "oathkeeper_blade").ok, "foreign choice cannot be previewed as a reward")
	_check(not Realm.preview_reward(state, "crypt_weapon", "sentinel_ring").ok, "fixed reward cannot be substituted")
	_check(not Realm.preview_reward(state, "crypt_gold", "sentinel_ring").ok, "gold reward rejects an item substitution")
	_check(not Realm.preview_reward(state, "invented_reward").ok, "unknown reward is not exposed")
	_eq(Realm.serialize(state), before, "all valid and rejected previews are read-only")
	var restored: Variant = Realm.deserialize(before)
	if _check(restored != null, "registered preview state survives JSON"):
		_eq(Realm.preview_reward(restored, "crypt_choice", "sentinel_ring"), first, "saving and loading preserves the exact preview instance")
	var action: Dictionary = Action.create(state.pendingEncounter)
	if not _check(_earned_clear(action), "actual commands clear the guardian before leaving its drops unclaimed"):
		return
	_check(_walk(action, [0, 9]), "leave unclaimed corpse drops through actual return movement")
	_check(Action.submit(action, {"kind": "exit"}).ok, "depart from the exit without collecting the choice")
	Action.advance(action, 45)
	if not _check(Realm.resolve_encounter(state, str(state.pendingEncounter.id), Action.outcome(action)).ok, "earned clear applies with unclaimed corpse loot"):
		return
	_eq(state.locations.bell_crypt.claimedRewardIds.size(), 0, "uncollected drops are not silently granted")
	if not _check(Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"}).ok, "unclaimed corpse rewards allow a legal later return"):
		return
	var second: Dictionary = Realm.preview_reward(state, "crypt_choice", "sentinel_ring")
	_eq(second.instance.affixes, first.instance.affixes, "dead guardian's unclaimed choice keeps its original rolls")
	_eq(second.instance.rollSeed, first.instance.rollSeed, "corpse reward identity, not visit count, determines its seed")
	action = Action.create(state.pendingEncounter)
	_eq(action.phase, "cleared", "persisted guardian stays dead on return")
	_eq(action.loot.size(), 4, "all still-unclaimed registered corpse drops appear on return")
	var choice: Dictionary = {}
	for loot: Dictionary in action.loot:
		if str(loot.kind) == "choice":
			choice = loot
	if not _check(not choice.is_empty() and _walk(action, choice.pos), "physically reach the returned corpse choice"):
		return
	_check(Action.submit(action, {"kind": "interact", "targetId": str(choice.id), "choiceId": "sentinel_ring"}).ok, "returned choice is actually collected as the ring")
	Action.advance(action, 10)
	_check(_walk(action, [0, 9]), "return with the actually collected ring")
	Action.submit(action, {"kind": "exit"})
	Action.advance(action, 45)
	if not _check(Realm.resolve_encounter(state, str(state.pendingEncounter.id), Action.outcome(action)).ok, "revisited corpse item is applied through the actual action result"):
		return
	_eq(Items.find_instance(state.hero, str(second.instance.instanceId)), second.instance, "earned ring equals the exact inspected instance and its affixes")
	_check(Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"}).ok, "other unclaimed corpse rewards remain available")
	_check(not Realm.preview_reward(state, "crypt_choice", "sentinel_ring").ok, "already claimed location choice cannot reappear under a new encounter ID")

func _hero(action: Dictionary) -> Dictionary:
	return Action.get_actor(action, str(action.heroId))

func _position(actor: Dictionary) -> Vector2:
	return Vector2(float(actor.pos[0]), float(actor.pos[1]))

func _idle(action: Dictionary) -> void:
	for tick: int in range(300):
		if _hero(action).action.is_empty() or str(action.phase) == "finished":
			return
		Action.advance(action)

func _walk(action: Dictionary, destination: Array) -> bool:
	_idle(action)
	if not Action.submit(action, {"kind": "move", "pos": destination}).ok:
		return false
	for tick: int in range(600):
		Action.advance(action)
		if str(action.phase) == "finished":
			return false
		if _position(_hero(action)).distance_to(Vector2(float(destination[0]), float(destination[1]))) < 0.15:
			return true
	return false

func _earned_clear(action: Dictionary) -> bool:
	for tick: int in range(5400):
		if str(action.phase) in ["cleared", "finished"]:
			break
		var hero: Dictionary = _hero(action)
		if hero.action.is_empty() and int(action.tick) >= int(hero.restartUntil):
			var target: Dictionary = {}
			var distance: float = INF
			for enemy: Dictionary in action.actors:
				if str(enemy.side) == "enemy" and int(enemy.hp) > 0 and _position(hero).distance_to(_position(enemy)) < distance:
					target = enemy
					distance = _position(hero).distance_to(_position(enemy))
			if target.is_empty():
				break
			var command: Dictionary = {"kind": "attack", "targetId": str(target.id)}
			if int(hero.mana) >= 14 and not hero.statuses.has("ward") and int(hero.cooldowns.get("ward", 0)) <= int(action.tick):
				command = {"kind": "cast", "ability": "ward"}
			elif distance < 2.4 and int(hero.mana) >= 12 and int(hero.cooldowns.get("cleave", 0)) <= int(action.tick):
				command = {"kind": "cast", "ability": "cleave", "pos": target.pos}
			Action.submit(action, command)
		Action.advance(action)
	return str(action.phase) == "cleared"

func _test_earned_crypt() -> void:
	var state: Dictionary = Realm.create_realm(711)
	Realm.accept_obligation(state, "bell_oath", "recover")
	Realm.construct_building(state, "dawnwatch", "granary")
	var opened: Dictionary = Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"})
	if not _check(opened.ok, "native-loop realm departure accepted"):
		return
	var previews: Array = [Realm.preview_reward(state, "crypt_weapon"), Realm.preview_reward(state, "crypt_set"), Realm.preview_reward(state, "crypt_choice", "mist_amulet")]
	var companies: Dictionary = state.companies.duplicate(true)
	var action: Dictionary = Action.create(opened.pendingEncounter)
	if not _check(_earned_clear(action), "actual starter commands earn all three enemy deaths"):
		return
	_check(int(_hero(action).hp) > 0, "protagonist survives earned clear")
	for loot: Dictionary in action.loot:
		_check(_walk(action, loot.pos), "physically reach registered loot " + str(loot.id))
		var command: Dictionary = {"kind": "interact", "targetId": str(loot.id)}
		if str(loot.kind) == "choice":
			command.choiceId = "mist_amulet"
		_check(Action.submit(action, command).ok, "collect real registered loot " + str(loot.id))
		Action.advance(action, 10)
	_eq(action.lootClaims.size(), 4, "weapon, set piece, one choice and exact gold physically collected")
	_check(_walk(action, [0, 9]), "return to entrance through actual movement")
	_check(Action.submit(action, {"kind": "exit"}).ok, "real extraction action starts")
	Action.advance(action, 45)
	var outcome: Dictionary = Action.outcome(action)
	if not _check(not outcome.is_empty() and str(outcome.resolution) == "victory", "earned action victory requires extraction"):
		return
	var encounter_id: String = str(state.pendingEncounter.id)
	var before: String = Realm.serialize(state)
	var forged: Dictionary = outcome.duplicate(true)
	for claim: Dictionary in forged.lootClaims:
		if str(claim.kind) == "gold":
			claim.amount = int(claim.amount) + 1
	_check(not Realm.resolve_encounter(state, encounter_id, forged).ok, "forged extra currency is rejected")
	_eq(Realm.serialize(state), before, "forged claim commits no partial loot or casualties")
	forged = outcome.duplicate(true)
	forged.lootClaims.append(forged.lootClaims[0].duplicate(true))
	_check(not Realm.resolve_encounter(state, encounter_id, forged).ok, "duplicate reward rejected")
	_eq(Realm.serialize(state), before, "duplicate reward is atomic")
	var gold_before: int = int(state.resources.gold)
	var resolved: Dictionary = Realm.resolve_encounter(state, encounter_id, outcome)
	if not _check(resolved.ok, "realm applies actual ActionRules outcome"):
		print("RESOLUTION_DIAGNOSTIC ", resolved)
		return
	_eq(state.resources.gold, gold_before + 240 + 180, "only registered cache and oath reward paid")
	_eq(state.hero.inventory.size(), 6, "three earned item instances join three starter items")
	for preview: Dictionary in previews:
		_eq(Items.find_instance(state.hero, str(preview.instance.instanceId)), preview.instance, "earned item matches exact preview: " + str(preview.instance.itemId))
	_eq(state.hero.hp, outcome.heroState.hp, "actual survivor health preserved")
	_eq(state.hero.mana, outcome.heroState.mana, "actual Focus preserved")
	_eq(state.companies, companies, "all stationed company membership is unchanged")
	_eq(state.watchIndex, 2, "extended action duration adds no realm time")
	_eq(state.obligations[0].status, "fulfilled", "real cleared extraction fulfils accepted oath")
	_eq(state.hero.xp, 120, "one registered first-clear experience award")
	_check(state.locations.bell_crypt.cleared, "actual extracted clear changes the location")
	for enemy: Dictionary in state.locations.bell_crypt.enemies:
		_eq(enemy.hp, 0, "actual enemy casualty persists: " + str(enemy.id))
	var reloaded: Variant = Realm.deserialize(Realm.serialize(state))
	_check(reloaded != null, "earned items, choices and quest state survive real JSON reload")
	if reloaded != null:
		_eq(reloaded.hero.inventory, state.hero.inventory, "affixes and full bounded item schema survive")
		_check(Items.equip(reloaded.hero, encounter_id + "/crypt_weapon/oathkeeper_blade", "main_hand").ok, "earned named unique can actually be equipped")
		_check(reloaded.hero.traits.has("cleave_ward"), "equipped unique changes real derived combat traits")
		_check(Realm.deserialize(Realm.serialize(reloaded)) != null, "equipped unique reloads without stat formula duplication")
	before = Realm.serialize(state)
	_check(not Realm.resolve_encounter(state, encounter_id, outcome).ok, "full earned outcome cannot be applied twice")
	_check(not Realm.begin_encounter(state, {"kind": "dungeon", "locationId": "bell_crypt"}).ok, "fully looted resolved dungeon cannot regenerate rewards")
	_eq(Realm.serialize(state), before, "replayed outcome and farming attempt leave state unchanged")
	earned_run = {"seed": 711, "watchIndex": int(state.watchIndex), "elapsedTicks": int(outcome.elapsedTicks), "hp": int(state.hero.hp), "mana": int(state.hero.mana), "lootClaims": state.claimedLoot.size(), "inventoryItems": state.hero.inventory.size(), "companyCount": state.expeditionCompanyIds.size(), "obligation": str(state.obligations[0].status)}

func _test_malformed() -> void:
	_check(Realm.deserialize("not json") == null, "malformed JSON rejected")
	var base: Dictionary = Realm.create_realm(711)
	var cases: Array = []
	var altered: Dictionary = base.duplicate(true)
	altered.resources.gold = -1
	cases.append(altered)
	altered = base.duplicate(true)
	altered.watchIndex = 4
	cases.append(altered)
	altered = base.duplicate(true)
	altered.expeditionCompanyIds.append(altered.expeditionCompanyIds[0])
	cases.append(altered)
	altered = base.duplicate(true)
	altered.hero.equipment.head = "missing/item"
	cases.append(altered)
	altered = base.duplicate(true)
	altered.hero.equipment.head = altered.hero.equipment.main_hand
	altered.hero.equipment.main_hand = ""
	cases.append(altered)
	altered = base.duplicate(true)
	altered.companies["company:dawn_guard"] = 9
	cases.append(altered)
	altered = base.duplicate(true)
	altered.hero.inventory[0].itemId = "invented_relic"
	cases.append(altered)
	altered = base.duplicate(true)
	altered.rivals.fara_zori.spentRecruitment = 0
	cases.append(altered)
	altered = base.duplicate(true)
	altered.locations.bell_crypt.enemies[0].hp = 900
	cases.append(altered)
	altered = base.duplicate(true)
	altered.settlements.dawnwatch.buildings = {"water_gate": {"stage": "complete", "level": 1, "builtWatch": 0}}
	altered.settlements.dawnwatch.lastConstructionDay = 1
	cases.append(altered)
	for index: int in range(cases.size()):
		_check(Realm.deserialize(Realm.serialize(cases[index])) == null, "malformed cross-field state rejected " + str(index))
	Realm.begin_encounter(base, {"kind": "dungeon", "locationId": "bell_crypt"})
	altered = base.duplicate(true)
	altered.pendingEncounter.lootRewards[0].itemId = "sentinel_ring"
	_check(Realm.deserialize(Realm.serialize(altered)) == null, "saved reward substitution rejected")
	altered = base.duplicate(true)
	altered.pendingEncounter.heroSnapshot.attack = 999
	_check(Realm.deserialize(Realm.serialize(altered)) == null, "saved combat snapshot stat forgery rejected")
	altered = base.duplicate(true)
	altered.pendingEncounter.playerCompanies = ["company:dawn_guard"]
	_check(Realm.deserialize(Realm.serialize(altered)) == null, "solo save cannot silently insert a company")
	altered = base.duplicate(true)
	altered.pendingEncounter.arena.obstacles = []
	_check(Realm.deserialize(Realm.serialize(altered)) == null, "reload cannot remove collision from visible dungeon walls")
	altered = base.duplicate(true)
	altered.pendingEncounter.heroSnapshot.pos = [0, -9]
	_check(Realm.deserialize(Realm.serialize(altered)) == null, "reload cannot move the hero behind the registered encounter entrance")
