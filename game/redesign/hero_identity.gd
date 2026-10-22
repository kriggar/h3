class_name HeroIdentity
extends RefCounted
## Fixed champion identity. Data includes design targets; permissions expose only
## abilities which actually exist in ActionRules. Unknown identity fails closed.

const ROSTER_PATH: String = "res://data/hero_roster.json"
const CLASSES_PATH: String = "res://data/class_catalog.json"
const SUPPORTED_SKILLS: Array[String] = ["cleave", "ward", "ember", "roots"]
static var _classes: Dictionary = {}
static var _races: Dictionary = {}
static var _heroes: Dictionary = {}
static var _factions: Dictionary = {}
static var _loaded: bool = false

static func _load_catalogs() -> void:
	if _loaded:
		return
	_loaded = true
	var roster: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROSTER_PATH))
	var classes: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLASSES_PATH))
	if not roster is Dictionary or not classes is Dictionary:
		push_error("The hero identity catalogs are missing or malformed.")
		return
	for entry: Dictionary in classes.get("classes", []):
		_classes[str(entry.id)] = entry.duplicate(true)
	for entry: Dictionary in roster.get("ancestries", []):
		_races[str(entry.id)] = entry.duplicate(true)
	for entry: Dictionary in roster.get("factions", []):
		_factions[str(entry.id)] = entry.duplicate(true)
	for entry: Dictionary in roster.get("heroes", []):
		var definition: Dictionary = entry.duplicate(true)
		definition["heroId"] = str(entry.id)
		definition["canonicalId"] = str(entry.id)
		definition["playable"] = str(entry.id) == "mara_veyne"
		_heroes[str(entry.id)] = definition
		for alias: String in entry.get("runtimeAliases", []):
			_heroes[alias] = definition.duplicate(true)

static func class_catalog() -> Dictionary:
	_load_catalogs()
	return _classes.duplicate(true)

static func race_catalog() -> Dictionary:
	_load_catalogs()
	return _races.duplicate(true)

static func faction_catalog() -> Dictionary:
	_load_catalogs()
	return _factions.duplicate(true)

static func hero_catalog() -> Dictionary:
	_load_catalogs()
	# 156 canonical champions plus the legacy internal alias "ileana".
	return _heroes.duplicate(true)

static func hero_definition(hero_or_id: Variant) -> Dictionary:
	_load_catalogs()
	var id: String = str(hero_or_id.get("heroId", hero_or_id.get("id", ""))) if hero_or_id is Dictionary else str(hero_or_id)
	return _heroes.get(id, {}).duplicate(true)

static func class_skills(class_id: String) -> Array:
	_load_catalogs()
	var result: Array = []
	for skill_id: String in _classes.get(class_id, {}).get("supportedSkills", []):
		if SUPPORTED_SKILLS.has(skill_id) and not result.has(skill_id):
			result.append(skill_id)
	return result

static func is_skill_allowed(hero: Dictionary, skill_id: String) -> bool:
	_load_catalogs()
	var definition: Dictionary = hero_definition(hero)
	if not identity_valid(hero):
		return false
	var class_id: String = str(hero.get("classId", definition.get("classId", "")))
	return class_skills(class_id).has(skill_id)

static func identity_valid(hero: Dictionary) -> bool:
	var definition: Dictionary = hero_definition(hero)
	if definition.is_empty():
		return false
	for key: String in ["id", "heroId"]:
		if hero.has(key):
			var named: Dictionary=hero_definition(str(hero[key]))
			if named.is_empty() or str(named.canonicalId)!=str(definition.canonicalId):
				return false
	for key: String in ["classId", "raceId", "factionId"]:
		if hero.has(key) and str(hero[key]) != str(definition[key]):
			return false
	return true

static func class_name_for(hero: Dictionary) -> String:
	_load_catalogs()
	var definition: Dictionary = hero_definition(hero)
	return str(_classes.get(str(hero.get("classId", definition.get("classId", ""))), {}).get("name", "Unknown class"))

static func race_name_for(hero: Dictionary) -> String:
	_load_catalogs()
	var definition: Dictionary = hero_definition(hero)
	return str(_races.get(str(hero.get("raceId", definition.get("raceId", ""))), {}).get("name", "Unknown race"))

static func identity_line(hero: Dictionary) -> String:
	return race_name_for(hero) + " · " + class_name_for(hero)

static func trait_view(hero: Dictionary) -> Dictionary:
	_load_catalogs()
	var definition: Dictionary = hero_definition(hero)
	var race_id: String = str(hero.get("raceId", definition.get("raceId", "")))
	var class_id: String = str(hero.get("classId", definition.get("classId", "")))
	var race: Dictionary = _races.get(race_id, {})
	var racial: Array = race.get("smallPassives", []).duplicate(true)
	if race.has("situationalTrait"):
		racial.append(race.situationalTrait.duplicate(true))
	return {"champion":definition, "class":_classes.get(class_id, {}).duplicate(true), "race":race.duplicate(true), "racialTraits":racial, "personalTraits":definition.get("personalTraits", []).duplicate(true), "supportedSkills":class_skills(class_id)}
