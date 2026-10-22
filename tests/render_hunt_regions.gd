extends SceneTree
## Native presentation integration. Run with a real display and imported assets.
## The route issues legal commands to the current rules and captures the actual
## game shell. It is not a performance benchmark or an OS-input playthrough.

const Shell = preload("res://game/redesign/game_shell.gd")
const Realm = preload("res://game/redesign/realm_rules.gd")
const Action = preload("res://game/redesign/action_rules.gd")
const Chart = preload("res://game/redesign/expedition_chart.gd")
var output_dir: String = "/tmp/draconia-hunt-regions-native"
var shell: Control
var checks: int = 0
var failures: Array[String] = []
var captures: Array = []
var locations: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("NATIVE HUNTS: "+message)
	return condition

func _frames(count: int = 3) -> void:
	for frame: int in range(count):
		await process_frame
	await RenderingServer.frame_post_draw

func _hero() -> Dictionary:
	return Action.get_actor(shell.action_state,str(shell.action_state.heroId))

func _v(position: Array) -> Vector2:
	return Vector2(float(position[0]),float(position[1]))

func _sync() -> void:
	shell.stage.sync_state(1.0)
	shell._update_action_hud()
	shell.arena_overlay.queue_redraw()

func _advance(count: int) -> void:
	for tick: int in range(count):
		shell._poll_interaction()
		Action.advance(shell.action_state)
		if str(shell.action_state.phase)=="finished":
			break

func _idle() -> bool:
	for tick: int in range(180):
		if _hero().action.is_empty() and int(shell.action_state.tick)>=int(_hero().restartUntil):
			return true
		_advance(1)
	return false

func _clear_pack() -> bool:
	for tick: int in range(5400):
		if str(shell.action_state.phase) in ["cleared","finished"]:
			break
		var hero: Dictionary = _hero()
		if hero.action.is_empty() and int(shell.action_state.tick)>=int(hero.restartUntil):
			var target: Dictionary = {}
			var distance: float = INF
			for actor: Dictionary in shell.action_state.actors:
				if str(actor.side)=="enemy" and int(actor.hp)>0 and _v(hero.pos).distance_to(_v(actor.pos))<distance:
					target=actor
					distance=_v(hero.pos).distance_to(_v(actor.pos))
			if target.is_empty():
				break
			var command: Dictionary = {"kind":"attack","targetId":str(target.id)}
			if int(hero.mana)>=14 and not hero.statuses.has("ward") and int(hero.cooldowns.get("ward",0))<=int(shell.action_state.tick):
				command={"kind":"cast","ability":"ward"}
			elif distance<2.4 and int(hero.mana)>=12 and int(hero.cooldowns.get("cleave",0))<=int(shell.action_state.tick):
				command={"kind":"cast","ability":"cleave","pos":target.pos}
			Action.submit(shell.action_state,command)
		_advance(1)
	return str(shell.action_state.phase)=="cleared"

func _capture(label: String, dimensions: Vector2i) -> void:
	root.size=dimensions
	await _frames(5)
	_sync()
	await _frames(3)
	var pixels: Image = root.get_texture().get_image()
	var path: String = output_dir.path_join(label+".png")
	_check(DisplayServer.window_get_size()==dimensions,"native window has the requested size: "+label)
	# The project's fixed aspect ratio letterboxes a 960x640 window. The root
	# texture is its 960x600 game content; the native window keeps 20px bars.
	_check(pixels.get_width()<=dimensions.x and pixels.get_height()<=dimensions.y and pixels.get_width()>=dimensions.x-1,"capture contains the full rendered content of this native window: "+label)
	_check(pixels.save_png(path)==OK,"actual game frame saved: "+label)
	var sidebar: Rect2 = shell._sidebar.get_global_rect()
	var button: Button = shell.find_child("ExpeditionReturn",true,false) as Button
	_check(button!=null and sidebar.encloses(button.get_global_rect()),"return action remains inside the visible sidebar: "+label)
	_check(shell.find_child("ExpeditionFieldChart",true,false).size.x>80,"field chart has usable width: "+label)
	if str(Chart.guidance(shell.action_state,true).phase)=="collect":
		var scroll: ScrollContainer = shell._right.get_parent() as ScrollContainer
		for control: Node in shell._loot_box.get_children():
			if control is Button and not control.is_queued_for_deletion():
				_check(scroll.get_global_rect().encloses(control.get_global_rect()),"each available reward action fits without being clipped: "+label)
	captures.append({"file":path.get_file(),"width":pixels.get_width(),"height":pixels.get_height(),"windowSize":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],"layout":str(shell.action_state.arena.get("layoutId","bell_crypt")),"tick":shell.action_state.tick,"phase":Chart.guidance(shell.action_state,true).phase})
	print("NATIVE_CAPTURE ",path)

func _inspect_geometry() -> void:
	var arena: Dictionary = shell.action_state.arena
	_check(shell.stage.registered_obstacle_visuals.size()==arena.obstacles.size(),"every registered obstacle has a native visual")
	for index: int in range(arena.obstacles.size()):
		var obstacle: Node3D = shell.stage.registered_obstacle_visuals[index]
		_check(Realm._same(obstacle.get_meta("collision_rect"),arena.obstacles[index].rect),"visual footprint matches collision rectangle %d" % index)
		var parts: Array = []
		shell.stage._collect_meshes(obstacle,Transform3D.IDENTITY,"",false,parts)
		_check(not parts.is_empty(),"registered obstacle has actual visible mesh geometry")
		var rect: Array = arena.obstacles[index].rect
		var solid_bounds := Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3])).grow(0.015)
		var fits: bool = true
		for part: Dictionary in parts:
			var bound: AABB = part.transform*part.mesh.get_aabb()
			fits=fits and solid_bounds.encloses(Rect2(Vector2(bound.position.x,bound.position.z),Vector2(bound.size.x,bound.size.z)))
		_check(fits,"actual transformed obstacle meshes fit their registered ground footprint %d" % index)
	var exit_position: Vector3 = Vector3(float(arena.exit[0]),0,float(arena.exit[1]))
	_check(shell.stage._exit_marker.position.is_equal_approx(exit_position),"extraction seal uses this location's registered exit")
	var projected: Vector2 = shell.stage.camera.unproject_position(exit_position)
	var picked: Dictionary = shell.stage.pick(projected)
	_check(str(picked.get("kind",""))=="exit" and Realm._same(picked.get("pos",[]),arena.exit),"clicking the visible seal picks the actual location exit")

func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir=argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size=Vector2i(1440,900)
	for slot: int in range(3):
		print("NATIVE_REGION_START ",slot)
		var campaign: Dictionary = Realm.create_realm(711)
		_check(Realm.allocate_attributes(campaign,{"might":1,"vitality":1,"spirit":1}).ok,"allocate legal starting attributes")
		shell=Shell.new()
		shell.qa_no_autoload=true
		shell.qa_no_autosave=true
		shell.sound_enabled=false
		shell.realm=campaign
		root.add_child(shell)
		shell.set_physics_process(false)
		await _frames(2)
		var contract: String = str(shell.realm.huntBoard.offers[slot].id)
		shell._begin_hunt(contract)
		await _frames(3)
		_check(shell.current_view=="dungeon" and not shell.action_state.is_empty(),"real expedition UI enters a registered solo hunt")
		shell.stage.zoom(6)
		_sync()
		_inspect_geometry()
		var layout: String = str(shell.action_state.arena.layoutId)
		_check(shell._send_action({"kind":"cast","ability":"ward"}).ok,"Mara's own Ward starts legally")
		_advance(26)
		_check(_idle(),"Ward finishes its committed animation")
		var enemy: Dictionary = shell.action_state.actors[1]
		_check(shell._send_action({"kind":"attack","targetId":str(enemy.id)}).ok,"select and pursue the actual outer hunter")
		_advance(28)
		_sync()
		_check(not Chart.target_summary(shell.action_state).is_empty(),"native target panel reflects a live selected foe")
		await _capture(layout+"-1440",Vector2i(1440,900))
		shell.stage.zoom(-6)
		await _capture(layout+"-default-camera-1440",Vector2i(1440,900))
		shell.stage.zoom(6)
		if slot==0:
			await _capture(layout+"-1280",Vector2i(1280,800))
			await _capture(layout+"-960",Vector2i(960,640))
		if _check(_clear_pack(),"registered pack defeated through legal commands in "+layout):
			_sync()
			_check(str(Chart.guidance(shell.action_state,true).phase)=="collect","objective switches from combat to actual remaining spoils")
			for loot: Dictionary in shell.action_state.loot:
				var node: Node3D = shell.stage._loot_nodes.get(str(loot.id))
				_check(node!=null and node.position.is_equal_approx(Vector3(float(loot.pos[0]),0,float(loot.pos[1]))),"visible loot stays at its saved pickup point: "+str(loot.id))
			_check(shell.stage._loot_piles.size()<shell.stage._loot_nodes.size(),"keeper rewards share one physical pile without intersecting chests")
			if slot==0:
				await _capture(layout+"-spoils-960",Vector2i(960,640))
			for loot: Dictionary in shell.action_state.loot:
				_check(_idle(),"hero can begin the next reward interaction")
				_sync()
				var loot_node: Node3D = shell.stage._loot_nodes[str(loot.id)]
				var picked: Dictionary = shell.stage.pick(shell.stage.camera.unproject_position(loot_node.position+Vector3(0,0.3,0)))
				_check(str(picked.get("kind",""))=="loot" and str(picked.get("targetId",""))==str(loot.id),"clicking a visible pile picks its next actual unclaimed reward")
				if str(picked.get("kind",""))!="loot":
					continue
				shell._inspect_loot(str(picked.targetId))
				for tick: int in range(1200):
					_advance(1)
					if bool(loot.claimed):
						break
				_check(bool(loot.claimed),"native loot action approaches and collects "+str(loot.id))
			_sync()
			_check(str(Chart.guidance(shell.action_state,true).phase)=="extract","objective names the entrance after every real claim")
			_check(shell.stage._loot_nodes.is_empty(),"claimed chests disappear from the native scene")
			if slot==0:
				await _capture(layout+"-extraction-1280",Vector2i(1280,800))
			_check(_idle(),"hero can begin the native return action")
			shell._request_exit()
			for tick: int in range(1500):
				_advance(1)
				if str(shell.action_state.phase)=="finished":
					break
			_check(str(shell.action_state.phase)=="finished" and not Action.outcome(shell.action_state).is_empty(),"single native return request reaches the correct seal and extracts")
			locations.append({"layout":layout,"tick":shell.action_state.tick,"claims":shell.action_state.lootClaims.duplicate(),"outcome":Action.outcome(shell.action_state)})
		shell._release_owned_audio(true)
		await _frames(4)
		shell.queue_free()
		await _frames(3)
	var report: Dictionary = {"checks":checks,"failures":failures,"captures":captures,"locations":locations,"engine":Engine.get_version_info().string,"scope":"Native scene and HUD integration using legal model commands; software rendering, no OS-input or performance claim."}
	var file: FileAccess = FileAccess.open(output_dir.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	file.close()
	print("NATIVE_HUNTS_SUMMARY ",JSON.stringify({"checks":checks,"failures":failures.size(),"captures":captures.size(),"locations":locations.size()}))
	quit(0 if failures.is_empty() else 1)
