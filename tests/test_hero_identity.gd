extends SceneTree
## Canonical identities, real class permissions, and grandfathered committed
## action state. The roster's design-only skills/traits are not claimed playable.
const Identity = preload("res://game/redesign/hero_identity.gd")
const Realm = preload("res://game/redesign/realm_rules.gd")
const Action = preload("res://game/redesign/action_rules.gd")

var groups: int = 0
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run_all")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("IDENTITY FAIL: " + label)
	return condition

func _eq(actual: Variant, expected: Variant, label: String) -> bool:
	var same: bool = Realm._same(actual, expected)
	return _check(same, label + (" [actual=%s expected=%s]" % [str(actual),str(expected)] if not same else ""))

func _run(label: String, test: Callable) -> void:
	groups += 1
	var before: int = failures
	test.call()
	print("IDENTITY GROUP ",groups," ",label,": ","PASS" if before == failures else "FAIL")

func _run_all() -> void:
	_run("Catalog integrity and distinct fixed champion signatures", _test_catalog)
	_run("One canonical campaign hero, allocation and reset retain identity", _test_realm)
	_run("Authoritative class-specific commands and atomic rejection", _test_permissions)
	_run("Class/race/alias substitution rejected in saved state", _test_corrupt)
	_run("V1/v2 migration leaves old registered encounters unchanged", _test_migration)
	_run("Committed legacy spells finish; new or queued forbidden casts do not", _test_legacy_casts)
	print("IDENTITY_SUMMARY ",JSON.stringify({"groups":groups,"checks":checks,"failures":failures}))
	quit(0 if failures == 0 else 1)

func _test_catalog() -> void:
	var heroes: Dictionary = Identity.hero_catalog()
	var classes: Dictionary = Identity.class_catalog()
	var races: Dictionary = Identity.race_catalog()
	_eq([classes.size(),races.size(),Identity.faction_catalog().size()], [20,8,9], "twenty classes, eight races, nine factions")
	var canonical: Dictionary = {}
	var traits: Dictionary = {}
	var assigned: Dictionary = {}
	var bad: Array = []
	for entry: Dictionary in heroes.values():
		if canonical.has(str(entry.canonicalId)):
			continue
		canonical[str(entry.canonicalId)] = true
		assigned[str(entry.classId)] = true
		if not classes.has(str(entry.classId)) or not races.has(str(entry.raceId)) or not Identity.faction_catalog().has(str(entry.factionId)) or not Identity.identity_valid({"id":str(entry.canonicalId),"classId":entry.classId,"raceId":entry.raceId,"factionId":entry.factionId}):
			bad.append(str(entry.canonicalId))
		if not entry.get("personalTraits") is Array or entry.personalTraits.is_empty():
			bad.append(str(entry.canonicalId)+":missing_trait")
		for trait_entry: Dictionary in entry.get("personalTraits",[]):
			if traits.has(str(trait_entry.id)) or str(trait_entry.get("status","")).is_empty():
				bad.append(str(entry.canonicalId)+":trait_identity")
			traits[str(trait_entry.id)] = true
	_eq(canonical.size(), 156, "aliases do not create an extra playable champion")
	_eq(traits.size(), 156, "all authored personal signature IDs remain distinct")
	_eq(assigned.size(), 20, "every defined class has roster representatives")
	_eq(bad, [], "every roster row links valid fixed class/race/faction and an explicit trait status")
	_eq(Identity.hero_definition("ileana").canonicalId,"mara_veyne","legacy protagonist alias resolves to Mara")
	_eq(Identity.class_skills("oathwarden"),["cleave","ward"],"Mara kit is only Cleave and Ward")
	_eq(Identity.class_skills("pyromancer"),["ember"],"Pyromancer owns the implemented fire skill")
	_eq(Identity.class_skills("druid"),["roots"],"Druid owns the implemented nature skill")
	_eq(Identity.class_skills("thief"),[],"Thief design does not borrow unsupported magic")
	_eq(Identity.class_skills("rogue"),[],"Rogue design does not borrow unsupported magic")
	_check(str(classes.thief.playstyle) != str(classes.rogue.playstyle) and classes.thief.plannedSkills != classes.rogue.plannedSkills and str(classes.thief.classTrait.id) != str(classes.rogue.classTrait.id),"Thief and Rogue have distinct playstyles, tool/skill plans, and class traits")
	var broad: Array = []
	for class_id: String in classes:
		if Identity.class_skills(class_id).size() > 2:
			broad.append(class_id)
	_eq(broad,[],"no release or debug class grants the old four-spell mix")
	_check(not Identity.is_skill_allowed({"id":"unknown","classId":"pyromancer"},"ember"),"unknown hero cannot borrow a known class")
	_check(not Identity.identity_valid({"id":"ileana","heroId":"vara_flint","classId":"pyromancer"}),"conflicting alias cannot disguise a class switch")
	classes.oathwarden.supportedSkills.append("ember")
	_eq(Identity.class_skills("oathwarden"),["cleave","ward"],"returned catalogs do not share permission arrays")

func _identity(hero: Dictionary) -> Array:
	return [hero.id,hero.classId,hero.raceId,hero.factionId,hero.skills]

func _test_realm() -> void:
	var state: Dictionary = Realm.create_realm(711,{"hero":{"id":"vara_flint","classId":"pyromancer","raceId":"stormmarked","factionId":"emberhorn_dominion","name":"Substituted"}})
	var expected: Array = ["ileana","oathwarden","hearthborn","ashen_crown",["cleave","ward"]]
	_eq(_identity(state.hero),expected,"new campaign setup cannot replace the implemented protagonist")
	_eq(state.hero.name,"Mara Veyne","fixed champion keeps canonical display identity")
	_check(not state.has("heroes"),"no multihero collection introduced")
	Realm.allocate_attributes(state,{"might":1})
	Realm.reset_attributes(state)
	_eq(_identity(state.hero),expected,"attribute reset cannot respec class or race")
	var loaded: Variant = Realm.deserialize(Realm.serialize(state))
	_check(loaded != null,"canonical identity round-trips")
	if loaded != null:
		_eq(_identity(loaded.hero),expected,"reload retains the same chosen champion")
	Realm.begin_encounter(state,{"kind":"dungeon","locationId":"bell_crypt"})
	_eq(_identity(state.pendingEncounter.heroSnapshot),expected,"new encounter contains the authoritative fixed kit")
	var action: Dictionary = Action.create(state.pendingEncounter)
	_eq(_identity(Action.get_actor(action,str(action.heroId))),expected,"native action actor uses the same fixed identity")

func _encounter(hero_id: String = "ileana", overrides: Dictionary = {}) -> Dictionary:
	var hero: Dictionary = {"id":hero_id,"pos":[0,0],"hp":120,"maxHp":120,"mana":100,"maxMana":100,"attack":18,"armor":2,"speed":4.6}
	hero.merge(overrides,true)
	return {"id":"identity-proof","kind":"dungeon","heroSnapshot":hero,"playerCompanies":[],"enemies":[{"id":"target","type":"wolf","pos":[0,-4],"hp":100,"maxHp":100,"behavior":"passive","armor":0}],"arena":{"entry":[0,0],"exit":[0,10]},"seed":711}

func _test_permissions() -> void:
	for pair: Array in [["ileana",["cleave","ward"]],["vara_flint",["ember"]],["cael_bracken",["roots"]]]:
		var source: Dictionary = _encounter(str(pair[0]))
		var state: Dictionary = Action.create(source)
		_eq(Action.get_actor(state,str(state.heroId)).skills,pair[1],"class-specific prepared kit for "+str(pair[0]))
		for ability: String in ["cleave","ward","ember","roots"]:
			state = Action.create(source)
			var before: String = Action.serialize(state)
			var result: Dictionary = Action.submit(state,{"kind":"cast","ability":ability,"pos":[0,-1]})
			_eq(bool(result.ok),pair[1].has(ability),"direct submit permission: "+str(pair[0])+" / "+ability)
			if not result.ok:
				_eq(Action.serialize(state),before,"off-class rejection spends no Focus or cooldown")
			else:
				Action.advance(state,int(Action.ABILITIES[ability].windup))
				_eq(Action.get_actor(state,str(state.heroId)).mana,100-int(Action.ABILITIES[ability].cost),"legal class release charges the actual cost")
	var mara: Dictionary = Action.create(_encounter())
	Action.get_actor(mara,"ileana").skills.append("ember")
	var before: String = Action.serialize(mara)
	_check(not Action.submit(mara,{"kind":"cast","ability":"ember","pos":[0,-4]}).ok,"forged prepared list cannot bypass canonical class")
	_eq(Action.serialize(mara),before,"forged-list cast rejection is atomic")
	Action.submit(mara,{"kind":"pause","paused":true})
	before = Action.serialize(mara)
	_check(not Action.submit(mara,{"kind":"cast","ability":"roots","pos":[0,-4]}).ok,"pause queue cannot bypass class permission")
	_eq(Action.serialize(mara),before,"illegal queue request does not replace an existing intent")
	for override: Dictionary in [{"classId":"pyromancer"},{"raceId":"stormmarked"},{"factionId":"vesper_court"},{"heroId":"vara_flint"},{"skills":["cleave","ward","ember","roots"]},{"skills":["ward","ward"]},{"skills":"ward"}]:
		_eq(Action.create(_encounter("ileana",override)).phase,"invalid","new action rejects inconsistent identity or kit: "+str(override))
	_eq(Action.create(_encounter("invented_hero",{"classId":"pyromancer"})).phase,"invalid","unknown actor identity is not a playable debug class")

func _test_corrupt() -> void:
	var state: Dictionary = Realm.create_realm(711)
	for pair: Array in [["classId","pyromancer"],["raceId","stormmarked"],["factionId","emberhorn_dominion"],["heroId","vara_flint"],["id","vara_flint"],["skills",["cleave","ward","ember"]]]:
		var changed: Dictionary = state.duplicate(true)
		changed.hero[pair[0]] = pair[1]
		_check(Realm.deserialize(Realm.serialize(changed)) == null,"realm save rejects identity substitution: "+str(pair[0]))
	Realm.begin_encounter(state,{"kind":"dungeon","locationId":"bell_crypt"})
	var changed: Dictionary = state.duplicate(true)
	changed.pendingEncounter.heroSnapshot.classId = "pyromancer"
	_check(Realm.deserialize(Realm.serialize(changed)) == null,"pending snapshot cannot substitute a new class")
	changed = state.duplicate(true)
	changed.pendingEncounter.heroSnapshot.skills.append("ember")
	_check(Realm.deserialize(Realm.serialize(changed)) == null,"pending snapshot cannot add a forbidden prepared skill")
	var source: Dictionary = _encounter("vara_flint")
	var action: Dictionary = Action.create(source)
	Action.submit(action,{"kind":"cast","ability":"ember","pos":[0,-4]})
	Action.advance(action,9)
	_check(not Action.deserialize(Action.serialize(action),source).is_empty(),"legal fire-caster committed state remains resumable")
	for pair: Array in [["classId","oathwarden"],["raceId","hearthborn"],["factionId","ashen_crown"],["skills",["ember","ward"]],["heroId","ileana"]]:
		var corrupted: Dictionary = Action.snapshot(action)
		corrupted.actors[0][pair[0]] = pair[1]
		_check(Action.restore(corrupted,source).is_empty(),"live save cannot alter fixed actor identity: "+str(pair[0]))

func _shell(file_name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/progression/"+file_name))

func _test_migration() -> void:
	for file: String in ["v1-town-save.json","v1-earned-equipment-save.json","v1-combat-save.json","v2-invested-combat-save.json","v2-legacy-ember-save.json"]:
		var shell: Dictionary = _shell(file)
		var original: Dictionary = JSON.parse_string(str(shell.realm))
		var loaded: Variant = Realm.deserialize(str(shell.realm))
		if not _check(loaded != null,"old save migrates to fixed identity: "+file):
			continue
		_eq(loaded.version,Realm.VERSION,"identity migration reaches the current schema version")
		_eq(_identity(loaded.hero),["ileana","oathwarden","hearthborn","ashen_crown",["cleave","ward"]],"legacy campaign is fixed to Mara's canonical identity")
		_eq(loaded.pendingEncounter,original.pendingEncounter,"trusted old pending dictionary remains exactly unchanged")
		_eq([loaded.hero.hp,loaded.hero.mana,loaded.hero.inventory],[original.hero.hp,original.hero.mana,original.hero.inventory],"identity migration never heals or replaces loot")
		if int(original.version) == 2:
			_eq(loaded.hero.progression,original.hero.progression,"v2 investments and unspent budget persist exactly")
		_check(Realm.deserialize(Realm.serialize(loaded)) != null,"migrated legacy contract can be persisted again")
		if loaded.pendingEncounter != null:
			var restored: Dictionary = Action.deserialize(str(shell.action),loaded.pendingEncounter)
			if _check(not restored.is_empty(),"live legacy actor restores without rewriting registry"):
				_eq(Action.get_actor(restored,"ileana").skills,Action.LEGACY_SAVED_SKILLS,"old actor shape is preserved solely for save continuity")
				_check(not Action.deserialize(Action.serialize(restored),loaded.pendingEncounter).is_empty(),"legacy actor can be saved again under canonical campaign")

func _test_legacy_casts() -> void:
	var shell: Dictionary = _shell("v2-legacy-ember-save.json")
	var realm: Variant = Realm.deserialize(str(shell.realm))
	var action: Dictionary = Action.deserialize(str(shell.action),realm.pendingEncounter)
	if not _check(not action.is_empty(),"genuine old committed Ember save loads"):
		return
	var hero: Dictionary = Action.get_actor(action,"ileana")
	_eq([action.tick,hero.action.committed,action.projectiles.size(),hero.mana],[9,true,1,30],"fixture contains an already paid, released projectile")
	var start: Array = action.projectiles[0].pos.duplicate()
	Action.advance(action,1)
	_check(action.projectiles.size() == 1 and action.projectiles[0].pos != start,"grandfathered projectile continues its physical flight")
	Action.advance(action,11)
	hero = Action.get_actor(action,"ileana")
	_eq(hero.mana,30,"restoring a committed cast never charges Focus twice")
	var before: String = Action.serialize(action)
	_check(not Action.submit(action,{"kind":"cast","ability":"ember","pos":[0,0]}).ok,"legacy broad skill list cannot start another fire spell")
	_eq(Action.serialize(action),before,"legacy forbidden resubmission is atomic")
	_check(Action.submit(action,{"kind":"cast","ability":"ward"}).ok,"same restored hero can still use her legal Oathwarden skill")
	Action.advance(action,6)
	_check(Action.get_actor(action,"ileana").statuses.has("ward"),"legal class cast releases normally after migration")
	# A pre-class queued request is a saved intent, not a committed spell.
	shell = _shell("v2-invested-combat-save.json")
	realm = Realm.deserialize(str(shell.realm))
	var saved: Dictionary = JSON.parse_string(str(shell.action))
	saved.paused = true
	saved.queuedCommand = {"kind":"cast","ability":"ember","pos":[0,0]}
	var loaded: Dictionary = Action.restore(saved,realm.pendingEncounter)
	if _check(not loaded.is_empty(),"obsolete queued spell does not make the whole save unloadable"):
		_eq(loaded.queuedCommand,{},"uncommitted forbidden queue is discarded")
		_check(not loaded.events.is_empty() and str(loaded.events[-1].type) == "command_discarded","discard has an explicit presentation event")
		_eq(Action.get_actor(loaded,"ileana").mana,40,"discarded queue spends no Focus")
	# Boundary fixture of a valid legacy windup: it retains its timeline on
	# restore, but the class guard prevents release and cost at commit time.
	action = Action.deserialize(str(shell.action),realm.pendingEncounter)
	hero = Action.get_actor(action,"ileana")
	Action._start_action(action,hero,"cast","ember",Vector2(0,0),"",9,12)
	Action.advance(action,5)
	loaded = Action.deserialize(Action.serialize(action),realm.pendingEncounter)
	if _check(not loaded.is_empty(),"pre-class uncommitted windup still loads"):
		var released_events: Array = Action.advance(loaded,4)
		_eq([loaded.projectiles.size(),Action.get_actor(loaded,"ileana").mana],[0,40],"forbidden windup cannot release a projectile or spend Focus")
		var blocked: bool = false
		var false_release: bool = false
		for event: Dictionary in released_events:
			blocked = blocked or (str(event.type) == "action_blocked" and str(event.get("reason","")) == "class_restriction")
			false_release = false_release or (str(event.type) == "action_committed" and str(event.get("ability","")) == "ember")
		_check(blocked,"blocked legacy release is explicitly reported")
		_check(not false_release,"blocked legacy windup cannot trigger a false spell release effect")
