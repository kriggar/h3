extends SceneTree
const Realm = preload("res://game/redesign/realm_rules.gd")
const Action = preload("res://game/redesign/action_rules.gd")

func _initialize() -> void:
	call_deferred("_run")

func _require(condition: bool, label: String) -> bool:
	if not condition:
		push_error("V4_FIXTURE_FAIL: " + label)
		quit(1)
	return condition

func _run() -> void:
	if not _require(Realm.VERSION == 4,"generator must run the frozen v4 rules"):
		return
	var realm: Dictionary = Realm.create_realm(711)
	if not _require(Realm.allocate_attributes(realm,{"might":1,"vitality":1,"spirit":1}).ok,"legal allocation"):
		return
	var id: String = str(Realm.hunt_board(realm).offers[0].id)
	if not _require(int(realm.huntBoard.version) == 1 and Realm.begin_hunt(realm,id).ok,"original board1 departure"):
		return
	var action: Dictionary = Action.create(realm.pendingEncounter)
	if not _require(str(action.phase) == "running" and Action.submit(action,{"kind":"cast","ability":"ward"}).ok,"legal class action"):
		return
	Action.advance(action,6)
	var hero: Dictionary = Action.get_actor(action,str(action.heroId))
	if not _require(hero.statuses.has("ward") and not hero.action.is_empty(),"committed Ward and recovery are live at fixture tick"):
		return
	var realm_text: String = Realm.serialize(realm)
	var action_text: String = Action.serialize(action)
	var restored_realm: Variant = Realm.deserialize(realm_text)
	if not _require(restored_realm != null,"v4 realm self-roundtrip"):
		return
	var restored: Dictionary = Action.deserialize(action_text,restored_realm.pendingEncounter)
	if not _require(not restored.is_empty() and Action.equivalent(restored,action),"v4 action self-roundtrip"):
		return
	Action.advance(action,60)
	Action.advance(restored,60)
	if not _require(Action.equivalent(restored,action),"v4 frozen continuation"):
		return
	var fixture: Dictionary = {"fixtureSchema":1,"sourceCommit":"9c84ff43ef3f9e1ea444fa90d7dee46a5e1c2b0d","realm":realm_text,"action":action_text,"continuationTicks":60,"expectedContinuation":Action.serialize(action)}
	var file: FileAccess = FileAccess.open("res://v4-active-hunt-save.json",FileAccess.WRITE)
	if not _require(file != null,"fixture output opens"):
		return
	file.store_string(JSON.stringify(fixture,"\t",true,true)+"\n")
	file.close()
	print("V4_FIXTURE_SUMMARY ",JSON.stringify({"realmVersion":realm.version,"huntBoardVersion":realm.huntBoard.version,"templateId":realm.huntBoard.offers[0].templateId,"tick":6,"continuationTick":action.tick,"liveWard":true,"sourceCommit":fixture.sourceCommit}))
	quit(0)
