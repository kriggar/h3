extends SceneTree
## Focused regression checks for read-only guidance at action/order boundaries.

const Action = preload("res://game/redesign/action_rules.gd")
const Guide = preload("res://game/redesign/expedition_chart.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _position_is(value: Array, expected: Vector2) -> bool:
	return value.size()==2 and Vector2(float(value[0]),float(value[1])).is_equal_approx(expected)

func _encounter() -> Dictionary:
	return {"encounterId":"guidance_fixture", "kind":"dungeon", "seed":711,
		"hero":{"id":"ileana", "hp":120, "maxHp":120, "mana":40, "maxMana":40, "pos":[0,8]},
		"arena":{"bounds":[-10,-12,10,12], "entry":[0,8], "exit":[4,10], "obstacles":[{"rect":[-1,-2,2,3]}]},
		"enemies":[{"id":"hunter", "pos":[3,-5], "hp":60, "maxHp":60, "behavior":"werewolf"}, {"id":"prowler", "pos":[-3,-8], "hp":40, "maxHp":40, "behavior":"melee"}],
		"lootRewards":[], "objective":{"type":"dungeon_clear"}}

func _run() -> void:
	var encounter: Dictionary = _encounter()
	var state: Dictionary = Action.create(encounter)
	_check(str(state.phase)=="running", "The real action fixture starts legally.")
	var hero: Dictionary = Action.get_actor(state,str(state.heroId))
	_check(Guide.guidance(state,true).phase=="combat", "A live hunt starts in combat guidance.")
	_check(Guide.guidance(state,true).remainingFoes==2, "Combat guidance counts both registered foes.")
	_check(Guide.guidance(state,false).title=="Defeat the vault guardians", "Story guidance uses the vault objective.")
	_check(Guide.target_summary(state).is_empty(), "Unselected foes do not appear in the target readout.")
	_check(Guide.movement_destination(state).is_empty(), "An idle hero has no destination marker.")
	var markers: Array = Guide.map_markers(state)
	_check(markers.size()==2, "The field chart reveals only Mara and the entrance before loot drops.")
	_check(markers[1].pos==[4,10], "The entrance marker uses the registered exit, not a fixed coordinate.")
	for marker: Dictionary in markers:
		_check(str(marker.kind) in ["hero","exit","loot"], "Enemy positions never become chart markers.")
	markers[0].pos[0]=99
	_check(float(hero.pos[0])==0, "Returned marker coordinates cannot mutate the hero snapshot.")
	_check(bool(Action.submit(state,{"kind":"move","pos":[4,7]}).ok), "A walkable movement order is accepted.")
	_check(_position_is(Guide.movement_destination(state),Vector2(4,7)), "The destination shows the accepted route endpoint.")
	_check(not bool(Action.submit(state,{"kind":"move","pos":[0,0]}).ok), "An order inside a registered obstacle is rejected.")
	_check(_position_is(Guide.movement_destination(state),Vector2(4,7)), "A rejected order cannot replace the accepted marker.")
	Action.submit(state,{"kind":"pause","paused":true})
	_check(bool(Action.submit(state,{"kind":"move","pos":[-4,7]}).get("queued",false)), "Paused movement remains a prepared command.")
	_check(_position_is(Guide.movement_destination(state),Vector2(4,7)), "A prepared order does not masquerade as the active route.")
	var resumed: Dictionary=Action.deserialize(Action.serialize(state),encounter)
	_check(not resumed.is_empty(), "The actual paused action snapshot restores successfully.")
	if not resumed.is_empty():
		_check(_position_is(Guide.movement_destination(resumed),Vector2(4,7)), "Save/resume retains the accepted destination.")
		Action.submit(resumed,{"kind":"pause","paused":false})
		_check(_position_is(Guide.movement_destination(resumed),Vector2(-4,7)), "Resuming applies the queued route before displaying its marker.")
	Action.submit(state,{"kind":"pause","paused":false})
	_check(bool(Action.submit(state,{"kind":"attack","targetId":"hunter"}).ok), "The leaping hunter can be selected through a real action order.")
	_check(Guide.movement_destination(state).is_empty(), "Attack pursuit has no misleading manual move marker.")
	var target: Dictionary=Guide.target_summary(state)
	_check(target.role=="Leaping hunter" and int(target.hp)==60, "The selected leaper exposes its real behavior and health.")
	Action.submit(state,{"kind":"attack","targetId":"prowler"})
	_check(Guide.target_summary(state).role=="Melee prowler", "Melee targets receive a distinct role label.")
	var dead_target: Dictionary=state.duplicate(true)
	Action.get_actor(dead_target,"prowler").hp=0
	_check(Guide.target_summary(dead_target).is_empty(), "Dead selections do not retain an active target readout.")
	var victory: Dictionary=state.duplicate(true)
	victory.objective={"completed":true,"progress":2,"target":2}
	victory.loot=[{"claimed":false,"pos":[3,-5]}, {"claimed":false,"pos":[3,-5]}, {"claimed":true,"pos":[-3,-8]}]
	var collection: Dictionary=Guide.guidance(victory,true)
	_check(collection.phase=="collect" and collection.unclaimedSpoils==2, "The collection phase counts only physically unclaimed rewards.")
	_check(Guide.map_markers(victory).size()==4, "Claimed spoils disappear from the field chart.")
	victory.loot[0].claimed=true
	victory.loot[1].claimed=true
	_check(Guide.guidance(victory,true).phase=="extract", "Collecting the final reward advances guidance to extraction.")
	_check(Guide.guidance(victory,false).detail.begins_with("Vault cleared."), "A cleared story revisit retains story wording.")
	# A real cleared revisit still accepts movement for spoils and extraction.
	var cleared_encounter: Dictionary=_encounter()
	for enemy: Dictionary in cleared_encounter.enemies:
		enemy.hp=0
	cleared_encounter.lootRewards=[{"id":"guidance_gold","sourceId":"hunter","kind":"gold","amount":15}]
	var cleared: Dictionary=Action.create(cleared_encounter)
	_check(str(cleared.phase)=="cleared" and Guide.guidance(cleared,true).phase=="collect", "A legitimate cleared revisit starts with its remaining spoils.")
	_check(bool(Action.submit(cleared,{"kind":"move","pos":[3,-5]}).ok), "Cleared encounters accept a route to unclaimed spoils.")
	_check(_position_is(Guide.movement_destination(cleared),Vector2(3,-5)), "The accepted collection route remains visible after combat ends.")
	var finished: Dictionary=cleared.duplicate(true)
	finished.phase="finished"
	_check(Guide.movement_destination(finished).is_empty(), "Finished encounters hide leftover route data.")
	var fallen: Dictionary=cleared.duplicate(true)
	Action.get_actor(fallen,str(fallen.heroId)).hp=0
	_check(Guide.movement_destination(fallen).is_empty(), "A fallen hero cannot display an active destination.")
	cleared_encounter.lootRewards=[]
	var extracting: Dictionary=Action.create(cleared_encounter)
	_check(str(extracting.phase)=="cleared" and Guide.guidance(extracting,true).phase=="extract", "A fully claimed revisit guides the hero to extraction.")
	Action.submit(extracting,{"kind":"pause","paused":true})
	_check(bool(Action.submit(extracting,{"kind":"move","pos":extracting.arena.exit}).get("queued",false)), "The extraction order can be prepared while paused.")
	_check(Guide.movement_destination(extracting).is_empty(), "A queued-only extraction order creates no false active marker.")
	Action.submit(extracting,{"kind":"pause","paused":false})
	_check(_position_is(Guide.movement_destination(extracting),Vector2(4,10)), "The accepted extraction route remains visible in the cleared phase.")
	var before: String=JSON.stringify(victory)
	Guide.guidance(victory,true)
	Guide.target_summary(victory)
	Guide.map_markers(victory)
	Guide.movement_destination(victory)
	_check(JSON.stringify(victory)==before, "Every field-guide query leaves authoritative state unchanged.")
	var reordered: Dictionary=state.duplicate(true)
	reordered.actors.reverse()
	_check(str(Guide.hero_actor(reordered).id)==str(state.heroId), "Mara is identified by heroId, never actor-array order.")
	for bounds: Array in [[-10,-12,10,12],[-16,-8,16,8],[-8,-20,8,20]]:
		for frame_size: Vector2 in [Vector2(150,104),Vector2(196,130),Vector2(244,130)]:
			var available: Rect2=Rect2(Vector2(10,8),frame_size)
			var fitted: Rect2=Guide.fitted_map_rect(bounds,available)
			_check(available.encloses(fitted), "The map fits its responsive frame without clipping.")
			_check(is_equal_approx(fitted.size.x/fitted.size.y,(float(bounds[2])-float(bounds[0]))/(float(bounds[3])-float(bounds[1]))), "The field chart preserves the layout's aspect ratio.")
			_check(Guide.map_point([bounds[0],bounds[1]],bounds,fitted).is_equal_approx(fitted.position), "The north-west bounds map to the correct corner.")
			_check(Guide.map_point([bounds[2],bounds[3]],bounds,fitted).is_equal_approx(fitted.end), "The south-east bounds map to the correct corner.")
	print(JSON.stringify({"suite":"expedition_guidance", "checks":checks, "failures":failures.size(), "messages":failures}))
	quit(0 if failures.is_empty() else 1)
