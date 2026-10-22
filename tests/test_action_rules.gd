extends SceneTree
## Fixed-step action rules; no renderer, campaign flags or fabricated wins.
const Rules = preload("res://game/redesign/action_rules.gd")
var checks: int = 0
var failures: int = 0
var groups: int = 0
var journey: Dictionary = {}

func _initialize() -> void:
	_run("Input ownership, aliases and JSON snapshots", _test_model)
	_run("Movement speed, obstacle routes and atomic rejection", _test_movement)
	_run("Exact fence and circle boundary clearance", _test_clearance)
	_run("Attack commitment, recovery, aim and cancellation", _test_attack)
	_run("Spell timing, costs, cooldowns and finite equipment wards", _test_spells)
	_run("Traveling projectiles, walls, burns and exactly one impact", _test_projectiles)
	_run("Guard direction, dodge windows and rooted movement", _test_defense)
	_run("Locked leap telegraph and interruption", _test_leap)
	_run("Unique cleave tradeoff and bounded nonrecursive ward", _test_unique)
	_run("Pause, queued intent and deterministic replay", _test_pause)
	_run("Persistent corpses, choice loot and extraction", _test_loot)
	_run("Defeat and same-tick extraction interruption", _test_finish)
	_run("Live action save validation and exact continuation", _test_persistence)
	_run("Authentic legacy grazing route restore and safe continuation", _test_legacy_path)
	_run("Earned three-enemy crypt, loot and return", _test_crypt)
	print("ACTION RULES: %d groups, %d checks, %d failures" % [groups, checks, failures])
	if not journey.is_empty():
		print("ACTION JOURNEY " + JSON.stringify(journey))
	quit(0 if failures == 0 else 1)

func _run(label: String, test: Callable) -> void:
	groups += 1
	var previous: int = failures
	test.call()
	print(("PASS " if previous == failures else "FAIL ") + label)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("ASSERTION: " + label)

func _eq(actual: Variant, expected: Variant, label: String) -> void:
	_check(actual == expected, label + " (actual=%s expected=%s)" % [str(actual), str(expected)])

func _enemy(id_value: String = "target", position: Array = [0.0, -1.4], extra: Dictionary = {}) -> Dictionary:
	var value: Dictionary = {"id": id_value, "pos": position, "hp": 100, "maxHp": 100, "attack": 10, "armor": 0, "behavior": "passive", "speed": 3.0, "type": "wolf"}
	value.merge(extra, true)
	return value

func _state(enemies: Array = [], hero_overrides: Dictionary = {}, extra: Dictionary = {}) -> Dictionary:
	var hero: Dictionary = {"id": "ileana", "name": "Mara Veyne", "pos": [0.0, 0.0], "hp": 120, "maxHp": 120, "mana": 100, "maxMana": 100, "attack": 18, "armor": 0, "speed": 4.6}
	hero.merge(hero_overrides, true)
	var setup: Dictionary = {"id": "test_crypt", "kind": "dungeon", "heroSnapshot": hero, "playerCompanies": [], "enemies": enemies, "seed": 421, "arena": {"entry": [0.0, 0.0], "exit": [0.0, 10.0]}}
	setup.merge(extra, true)
	return Rules.create(setup)

func _fire_state(enemies: Array = [], hero_overrides: Dictionary = {}, extra: Dictionary = {}) -> Dictionary:
	var identity: Dictionary = {"id":"vara_flint", "name":"Vara Flint", "classId":"pyromancer", "raceId":"stormmarked", "factionId":"emberhorn_dominion"}
	identity.merge(hero_overrides, true)
	return _state(enemies, identity, extra)

func _nature_state(enemies: Array = [], hero_overrides: Dictionary = {}, extra: Dictionary = {}) -> Dictionary:
	var identity: Dictionary = {"id":"cael_bracken", "name":"Cael Bracken", "classId":"druid", "raceId":"hearthborn", "factionId":"thornweald_court"}
	identity.merge(hero_overrides, true)
	return _state(enemies, identity, extra)

func _hero(state: Dictionary) -> Dictionary:
	return Rules.get_actor(state, str(state.heroId))

func _pos(actor: Dictionary) -> Vector2:
	return Vector2(float(actor.pos[0]), float(actor.pos[1]))

func _count(events: Array, event_type: String) -> int:
	var result: int = 0
	for event: Dictionary in events:
		if str(event.type) == event_type:
			result += 1
	return result

func _test_model() -> void:
	var enemy: Dictionary = _enemy()
	var source: Dictionary = {"id": "registered_42", "heroSnapshot": {"id": "ileana", "pos": [0, 0], "maxHp": 120, "hp": 85}, "enemies": [enemy], "playerCompanies": []}
	var before: String = JSON.stringify(source)
	var state: Dictionary = Rules.create(source)
	_eq(JSON.stringify(source), before, "create does not mutate registry input")
	_eq(state.encounterId, "registered_42", "realm id alias")
	_eq(_hero(state).hp, 85, "persistent hero health")
	_eq(state.phase, "running", "valid model runs")
	var copy: Dictionary = Rules.snapshot(state)
	copy.actors[0].hp = 1
	_eq(_hero(state).hp, 85, "snapshot does not share actor references")
	_check(JSON.parse_string(JSON.stringify(Rules.snapshot(state))) is Dictionary, "all snapshot fields JSON compatible")
	_eq(Rules.create({"enemies": [_enemy("ileana")]}).phase, "invalid", "duplicate identity rejected")
	_eq(_state([], {}, {"objective": {"type": "unknown"}}).phase, "invalid", "unimplemented objective rejected instead of fake clear")
	_eq(_state([], {}, {"playerCompanies": [{"id": "company"}]}).phase, "invalid", "companies cannot silently disappear")
	_eq(_state([], {"pos": [50, 50]}).phase, "invalid", "off-arena spawn rejected")

func _test_movement() -> void:
	var state: Dictionary = _state()
	_check(Rules.submit(state, {"kind": "move", "pos": [8, 0]}).ok, "valid destination")
	Rules.advance(state, 30)
	_check(absf(_pos(_hero(state)).x - 4.6) < 0.001, "movement uses 4.6 metres per second")
	Rules.advance(state, 60)
	_check(_pos(_hero(state)).distance_to(Vector2(8, 0)) < 0.01, "movement stops at destination")
	var before: String = JSON.stringify(state)
	_check(not Rules.submit(state, {"kind": "move", "pos": [11, 0]}).ok, "blocked command rejected")
	_eq(JSON.stringify(state), before, "rejected movement is atomic")
	var routed: Dictionary = _state([], {"pos": [-4, 0]}, {"arena": {"bounds": [-10, -12, 10, 12], "obstacles": [{"rect": [-0.5, -2, 1, 4]}]}})
	_check(Rules.submit(routed, {"kind": "move", "pos": [4, 0]}).ok, "path can route around a wall")
	var crossed: bool = false
	for step: int in range(180):
		Rules.advance(routed)
		var p: Vector2 = _pos(_hero(routed))
		if p.x > -0.91 and p.x < 0.91 and p.y > -2.41 and p.y < 2.41:
			crossed = true
	_check(not crossed, "route never intersects expanded wall")
	_check(_pos(_hero(routed)).distance_to(Vector2(4, 0)) < 0.1, "route reaches other side")
	var sealed: Dictionary = _state([], {"pos": [-4, 0]}, {"arena": {"bounds": [-10, -12, 10, 12], "obstacles": [{"rect": [-0.5, -12, 1, 24]}]}})
	_check(not Rules.submit(sealed, {"kind": "move", "pos": [4, 0]}).ok, "unreachable destination rejected")
	# Reproduces the actual seed-712 Briar clear: a long direct segment grazed
	# a fence corner, then stalled when shorter movement steps found the wall.
	var corner: Dictionary = _state([], {"pos": [0.527720212936401, -5.21601676940918]}, {"arena": {"bounds": [-12, -12, 12, 12], "obstacles": [{"rect": [-4, 4, 8, 1]}]}})
	_check(Rules.submit(corner, {"kind": "move", "pos": [-8, 10]}).ok, "corner-grazing extraction route is accepted")
	var crossed_corner: bool = false
	var wall: Rect2 = Rect2(-4, 4, 8, 1).grow(0.42)
	for step: int in range(240):
		Rules.advance(corner)
		if wall.has_point(_pos(_hero(corner))):
			crossed_corner = true
	_check(not crossed_corner, "corner route keeps the hero outside the solid fence")
	_check(_pos(_hero(corner)).distance_to(Vector2(-8, 10)) < 0.1, "one movement command reaches extraction without a manual retry at the corner")

func _test_clearance() -> void:
	var fence: Dictionary = _state([], {"pos": [-4, -4]}, {"arena": {"obstacles": [{"rect": [-1, -1, 2, 2]}]}})
	_check(not Rules._line_clear(fence,Vector2(-3,-1.5),Vector2(3,-1.5),0.5), "the included minimum fence edge blocks a tangent segment")
	_check(not Rules._line_clear(fence,Vector2(-3,0),Vector2(0,-3),0.5), "touching only the included minimum fence corner is blocked")
	_check(Rules._line_clear(fence,Vector2(-3,1.5),Vector2(3,1.5),0.5), "the excluded maximum fence edge remains traversable")
	var pillar: Dictionary = _state([], {"pos": [-4, -4]}, {"arena": {"obstacles": [{"pos": [0, 0], "radius": 1.0}]}})
	_check(not Rules._line_clear(pillar,Vector2(-3,1.5),Vector2(3,1.5),0.5), "touching a circular pillar boundary is blocked")

func _test_attack() -> void:
	var state: Dictionary = _state([_enemy()])
	_check(Rules.submit(state, {"kind": "attack", "targetId": "target"}).ok, "attack accepts registered live enemy")
	var events: Array = Rules.advance(state)
	_eq(_count(events, "action_started"), 1, "attack emits one start event")
	_eq(_hero(state).animState, "attack", "new attack is not overwritten by idle path processing")
	Rules.advance(state, 7)
	_eq(Rules.get_actor(state, "target").hp, 100, "windup applies no early damage")
	events = Rules.advance(state)
	_eq(Rules.get_actor(state, "target").hp, 82, "one strike at commitment")
	_eq(_count(events, "damage"), 1, "one damage event")
	_check(not Rules.submit(state, {"kind": "move", "pos": [3, 0]}).ok, "commitment cannot be animation-cancelled")
	Rules.advance(state, 13)
	_eq(Rules.get_actor(state, "target").hp, 82, "recovery does not replay hit")
	Rules.advance(state, 9)
	_eq(Rules.get_actor(state, "target").hp, 64, "held target repeats basic attack")
	var evade: Dictionary = _state([_enemy()])
	Rules.submit(evade, {"kind": "attack", "targetId": "target"})
	Rules.advance(evade)
	Rules.get_actor(evade, "target").pos = [6, 0]
	Rules.advance(evade, 8)
	_eq(Rules.get_actor(evade, "target").hp, 100, "committed aim does not hit a distant target")
	var cancel: Dictionary = _state([_enemy()])
	Rules.submit(cancel, {"kind": "cast", "ability": "cleave", "pos": [0, -1]})
	Rules.advance(cancel, 3)
	_check(Rules.submit(cancel, {"kind": "move", "pos": [3, 0]}).ok, "windup can be abandoned")
	Rules.advance(cancel, 20)
	_eq(Rules.get_actor(cancel, "target").hp, 100, "cancelled cast does not deal damage")
	_eq(_hero(cancel).mana, 100, "cancelled cast spends no Focus")
	_eq(_hero(cancel).cooldowns.size(), 0, "cancelled cast grants no cooldown bypass")

func _test_spells() -> void:
	var state: Dictionary = _state([], {"wardBonus": 8})
	_check(Rules.submit(state, {"kind": "cast", "ability": "ward"}).ok, "ward starts")
	Rules.advance(state, 5)
	_eq(_hero(state).mana, 100, "Focus remains until release")
	_check(not _hero(state).statuses.has("ward"), "no shield before release")
	Rules.advance(state)
	_eq(_hero(state).mana, 86, "ward charges exact Focus cost once")
	_eq(_hero(state).statuses.ward.pool, 53, "four-piece bonus adds eight finite capacity")
	Rules.advance(state, 8)
	var before: String = JSON.stringify(state)
	_check(not Rules.submit(state, {"kind": "cast", "ability": "ward"}).ok, "cooldown rejects repeat")
	_eq(JSON.stringify(state), before, "cooldown rejection is atomic")
	Rules._status(state, _hero(state), "ward", 180, {"pool": 8})
	_eq(_hero(state).statuses.ward.pool, 53, "weak replacement cannot erase stronger shield")
	Rules._damage(state, "target", _hero(state), 60, "physical", Vector2(0, -1), true)
	_eq(_hero(state).hp, 113, "ward absorbs finite pool then takes overflow")
	_check(not _hero(state).statuses.has("ward"), "spent ward is removed")
	var poor: Dictionary = _fire_state([], {"mana": 9})
	before = JSON.stringify(poor)
	_check(not Rules.submit(poor, {"kind": "cast", "ability": "ember", "pos": [0, -5]}).ok, "insufficient Focus rejects")
	_eq(JSON.stringify(poor), before, "unaffordable skill spends nothing")
	_check(not Rules.submit(poor, {"kind": "cast", "ability": "invented"}).ok, "unprepared skill rejected")
	var crowded: Dictionary = _fire_state()
	Rules.submit(crowded, {"kind": "cast", "ability": "ember", "pos": [0, -6]})
	Rules.advance(crowded, 8)
	for index: int in range(Rules.MAX_PROJECTILES):
		Rules._projectile(crowded, _hero(crowded), Vector2(0, -6), 1, "fire", false)
	Rules.advance(crowded)
	_eq(_hero(crowded).mana, 100, "budget filled during windup does not consume Focus")
	_check(not _hero(crowded).cooldowns.has("ember"), "blocked release does not charge a cooldown")
	var expiry: Dictionary = _state()
	Rules.submit(expiry, {"kind": "cast", "ability": "ward"})
	Rules.advance(expiry, 185)
	_check(_hero(expiry).statuses.has("ward"), "ward exists one tick before expiry")
	Rules.advance(expiry)
	_check(not _hero(expiry).statuses.has("ward"), "ward expires at exact duration")

func _test_projectiles() -> void:
	var state: Dictionary = _fire_state([_enemy("target", [0, -6])])
	Rules.submit(state, {"kind": "cast", "ability": "ember", "pos": [0, -6]})
	Rules.advance(state, 8)
	_eq(state.projectiles.size(), 0, "projectile waits for release frame")
	var events: Array = Rules.advance(state)
	_eq(_count(events, "projectile_spawned"), 1, "exactly one projectile released")
	_eq(Rules.get_actor(state, "target").hp, 100, "ranged skill is not instant hit")
	Rules.advance(state, 10)
	_eq(Rules.get_actor(state, "target").hp, 100, "flight time follows distance")
	events = Rules.advance(state, 8)
	_eq(Rules.get_actor(state, "target").hp, 72, "fire hit has known damage")
	_eq(_count(events, "projectile_hit"), 1, "projectile impacts once")
	_eq(state.projectiles.size(), 0, "impact removes projectile")
	_check(Rules.get_actor(state, "target").statuses.has("burn"), "contact adds timed burn")
	Rules.advance(state, 90)
	_eq(Rules.get_actor(state, "target").hp, 63, "burn has three finite ticks")
	_check(not Rules.get_actor(state, "target").statuses.has("burn"), "burn expires")
	var wall: Dictionary = _fire_state([_enemy("target", [0, -6])], {}, {"arena": {"obstacles": [{"rect": [-2, -3, 4, 0.10]}]}})
	_check(not Rules.submit(wall, {"kind": "cast", "ability": "ember", "pos": [0, -6]}).ok, "cover blocks aimed spell command")
	Rules._projectile(wall, _hero(wall), Vector2(0, -6), 28, "fire", true)
	Rules.advance(wall, 30)
	_eq(Rules.get_actor(wall, "target").hp, 100, "thin wall catches a traveling projectile")
	_eq(wall.projectiles.size(), 0, "wall impact removes projectile")

func _test_defense() -> void:
	var state: Dictionary = _state()
	Rules.submit(state, {"kind": "guard", "pos": [0, -3]})
	Rules._damage(state, "enemy", _hero(state), 20, "physical", Vector2(0, -2), true)
	_eq(_hero(state).hp, 111, "frontal guard reduces incoming damage")
	Rules._damage(state, "enemy", _hero(state), 20, "physical", Vector2(0, 2), true)
	_eq(_hero(state).hp, 91, "rear attack bypasses directional guard")
	var dodge: Dictionary = _state()
	Rules.submit(dodge, {"kind": "dodge", "pos": [3, 0]})
	Rules.advance(dodge)
	Rules._damage(dodge, "enemy", _hero(dodge), 20, "physical", Vector2.ZERO, false)
	_eq(_hero(dodge).hp, 120, "dodge evades during active window")
	Rules.advance(dodge, 5)
	Rules._damage(dodge, "enemy", _hero(dodge), 20, "physical", Vector2.ZERO, false)
	_eq(_hero(dodge).hp, 100, "dodge recovery is vulnerable")
	Rules.advance(dodge, 3)
	_check(absf(_pos(_hero(dodge)).x - 1.5) < 0.01, "halfway through dodge translation at nine ticks")
	_check(not Rules.submit(dodge, {"kind": "move", "pos": [6, 0]}).ok, "roll recovery cannot be cancelled after commitment")
	Rules.advance(dodge, 9)
	_check(absf(_pos(_hero(dodge)).x - 3.0) < 0.01, "dodge completes three metres at eighteen ticks")
	_eq(_hero(dodge).animState, "dodge", "get-up recovery retains dodge visual state")
	Rules.advance(dodge, 5)
	_check(not _hero(dodge).action.is_empty(), "roll remains committed through tick23")
	_check(absf(_pos(_hero(dodge)).x - 3.0) < 0.01, "get-up recovery adds no extra displacement")
	Rules.advance(dodge)
	_check(_hero(dodge).action.is_empty(), "roll completes at tick24")
	_check(not Rules.submit(dodge, {"kind": "dodge", "pos": [6, 0]}).ok, "dodge recharge prevents spam")
	var bound_dodge: Dictionary = _state()
	Rules.submit(bound_dodge, {"kind": "dodge", "pos": [3, 0]})
	Rules.advance(bound_dodge)
	var stopped_at: Vector2 = _pos(_hero(bound_dodge))
	Rules._status(bound_dodge, _hero(bound_dodge), "rooted", 30)
	Rules.advance(bound_dodge, 9)
	_eq(_pos(_hero(bound_dodge)), stopped_at, "root applied during dodge halts its translation")
	var rooted: Dictionary = _state([_enemy()])
	Rules._status(rooted, _hero(rooted), "rooted", 30)
	Rules.submit(rooted, {"kind": "move", "pos": [3, 0]})
	Rules.advance(rooted, 10)
	_eq(_pos(_hero(rooted)), Vector2.ZERO, "roots stop movement")
	_check(not Rules.submit(rooted, {"kind": "dodge", "pos": [3, 0]}).ok, "roots prevent dodge")
	Rules.submit(rooted, {"kind": "attack", "targetId": "target"})
	Rules.advance(rooted, 9)
	_eq(Rules.get_actor(rooted, "target").hp, 82, "root does not silence adjacent attacks")
	var spell: Dictionary = _nature_state([_enemy("target", [0, -4], {"behavior": "melee"})])
	Rules.submit(spell, {"kind": "cast", "ability": "roots", "pos": [0, -4]})
	Rules.advance(spell, 12)
	_check(Rules.get_actor(spell, "target").statuses.has("rooted"), "roots applies to enemy in marked area")

func _test_leap() -> void:
	var state: Dictionary = _state([_enemy("alpha", [0, -6], {"behavior": "werewolf"})])
	var alpha: Dictionary = Rules.get_actor(state, "alpha")
	alpha.leapReadyAt = 0
	var events: Array = Rules.advance(state)
	_eq(alpha.action.kind, "leap", "eligible alpha chooses telegraphed leap")
	_eq(alpha.animState, "attack", "leap windup retains its attack animation state")
	_check(bool(events[0].telegraph), "hostile start is marked as telegraph")
	_eq(alpha.action.aim, [0.0, 0.0], "leap locks announced destination")
	Rules.submit(state, {"kind": "move", "pos": [5, 0]})
	Rules.advance(state, 35)
	_check(_pos(alpha).distance_to(Vector2.ZERO) < 0.05, "eight travel ticks reach locked aim")
	_eq(_hero(state).hp, 120, "moving out of impact avoids hit")
	var stopped: Dictionary = _state([_enemy("alpha", [0, -6], {"behavior": "werewolf"})])
	alpha = Rules.get_actor(stopped, "alpha")
	alpha.leapReadyAt = 0
	Rules.advance(stopped, 28)
	Rules._status(stopped, alpha, "rooted", 60)
	Rules.advance(stopped, 8)
	_check(_pos(alpha).distance_to(Vector2(0, -6)) < 0.05, "root interrupts leap travel")
	_eq(_hero(stopped).hp, 120, "interrupted leap causes no phantom impact")

func _test_unique() -> void:
	var enemies: Array = [_enemy("a", [0, -1.5]), _enemy("b", [1.0, -1.5]), _enemy("c", [-1.0, -1.5]), _enemy("d", [0.5, -2.3])]
	var normal: Dictionary = _state(enemies)
	Rules.submit(normal, {"kind": "cast", "ability": "cleave", "pos": [0, -2]})
	Rules.advance(normal, 10)
	_eq(Rules.get_actor(normal, "a").hp, 69, "ordinary cleave damage")
	var unique: Dictionary = _state(enemies, {"traits": ["cleave_ward"]})
	Rules.submit(unique, {"kind": "cast", "ability": "cleave", "pos": [0, -2]})
	var events: Array = Rules.advance(unique, 10)
	_eq(Rules.get_actor(unique, "a").hp, 74, "unique sacrifices 15 percent cleave base damage")
	_eq(_hero(unique).statuses.ward.pool, 24, "ward caps at 24 even with four hits")
	_eq(_count(events, "status_applied"), 1, "one ward proc per cast")
	Rules.advance(unique, 14)
	_eq(_hero(unique).statuses.ward.pool, 24, "recovery cannot proc extra wards")
	var single: Dictionary = _state([_enemy()], {"traits": ["cleave_ward"]})
	Rules.submit(single, {"kind": "cast", "ability": "cleave", "pos": [0, -1]})
	Rules.advance(single, 10)
	_eq(_hero(single).statuses.ward.pool, 8, "single contact grants eight shield")
	var miss: Dictionary = _state([_enemy("target", [0, -6])], {"traits": ["cleave_ward"]})
	Rules.submit(miss, {"kind": "cast", "ability": "cleave", "pos": [0, -2]})
	Rules.advance(miss, 10)
	_check(not _hero(miss).statuses.has("ward"), "missed cleave cannot farm shield")

func _test_pause() -> void:
	var state: Dictionary = _state()
	Rules.submit(state, {"kind": "pause", "paused": true})
	var before: String = JSON.stringify(Rules.snapshot(state))
	Rules.advance(state, 600)
	_eq(JSON.stringify(Rules.snapshot(state)), before, "pause freezes authoritative state and timers")
	_check(Rules.submit(state, {"kind": "move", "pos": [4, 0]}).ok, "pause permits one validated intent")
	_eq(_pos(_hero(state)), Vector2.ZERO, "queue does not move the hero")
	_eq(state.tick, 0, "queue does not advance time")
	Rules.submit(state, {"kind": "pause", "paused": false})
	Rules.advance(state, 30)
	_check(_pos(_hero(state)).distance_to(Vector2(4, 0)) < 0.01, "queued intent executes after resume")
	var a: Dictionary = _fire_state([_enemy("target", [0, -6])])
	var b: Dictionary = _fire_state([_enemy("target", [0, -6])])
	for model: Dictionary in [a, b]:
		Rules.submit(model, {"kind": "cast", "ability": "ember", "pos": [0, -6]})
		Rules.advance(model, 90)
	_eq(JSON.stringify(a), JSON.stringify(b), "same inputs reproduce full state and event ordering")

func _test_loot() -> void:
	var rewards: Array = [{"id": "weapon", "sourceId": "corpse", "kind": "item", "itemId": "oathkeeper_blade"}, {"id": "choice", "sourceId": "corpse", "kind": "choice", "options": ["mist_amulet", "sentinel_ring"]}]
	var state: Dictionary = _state([_enemy("corpse", [0, -1], {"hp": 0}), _enemy("live", [8, -8])], {}, {"lootRewards": rewards})
	_check(bool(Rules.get_actor(state, "corpse").dead), "persisted dead actor stays a corpse")
	_eq(state.objective.progress, 1, "corpse contributes objective progress")
	_eq(state.loot.size(), 2, "unclaimed rewards spawn from persistent corpse")
	Rules.advance(state, 60)
	_eq(Rules.get_actor(state, "corpse").hp, 0, "corpse never regenerates")
	_eq(state.loot.size(), 2, "corpse rewards do not repeat")
	_check(Rules.submit(state, {"kind": "interact", "targetId": "weapon"}).ok, "nearby item pickup starts")
	Rules.advance(state, 9)
	_eq(state.lootClaims.size(), 1, "one pickup makes one claim")
	_eq(state.lootClaims[0].instanceId, "test_crypt/weapon/oathkeeper_blade", "stable instance identity")
	Rules.advance(state)
	_check(not Rules.submit(state, {"kind": "interact", "targetId": "weapon"}).ok, "claimed reward cannot duplicate")
	_check(not Rules.submit(state, {"kind": "interact", "targetId": "choice", "choiceId": "invented"}).ok, "only registered choice is legal")
	_check(Rules.submit(state, {"kind": "interact", "targetId": "choice", "choiceId": "sentinel_ring"}).ok, "one choice accepted")
	Rules.advance(state, 10)
	_eq(state.lootClaims.size(), 2, "choice gives exactly one item")
	_eq(state.lootClaims[1].itemId, "sentinel_ring", "chosen item identity preserved")
	_check(not Rules.submit(state, {"kind": "interact", "targetId": "choice", "choiceId": "mist_amulet"}).ok, "alternate choice cannot be claimed later")
	Rules.submit(state, {"kind": "exit"})
	Rules.advance(state, 45)
	var result: Dictionary = Rules.outcome(state)
	_eq(result.resolution, "retreat", "leaving live opposition is retreat")
	_eq(result.enemySurvivors.size(), 1, "result preserves actual living opponent")
	_eq(result.enemySurvivors[0].hp, 100, "survivor health preserved")
	_eq(result.lootClaims.size(), 2, "carried loot survives escape")
	_eq(result.companySurvivors, [], "solo result leaves companies to realm adapter")
	_check(JSON.parse_string(JSON.stringify(result)) is Dictionary, "outcome JSON compatible")
	var clear: Dictionary = _state([_enemy("corpse", [0, -1], {"hp": 0})])
	_eq(clear.phase, "cleared", "clear waits for physical extraction")
	_eq(Rules.outcome(clear), {}, "no result before extraction")
	Rules.submit(clear, {"kind": "exit"})
	Rules.advance(clear, 45)
	_eq(Rules.outcome(clear).resolution, "victory", "clear and extract yields victory")
	_check(Rules.outcome(clear).objective.extracted, "result records extraction")

func _test_finish() -> void:
	var state: Dictionary = _state([_enemy("enemy", [0, -1.4], {"behavior": "melee", "attack": 500})])
	Rules.advance(state, 19)
	_eq(Rules.outcome(state).resolution, "defeat", "lethal enemy attack ends encounter")
	_eq(_hero(state).hp, 0, "defeat health is clamped")
	var tick: int = int(state.tick)
	Rules.advance(state, 120)
	_eq(state.tick, tick, "finished encounter cannot keep dealing damage")
	_check(not Rules.submit(state, {"kind": "cast", "ability": "ward"}).ok, "postmortem action rejected")
	var simultaneous: Dictionary = _state([_enemy()])
	Rules.submit(simultaneous, {"kind": "exit"})
	var enemy: Dictionary = Rules.get_actor(simultaneous, "target")
	Rules._start_action(simultaneous, enemy, "attack", "", Vector2.ZERO, "ileana", 45, 20)
	Rules.advance(simultaneous, 45)
	_eq(Rules.outcome(simultaneous), {}, "same-tick enemy hit interrupts extraction")
	_check(not simultaneous.objective.extracted, "interrupted extraction never flags success")
	var lethal: Dictionary = _state([_enemy("target", [0, -1.4], {"attack": 500})])
	Rules.submit(lethal, {"kind": "exit"})
	Rules._start_action(lethal, Rules.get_actor(lethal, "target"), "attack", "", Vector2.ZERO, "ileana", 45, 20)
	Rules.advance(lethal, 45)
	_eq(Rules.outcome(lethal).resolution, "defeat", "death wins simultaneous extraction race")
	var late_projectile: Dictionary = _state([_enemy("target", [0, -1.4], {"attack": 500, "hp": 1, "behavior": "melee"})])
	Rules.advance(late_projectile, 18)
	Rules._projectile(late_projectile, _hero(late_projectile), Vector2(0, -1.4), 100, "fire", false)
	Rules.advance(late_projectile)
	_eq(Rules.outcome(late_projectile).resolution, "defeat", "lethal contact resolves before later projectile phase")
	_eq(Rules.get_actor(late_projectile, "target").hp, 1, "finished result and live state do not diverge from postmortem projectile")

func _wait_idle(state: Dictionary, limit: int = 300) -> void:
	var remaining: int = limit
	while not _hero(state).action.is_empty() and str(state.phase) != "finished" and remaining > 0:
		Rules.advance(state)
		remaining -= 1

func _walk(state: Dictionary, point: Array, limit: int = 600) -> bool:
	_wait_idle(state)
	if not Rules.submit(state, {"kind": "move", "pos": point}).ok:
		return false
	for tick: int in range(limit):
		Rules.advance(state)
		if str(state.phase) == "finished":
			return false
		if _pos(_hero(state)).distance_to(Vector2(float(point[0]), float(point[1]))) < 0.15:
			return true
	return false

func _test_crypt() -> void:
	var enemies: Array = [_enemy("crypt_wolf_1", [-3, 3], {"behavior": "melee", "hp": 45, "maxHp": 45, "attack": 8}), _enemy("crypt_wolf_2", [3, 0], {"behavior": "melee", "hp": 45, "maxHp": 45, "attack": 8}), _enemy("crypt_alpha", [0, -7], {"behavior": "werewolf", "hp": 100, "maxHp": 100, "attack": 12, "armor": 3, "speed": 3.5})]
	var rewards: Array = [{"id": "crypt_weapon", "sourceId": "crypt_alpha", "kind": "item", "itemId": "oathkeeper_blade"}, {"id": "crypt_set", "sourceId": "crypt_alpha", "kind": "item", "itemId": "bellwarden_hood"}, {"id": "crypt_choice", "sourceId": "crypt_alpha", "kind": "choice", "options": ["mist_amulet", "sentinel_ring"]}]
	var state: Dictionary = _state(enemies, {"pos": [0, 8], "mana": 40, "maxMana": 40, "armor": 2}, {"id": "earned_crypt", "lootRewards": rewards, "arena": {"entry": [0, 9], "exit": [0, 10]}})
	var commands: int = 0
	for tick: int in range(5400):
		if str(state.phase) in ["cleared", "finished"]:
			break
		var hero: Dictionary = _hero(state)
		if hero.action.is_empty() and int(state.tick) >= int(hero.restartUntil):
			var nearest: Dictionary = {}
			var distance: float = INF
			for enemy: Dictionary in state.actors:
				if str(enemy.side) == "enemy" and int(enemy.hp) > 0 and _pos(hero).distance_to(_pos(enemy)) < distance:
					nearest = enemy
					distance = _pos(hero).distance_to(_pos(enemy))
			if nearest.is_empty():
				break
			var command: Dictionary = {"kind": "attack", "targetId": str(nearest.id)}
			if int(hero.mana) >= 14 and not hero.statuses.has("ward") and int(hero.cooldowns.get("ward", 0)) <= int(state.tick):
				command = {"kind": "cast", "ability": "ward"}
			elif distance < 2.4 and int(hero.mana) >= 12 and int(hero.cooldowns.get("cleave", 0)) <= int(state.tick):
				command = {"kind": "cast", "ability": "cleave", "pos": nearest.pos}
			if Rules.submit(state, command).ok:
				commands += 1
		Rules.advance(state)
	_eq(state.phase, "cleared", "starter hero earns clear against all registered crypt enemies")
	_check(int(_hero(state).hp) > 0, "starter survives without changing HP or enemy flags")
	_eq(state.objective.progress, 3, "three actual kills registered")
	if str(state.phase) != "cleared":
		return
	for loot: Dictionary in state.loot:
		_check(_walk(state, loot.pos), "hero physically reaches " + str(loot.id))
		var command: Dictionary = {"kind": "interact", "targetId": str(loot.id)}
		if str(loot.kind) == "choice":
			command.choiceId = "mist_amulet"
		_check(Rules.submit(state, command).ok, "physical pickup accepted: " + str(loot.id))
		Rules.advance(state, 10)
	_eq(state.lootClaims.size(), 3, "earned weapon, set piece and one choice")
	_check(_walk(state, [0, 9]), "hero returns to entrance under real movement")
	_check(Rules.submit(state, {"kind": "exit"}).ok, "extraction starts at entrance")
	Rules.advance(state, 45)
	var result: Dictionary = Rules.outcome(state)
	_eq(result.resolution, "victory", "earned run produces valid victory")
	_eq(result.enemySurvivors, [], "enemy casualties are actual deaths")
	_check(result.objective.completed and result.objective.extracted, "clear and extraction both required")
	journey = {"elapsedTicks": result.elapsedTicks, "seconds": float(result.elapsedTicks) / 30.0, "heroHp": result.heroState.hp, "mana": result.heroState.mana, "claims": result.lootClaims.size(), "commands": commands}

func _roundtrip(state: Dictionary, encounter: Dictionary, label: String) -> Dictionary:
	var loaded: Dictionary = Rules.deserialize(Rules.serialize(state), encounter)
	_check(not loaded.is_empty(), label + " restores")
	if not loaded.is_empty():
		_check(Rules.equivalent(state, loaded), label + " preserves every authoritative field")
		if not Rules._same(Rules.snapshot(state), loaded):
			print("SAVE DIFFERENCE " + _difference(Rules.snapshot(state), loaded))
	return loaded

func _difference(a: Variant, b: Variant, path: String = "root") -> String:
	if Rules._same(a, b):
		return ""
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			var found: String = _difference(a[key], b.get(key), path + "." + str(key))
			if not found.is_empty():
				return found
	if a is Array and b is Array and a.size() == b.size():
		for index: int in range(a.size()):
			var found: String = _difference(a[index], b[index], path + "[%d]" % index)
			if not found.is_empty():
				return found
	return path + " = " + ("%.18f / %.18f" % [float(a), float(b)] if (a is int or a is float) and (b is int or b is float) else str(a) + " / " + str(b))

func _test_persistence() -> void:
	var encounter: Dictionary = {"id": "saved_crypt", "kind": "dungeon", "seed": 421, "heroSnapshot": {"id": "vara_flint", "classId":"pyromancer", "raceId":"stormmarked", "factionId":"emberhorn_dominion", "pos": [0, 0], "hp": 120, "maxHp": 120, "mana": 100, "maxMana": 100}, "playerCompanies": [], "enemies": [_enemy("target", [0, -6]), _enemy("corpse", [1, 1], {"hp": 0})], "lootRewards": [{"id": "weapon", "sourceId": "corpse", "kind": "item", "itemId": "oathkeeper_blade"}, {"id": "coins", "sourceId": "corpse", "kind": "gold", "amount": 12}], "arena": {"entry": [0, 0], "exit": [0, 10]}}
	var state: Dictionary = Rules.create(encounter)
	_roundtrip(state, encounter, "initial corpse and unclaimed drops")
	var roll: Dictionary = Rules.create(encounter)
	Rules.submit(roll, {"kind": "dodge", "pos": [3, 0]})
	Rules.advance(roll, 9)
	var resumed_roll: Dictionary = _roundtrip(roll, encounter, "dodge during translation")
	if not resumed_roll.is_empty():
		Rules.advance(roll, 15)
		Rules.advance(resumed_roll, 15)
		_check(Rules.equivalent(roll, resumed_roll), "resumed roll keeps movement endpoint and full get-up recovery")
	var wrong_tick: Dictionary = Rules.snapshot(state)
	wrong_tick.tick = 1
	_check(not Rules.equivalent(state, wrong_tick), "semantic equality still detects changed gameplay timing")
	Rules.submit(state, {"kind": "cast", "ability": "ember", "pos": [0, -6]})
	Rules.advance(state, 5)
	_roundtrip(state, encounter, "uncommitted spell windup")
	Rules.advance(state, 9)
	var loaded: Dictionary = _roundtrip(state, encounter, "live projectile, committed recovery and cooldown")
	if loaded.is_empty():
		return
	Rules.advance(state, 16)
	Rules.advance(loaded, 16)
	_check(Rules._same(state, loaded), "resumed projectile produces identical impact and status")
	_roundtrip(state, encounter, "active burn and next damage tick")
	Rules.submit(state, {"kind": "pause", "paused": true})
	Rules.submit(state, {"kind": "move", "pos": [4, 0]})
	loaded = _roundtrip(state, encounter, "pause with queued intent")
	if loaded.is_empty():
		return
	for model: Dictionary in [state, loaded]:
		Rules.submit(model, {"kind": "pause", "paused": false})
		Rules.advance(model, 90)
	_check(Rules._same(state, loaded), "resumed queue moves identically without resetting time")
	_check(_walk(state, [0, 0]), "save fixture returns through normal movement")
	Rules.submit(state, {"kind": "interact", "targetId": "weapon"})
	Rules.advance(state, 4)
	_roundtrip(state, encounter, "incomplete pickup channel")
	Rules.advance(state, 6)
	_roundtrip(state, encounter, "claimed unique with stable instance ID")
	Rules.submit(state, {"kind": "interact", "targetId": "coins"})
	Rules.advance(state, 10)
	_roundtrip(state, encounter, "fixed registered gold claim")
	Rules.submit(state, {"kind": "exit"})
	Rules.advance(state, 20)
	loaded = _roundtrip(state, encounter, "partially complete extraction")
	if loaded.is_empty():
		return
	Rules.advance(state, 25)
	Rules.advance(loaded, 25)
	_check(Rules._same(Rules.outcome(state), Rules.outcome(loaded)), "resume completes the same once-only result")
	_roundtrip(state, encounter, "finished retreat result")
	var pristine: Dictionary = Rules.snapshot(Rules.create(encounter))
	var mutations: Array = [
		["foreign encounter", func(s: Dictionary) -> void: s.encounterId = "another_crypt"],
		["foreign actor", func(s: Dictionary) -> void: s.actors[1].id = "unregistered"],
		["duplicate actor", func(s: Dictionary) -> void: s.actors.append(s.actors[1].duplicate(true))],
		["changed equipment-derived attack", func(s: Dictionary) -> void: s.actors[0].attack = 9999],
		["over-maximum health", func(s: Dictionary) -> void: s.actors[0].hp = 121],
		["nonfinite position", func(s: Dictionary) -> void: s.actors[0].pos[0] = INF],
		["removed arena wall", func(s: Dictionary) -> void: s.arena.bounds = [-100, -100, 100, 100]],
		["negative tick", func(s: Dictionary) -> void: s.tick = -1],
		["unknown inventory resource", func(s: Dictionary) -> void: s.gold = 100000],
		["invented reward", func(s: Dictionary) -> void: s.lootRewards[0].itemId = "invented_unique"],
		["altered gold reward", func(s: Dictionary) -> void: s.lootRewards[1].amount = 1000],
		["duplicate drop", func(s: Dictionary) -> void: s.loot.append(s.loot[0].duplicate(true))],
		["revived corpse", func(s: Dictionary) -> void: s.actors[2].hp = 100],
		["fictional completed objective", func(s: Dictionary) -> void: s.objective.completed = true],
		["forged status", func(s: Dictionary) -> void: s.actors[0].statuses = {"invincible": {"until": 999999}}],
		["foreign UI event", func(s: Dictionary) -> void: s.events = [{"type": "loot_claimed", "amount": 999}]],
		["non-dictionary actor", func(s: Dictionary) -> void: s.actors[1] = "bad"],
		["malformed path", func(s: Dictionary) -> void: s.actors[0].path = [["x", 0]]],
		["malformed queued command", func(s: Dictionary) -> void: s.paused = true; s.queuedCommand = {"kind": "move", "pos": ["x", 0]}]
	]
	for entry: Array in mutations:
		var altered: Dictionary = pristine.duplicate(true)
		var mutation: Callable = entry[1]
		mutation.call(altered)
		_check(Rules.restore(altered, encounter).is_empty(), "reject " + str(entry[0]))
	var bad_claim: Dictionary = Rules.snapshot(state)
	bad_claim.lootClaims[0].instanceId = "dupe/alternate"
	_check(Rules.restore(bad_claim, encounter).is_empty(), "reject forged item instance claim")
	var duplicate_claim: Dictionary = Rules.snapshot(state)
	duplicate_claim.lootClaims.append(duplicate_claim.lootClaims[0].duplicate(true))
	_check(Rules.restore(duplicate_claim, encounter).is_empty(), "reject duplicate result claim")
	_check(Rules.deserialize("{broken", encounter).is_empty(), "malformed JSON rejected")
	_check(Rules.deserialize("[]", encounter).is_empty(), "non-object JSON rejected")
	_check(Rules.deserialize(Rules.serialize(state), {}).is_empty(), "trusted pending registry is mandatory")

func _test_legacy_path() -> void:
	var path: String = "res://tests/fixtures/dungeons/v4-grazing-path-save.json"
	_check(FileAccess.file_exists(path), "authentic pre-fix movement snapshot is present")
	if not FileAccess.file_exists(path):
		return
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(fixture is Dictionary, "legacy movement fixture parses")
	if not fixture is Dictionary:
		return
	var encounter: Dictionary = fixture.registeredEncounter
	var saved: Dictionary = JSON.parse_string(str(fixture.action))
	var raw_before: String = JSON.stringify(saved)
	var loaded: Dictionary = Rules.restore(saved,encounter)
	_check(not loaded.is_empty(), "genuine old sampler-accepted route still restores")
	if loaded.is_empty():
		return
	_check(Rules.equivalent(saved,loaded), "restoration preserves every field of the original snapshot")
	_eq(JSON.stringify(saved),raw_before, "restoration does not rewrite the input snapshot")
	var endpoint: Array = Rules._p(Rules._v(fixture.command.pos))
	_eq(_hero(loaded).path,[endpoint], "the original direct route remains intact at load")
	var destination: Vector2 = Rules._v(fixture.command.pos)
	_check(not Rules._line_clear(loaded,_pos(_hero(loaded)),destination,float(_hero(loaded).radius)), "fixture captures the genuine corner-grazing legacy segment")
	var fresh: Dictionary = Rules.create(encounter)
	_check(Rules.submit(fresh,fixture.command).ok, "a new command for the same destination is accepted")
	_check(_hero(fresh).path.size() > 1, "new commands already route around the corner")
	var previous: Vector2 = _pos(_hero(fresh))
	var exact_route: bool = true
	for point: Array in _hero(fresh).path:
		exact_route = exact_route and Rules._line_clear(fresh,previous,Rules._v(point),float(_hero(fresh).radius))
		previous = Rules._v(point)
	_check(exact_route, "every leg of a newly accepted path passes exact clearance")
	var replay: Dictionary = Rules.deserialize(str(fixture.action),encounter)
	_check(not replay.is_empty(), "a second independent resume succeeds")
	if replay.is_empty():
		return
	var origin: Vector2 = _pos(_hero(loaded))
	Rules.advance(loaded)
	Rules.advance(replay)
	_check(_hero(loaded).path.size() > 1, "first resumed motion replans the obsolete direct leg")
	_eq(_hero(loaded).path.back(),endpoint, "automatic replanning retains the original player destination")
	_check(_pos(_hero(loaded)).distance_to(origin) > 0.0, "the resumed hero moves on the first tick")
	_check(Rules.equivalent(loaded,replay), "first-tick replanning is deterministic")
	var safe_motion: bool = true
	for tick: int in range(60):
		Rules.advance(loaded)
		Rules.advance(replay)
		safe_motion = safe_motion and Rules._walkable(loaded,_pos(_hero(loaded)),float(_hero(loaded).radius))
	_check(safe_motion, "resumed motion never enters a solid obstacle")
	_check(Rules.equivalent(loaded,replay), "continued movement and enemy AI replay identically")
	_eq(JSON.stringify(saved),raw_before, "continued play cannot mutate the raw saved snapshot")
	var modern_encounter: Dictionary = encounter.duplicate(true)
	modern_encounter.arena["layoutId"] = "current_layout_fixture"
	var modern_saved: Dictionary = saved.duplicate(true)
	modern_saved.arena["layoutId"] = "current_layout_fixture"
	_check(Rules.restore(modern_saved,modern_encounter).is_empty(), "a registered current layout rejects the same obsolete saved leg")
	var mutations: Array = [
		["wall-crossing route",func(s:Dictionary)->void:s.actors[0].path=[[-8,-8]]],
		["off-arena route",func(s:Dictionary)->void:s.actors[0].path=[[500,500]]],
		["nonfinite route",func(s:Dictionary)->void:s.actors[0].path=[[NAN,0]]],
		["forged reward",func(s:Dictionary)->void:s.lootRewards[0].itemId="forged_legendary"],
		["forged committed action",func(s:Dictionary)->void:s.actors[0].action={"kind":"cast","ability":"ward","committed":true}]
	]
	for entry: Array in mutations:
		var invalid: Dictionary = saved.duplicate(true)
		var mutate: Callable = entry[1]
		mutate.call(invalid)
		_check(Rules.restore(invalid,encounter).is_empty(), "legacy route compatibility still rejects " + str(entry[0]))
