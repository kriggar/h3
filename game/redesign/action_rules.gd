class_name ActionRules
extends RefCounted
## Authoritative fixed-step action model. Scene animation never applies damage.

const TICK_RATE: int = 30
const STEP: float = 1.0 / 30.0
const MAX_ACTORS: int = 192
const MAX_PROJECTILES: int = 128
const DODGE_TICKS: int = 24
const DODGE_MOVE_TICKS: int = 18
const Identity = preload("res://game/redesign/hero_identity.gd")
# Used only while validating a saved pre-class actor against its old registry.
# This is not a selectable class or permission list for new actions.
const LEGACY_SAVED_SKILLS: Array = ["cleave", "ember", "ward", "roots"]
const ABILITIES: Dictionary = {
	"cleave": {"name": "Cleave", "cost": 12, "cooldown": 90, "windup": 10, "recovery": 14, "range": 2.5},
	"ember": {"name": "Ember", "cost": 10, "cooldown": 48, "windup": 9, "recovery": 12, "range": 14.0},
	"ward": {"name": "Ward", "cost": 14, "cooldown": 210, "windup": 6, "recovery": 8, "range": 8.0},
	"roots": {"name": "Living Roots", "cost": 16, "cooldown": 180, "windup": 12, "recovery": 12, "range": 11.0}
}

static func _v(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Array and value.size() >= 2 and (value[0] is int or value[0] is float) and (value[1] is int or value[1] is float):
		var result: Vector2 = Vector2(float(value[0]), float(value[1]))
		if is_finite(result.x) and is_finite(result.y):
			return result
	return fallback

static func _p(value: Vector2) -> Array:
	return [value.x, value.y]

static func _actor(source: Dictionary, side: String, hero: bool, index: int, legacy_identity: bool = false) -> Dictionary:
	var value: Dictionary = source.duplicate(true)
	var max_hp: int = clampi(int(source.get("maxHp", source.get("hp", 60))), 1, 100000)
	var max_mana: int = clampi(int(source.get("maxMana", source.get("mana", 40 if hero else 0))), 0, 10000)
	value.merge({"id": str(source.get("id", "ileana" if hero else "enemy_%d" % index)), "side": side, "type": str(source.get("type", "ileana" if hero else "wolf")), "isHero": hero, "companyId": str(source.get("companyId", "")), "pos": _p(_v(source.get("pos", [0, 8] if hero else [0, -4]))), "spawnPos": _p(_v(source.get("pos", [0, 8] if hero else [0, -4]))), "facing": [0.0, -1.0] if hero else [0.0, 1.0], "hp": clampi(int(source.get("hp", max_hp)), 0, max_hp), "maxHp": max_hp, "mana": clampi(int(source.get("mana", max_mana)), 0, max_mana), "maxMana": max_mana, "attack": clampi(int(source.get("attack", 18 if hero else 9)), 1, 10000), "armor": clampi(int(source.get("armor", 2 if hero else 0)), 0, 500), "speed": clampf(float(source.get("speed", 4.6 if hero else 3.0)), 0.1, 20.0), "radius": clampf(float(source.get("radius", 0.42 if hero else 0.5)), 0.15, 3.0), "range": clampf(float(source.get("range", 1.8)), 0.4, 30.0), "behavior": str(source.get("behavior", "hero" if hero else "melee")), "animState": "idle", "animStartedTick": 0, "action": {}, "path": [], "targetId": "", "guarding": false, "statuses": {}, "cooldowns": {}, "dodgeReadyAt": 0, "leapReadyAt": 30, "restartUntil": 0, "nextThink": 0, "lastCastTick": -1000, "manaRemainder": 0, "dead": false, "traits": source.get("traits", []).duplicate()}, true)
	var default_skills: Array = []
	if hero:
		if legacy_identity:
			default_skills = LEGACY_SAVED_SKILLS.duplicate()
		else:
			var definition: Dictionary = Identity.hero_definition(value)
			if not definition.is_empty():
				for key: String in ["classId", "raceId", "factionId"]:
					if not value.has(key):
						value[key] = str(definition[key])
				default_skills = Identity.class_skills(str(definition.classId))
	var prepared: Variant = source.get("skills", default_skills)
	value["skills"] = prepared.duplicate() if prepared is Array else []
	return value

static func create(encounter: Dictionary) -> Dictionary:
	return _create(encounter, false)

static func _create(encounter: Dictionary, legacy_identity: bool) -> Dictionary:
	var hero_source: Dictionary = encounter.get("hero", encounter.get("heroSnapshot", {}))
	var arena: Dictionary = encounter.get("arena", {}).duplicate(true)
	arena["bounds"] = arena.get("bounds", [-10.0, -12.0, 10.0, 12.0])
	arena["obstacles"] = arena.get("obstacles", [])
	arena["entry"] = arena.get("entry", [0.0, 9.0])
	arena["exit"] = arena.get("exit", [0.0, 10.0])
	var hero: Dictionary = _actor(hero_source, "player", true, 0, legacy_identity)
	var actors: Array = [hero]
	var ids: Dictionary = {str(hero.id): true}
	var errors: Array = []
	if not Identity.identity_valid(hero):
		errors.append("The hero's fixed class or race is not registered.")
	if hero_source.has("skills") and not hero_source.skills is Array:
		errors.append("Prepared skills must be an array.")
	if not legacy_identity:
		var seen_skills: Dictionary = {}
		for skill: Variant in hero.skills:
			if not skill is String or seen_skills.has(skill) or not Identity.is_skill_allowed(hero, str(skill)):
				errors.append("The prepared kit contains an ability outside the hero's class.")
			seen_skills[skill] = true
	if arena.bounds.size() != 4 or float(arena.bounds[2]) <= float(arena.bounds[0]) or float(arena.bounds[3]) <= float(arena.bounds[1]):
		errors.append("Arena bounds are invalid.")
		arena.bounds = [-10.0, -12.0, 10.0, 12.0]
	for source: Dictionary in encounter.get("enemies", []):
		var enemy: Dictionary = _actor(source, "enemy", false, actors.size())
		if ids.has(str(enemy.id)):
			errors.append("Duplicate actor identifier: " + str(enemy.id))
			continue
		ids[str(enemy.id)] = true
		actors.append(enemy)
	if actors.size() > MAX_ACTORS:
		errors.append("Encounter exceeds the actor budget.")
	var rewards: Array = []
	var reward_ids: Dictionary = {}
	for source: Dictionary in encounter.get("lootRewards", []):
		var reward: Dictionary = source.duplicate(true)
		var reward_id: String = str(reward.get("id", ""))
		if reward_id.is_empty() or reward_ids.has(reward_id) or not ids.has(str(reward.get("sourceId", ""))):
			errors.append("Loot reward has a missing, duplicate or invalid source identifier.")
			continue
		reward_ids[reward_id] = true
		reward["dropped"] = false
		rewards.append(reward)
	var objective_type: String = str(encounter.get("objective", {}).get("type", "dungeon_clear"))
	if not objective_type in ["dungeon_clear", "elimination"]:
		errors.append("This action slice does not implement the requested objective.")
	if not encounter.get("companies", encounter.get("playerCompanies", [])).is_empty():
		errors.append("Company simulation is not enabled in this solo action slice.")
	var state: Dictionary = {"schemaVersion": 1, "encounterId": str(encounter.get("encounterId", encounter.get("id", "action_encounter"))), "kind": str(encounter.get("kind", "dungeon")), "seed": int(encounter.get("seed", 1)), "rng": int(encounter.get("seed", 1)) & 0xffffffff, "tick": 0, "paused": false, "queuedCommand": {}, "pendingExit": false, "phase": "running" if errors.is_empty() else "invalid", "errors": errors, "heroId": str(hero.id), "actors": actors, "projectiles": [], "loot": [], "lootRewards": rewards, "lootClaims": [], "arena": arena, "objective": {"type": objective_type, "completed": false, "progress": 0, "target": actors.size() - 1, "extracted": false}, "events": [], "result": {}, "nextProjectile": 0, "inputSequence": 0}
	if not _walkable(state, _v(hero.pos), float(hero.radius)):
		state.errors.append("Hero starts outside walkable ground.")
		state.phase = "invalid"
	for enemy: Dictionary in actors.slice(1):
		if not _walkable(state, _v(enemy.pos), float(enemy.radius)):
			state.errors.append("Enemy starts outside walkable ground: " + str(enemy.id))
			state.phase = "invalid"
	if errors.is_empty():
		# A revisit carries every registered enemy, including hp=0 corpses.
		# Only still-unclaimed registered rewards are supplied by the realm.
		for actor: Dictionary in actors:
			if int(actor.hp) <= 0:
				_die(state, actor, "")
		_update_objective(state)
	return state

static func get_actor(state: Dictionary, actor_id: String) -> Dictionary:
	for actor: Dictionary in state.get("actors", []):
		if str(actor.id) == actor_id:
			return actor
	return {}

static func snapshot(state: Dictionary) -> Dictionary:
	var result: Dictionary = state.duplicate(true)
	result.events = []
	return result

static func outcome(state: Dictionary) -> Dictionary:
	return state.get("result", {}).duplicate(true)

static func _emit(state: Dictionary, event_type: String, data: Dictionary = {}) -> void:
	var event: Dictionary = data.duplicate(true)
	event["type"] = event_type
	event["tick"] = int(state.tick)
	state.events.append(event)

static func _reject(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}

static func submit(state: Dictionary, command: Dictionary) -> Dictionary:
	if str(state.get("phase", "invalid")) in ["invalid", "finished"]:
		return _reject("This encounter is not accepting actions.")
	var kind: String = str(command.get("kind", ""))
	if kind == "pause":
		state.paused = bool(command.get("paused", not bool(state.paused)))
		_emit(state, "pause_changed", {"paused": bool(state.paused)})
		if not bool(state.paused) and not state.queuedCommand.is_empty():
			var queued: Dictionary = state.queuedCommand.duplicate(true)
			state.queuedCommand.clear()
			var report: Dictionary = submit(state, queued)
			if not bool(report.ok):
				_emit(state, "command_discarded", {"reason": str(report.reason)})
		return {"ok": true, "reason": ""}
	var actor: Dictionary = get_actor(state, str(state.heroId))
	if actor.is_empty() or int(actor.hp) <= 0:
		return _reject("The hero cannot act.")
	if command.has("actorId") and str(command.actorId) != str(actor.id):
		return _reject("This action belongs to the hero.")
	if bool(state.paused):
		# One replaceable intent, validated without mutating the paused model.
		var probe: Dictionary = state.duplicate(true)
		probe.paused = false
		var legal: Dictionary = submit(probe, command)
		if not bool(legal.ok):
			return legal
		state.queuedCommand = command.duplicate(true)
		_emit(state, "command_queued", {"command": state.queuedCommand})
		return {"ok": true, "reason": "", "queued": true}
	var action: Dictionary = actor.action
	if not action.is_empty() and int(state.tick) >= int(action.commitTick):
		return _reject("The current action is committed.")
	if int(state.tick) < int(actor.restartUntil):
		return _reject("The hero is recovering from a cancelled action.")
	var position: Vector2 = _v(actor.pos)
	var destination: Vector2 = _v(command.get("pos", actor.pos), position)
	if kind == "move":
		if not _walkable(state, destination, float(actor.radius)):
			return _reject("That destination is blocked.")
		var route: Array = _path(state, position, destination, float(actor.radius))
		if route.is_empty() and position.distance_to(destination) > 0.15:
			return _reject("No clear route reaches that point.")
		_cancel(state, actor)
		actor.path = route
		actor.targetId = ""
		actor.guarding = false
		_emit(state, "move_started", {"actorId": str(actor.id), "pos": _p(destination)})
	elif kind == "attack":
		var target: Dictionary = get_actor(state, str(command.get("targetId", "")))
		if target.is_empty() or int(target.hp) <= 0 or str(target.side) == "player":
			return _reject("Choose a living enemy.")
		_cancel(state, actor)
		actor.targetId = str(target.id)
		actor.guarding = false
		actor.nextThink = 0
	elif kind == "cast":
		var ability: String = str(command.get("ability", ""))
		if not Identity.is_skill_allowed(actor, ability):
			return _reject("That ability does not belong to this hero's class.")
		if not ABILITIES.has(ability) or not actor.skills.has(ability):
			return _reject("That ability is not prepared.")
		var data: Dictionary = ABILITIES[ability]
		if int(actor.mana) < int(data.cost):
			return _reject("Not enough Focus.")
		if int(actor.cooldowns.get(ability, 0)) > int(state.tick):
			return _reject("That ability is recovering.")
		if position.distance_to(destination) > float(data.range) + 0.01 and ability != "ward":
			return _reject("That point is out of range.")
		if ability in ["ember", "roots"] and not _line_clear(state, position, destination, 0.05):
			return _reject("The target is behind solid cover.")
		if ability == "roots" and not _inside_bounds(state, destination, 0.0):
			return _reject("The target lies outside the battlefield.")
		if ability == "ember" and state.projectiles.size() >= MAX_PROJECTILES:
			return _reject("The projectile budget is temporarily full.")
		_cancel(state, actor)
		actor.targetId = ""
		actor.path = []
		actor.guarding = false
		_start_action(state, actor, "cast", ability, destination, "", int(data.windup), int(data.recovery))
	elif kind == "guard":
		_cancel(state, actor)
		actor.guarding = bool(command.get("guarding", true))
		actor.targetId = ""
		actor.path = []
		if destination.distance_to(position) > 0.01:
			actor.facing = _p((destination - position).normalized())
		_emit(state, "guard_changed", {"actorId": str(actor.id), "guarding": bool(actor.guarding)})
	elif kind == "dodge":
		if int(actor.dodgeReadyAt) > int(state.tick):
			return _reject("Dodge is recovering.")
		if _has_status(actor, "rooted", int(state.tick)):
			return _reject("Roots prevent the dodge.")
		var direction: Vector2 = (destination - position).normalized()
		if direction.length_squared() < 0.5:
			return _reject("Choose a direction to dodge.")
		_cancel(state, actor)
		actor.targetId = ""
		actor.path = []
		actor.guarding = false
		actor.dodgeReadyAt = int(state.tick) + 120
		_start_action(state, actor, "dodge", "", position + direction * 3.0, "", 0, DODGE_TICKS)
	elif kind == "interact":
		var loot: Dictionary = _loot_by_id(state, str(command.get("targetId", "")))
		if loot.is_empty() or bool(loot.get("claimed", false)):
			return _reject("That reward is no longer available.")
		if position.distance_to(_v(loot.pos)) > 1.8:
			return _reject("Move closer to collect the reward.")
		var choice_id: String = str(command.get("choiceId", ""))
		if str(loot.kind) == "choice" and not loot.get("options", []).has(choice_id):
			return _reject("Choose one of the offered rewards.")
		_cancel(state, actor)
		actor.path = []
		actor.targetId = ""
		_start_action(state, actor, "pickup", choice_id, _v(loot.pos), str(loot.id), 9, 0)
	elif kind == "exit":
		var exit_position: Vector2 = _v(state.arena.exit)
		var entry_position: Vector2 = _v(state.arena.entry)
		if minf(position.distance_to(exit_position), position.distance_to(entry_position)) > 1.8:
			return _reject("Reach an exit before leaving the crypt.")
		_cancel(state, actor)
		actor.path = []
		actor.targetId = ""
		_start_action(state, actor, "exit", "", position, "", 45, 0)
	else:
		return _reject("Unknown action.")
	state.inputSequence = int(state.inputSequence) + 1
	return {"ok": true, "reason": ""}

static func _cancel(state: Dictionary, actor: Dictionary) -> void:
	if not actor.action.is_empty():
		_emit(state, "action_cancelled", {"actorId": str(actor.id), "action": str(actor.action.kind)})
		actor.restartUntil = int(state.tick) + 3
	actor.action = {}

static func _start_action(state: Dictionary, actor: Dictionary, kind: String, ability: String, aim: Vector2, target_id: String, windup: int, recovery: int) -> void:
	var direction: Vector2 = aim - _v(actor.pos)
	if direction.length_squared() > 0.0001:
		actor.facing = _p(direction.normalized())
	actor.action = {"kind": kind, "ability": ability, "startTick": int(state.tick), "commitTick": int(state.tick) + windup, "endTick": int(state.tick) + windup + maxi(1, recovery), "aim": _p(aim), "origin": actor.pos.duplicate(), "targetId": target_id, "committed": false, "hitIds": []}
	actor.animState = "dodge" if kind == "dodge" else "attack" if kind in ["attack", "leap"] or ability == "cleave" else "cast"
	actor.animStartedTick = int(state.tick)
	_emit(state, "action_started", {"actorId": str(actor.id), "action": actor.action.duplicate(true), "telegraph": str(actor.side) == "enemy"})

static func _has_status(actor: Dictionary, status_id: String, tick: int) -> bool:
	return actor.statuses.has(status_id) and int(actor.statuses[status_id].until) > tick

static func _status(state: Dictionary, actor: Dictionary, status_id: String, duration: int, data: Dictionary = {}) -> void:
	var effect: Dictionary = data.duplicate(true)
	effect["until"] = int(state.tick) + duration
	if status_id == "ward" and _has_status(actor, status_id, int(state.tick)):
		effect["pool"] = maxi(int(effect.get("pool", 0)), int(actor.statuses[status_id].get("pool", 0)))
	if status_id == "burn":
		effect["nextTick"] = int(state.tick) + 30
		if _has_status(actor, status_id, int(state.tick)):
			effect.nextTick = int(actor.statuses[status_id].get("nextTick", effect.nextTick))
			effect.damage = maxi(int(effect.get("damage", 0)), int(actor.statuses[status_id].get("damage", 0)))
	actor.statuses[status_id] = effect
	_emit(state, "status_applied", {"actorId": str(actor.id), "status": status_id, "effect": effect})

static func advance(state: Dictionary, steps: int = 1) -> Array:
	if str(state.get("phase", "invalid")) == "invalid":
		return []
	for _step: int in range(clampi(steps, 0, 600)):
		if bool(state.paused) or str(state.phase) == "finished":
			break
		state.tick = int(state.tick) + 1
		for actor: Dictionary in state.actors:
			if str(state.phase) == "finished":
				break
			if int(actor.hp) <= 0:
				continue
			_tick_statuses(state, actor)
			if int(actor.hp) <= 0 or str(state.phase) == "finished":
				continue
			if bool(actor.isHero) and int(state.tick) - int(actor.lastCastTick) >= 60:
				actor.manaRemainder = int(actor.manaRemainder) + 2
				if int(actor.manaRemainder) >= TICK_RATE:
					var recovered: int = int(actor.manaRemainder) / TICK_RATE
					actor.mana = mini(int(actor.maxMana), int(actor.mana) + recovered)
					actor.manaRemainder = int(actor.manaRemainder) % TICK_RATE
			if not actor.action.is_empty():
				_tick_action(state, actor)
			else:
				_think(state, actor)
				if actor.action.is_empty():
					_follow_path(state, actor)
		if str(state.phase) == "finished":
			break
		_update_projectiles(state)
		_update_objective(state)
		# Incoming damage on the extraction tick can still interrupt or kill.
		if bool(state.pendingExit):
			state.pendingExit = false
			var hero: Dictionary = get_actor(state, str(state.heroId))
			if str(state.phase) != "finished" and int(hero.hp) > 0 and str(hero.action.get("kind", "")) == "exit":
				state.objective.extracted = true
				_finish(state, "victory" if bool(state.objective.completed) else "retreat", "crypt_cleared" if bool(state.objective.completed) else "escaped_at_entrance")
	var events: Array = state.events.duplicate(true)
	state.events.clear()
	return events

static func _tick_statuses(state: Dictionary, actor: Dictionary) -> void:
	var keys: Array = actor.statuses.keys()
	for key: String in keys:
		var effect: Dictionary = actor.statuses[key]
		if key == "burn" and int(state.tick) >= int(effect.get("nextTick", 0)) and int(state.tick) <= int(effect.until):
			effect.nextTick = int(effect.nextTick) + 30
			_damage(state, str(effect.get("sourceId", "")), actor, int(effect.get("damage", 0)), "fire", _v(actor.pos), false)
		if int(effect.until) <= int(state.tick):
			actor.statuses.erase(key)
			_emit(state, "status_expired", {"actorId": str(actor.id), "status": key})

static func _tick_action(state: Dictionary, actor: Dictionary) -> void:
	var action: Dictionary = actor.action
	if str(action.kind) == "dodge":
		if _has_status(actor, "rooted", int(state.tick)):
			_cancel(state, actor)
			actor.animState = "idle"
			return
		var progress: float = clampf(float(int(state.tick) - int(action.startTick)) / float(DODGE_MOVE_TICKS), 0.0, 1.0)
		var target: Vector2 = _v(action.origin).lerp(_v(action.aim), progress)
		_move_toward(state, actor, target, 3.0 / float(DODGE_MOVE_TICKS) + 0.001)
	if not bool(action.committed) and int(state.tick) >= int(action.commitTick):
		action.committed = true
		_commit(state, actor, action)
	if str(state.phase) == "finished" or int(actor.hp) <= 0:
		return
	if str(action.kind) == "leap" and int(state.tick) > int(action.commitTick) and int(state.tick) <= int(action.commitTick) + 8:
		if _has_status(actor, "rooted", int(state.tick)):
			_cancel(state, actor)
			actor.animState = "idle"
			return
		var progress: float = clampf(float(int(state.tick) - int(action.commitTick)) / 8.0, 0.0, 1.0)
		var target: Vector2 = _v(action.origin).lerp(_v(action.aim), progress)
		_move_toward(state, actor, target, _v(action.origin).distance_to(_v(action.aim)) / 8.0 + 0.01)
		if int(state.tick) == int(action.commitTick) + 8:
			_area_damage(state, actor, _v(actor.pos), 1.3, int(actor.attack) + 5, "physical", false)
	if int(state.tick) >= int(action.endTick):
		actor.action = {}
		actor.animState = "guard" if bool(actor.guarding) else "idle"
		actor.animStartedTick = int(state.tick)

static func _commit(state: Dictionary, actor: Dictionary, action: Dictionary) -> void:
	var kind: String = str(action.kind)
	var ability: String = str(action.ability)
	# Legacy casts which already released keep their committed result. An
	# old saved windup cannot release a newly forbidden class ability or
	# advertise a release event to spell feedback.
	if kind == "cast" and not Identity.is_skill_allowed(actor, ability):
		_emit(state, "action_blocked", {"actorId":str(actor.id), "reason":"class_restriction"})
		return
	_emit(state, "action_committed", {"actorId": str(actor.id), "kind": kind, "ability": ability})
	if kind == "attack":
		if str(actor.behavior) == "ranged":
			_projectile(state, actor, _v(action.aim), int(actor.attack), "physical", false)
		else:
			_melee(state, actor, float(actor.range), int(actor.attack), 80.0, 1)
	elif kind == "cast":
		var data: Dictionary = ABILITIES[ability]
		if ability == "ember" and state.projectiles.size() >= MAX_PROJECTILES:
			_emit(state, "action_blocked", {"actorId": str(actor.id), "reason": "projectile_budget"})
			return
		actor.mana = maxi(0, int(actor.mana) - int(data.cost))
		actor.lastCastTick = int(state.tick)
		actor.cooldowns[ability] = int(state.tick) + int(data.cooldown)
		if ability == "cleave":
			var amount: int = floori(float(actor.attack) * 1.5) + 4
			if actor.traits.has("cleave_ward"):
				amount = floori(float(amount) * 0.85)
			var hits: int = _melee(state, actor, float(data.range), amount, 120.0, 6)
			if hits > 0 and actor.traits.has("cleave_ward"):
				_status(state, actor, "ward", 180, {"pool": mini(24, hits * 8), "sourceId": str(actor.id), "source": "cleave_ward"})
		elif ability == "ember":
			_projectile(state, actor, _v(action.aim), 22 + 3 * int(actor.get("power", 2)), "fire", true)
		elif ability == "ward":
			_status(state, actor, "ward", 180, {"pool": 35 + 5 * int(actor.get("power", 2)) + maxi(0, int(actor.get("wardBonus", 0))), "sourceId": str(actor.id)})
		elif ability == "roots":
			for other: Dictionary in state.actors:
				if int(other.hp) > 0 and str(other.side) != str(actor.side) and _v(other.pos).distance_to(_v(action.aim)) <= 2.0 + float(other.radius):
					_status(state, other, "rooted", 75, {"sourceId": str(actor.id)})
			_emit(state, "ground_effect", {"effect": "roots", "pos": action.aim, "radius": 2.0, "durationTicks": 75})
	elif kind == "pickup":
		_claim_loot(state, actor, str(action.targetId), ability)
	elif kind == "exit":
		state.pendingExit = true

static func _melee(state: Dictionary, actor: Dictionary, reach: float, damage: int, arc_degrees: float, cap: int) -> int:
	var targets: Array = []
	var origin: Vector2 = _v(actor.pos)
	var facing: Vector2 = _v(actor.facing, Vector2(0, -1))
	for target: Dictionary in state.actors:
		if int(target.hp) <= 0 or str(target.side) == str(actor.side):
			continue
		var offset: Vector2 = _v(target.pos) - origin
		if offset.length() <= reach + float(target.radius) and (offset.length() < 0.01 or facing.dot(offset.normalized()) >= cos(deg_to_rad(arc_degrees * 0.5))) and _line_clear(state, origin, _v(target.pos), 0.05):
			targets.append(target)
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da: float = _v(a.pos).distance_squared_to(origin)
		var db: float = _v(b.pos).distance_squared_to(origin)
		return str(a.id) < str(b.id) if is_equal_approx(da, db) else da < db
	)
	var hits: int = 0
	for target: Dictionary in targets.slice(0, cap):
		var report: Dictionary = _damage(state, str(actor.id), target, damage, "physical", origin, true)
		if bool(report.get("contact", false)):
			hits += 1
	return hits

static func _area_damage(state: Dictionary, actor: Dictionary, center: Vector2, radius: float, damage: int, element: String, guardable: bool) -> void:
	for target: Dictionary in state.actors:
		if int(target.hp) > 0 and str(target.side) != str(actor.side) and _v(target.pos).distance_to(center) <= radius + float(target.radius):
			_damage(state, str(actor.id), target, damage, element, _v(actor.pos), guardable)
	_emit(state, "ground_effect", {"effect": "impact", "pos": _p(center), "radius": radius, "durationTicks": 15})

static func _damage(state: Dictionary, source_id: String, target: Dictionary, raw: int, element: String, origin: Vector2, guardable: bool) -> Dictionary:
	if int(target.hp) <= 0:
		return {"contact": false, "damage": 0}
	var action: Dictionary = target.action
	if not action.is_empty() and str(action.kind) == "dodge" and int(state.tick) >= int(action.startTick) + 1 and int(state.tick) <= int(action.startTick) + 5:
		_emit(state, "evaded", {"actorId": str(target.id), "sourceId": source_id})
		return {"contact": false, "damage": 0}
	var reduction: float = minf(0.8, float(target.armor) / (float(target.armor) + 50.0)) if element == "physical" else clampf(float(target.get("resistances", {}).get(element, 0.0)), 0.0, 0.8)
	var amount: int = maxi(1, floori(float(maxi(0, raw)) * (1.0 - reduction))) if raw > 0 else 0
	var blocked: int = 0
	if guardable and bool(target.guarding):
		var to_source: Vector2 = (origin - _v(target.pos)).normalized()
		if _v(target.facing).dot(to_source) >= 0.25:
			blocked = floori(float(amount) * 0.55)
			amount -= blocked
	var absorbed: int = 0
	if _has_status(target, "ward", int(state.tick)):
		var shield: Dictionary = target.statuses.ward
		absorbed = mini(amount, int(shield.pool))
		shield.pool = int(shield.pool) - absorbed
		amount -= absorbed
		if int(shield.pool) <= 0:
			target.statuses.erase("ward")
			_emit(state, "ward_broken", {"actorId": str(target.id)})
	var applied: int = mini(int(target.hp), amount)
	target.hp = maxi(0, int(target.hp) - amount)
	_emit(state, "damage", {"actorId": str(target.id), "targetId": str(target.id), "sourceId": source_id, "amount": applied, "blocked": blocked, "absorbed": absorbed, "element": element, "pos": target.pos})
	if not action.is_empty() and str(action.kind) in ["exit", "pickup"] and applied > 0:
		_cancel(state, target)
	if int(target.hp) <= 0:
		_die(state, target, source_id)
	return {"contact": true, "damage": applied, "absorbed": absorbed, "blocked": blocked}

static func _projectile(state: Dictionary, actor: Dictionary, aim: Vector2, damage: int, element: String, burning: bool) -> void:
	if state.projectiles.size() >= MAX_PROJECTILES:
		_emit(state, "action_blocked", {"actorId": str(actor.id), "reason": "projectile_budget"})
		return
	var direction: Vector2 = (aim - _v(actor.pos)).normalized()
	if direction.length_squared() < 0.5:
		direction = _v(actor.facing)
	state.nextProjectile = int(state.nextProjectile) + 1
	var projectile: Dictionary = {"id": "projectile_%d" % int(state.nextProjectile), "sourceId": str(actor.id), "side": str(actor.side), "pos": _p(_v(actor.pos) + direction * (float(actor.radius) + 0.15)), "direction": _p(direction), "speed": 12.0, "damage": damage, "element": element, "burning": burning, "expires": int(state.tick) + 45, "radius": 0.13}
	state.projectiles.append(projectile)
	_emit(state, "projectile_spawned", {"projectile": projectile})

static func _update_projectiles(state: Dictionary) -> void:
	for index: int in range(state.projectiles.size() - 1, -1, -1):
		if str(state.phase) == "finished":
			break
		var projectile: Dictionary = state.projectiles[index]
		var start: Vector2 = _v(projectile.pos)
		var finish: Vector2 = start + _v(projectile.direction) * float(projectile.speed) * STEP
		var target: Dictionary = {}
		var best_distance: float = 1000000.0
		for candidate: Dictionary in state.actors:
			if int(candidate.hp) <= 0 or str(candidate.side) == str(projectile.side):
				continue
			var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(_v(candidate.pos), start, finish)
			if nearest.distance_to(_v(candidate.pos)) <= float(candidate.radius) + float(projectile.radius):
				var distance: float = start.distance_squared_to(nearest)
				if distance < best_distance and _line_clear(state, start, nearest, float(projectile.radius)):
					best_distance = distance
					target = candidate
		if not target.is_empty():
			var report: Dictionary = _damage(state, str(projectile.sourceId), target, int(projectile.damage), str(projectile.element), start, true)
			if bool(projectile.burning) and bool(report.contact) and int(target.hp) > 0:
				_status(state, target, "burn", 90, {"damage": 3, "sourceId": str(projectile.sourceId)})
			_emit(state, "projectile_hit", {"projectileId": str(projectile.id), "targetId": str(target.id), "pos": target.pos})
			state.projectiles.remove_at(index)
		elif not _line_clear(state, start, finish, float(projectile.radius)) or int(state.tick) >= int(projectile.expires):
			_emit(state, "projectile_removed", {"projectileId": str(projectile.id), "pos": _p(finish)})
			state.projectiles.remove_at(index)
		else:
			projectile.pos = _p(finish)

static func _think(state: Dictionary, actor: Dictionary) -> void:
	if int(state.tick) < int(actor.restartUntil):
		return
	if not bool(actor.isHero) and str(actor.behavior) == "passive":
		return
	var target: Dictionary = get_actor(state, str(actor.targetId)) if bool(actor.isHero) else get_actor(state, str(state.heroId))
	if target.is_empty() or int(target.hp) <= 0:
		if not str(actor.targetId).is_empty():
			actor.targetId = ""
		return
	var distance: float = _v(actor.pos).distance_to(_v(target.pos))
	if not bool(actor.isHero) and distance > float(actor.get("aggroRange", 11.0)):
		actor.path = []
		return
	var ranged: bool = str(actor.behavior) == "ranged"
	var reach: float = float(actor.get("range", 1.8))
	if str(actor.behavior) == "werewolf" and distance >= 3.0 and distance <= 7.0 and int(state.tick) >= int(actor.leapReadyAt) and not _has_status(actor, "rooted", int(state.tick)) and _line_clear(state, _v(actor.pos), _v(target.pos), float(actor.radius)):
		actor.path = []
		actor.leapReadyAt = int(state.tick) + 180
		_start_action(state, actor, "leap", "", _v(target.pos), str(target.id), 27, 20)
		return
	if distance <= reach + float(target.radius) and _line_clear(state, _v(actor.pos), _v(target.pos), 0.05):
		actor.path = []
		_start_action(state, actor, "attack", "", _v(target.pos), str(target.id), 8 if bool(actor.isHero) else 18, 13 if bool(actor.isHero) else 20)
	elif int(state.tick) >= int(actor.nextThink) and not _has_status(actor, "rooted", int(state.tick)):
		actor.nextThink = int(state.tick) + 12
		var direction: Vector2 = (_v(actor.pos) - _v(target.pos)).normalized()
		var destination: Vector2 = _v(target.pos) + direction * (reach * 0.80 if ranged else maxf(0.8, reach * 0.65))
		actor.path = _path(state, _v(actor.pos), destination, float(actor.radius))
		# An approach point beside a valid target can fall inside a corner.
		# Reaching attack range still stops pursuit before bodies overlap.
		if actor.path.is_empty():
			actor.path = _path(state, _v(actor.pos), _v(target.pos), float(actor.radius))

static func _follow_path(state: Dictionary, actor: Dictionary) -> void:
	if _has_status(actor, "rooted", int(state.tick)) or actor.path.is_empty():
		actor.animState = "guard" if bool(actor.guarding) else "idle"
		return
	# Preserve a legacy snapshot at load, then replace only its stale movement
	# route before motion. New commands never use the old sampled clearance.
	if not state.arena.has("layoutId") and not _line_clear(state, _v(actor.pos), _v(actor.path[0]), float(actor.radius)):
		actor.path = _path(state, _v(actor.pos), _v(actor.path.back()), float(actor.radius))
		if actor.path.is_empty():
			actor.animState = "guard" if bool(actor.guarding) else "idle"
			return
	var destination: Vector2 = _v(actor.path[0])
	var before: Vector2 = _v(actor.pos)
	_move_toward(state, actor, destination, float(actor.speed) * STEP * (0.45 if bool(actor.guarding) else 1.0))
	if _v(actor.pos).distance_to(destination) < 0.0001:
		actor.path.pop_front()
	if _v(actor.pos).distance_to(before) > 0.001:
		if str(actor.animState) != "run":
			actor.animStartedTick = int(state.tick)
		actor.animState = "run"
	else:
		actor.animState = "idle"

static func _move_toward(state: Dictionary, actor: Dictionary, destination: Vector2, budget: float) -> void:
	var start: Vector2 = _v(actor.pos)
	var next: Vector2 = start.move_toward(destination, budget)
	if _line_clear(state, start, next, float(actor.radius)):
		# Friendly actors yield; enemies remain soft blocking bodies.
		for other: Dictionary in state.actors:
			if str(other.id) == str(actor.id) or int(other.hp) <= 0 or str(other.side) == str(actor.side):
				continue
			var separation: float = float(actor.radius) + float(other.radius)
			if next.distance_to(_v(other.pos)) < separation * 0.85 and start.distance_to(_v(other.pos)) >= separation * 0.85:
				next = start
				break
		if next.distance_to(start) > 0.00001:
			actor.facing = _p((next - start).normalized())
			actor.pos = _p(next)

static func _inside_bounds(state: Dictionary, position: Vector2, radius: float) -> bool:
	var bounds: Array = state.arena.bounds
	return position.x >= float(bounds[0]) + radius and position.y >= float(bounds[1]) + radius and position.x <= float(bounds[2]) - radius and position.y <= float(bounds[3]) - radius

static func _walkable(state: Dictionary, position: Vector2, radius: float) -> bool:
	if not _inside_bounds(state, position, radius):
		return false
	for obstacle: Dictionary in state.arena.obstacles:
		if obstacle.has("rect"):
			var values: Array = obstacle.rect
			var rect: Rect2 = Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3])).grow(radius)
			if rect.has_point(position):
				return false
		else:
			if position.distance_to(_v(obstacle.get("pos", []))) <= radius + float(obstacle.get("radius", 0.5)):
				return false
	return true

static func _line_clear(state: Dictionary, a: Vector2, b: Vector2, radius: float) -> bool:
	# Bounds are convex: valid endpoints keep the whole segment inside them.
	if not _inside_bounds(state, a, radius) or not _inside_bounds(state, b, radius):
		return false
	for obstacle: Dictionary in state.arena.obstacles:
		if obstacle.has("rect"):
			var values: Array = obstacle.rect
			var rect: Rect2 = Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3])).grow(radius)
			if _segment_hits_rect(a, b, rect):
				return false
		else:
			var center: Vector2 = _v(obstacle.get("pos", []))
			var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(center, a, b)
			if center.distance_to(nearest) <= radius + float(obstacle.get("radius", 0.5)):
				return false
	return true

static func _segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	# Clip the complete segment against each axis instead of sampling points.
	# Match _walkable/Rect2.has_point: minimum edges are included; maximum
	# edges are excluded. In particular, travelling along an excluded edge
	# stays valid, while touching an included corner still blocks the route.
	var enter: float = 0.0
	var leave: float = 1.0
	var enter_included: bool = true
	var leave_included: bool = true
	for axis: int in range(2):
		var origin: float = float(a[axis])
		var delta: float = float(b[axis]) - origin
		var minimum: float = float(rect.position[axis])
		var maximum: float = float(rect.end[axis])
		if delta == 0.0:
			if origin < minimum or origin >= maximum:
				return false
			continue
		var near: float = (minimum - origin) / delta if delta > 0.0 else (maximum - origin) / delta
		var far: float = (maximum - origin) / delta if delta > 0.0 else (minimum - origin) / delta
		var near_included: bool = delta > 0.0
		var far_included: bool = delta < 0.0
		if near > enter:
			enter = near
			enter_included = near_included
		elif near == enter:
			enter_included = enter_included and near_included
		if far < leave:
			leave = far
			leave_included = far_included
		elif far == leave:
			leave_included = leave_included and far_included
		if enter > leave or (enter == leave and not (enter_included and leave_included)):
			return false
	return true

static func _legacy_saved_line_clear(state: Dictionary, a: Vector2, b: Vector2, radius: float) -> bool:
	# Frozen-v4 vaults can contain routes accepted by the old 0.12-unit
	# sampler. This compatibility check is solely for otherwise-valid saves;
	# exact geometry owns every new route and every simulated movement step.
	if state.arena.has("layoutId") or not _walkable(state, a, radius) or not _walkable(state, b, radius):
		return false
	var count: int = maxi(1, ceili(a.distance_to(b) / 0.12))
	# The original vault's diagonal requires fewer than 300 samples.
	if count > 512:
		return false
	for index: int in range(count + 1):
		if not _walkable(state, a.lerp(b, float(index) / float(count)), radius):
			return false
	return true

static func _path(state: Dictionary, start: Vector2, destination: Vector2, radius: float) -> Array:
	if not _walkable(state, destination, radius):
		return []
	if _line_clear(state, start, destination, radius):
		return [_p(destination)]
	var grid: float = 0.75
	var origin: Vector2 = Vector2(float(state.arena.bounds[0]), float(state.arena.bounds[1]))
	var first: Vector2i = Vector2i(roundi((start.x - origin.x) / grid), roundi((start.y - origin.y) / grid))
	var goal: Vector2i = Vector2i(roundi((destination.x - origin.x) / grid), roundi((destination.y - origin.y) / grid))
	var open: Array = [first]
	var costs: Dictionary = {first: 0.0}
	var previous: Dictionary = {}
	var closed: Dictionary = {}
	var visited: int = 0
	while not open.is_empty() and visited < 4096:
		var best_index: int = 0
		var best_score: float = INF
		for index: int in range(open.size()):
			var cell: Vector2i = open[index]
			var score: float = float(costs[cell]) + Vector2(cell - goal).length()
			if score < best_score:
				best_score = score
				best_index = index
		var current: Vector2i = open[best_index]
		open.remove_at(best_index)
		if closed.has(current):
			continue
		closed[current] = true
		visited += 1
		# The actual start, not its rounded grid cell, owns the first links.
		var here: Vector2 = start if current == first else origin + Vector2(current) * grid
		if (current == goal or here.distance_to(destination) < grid) and _line_clear(state, here, destination, radius):
			var reversed: Array = [_p(destination)]
			var cursor: Vector2i = current
			while cursor != first:
				reversed.append(_p(origin + Vector2(cursor) * grid))
				cursor = previous[cursor]
			reversed.reverse()
			# The rounded starting cell is not authoritative: validate the first leg.
			if reversed.is_empty() or not _line_clear(state, start, _v(reversed[0]), radius):
				return []
			return reversed
		for offset: Vector2i in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(1,1)]:
			var next: Vector2i = current + offset
			var next_point: Vector2 = origin + Vector2(next) * grid
			if closed.has(next) or not _line_clear(state, here, next_point, radius):
				continue
			var cost: float = float(costs[current]) + Vector2(offset).length()
			if not costs.has(next) or cost < float(costs[next]):
				costs[next] = cost
				previous[next] = current
				open.append(next)
	return []

static func _die(state: Dictionary, actor: Dictionary, source_id: String) -> void:
	if bool(actor.dead):
		return
	actor.dead = true
	actor.hp = 0
	actor.path = []
	actor.action = {}
	actor.statuses = {}
	actor.animState = "death"
	actor.animStartedTick = int(state.tick)
	_emit(state, "actor_died", {"actorId": str(actor.id), "sourceId": source_id, "pos": actor.pos})
	if bool(actor.isHero):
		_finish(state, "defeat", "ileana_fell")
		return
	for reward: Dictionary in state.lootRewards:
		if str(reward.sourceId) == str(actor.id) and not bool(reward.dropped):
			reward.dropped = true
			var loot: Dictionary = reward.duplicate(true)
			loot["pos"] = actor.pos.duplicate()
			loot["claimed"] = false
			state.loot.append(loot)
			_emit(state, "loot_dropped", {"loot": loot})

static func _loot_by_id(state: Dictionary, loot_id: String) -> Dictionary:
	for loot: Dictionary in state.loot:
		if str(loot.id) == loot_id:
			return loot
	return {}

static func _claim_loot(state: Dictionary, actor: Dictionary, reward_id: String, choice_id: String) -> void:
	var loot: Dictionary = _loot_by_id(state, reward_id)
	if loot.is_empty() or bool(loot.claimed) or _v(actor.pos).distance_to(_v(loot.pos)) > 1.8:
		return
	var kind: String = "item" if str(loot.kind) == "choice" else str(loot.kind)
	var item_id: String = choice_id if str(loot.kind) == "choice" else str(loot.get("itemId", ""))
	if str(loot.kind) == "choice" and not loot.get("options", []).has(item_id):
		return
	var claim_id: String = str(state.encounterId) + "/" + str(loot.id)
	var claim: Dictionary = {"claimId": claim_id, "rewardId": str(loot.id), "kind": kind}
	if kind == "item":
		claim["itemId"] = item_id
		claim["instanceId"] = claim_id + "/" + item_id
	else:
		claim["amount"] = maxi(0, int(loot.get("amount", 0)))
	loot.claimed = true
	state.lootClaims.append(claim)
	_emit(state, "loot_claimed", {"claim": claim})

static func _update_objective(state: Dictionary) -> void:
	if str(state.phase) in ["finished", "invalid"]:
		return
	var remaining: int = 0
	for actor: Dictionary in state.actors:
		if str(actor.side) == "enemy" and int(actor.hp) > 0:
			remaining += 1
	var progress: int = int(state.objective.target) - remaining
	if progress != int(state.objective.progress):
		state.objective.progress = progress
		_emit(state, "objective_changed", {"objective": state.objective})
	if remaining == 0 and not bool(state.objective.completed):
		state.objective.completed = true
		state.phase = "cleared"
		_emit(state, "encounter_cleared", {"objective": state.objective})
		if str(state.kind) != "dungeon":
			_finish(state, "victory", "enemy_defeated")

static func _finish(state: Dictionary, resolution: String, reason: String) -> void:
	if str(state.phase) == "finished":
		return
	var hero: Dictionary = get_actor(state, str(state.heroId))
	var survivors: Array = []
	for actor: Dictionary in state.actors:
		if str(actor.side) == "enemy" and int(actor.hp) > 0:
			survivors.append({"id": str(actor.id), "type": str(actor.type), "hp": int(actor.hp), "maxHp": int(actor.maxHp), "companyId": str(actor.companyId)})
	state.objective.progress = int(state.objective.target) - survivors.size()
	state.objective.completed = survivors.is_empty()
	state.phase = "finished"
	state.result = {"schemaVersion": 1, "encounterId": str(state.encounterId), "kind": str(state.kind), "resolution": resolution, "reason": reason, "elapsedTicks": int(state.tick), "heroState": {"hp": int(hero.hp), "maxHp": int(hero.maxHp), "mana": int(hero.mana), "maxMana": int(hero.maxMana)}, "companySurvivors": [], "enemySurvivors": survivors, "casualties": [], "lootClaims": state.lootClaims.duplicate(true), "objective": state.objective.duplicate(true)}
	_emit(state, "finished", {"result": state.result})

## Save data is always checked against the realm's registered pending encounter.
## It can restore an actual fight, never introduce actors, loot or item-derived stats.
static func serialize(state: Dictionary) -> String:
	return JSON.stringify(snapshot(state), "", true, true)

## Numeric JSON types may change int -> float without changing any rule value.
## Compare authoritative snapshots, preserving every field except drained UI events.
static func equivalent(first: Dictionary, second: Dictionary) -> bool:
	return _same(snapshot(first), snapshot(second))

static func deserialize(encoded: String, registered_encounter: Dictionary) -> Dictionary:
	if encoded.length() > 4194304:
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(encoded) != OK:
		return {}
	var decoded: Variant = parser.data
	if not decoded is Dictionary:
		return {}
	return restore(decoded, registered_encounter)

static func _numeric(value: Variant, minimum: float, maximum: float, whole: bool = false) -> bool:
	if not (value is int or value is float):
		return false
	var number: float = float(value)
	return is_finite(number) and number >= minimum and number <= maximum and (not whole or floor(number) == number)

static func _same(first: Variant, second: Variant) -> bool:
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

static func _keys(value: Dictionary, allowed: Array, required: Array = []) -> bool:
	for key: Variant in value:
		if not key is String or not allowed.has(key):
			return false
	for key: String in required:
		if not value.has(key):
			return false
	return true

static func _point(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _numeric(value[0], -100000.0, 100000.0) and _numeric(value[1], -100000.0, 100000.0)

static func _saved_action_valid(state: Dictionary, actor: Dictionary) -> bool:
	if not actor.action is Dictionary:
		return false
	var action: Dictionary = actor.action
	if action.is_empty():
		return true
	var fields: Array = ["kind", "ability", "startTick", "commitTick", "endTick", "aim", "origin", "targetId", "committed", "hitIds"]
	if not _keys(action, fields, fields) or not action.kind is String or not action.ability is String or not action.targetId is String or not action.committed is bool or not action.hitIds is Array:
		return false
	if not _point(action.aim) or not _point(action.origin) or action.hitIds.size() > 6:
		return false
	action.aim = _p(_v(action.aim))
	action.origin = _p(_v(action.origin))
	if not _numeric(action.startTick, 0, int(state.tick), true):
		return false
	var windup: int = 0
	var recovery: int = 0
	match str(action.kind):
		"attack":
			windup = 8 if bool(actor.isHero) else 18
			recovery = 13 if bool(actor.isHero) else 20
			if not str(action.ability).is_empty() or get_actor(state, str(action.targetId)).is_empty():
				return false
		"cast":
			if not bool(actor.isHero) or not ABILITIES.has(str(action.ability)) or not actor.skills.has(str(action.ability)) or not str(action.targetId).is_empty():
				return false
			windup = int(ABILITIES[str(action.ability)].windup)
			recovery = int(ABILITIES[str(action.ability)].recovery)
		"leap":
			if str(actor.behavior) != "werewolf" or not str(action.ability).is_empty() or get_actor(state, str(action.targetId)).is_empty():
				return false
			windup = 27
			recovery = 20
		"dodge":
			if not bool(actor.isHero) or not str(action.ability).is_empty() or not str(action.targetId).is_empty() or _v(action.origin).distance_to(_v(action.aim)) > 3.001:
				return false
			recovery = DODGE_TICKS
		"pickup":
			if not bool(actor.isHero) or _loot_by_id(state, str(action.targetId)).is_empty():
				return false
			var loot: Dictionary = _loot_by_id(state, str(action.targetId))
			if str(loot.kind) == "choice" and not loot.options.has(str(action.ability)) or str(loot.kind) != "choice" and not str(action.ability).is_empty():
				return false
			windup = 9
		"exit":
			if not bool(actor.isHero) or not str(action.ability).is_empty() or not str(action.targetId).is_empty():
				return false
			if minf(_v(actor.pos).distance_to(_v(state.arena.entry)), _v(actor.pos).distance_to(_v(state.arena.exit))) > 1.8001:
				return false
			windup = 45
		_:
			return false
	if not _numeric(action.commitTick, int(action.startTick) + windup, int(action.startTick) + windup, true) or not _numeric(action.endTick, int(action.startTick) + windup + maxi(1, recovery), int(action.startTick) + windup + maxi(1, recovery), true):
		return false
	if int(action.endTick) <= int(state.tick) or bool(action.committed) != (int(state.tick) >= int(action.commitTick) and int(state.tick) > int(action.startTick)):
		return false
	var hits: Dictionary = {}
	for hit: Variant in action.hitIds:
		if not hit is String or hits.has(hit) or get_actor(state, hit).is_empty():
			return false
		hits[hit] = true
	return true

static func _saved_statuses_valid(state: Dictionary, actor: Dictionary) -> bool:
	if not actor.statuses is Dictionary or actor.statuses.size() > 3:
		return false
	for key: Variant in actor.statuses:
		if not key is String or not actor.statuses[key] is Dictionary:
			return false
		var effect: Dictionary = actor.statuses[key]
		var duration: int = 180 if key == "ward" else 90 if key == "burn" else 75
		if not _numeric(effect.get("until"), int(state.tick) + 1, int(state.tick) + duration, true) or not effect.get("sourceId") is String or get_actor(state, str(effect.sourceId)).is_empty():
			return false
		if key == "ward":
			if not _keys(effect, ["until", "sourceId", "pool", "source"], ["until", "sourceId", "pool"]):
				return false
			var maximum: int = maxi(24, 35 + 5 * int(actor.get("power", 2)) + maxi(0, int(actor.get("wardBonus", 0))))
			if not _numeric(effect.pool, 1, maximum, true) or effect.has("source") and effect.source != "cleave_ward":
				return false
		elif key == "burn":
			if not _keys(effect, ["until", "sourceId", "damage", "nextTick"], ["until", "sourceId", "damage", "nextTick"]) or not _numeric(effect.damage, 3, 3, true) or not _numeric(effect.nextTick, int(state.tick) + 1, int(state.tick) + 30, true):
				return false
		elif key == "rooted":
			if not _keys(effect, ["until", "sourceId"], ["until", "sourceId"]):
				return false
		else:
			return false
	return true

static func _saved_loot_valid(state: Dictionary, baseline: Dictionary) -> bool:
	if not state.lootRewards is Array or not state.loot is Array or not state.lootClaims is Array or state.lootRewards.size() != baseline.lootRewards.size() or state.loot.size() > state.lootRewards.size() or state.lootClaims.size() > state.loot.size():
		return false
	var rewards: Dictionary = {}
	for index: int in range(baseline.lootRewards.size()):
		var original: Dictionary = baseline.lootRewards[index]
		var saved: Variant = state.lootRewards[index]
		if not saved is Dictionary or not saved.get("dropped") is bool:
			return false
		var expected: Dictionary = original.duplicate(true)
		expected.dropped = bool(saved.dropped)
		if not _same(saved, expected):
			return false
		if bool(saved.dropped) != (int(get_actor(state, str(saved.sourceId)).hp) <= 0):
			return false
		rewards[str(saved.id)] = saved
	var drops: Dictionary = {}
	for value: Variant in state.loot:
		if not value is Dictionary or not value.get("id") is String or not rewards.has(value.id) or drops.has(value.id) or not value.get("claimed") is bool:
			return false
		if not _point(value.get("pos")):
			return false
		value.pos = _p(_v(value.pos))
		var reward: Dictionary = rewards[value.id]
		var expected: Dictionary = reward.duplicate(true)
		expected["pos"] = get_actor(state, str(reward.sourceId)).pos.duplicate()
		expected["claimed"] = bool(value.claimed)
		if not bool(reward.dropped) or not _same(value, expected):
			return false
		drops[str(value.id)] = value
	for reward: Dictionary in rewards.values():
		if bool(reward.dropped) != drops.has(str(reward.id)):
			return false
	var claims: Dictionary = {}
	for value: Variant in state.lootClaims:
		if not value is Dictionary or not value.get("rewardId") is String or not drops.has(value.rewardId) or claims.has(value.rewardId):
			return false
		var loot: Dictionary = drops[value.rewardId]
		var kind: String = "item" if str(loot.kind) == "choice" else str(loot.kind)
		var claim_id: String = str(state.encounterId) + "/" + str(loot.id)
		var expected: Dictionary = {"claimId": claim_id, "rewardId": str(loot.id), "kind": kind}
		if kind == "item":
			if not value.get("itemId") is String:
				return false
			var item_id: String = str(value.itemId)
			if str(loot.kind) == "choice" and not loot.options.has(item_id) or str(loot.kind) != "choice" and item_id != str(loot.itemId):
				return false
			expected["itemId"] = item_id
			expected["instanceId"] = claim_id + "/" + item_id
		elif kind == "gold":
			expected["amount"] = int(loot.amount)
		else:
			return false
		if not bool(loot.claimed) or not _same(value, expected):
			return false
		claims[str(value.rewardId)] = true
	for loot: Dictionary in drops.values():
		if bool(loot.claimed) != claims.has(str(loot.id)):
			return false
	return true

static func restore(saved: Dictionary, registered_encounter: Dictionary) -> Dictionary:
	if saved.is_empty() or registered_encounter.is_empty():
		return {}
	var legacy_identity: bool = _uses_legacy_identity(saved, registered_encounter)
	var baseline: Dictionary = _create(registered_encounter, legacy_identity)
	if str(baseline.phase) == "invalid" or not _keys(saved, baseline.keys(), baseline.keys()):
		return {}
	for key: String in ["schemaVersion", "encounterId", "kind", "seed", "rng", "heroId", "arena", "errors"]:
		if not _same(saved[key], baseline[key]):
			return {}
	if not _numeric(saved.tick, 0, 100000000, true) or not _numeric(saved.nextProjectile, 0, 10000000, true) or not _numeric(saved.inputSequence, 0, 10000000, true) or not saved.paused is bool or saved.pendingExit != false or saved.events != [] or not saved.queuedCommand is Dictionary:
		return {}
	if not saved.phase is String or not str(saved.phase) in ["running", "cleared", "finished"] or not saved.actors is Array or saved.actors.size() != baseline.actors.size() or not saved.result is Dictionary:
		return {}
	var state: Dictionary = saved.duplicate(true)
	var mutable: Array = ["pos", "facing", "hp", "mana", "action", "path", "targetId", "guarding", "statuses", "cooldowns", "dodgeReadyAt", "leapReadyAt", "restartUntil", "nextThink", "lastCastTick", "manaRemainder", "dead", "animState", "animStartedTick"]
	for index: int in range(state.actors.size()):
		var value: Variant = state.actors[index]
		var original: Dictionary = baseline.actors[index]
		if not value is Dictionary or not _keys(value, original.keys(), original.keys()):
			return {}
		for key: String in original:
			if not mutable.has(key) and not _same(value[key], original[key]):
				return {}
		if not _numeric(value.hp, 0, int(original.maxHp), true) or not _numeric(value.mana, 0, int(original.maxMana), true) or not _point(value.pos) or not _point(value.facing) or not value.dead is bool or bool(value.dead) != (int(value.hp) == 0) or not value.guarding is bool:
			return {}
		# The simulation uses Godot Vector2 precision. Restore those exact values
		# after JSON's decimal conversion, rather than accumulating roundoff.
		value.pos = _p(_v(value.pos))
		value.facing = _p(_v(value.facing))
		if not _walkable(state, _v(value.pos), float(original.radius)) or absf(_v(value.facing).length() - 1.0) > 0.001 or not value.path is Array or value.path.size() > 4096 or not value.targetId is String:
			return {}
		if not str(value.targetId).is_empty() and get_actor(baseline, str(value.targetId)).is_empty():
			return {}
		var previous: Vector2 = _v(value.pos)
		for path_index: int in range(value.path.size()):
			var point: Variant = value.path[path_index]
			if not _point(point):
				return {}
			if not _line_clear(state, previous, _v(point), float(value.radius)) and not _legacy_saved_line_clear(state, previous, _v(point), float(value.radius)):
				return {}
			value.path[path_index] = _p(_v(point))
			previous = _v(point)
		if not value.animState is String or not str(value.animState) in ["idle", "run", "guard", "dodge", "attack", "cast", "death"] or not _numeric(value.animStartedTick, 0, int(state.tick), true) or not _numeric(value.manaRemainder, 0, TICK_RATE - 1, true):
			return {}
		if bool(value.dead) and (not value.path.is_empty() or not value.action is Dictionary or not value.action.is_empty() or str(value.animState) != "death"):
			return {}
		for timing: String in ["dodgeReadyAt", "leapReadyAt", "restartUntil", "nextThink"]:
			var maximum: int = 120 if timing == "dodgeReadyAt" else 180 if timing == "leapReadyAt" else 3 if timing == "restartUntil" else 12
			if not _numeric(value[timing], 0, int(state.tick) + maximum, true):
				return {}
		if not _numeric(value.lastCastTick, -1000, int(state.tick), true) or not value.cooldowns is Dictionary or value.cooldowns.size() > ABILITIES.size():
			return {}
		for skill: Variant in value.cooldowns:
			if not skill is String or not ABILITIES.has(skill) or not _numeric(value.cooldowns[skill], 0, int(state.tick) + int(ABILITIES[skill].cooldown), true):
				return {}
	if not _saved_loot_valid(state, baseline):
		return {}
	for actor: Dictionary in state.actors:
		if not _saved_action_valid(state, actor) or not _saved_statuses_valid(state, actor):
			return {}
	if not state.projectiles is Array or state.projectiles.size() > MAX_PROJECTILES:
		return {}
	var projectile_ids: Dictionary = {}
	for value: Variant in state.projectiles:
		var fields: Array = ["id", "sourceId", "side", "pos", "direction", "speed", "damage", "element", "burning", "expires", "radius"]
		if not value is Dictionary or not _keys(value, fields, fields) or not value.id is String or not str(value.id).begins_with("projectile_") or projectile_ids.has(value.id) or not value.sourceId is String:
			return {}
		var serial: String = str(value.id).trim_prefix("projectile_")
		if not serial.is_valid_int() or int(serial) < 1 or int(serial) > int(state.nextProjectile):
			return {}
		projectile_ids[str(value.id)] = true
		var source: Dictionary = get_actor(state, str(value.sourceId))
		if source.is_empty() or value.side != source.side or not _point(value.pos) or not _point(value.direction) or absf(_v(value.direction).length() - 1.0) > 0.001 or not _numeric(value.speed, 12, 12) or not _numeric(value.radius, 0.13, 0.13) or not _numeric(value.expires, int(state.tick) + 1, int(state.tick) + 45, true):
			return {}
		value.pos = _p(_v(value.pos))
		value.direction = _p(_v(value.direction))
		var expected_damage: int = 22 + 3 * int(source.get("power", 2)) if bool(source.isHero) else int(source.attack)
		if not _numeric(value.damage, expected_damage, expected_damage, true) or value.element != ("fire" if bool(source.isHero) else "physical") or value.burning != bool(source.isHero) or not _inside_bounds(state, _v(value.pos), 0.0):
			return {}
	if not state.objective is Dictionary or not _keys(state.objective, ["type", "completed", "progress", "target", "extracted"], ["type", "completed", "progress", "target", "extracted"]):
		return {}
	var remaining: int = 0
	for actor: Dictionary in state.actors:
		if str(actor.side) == "enemy" and int(actor.hp) > 0:
			remaining += 1
	var objective: Dictionary = state.objective
	if objective.type != baseline.objective.type or not _numeric(objective.target, int(baseline.objective.target), int(baseline.objective.target), true) or not _numeric(objective.progress, int(objective.target) - remaining, int(objective.target) - remaining, true) or not objective.completed is bool or bool(objective.completed) != (remaining == 0) or not objective.extracted is bool:
		return {}
	var hero: Dictionary = get_actor(state, str(state.heroId))
	if str(state.phase) == "finished":
		var resolution: String = "defeat" if int(hero.hp) == 0 else "victory" if bool(objective.completed) else "retreat"
		var reason: String = "ileana_fell" if resolution == "defeat" else "crypt_cleared" if resolution == "victory" and str(state.kind) == "dungeon" else "enemy_defeated" if resolution == "victory" else "escaped_at_entrance"
		if resolution != "defeat" and str(state.kind) == "dungeon" and not bool(objective.extracted) or resolution == "defeat" and bool(objective.extracted):
			return {}
		var expected: Dictionary = state.duplicate(true)
		expected.phase = "running"
		expected.result = {}
		expected.events = []
		_finish(expected, resolution, reason)
		if not _same(expected.result, state.result):
			return {}
	elif int(hero.hp) <= 0 or not state.result.is_empty() or bool(objective.extracted) or str(state.phase) != ("cleared" if remaining == 0 else "running"):
		return {}
	if not state.queuedCommand.is_empty():
		if not bool(state.paused) or str(state.phase) == "finished" or not _keys(state.queuedCommand, ["kind", "actorId", "targetId", "pos", "ability", "guarding", "choiceId"], ["kind"]) or state.queuedCommand.kind == "pause":
			return {}
		for key: String in ["kind", "actorId", "targetId", "ability", "choiceId"]:
			if state.queuedCommand.has(key) and not state.queuedCommand[key] is String:
				return {}
		if state.queuedCommand.has("pos") and not _point(state.queuedCommand.pos) or state.queuedCommand.has("guarding") and not state.queuedCommand.guarding is bool:
			return {}
		var probe: Dictionary = state.duplicate(true)
		probe.paused = false
		probe.queuedCommand = {}
		if not bool(submit(probe, state.queuedCommand).ok):
			var forbidden_old_skill: bool = legacy_identity and str(state.queuedCommand.get("kind", "")) == "cast" and str(state.queuedCommand.get("actorId", hero.id)) == str(hero.id) and ABILITIES.has(str(state.queuedCommand.get("ability", ""))) and not Identity.is_skill_allowed(hero, str(state.queuedCommand.get("ability", "")))
			if not forbidden_old_skill:
				return {}
			# A queued request has not committed any cost or gameplay effect.
			# Discard it with an explicit event instead of rejecting a valid save.
			state.queuedCommand = {}
			_emit(state, "command_discarded", {"reason":"The queued ability no longer belongs to this hero's class."})
	return state

static func _uses_legacy_identity(saved: Dictionary, registered_encounter: Dictionary) -> bool:
	var source: Variant = registered_encounter.get("hero", registered_encounter.get("heroSnapshot", {}))
	if not source is Dictionary or str(source.get("id", "")) != "ileana" or not saved.get("actors") is Array or saved.actors.is_empty() or not saved.actors[0] is Dictionary:
		return false
	var actor: Dictionary = saved.actors[0]
	for key: String in ["classId", "raceId", "factionId", "heroId"]:
		if source.has(key) or actor.has(key):
			return false
	return not source.has("skills") and _same(actor.get("skills"), LEGACY_SAVED_SKILLS)
