extends SceneTree
## Run only inside a temporary copy of the published source commit.
const Action = preload("res://game/redesign/action_rules.gd")
const SOURCE_COMMIT: String = "9c84ff43ef3f9e1ea444fa90d7dee46a5e1c2b0d"
const SOURCE_SHA256: String = "42d7c1d94de751ecf81fc687ba11897f4ba2ab0752e0fc1fde81c6c4b66791d7"

func _initialize() -> void:
	var source: String = FileAccess.get_file_as_string("res://game/redesign/action_rules.gd")
	if source.sha256_text() != SOURCE_SHA256:
		push_error("This generator requires the exact published ActionRules source.")
		quit(1)
		return
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/dungeons/v4-active-hunt-save.json"))
	var realm: Dictionary = JSON.parse_string(str(fixture.realm))
	var pending: Dictionary = realm.pendingEncounter
	var action: Dictionary = Action.create(pending)
	var destination: Vector2 = Vector2(-5.0004,0.32)
	var command: Dictionary = {"kind":"move","pos":[destination.x,destination.y]}
	if not Action.submit(action,command).ok:
		push_error("The original movement command must be accepted.")
		quit(1)
		return
	var saved: String = Action.serialize(action)
	var restored: Dictionary = Action.deserialize(saved,pending)
	if restored.is_empty() or not Action.equivalent(restored,action):
		push_error("The actual old snapshot must restore through its own rules.")
		quit(1)
		return
	var output: FileAccess = FileAccess.open("res://v4-grazing-path-save.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"schema":"draconia-frozen-v4-grazing-path","sourceCommit":SOURCE_COMMIT,"sourceSha256":source.sha256_text(),"sourceFixture":"v4-active-hunt-save.json","command":command,"registeredEncounter":pending,"action":saved},"\t")+"\n")
	output.close()
	print("V4_GRAZING_FIXTURE_SUMMARY ",JSON.stringify({"sourceCommit":SOURCE_COMMIT,"oldRestores":true,"tick":action.tick,"destination":command.pos}))
	quit(0)
