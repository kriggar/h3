class_name BattleRules
extends RefCounted
## Native, deterministic tactical rules shared by the interactive field and tests.

const COLS: int = 17
const ROWS: int = 11

static func unit(type: String) -> Dictionary:
	return CampaignCore.UNITS.get(type, {})

static func point(stack: Dictionary) -> Vector2i:
	return Vector2i(int(stack.get("col", 0)), int(stack.get("row", 0)))

static func valid_hex(p: Vector2i) -> bool:
	return p.x > 0 and p.x < COLS - 1 and p.y >= 0 and p.y < ROWS

static func neighbors(p: Vector2i) -> Array:
	var odd: int = p.y & 1
	var result: Array = []
	for candidate: Vector2i in [Vector2i(p.x - 1, p.y), Vector2i(p.x + 1, p.y), Vector2i(p.x - 1 + odd, p.y - 1), Vector2i(p.x + odd, p.y - 1), Vector2i(p.x - 1 + odd, p.y + 1), Vector2i(p.x + odd, p.y + 1)]:
		if valid_hex(candidate):
			result.append(candidate)
	return result

static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var aq: int = a.x - floori(float(a.y - (a.y & 1)) / 2.0)
	var bq: int = b.x - floori(float(b.y - (b.y & 1)) / 2.0)
	return int((absi(aq - bq) + absi(a.y - b.y) + absi(-aq - a.y + bq + b.y)) / 2)

static func obstacles() -> Dictionary:
	return {Vector2i(7, 2): true, Vector2i(9, 8): true, Vector2i(8, 7): true}

static func reachable(start: Vector2i, speed: int, occupied: Dictionary = {}, terrain: Dictionary = {}) -> Dictionary:
	var first: Dictionary = {"point": start, "distance": 0, "path": []}
	var found: Dictionary = {start: first}
	var queue: Array = [first]
	var index: int = 0
	while index < queue.size():
		var current: Dictionary = queue[index]
		index += 1
		if int(current.distance) >= speed:
			continue
		for next: Vector2i in neighbors(current.point):
			if found.has(next) or occupied.has(next) or terrain.has(next):
				continue
			var path: Array = current.path.duplicate()
			path.append(next)
			var node: Dictionary = {"point": next, "distance": int(current.distance) + 1, "path": path}
			found[next] = node
			queue.append(node)
	return found

static func make_stacks(army: Array, side: String) -> Array:
	var valid: Array = []
	for source: Dictionary in army:
		if not unit(str(source.get("type", ""))).is_empty() and int(source.get("count", 0)) > 0 and valid.size() < 7:
			valid.append(source)
	var result: Array = []
	for index: int in range(valid.size()):
		var source: Dictionary = valid[index]
		var kind: String = str(source.type)
		var count: int = int(source.count)
		result.append({"id": "%s-%d" % [side, index], "type": kind, "side": side, "index": index, "count": count, "initialCount": count, "totalHp": count * int(unit(kind).hp), "col": 2 if side == "player" else 14, "row": roundi(float(index + 1) * float(ROWS - 1) / float(valid.size() + 1)), "shots": int(unit(kind).get("shots", 0)), "waited": false, "defended": false, "retaliated": false})
	return result

static func living(stacks: Array, side: String = "") -> Array:
	var result: Array = []
	for stack: Dictionary in stacks:
		if int(stack.count) > 0 and (side.is_empty() or str(stack.side) == side):
			result.append(stack)
	return result

static func occupied(stacks: Array, except_id: String = "") -> Dictionary:
	var result: Dictionary = {}
	for stack: Dictionary in living(stacks):
		if str(stack.id) != except_id:
			result[point(stack)] = true
	return result

static func movement(stacks: Array, actor: Dictionary, terrain: Dictionary = {}) -> Dictionary:
	var speed: int = int(unit(str(actor.type)).speed)
	var blocks: Dictionary = occupied(stacks, str(actor.id))
	if not bool(unit(str(actor.type)).get("flying", false)):
		return reachable(point(actor), speed, blocks, terrain)
	var result: Dictionary = {}
	for row: int in range(ROWS):
		for col: int in range(1, COLS - 1):
			var destination: Vector2i = Vector2i(col, row)
			var distance: int = hex_distance(point(actor), destination)
			if distance <= speed and not blocks.has(destination) and not terrain.has(destination):
				result[destination] = {"point": destination, "distance": distance, "path": [] if distance == 0 else [destination]}
	return result

static func attack_multiplier(attack: int, defense: int) -> float:
	var difference: int = attack - defense
	if difference >= 0:
		return 1.0 + minf(3.0, float(difference) * 0.05)
	return 1.0 - minf(0.7, float(-difference) * 0.025)

static func stats(stack: Dictionary, hero: Dictionary, context: Dictionary = {}) -> Dictionary:
	var data: Dictionary = unit(str(stack.type))
	var player: bool = str(stack.side) == "player"
	var attack: int = int(data.attack) + (int(hero.get("attack", 0)) + int(context.get("attackBonus", 0)) if player else int(context.get("enemyAttackBonus", 0)))
	var defense: int = int(data.defense) + (int(hero.get("defense", 0)) + int(context.get("defenseBonus", 0)) if player else int(context.get("enemyDefenseBonus", 0)))
	if bool(stack.get("defended", false)):
		defense += maxi(1, floori(float(data.defense) * 0.2))
	return {"attack": attack, "defense": defense, "speed": int(data.speed)}

static func can_shoot(stacks: Array, attacker: Dictionary, defender: Dictionary) -> bool:
	if int(unit(str(attacker.type)).get("shots", 0)) <= 0 or int(attacker.get("shots", 0)) <= 0 or str(attacker.side) == str(defender.side):
		return false
	for other: Dictionary in living(stacks):
		if str(other.side) != str(attacker.side) and hex_distance(point(attacker), point(other)) == 1:
			return false
	return true

static func damage_range(attacker: Dictionary, defender: Dictionary, hero: Dictionary, context: Dictionary = {}, shooting: bool = false) -> Vector2i:
	var data: Dictionary = unit(str(attacker.type))
	var a: Dictionary = stats(attacker, hero, context)
	var d: Dictionary = stats(defender, hero, context)
	var multiplier: float = attack_multiplier(int(a.attack), int(d.defense))
	if not shooting and int(data.get("shots", 0)) > 0:
		multiplier *= 0.5
	if shooting and hex_distance(point(attacker), point(defender)) > 10:
		multiplier *= 0.5
	return Vector2i(maxi(1, floori(float(attacker.count) * float(data.minDamage) * multiplier)), maxi(1, floori(float(attacker.count) * float(data.maxDamage) * multiplier)))

static func damaged(stack: Dictionary, amount: int) -> Dictionary:
	var result: Dictionary = stack.duplicate(true)
	result.totalHp = maxi(0, int(stack.totalHp) - maxi(0, amount))
	result.count = ceili(float(result.totalHp) / float(unit(str(stack.type)).hp))
	return result

static func hit(attacker: Dictionary, defender: Dictionary, hero: Dictionary, context: Dictionary, shooting: bool, rng: RandomNumberGenerator) -> Dictionary:
	var damage: Vector2i = damage_range(attacker, defender, hero, context, shooting)
	var amount: int = rng.randi_range(damage.x, damage.y)
	var after: Dictionary = damaged(defender, amount)
	return {"damage": amount, "killed": int(defender.count) - int(after.count), "after": after}

static func round_order(stacks: Array, round_number: int = 1) -> Array:
	var ordered: Array = living(stacks)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_speed: int = int(unit(str(a.type)).speed)
		var b_speed: int = int(unit(str(b.type)).speed)
		if a_speed != b_speed:
			return a_speed > b_speed
		if str(a.side) == str(b.side):
			return int(a.index) < int(b.index)
		return str(a.side) == ("player" if round_number % 2 == 1 else "enemy")
	)
	var result: Array = []
	for stack: Dictionary in ordered:
		result.append(str(stack.id))
	return result

static func wait_order(order: Array, stack_id: String) -> Array:
	var result: Array = []
	for entry: String in order:
		if entry != stack_id:
			result.append(entry)
	result.append(stack_id)
	return result

static func stack_by_id(stacks: Array, stack_id: String) -> Dictionary:
	for stack: Dictionary in stacks:
		if str(stack.id) == stack_id:
			return stack
	return {}

static func outcome(stacks: Array) -> String:
	if living(stacks, "player").is_empty():
		return "defeat"
	if living(stacks, "enemy").is_empty():
		return "victory"
	return ""

static func attack_plan(stacks: Array, attacker: Dictionary, defender: Dictionary, terrain: Dictionary) -> Dictionary:
	if can_shoot(stacks, attacker, defender):
		return {"shooting": true, "path": []}
	if hex_distance(point(attacker), point(defender)) == 1:
		return {"shooting": false, "path": []}
	var choices: Dictionary = movement(stacks, attacker, terrain)
	var best: Dictionary = {}
	for neighbor: Vector2i in neighbors(point(defender)):
		if choices.has(neighbor):
			var candidate: Dictionary = choices[neighbor]
			if best.is_empty() or int(candidate.distance) < int(best.distance):
				best = candidate
	if best.is_empty():
		return {}
	return {"shooting": false, "path": best.path.duplicate()}

static func choose_action(stacks: Array, actor: Dictionary, hero: Dictionary, context: Dictionary, terrain: Dictionary) -> Dictionary:
	var opponents: Array = living(stacks, "enemy" if str(actor.side) == "player" else "player")
	var options: Array = []
	for target: Dictionary in opponents:
		var plan: Dictionary = attack_plan(stacks, actor, target, terrain)
		if not plan.is_empty():
			var damage: Vector2i = damage_range(actor, target, hero, context, bool(plan.shooting))
			var average: float = float(damage.x + damage.y) / 2.0
			var score: float = minf(float(target.totalHp), average) / float(unit(str(target.type)).hp) + (20.0 if average >= float(target.totalHp) else 0.0) + (2.0 if int(unit(str(target.type)).get("shots", 0)) > 0 else 0.0)
			options.append({"target": str(target.id), "plan": plan, "score": score})
	if not options.is_empty():
		options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
		var best: Dictionary = options[0]
		return {"kind": "attack", "target": best.target, "path": best.plan.path, "shooting": best.plan.shooting}
	var paths: Dictionary = reachable(point(actor), COLS * ROWS, occupied(stacks, str(actor.id)), terrain)
	var best_path: Array = []
	for target: Dictionary in opponents:
		for neighbor: Vector2i in neighbors(point(target)):
			if paths.has(neighbor):
				var path: Array = paths[neighbor].path
				if best_path.is_empty() or path.size() < best_path.size():
					best_path = path
	if not best_path.is_empty():
		return {"kind": "move", "path": best_path.slice(0, int(unit(str(actor.type)).speed))}
	return {"kind": "defend"}

static func spell_target(stacks: Array) -> Dictionary:
	var enemies: Array = living(stacks, "enemy")
	enemies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(b.count) * int(unit(str(b.type)).maxDamage) < int(a.count) * int(unit(str(a.type)).maxDamage))
	return {} if enemies.is_empty() else enemies[0]

static func arrow_damage(hero: Dictionary) -> int:
	return 20 + 15 * int(hero.get("power", 1))

static func healing_amount(stack: Dictionary, hero: Dictionary) -> int:
	return maxi(0, mini(30 + 10 * int(hero.get("power", 1)), int(stack.count) * int(unit(str(stack.type)).hp) - int(stack.totalHp)))

static func result(stacks: Array, mana: int, resolution: String, rounds: int = 1) -> Dictionary:
	var survivors: Array = []
	var remaining: Array = []
	var xp: int = 0
	for stack: Dictionary in stacks:
		if str(stack.side) == "enemy":
			xp += int(stack.initialCount) * int(unit(str(stack.type)).hp)
		if int(stack.count) > 0:
			if str(stack.side) == "player":
				survivors.append({"type": str(stack.type), "count": int(stack.count)})
			else:
				remaining.append({"type": str(stack.type), "count": int(stack.count)})
	return {"victory": resolution == "victory", "retreated": resolution == "retreat", "army": survivors, "mana": mana, "xp": maxi(50, xp) if resolution == "victory" else 0, "enemyRemaining": remaining, "rounds": rounds}

static func _simulation_strike(stacks: Array, attacker: Dictionary, defender: Dictionary, hero: Dictionary, context: Dictionary, shooting: bool, rng: RandomNumberGenerator) -> void:
	if shooting:
		attacker.shots = maxi(0, int(attacker.shots) - 1)
	var strike: Dictionary = hit(attacker, defender, hero, context, shooting, rng)
	defender.merge(strike.after, true)
	if not shooting and int(defender.count) > 0 and not bool(defender.retaliated) and int(attacker.count) > 0:
		defender.retaliated = true
		var retaliation: Dictionary = hit(defender, attacker, hero, context, false, rng)
		attacker.merge(retaliation.after, true)

static func simulate(hero: Dictionary, army: Array, enemies: Array, context: Dictionary = {}, seed_value: int = 1, max_rounds: int = 100) -> Dictionary:
	var stacks: Array = make_stacks(army, "player") + make_stacks(enemies, "enemy")
	var mana: int = maxi(0, int(hero.get("mana", 0)))
	var round_number: int = 1
	var spell_round: int = 0
	var queue: Array = round_order(stacks)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var terrain: Dictionary = obstacles()
	var actions: int = 0
	while round_number <= max_rounds and actions < 10000:
		var resolution: String = outcome(stacks)
		if not resolution.is_empty():
			var completed: Dictionary = result(stacks, mana, resolution, round_number)
			completed["actions"] = actions
			return completed
		while not queue.is_empty() and int(stack_by_id(stacks, str(queue[0])).get("count", 0)) <= 0:
			queue.pop_front()
		if queue.is_empty():
			round_number += 1
			for stack: Dictionary in stacks:
				stack.waited = false
				stack.retaliated = false
			queue = round_order(stacks, round_number)
			continue
		var actor: Dictionary = stack_by_id(stacks, str(queue[0]))
		actor.defended = false
		if str(actor.side) == "player" and spell_round != round_number and mana >= 5:
			var target: Dictionary = spell_target(stacks)
			if not target.is_empty():
				target.merge(damaged(target, arrow_damage(hero)), true)
				mana -= 5
				spell_round = round_number
				if not outcome(stacks).is_empty():
					continue
		var action: Dictionary = choose_action(stacks, actor, hero, context, terrain)
		var path: Array = action.get("path", [])
		if not path.is_empty():
			var destination: Vector2i = path.back()
			actor.col = destination.x
			actor.row = destination.y
		if str(action.kind) == "attack":
			var target: Dictionary = stack_by_id(stacks, str(action.target))
			_simulation_strike(stacks, actor, target, hero, context, bool(action.shooting), rng)
		elif str(action.kind) == "defend":
			actor.defended = true
		queue.pop_front()
		actions += 1
	var stalled: Dictionary = result(stacks, mana, "retreat", round_number)
	stalled["stalemate"] = true
	return stalled
