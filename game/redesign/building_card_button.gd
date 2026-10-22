extends "res://game/redesign/manuscript_button.gd"
## The original painted card remains visible during hover, focus and press.
## Authored 3D work cycles belong to TownStage; a card never swaps to a model.

const Art = preload("res://game/redesign/manuscript_art.gd")
var building_id: String = ""

func _ready() -> void:
	# Resolve by the stable gameplay ID, independently of old rendered-card
	# manifests. Missing/stale model proof cannot disable a valid painted button.
	artwork = Art.building(building_id)
	super._ready()

func _source_proof() -> Dictionary:
	# Kept only so the archived model-hover harness remains parseable. This is
	# never consulted by the painted button, its availability or its input path.
	return {"sourceMatches":false,"status":"historical_model_card_proof_not_applicable","paintedSourcePath":Art.BUILDING_ATLAS,"paintedSourceSha256":Art.BUILDING_ATLAS_SHA256}
