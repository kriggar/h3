class_name DungeonCatalog
extends RefCounted
## Registered geometry shared by the realm and its native presentation.
## Version 1 is immutable: an old, unfinished contract keeps its exact arena.
## Presentation may dress these obstacles, but may not invent solid obstacles.

const CURRENT_REGISTRY_VERSION: int = 2
const LEGACY_ARENA: Dictionary = {"bounds": [-10, -12, 10, 12], "obstacles": [{"rect": [-10, -3, 8, 0.9]}, {"rect": [2, -3, 8, 0.9]}, {"rect": [-6, 2, 1.4, 1.4]}, {"rect": [4.6, 2, 1.4, 1.4]}], "entry": [0, 9], "exit": [0, 10]}
const LOCATIONS: Dictionary = {
	"hollow_kennels": {
		"layoutId": "briar_kennels",
		"briefing": "Circle the broken pens to separate the pack. The inner yard gives the keeper room to leap.",
		"arena": {
			"bounds": [-12, -12, 12, 12],
			"entry": [-8, 9], "exit": [-8, 10], "layoutId": "briar_kennels",
			"obstacles": [
				{"rect": [-4, 4, 8, 1], "kind": "fence"},
				{"rect": [-12, -3, 8, 1], "kind": "fence"},
				{"rect": [4, -3, 8, 1], "kind": "fence"},
				{"rect": [-1, 0, 2, 1.5], "kind": "rubble"},
				{"rect": [-8, -9, 1, 3], "kind": "fence"}
			]
		},
		"spawns": {"scout": [-7, 3], "hound": [7, 1], "keeper": [0, -8]},
		"legacySpawns": {"scout": [-3, 3], "hound": [3, 0], "keeper": [0, -7]}
	},
	"ashen_watch": {
		"layoutId": "ashen_cellar",
		"briefing": "Use the cellar's side aisles to divide four hunters. Stone piers break a direct pursuit.",
		"arena": {
			"bounds": [-10, -14, 10, 12],
			"entry": [0, 9], "exit": [0, 10], "layoutId": "ashen_cellar",
			"obstacles": [
				{"rect": [-5.5, 2, 2, 2], "kind": "pier"},
				{"rect": [3.5, 2, 2, 2], "kind": "pier"},
				{"rect": [-5.5, -6, 2, 2], "kind": "pier"},
				{"rect": [3.5, -6, 2, 2], "kind": "pier"},
				{"rect": [-1, -3, 2, 3], "kind": "rubble"}
			]
		},
		"spawns": {"scout": [-7, 4], "runner": [7, 1], "lurker": [-6, -9], "keeper": [5, -11]},
		"legacySpawns": {"scout": [-3, 3], "runner": [3, 0], "lurker": [-3, -7], "keeper": [3, -9]}
	},
	"moonfang_underpass": {
		"layoutId": "moonfang_underpass",
		"briefing": "Follow the passage around the rock shoulders. Keep a clear escape lane for the two hunters' leaps.",
		"arena": {
			"bounds": [-8, -17, 8, 12],
			"entry": [0, 9], "exit": [0, 10], "layoutId": "moonfang_underpass",
			"obstacles": [
				{"rect": [-8, -1, 6, 2], "kind": "rubble"},
				{"rect": [2, -9, 6, 2], "kind": "rubble"},
				{"rect": [-1, -14.5, 2, 1], "kind": "rubble"}
			]
		},
		"spawns": {"scout": [-3, 3], "hunter": [3, -5], "keeper": [-3, -13]},
		"legacySpawns": {"scout": [-3, 3], "hunter": [3, -6], "keeper": [-3, -9]}
	}
}

static func arena_for(template_id: String, registry_version: int = CURRENT_REGISTRY_VERSION) -> Dictionary:
	if not registry_version in [1, CURRENT_REGISTRY_VERSION]:
		return {}
	if template_id == "bell_crypt":
		return LEGACY_ARENA.duplicate(true)
	if not LOCATIONS.has(template_id):
		return {}
	return LEGACY_ARENA.duplicate(true) if registry_version == 1 else LOCATIONS[template_id].arena.duplicate(true)

static func layout_id_for(template_id: String, registry_version: int = CURRENT_REGISTRY_VERSION) -> String:
	var arena: Dictionary = arena_for(template_id, registry_version)
	return "" if arena.is_empty() else str(arena.get("layoutId", "bell_crypt"))

static func hero_spawn_for(template_id: String, registry_version: int = CURRENT_REGISTRY_VERSION) -> Array:
	var arena: Dictionary = arena_for(template_id, registry_version)
	if arena.is_empty():
		return []
	return [0, 8] if not arena.has("layoutId") else arena.entry.duplicate()

static func enemy_positions_for(template_id: String, registry_version: int = CURRENT_REGISTRY_VERSION) -> Dictionary:
	if not LOCATIONS.has(template_id) or not registry_version in [1, CURRENT_REGISTRY_VERSION]:
		return {}
	return LOCATIONS[template_id]["legacySpawns" if registry_version == 1 else "spawns"].duplicate(true)

static func briefing_for(template_id: String, registry_version: int = CURRENT_REGISTRY_VERSION) -> String:
	if arena_for(template_id, registry_version).is_empty():
		return ""
	return "A divided stone vault. Reach the keeper, collect the spoils, and return to the entrance seal." if registry_version == 1 or template_id == "bell_crypt" else str(LOCATIONS[template_id].briefing)
