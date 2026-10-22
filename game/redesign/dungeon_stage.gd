extends "res://game/redesign/environment_kit.gd"

const Action = preload("res://game/redesign/action_rules.gd")
const Appearance = preload("res://game/redesign/hero_appearance.gd")
const Feedback = preload("res://game/redesign/spell_feedback.gd")
const Reflections = preload("res://game/redesign/pbr_lighting.gd")
const HERO_MODEL: String = "res://assets/models/mara/mara.glb"
const WOLF_MODEL: String = "res://assets/models/werewolf/werewolf.glb"

var action_state: Dictionary = {}
var actors: Dictionary = {}
var _loot_nodes: Dictionary = {}
var feedback: Feedback
var sound_enabled: bool = true
var _camera_target: Vector3 = Vector3.ZERO
var _camera_initialized: bool = false
var _zoom: float = 15.0
var _exit_marker: Node3D

func _ready() -> void:
	setup_light(true,false)
	Reflections.apply_reflections(environment)
	feedback=Feedback.new()
	feedback.set_sound_enabled(sound_enabled)
	add_child(feedback)
	terrain(Vector2(24,28),30,true)
	_build_vault()
	if not action_state.is_empty():
		set_state(action_state)

func _build_vault() -> void:
	var wall_mat: StandardMaterial3D = material(Color("656f6d"),0.96,STONE_TEX)
	for x: float in [-10.6,10.6]:
		for index: int in range(7):
			var piece: Node3D = model(FORT,"modular_fort_01_wall_thin_straight_01",self,3.3)
			piece.position = Vector3(x,0,-10.5+index*3.6)
			piece.scale.x = 0.75
			piece.scale.z = 0.95
	for index: int in range(6):
		var rear: Node3D = model(FORT,"modular_fort_01_wall_thin_straight_01",self,4.0)
		rear.position = Vector3(-9.0+index*3.6,0,-12.6)
		rear.rotation.y = PI*0.5
		var near: Node3D = model(FORT,"modular_fort_01_wall_thin_straight_01",self,1.1)
		near.position = Vector3(-9.0+index*3.6,0,12.6)
		near.rotation.y = PI*0.5
	var obstacles: Array = action_state.get("arena",{}).get("obstacles",[])
	for obstacle: Dictionary in obstacles:
		if not obstacle.has("rect"):
			continue
		var rect: Array = obstacle.rect
		var width: float = float(rect[2])
		var depth: float = float(rect[3])
		var center: Vector3 = Vector3(float(rect[0])+width*0.5,0,float(rect[1])+depth*0.5)
		if width < 2 and depth < 2:
			box(self,center+Vector3(0,0.2,0),Vector3(width,0.4,depth),wall_mat)
			cylinder(self,center+Vector3(0,1.4,0),minf(width,depth)*0.43,2.4,stone)
			box(self,center+Vector3(0,2.6,0),Vector3(width,0.35,depth),wall_mat)
		else:
			box(self,center+Vector3(0,0.8,0),Vector3(width,1.6,depth),wall_mat)
			box(self,center+Vector3(0,1.63,0),Vector3(width+0.08,0.18,depth+0.12),stone)
	# Braziers sit in wall niches outside the movement rectangle. Every solid
	# object inside that rectangle is built from the rules' registered obstacles.
	for point: Vector2 in [Vector2(-10.3,7),Vector2(10.3,7),Vector2(-10.3,-6),Vector2(10.3,-6),Vector2(-3,-12.2),Vector2(3,-12.2)]:
		cylinder(self,Vector3(point.x,0.65,point.y),0.18,1.3,bronze)
		cylinder(self,Vector3(point.x,1.35,point.y),0.3,0.2,bronze,0.22)
		fire(self,Vector3(point.x,1.4,point.y),0.85)
	for side: float in [-1,1]:
		for index: int in range(3):
			# Walkable grave slabs are flush with the floor; they are not coffins.
			var slab: MeshInstance3D = box(self,Vector3(side*8.5,0.018,-7.0+index*5.0),Vector3(1.5,0.036,2.5),stone)
			slab.rotation.y = side*0.04
	for index: int in range(7):
		var rock: Node3D = model(ROCKS,"rock_moss_set_02_rock%02d" % (7+index%7),self,0.25+float(index%3)*0.08)
		rock.position = Vector3(-11.3+float(index%2)*22.6,0,-10+index*3)
	banner(self,Vector3(-3,0,-12.4),4.4,Color("493e47"))
	banner(self,Vector3(3,0,-12.4),4.4,Color("493e47"))
	_exit_marker = Node3D.new()
	_exit_marker.position = Vector3(0,0,10)
	_exit_marker.name = "ExtractionSeal"
	add_child(_exit_marker)
	plane(_exit_marker,Vector3(0,0.015,0),Vector2(3.1,2.8),stone)
	_ring(_exit_marker,1.5,Color("9cb17d"),0.05)

func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var player: AnimationPlayer = _find_player(child)
		if player != null:
			return player
	return null

func _ring(parent: Node3D, radius: float, color: Color, y: float = 0.035) -> MeshInstance3D:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = maxf(0.02,radius-0.045)
	mesh.outer_radius = radius
	mesh.rings = 32
	mesh.ring_segments = 6
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	var mat: StandardMaterial3D = material(color,0.8)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	instance.material_override = mat
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position.y = y
	parent.add_child(instance)
	return instance

func _make_actor(actor: Dictionary) -> void:
	var root: Node3D = Node3D.new()
	root.name = "Actor_" + str(actor.id)
	add_child(root)
	var path: String = HERO_MODEL if bool(actor.isHero) else WOLF_MODEL
	if not ResourceLoader.exists(path):
		push_error("An accepted full 3D actor model is required: " + path)
		root.queue_free()
		return
	var body: Node3D = Appearance.instantiate_model(path) if path==HERO_MODEL else (load(path) as PackedScene).instantiate() as Node3D
	var pivot: Node3D = Node3D.new()
	root.add_child(pivot)
	pivot.add_child(body)
	if not bool(actor.isHero):
		var parts: Array = []
		_collect_meshes(body,Transform3D.IDENTITY,"",false,parts)
		var bounds: AABB
		var first: bool = true
		for part: Dictionary in parts:
			var bound: AABB = part.transform * part.mesh.get_aabb()
			bounds = bound if first else bounds.merge(bound)
			first = false
		var height: float = 2.55 if str(actor.id) == "crypt_alpha" else 2.05
		var factor: float = height / maxf(0.01,bounds.size.y)
		pivot.scale = Vector3.ONE*factor
		pivot.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	var player: AnimationPlayer = _find_player(body)
	if player != null:
		player.speed_scale = 0.0
		if player.has_animation("idle"):
			player.play("idle")
	var ring: MeshInstance3D = _ring(root,float(actor.radius)+0.2,Color("cbb778") if bool(actor.isHero) else Color("a04b3b"))
	var telegraph: MeshInstance3D = _ring(root,2.05,Color("e79c51"),0.045)
	telegraph.visible = false
	var appearance: Dictionary = Appearance.apply(body,actor) if bool(actor.isHero) else {}
	actors[str(actor.id)] = {"node":root,"body":body,"pivot":pivot,"visualBaseY":pivot.position.y,"player":player,"ring":ring,"telegraph":telegraph,"hitTick":-100,"appearance":appearance,"droppedSword":null}

func set_sound_enabled(enabled: bool) -> void:
	sound_enabled=enabled
	if feedback!=null:feedback.set_sound_enabled(enabled)

func set_state(state: Dictionary) -> void:
	action_state = state
	if camera == null:
		return
	for actor: Dictionary in state.actors:
		if not actors.has(str(actor.id)):
			_make_actor(actor)
	sync_state(0.0)

func sync_state(delta: float) -> void:
	if action_state.is_empty() or camera == null:
		return
	var hero: Dictionary = Action.get_actor(action_state,str(action_state.heroId))
	var target: Vector3 = Vector3(float(hero.pos[0]),0.7,float(hero.pos[1]))
	if not _camera_initialized:
		_camera_target = target
		_camera_initialized = true
	_camera_target = _camera_target.lerp(target,minf(1.0,delta*6.0))
	camera.size = _zoom
	camera.position = _camera_target + Vector3(15,24,21)
	camera.look_at(_camera_target,Vector3.UP)
	for actor: Dictionary in action_state.actors:
		if not actors.has(str(actor.id)):
			continue
		var visual: Dictionary = actors[str(actor.id)]
		visual.node.position = Vector3(float(actor.pos[0]),0,float(actor.pos[1]))
		var facing: Vector2 = Vector2(float(actor.facing[0]),float(actor.facing[1]))
		if facing.length_squared() > 0.01:
			visual.pivot.rotation.y = atan2(facing.x,facing.y)
		visual.ring.visible = int(actor.hp)>0
		var active: Dictionary = actor.action
		var leap: bool = str(active.get("kind",""))=="leap"
		var warning_end: int = int(active.get("commitTick",0))+(8 if leap else 0)
		visual.telegraph.visible = int(actor.hp)>0 and not bool(actor.isHero) and not active.is_empty() and int(action_state.tick)<warning_end
		if visual.telegraph.visible:
			var radius: float = 1.3 if leap else 2.05
			var warning_mesh: TorusMesh = visual.telegraph.mesh as TorusMesh
			if not is_equal_approx(warning_mesh.outer_radius,radius):
				warning_mesh.inner_radius = radius-0.045
				warning_mesh.outer_radius = radius
			if leap:
				# The aim is locked when the leap starts. Offset from the moving
				# actor keeps this exact-radius warning fixed at the landing point.
				visual.telegraph.position = Vector3(float(active.aim[0])-float(actor.pos[0]),0.045,float(active.aim[1])-float(actor.pos[1]))
				visual.telegraph.scale = Vector3.ONE
			else:
				visual.telegraph.position = Vector3(0,0.045,0)
				var progress: float = clampf(float(int(action_state.tick)-int(active.startTick))/maxf(1,float(int(active.commitTick)-int(active.startTick))),0,1)
				visual.telegraph.scale = Vector3.ONE*(0.6+progress*0.4)
		_sync_animation(visual,actor)
	_sync_loot()
	# Sample the actual weapon only after its native rig has been posed. Status
	# and projectile visuals are reconstructed from the saved rules snapshot.
	if feedback!=null:feedback.sync(action_state,actors,camera)

func _sync_animation(visual: Dictionary, actor: Dictionary) -> void:
	var player: AnimationPlayer = visual.player as AnimationPlayer
	if player == null:
		return
	var clip: String = str(actor.animState)
	var active: Dictionary = actor.action
	var spell: bool = clip=="cast" and str(active.get("kind",""))=="cast" and str(active.get("ability",""))!="cleave"
	var cast_progress: float = -1.0
	if spell and player.has_animation("cast_start"):
		if int(action_state.tick)<int(active.commitTick):
			clip="cast_start"
			cast_progress=clampf(float(int(action_state.tick)-int(active.startTick))/maxf(1,float(int(active.commitTick)-int(active.startTick))),0,1)
		else:
			var recovery: float = clampf(float(int(action_state.tick)-int(active.commitTick))/maxf(1,float(int(active.endTick)-int(active.commitTick))),0,1)
			clip="cast_release" if recovery<0.7 else "cast_end"
			cast_progress=recovery/0.7 if recovery<0.7 else (recovery-0.7)/0.3
	elif clip=="cast":
		# Collection and extraction are sustained interactions, not offensive casts.
		clip="combat_idle" if player.has_animation("combat_idle") else "idle"
	if clip == "guard":
		clip = "combat_idle" if player.has_animation("combat_idle") else "idle"
	if clip == "dodge" and not player.has_animation("dodge"):
		clip = "run"
	if int(action_state.tick)-int(visual.hitTick)<7 and actor.action.is_empty() and int(actor.hp)>0 and player.has_animation("hit"):
		clip = "hit"
	if not player.has_animation(clip):
		clip = "idle"
	var length: float = player.get_animation(clip).length
	var elapsed: float = maxf(0,float(int(action_state.tick)-int(actor.animStartedTick))/Action.TICK_RATE)
	var value: float = fmod(elapsed,maxf(0.001,length))
	if cast_progress>=0:
		value=minf(length*cast_progress,maxf(0,length-0.001))
	elif clip == "death":
		value = minf(elapsed,maxf(0,length-0.001))
	elif clip == "hit":
		value = minf(float(int(action_state.tick)-int(visual.hitTick))/Action.TICK_RATE,maxf(0,length-0.001))
	elif clip=="dodge" and not active.is_empty():
		value=minf(length*clampf(float(int(action_state.tick)-int(active.startTick))/maxf(1,float(int(active.endTick)-int(active.startTick))),0,1),maxf(0,length-0.001))
	elif clip == "run" and bool(actor.isHero):
		value=fmod(elapsed*float(actor.speed)/4.7744,maxf(0.001,length))
	elif clip in ["attack","cast"] and not actor.action.is_empty():
		var action: Dictionary = actor.action
		var now: float = float(action_state.tick)
		var contact: float = 0.44 if clip == "attack" else 0.5
		if now <= float(action.commitTick):
			value = length*contact*clampf((now-float(action.startTick))/maxf(1,float(action.commitTick)-float(action.startTick)),0,1)
		else:
			value = length*(contact+(1.0-contact)*clampf((now-float(action.commitTick))/maxf(1,float(action.endTick)-float(action.commitTick)),0,1))
		value = minf(value,maxf(0,length-0.001))
	if str(player.current_animation) != clip:
		player.play(clip)
	player.seek(value,true)
	# A fitted garment may need a measured clearance envelope during a roll/fall.
	# Always restore the stored visual baseline first: never accumulate offsets or
	# move the actor root, its rules position, collision, or ground status markers.
	var pivot: Node3D = visual.pivot as Node3D
	var body: Node3D = visual.body as Node3D
	var clearance: float = Appearance.visual_clearance(visual.appearance,clip,value)
	pivot.position.y=float(visual.visualBaseY)+clearance*absf(pivot.scale.y*body.scale.y)
	if not visual.appearance.is_empty():
		Appearance.weapon_visible(visual.appearance,not spell and clip!="dodge" and clip!="death")
		var loose_path: String = str(visual.appearance.looseSword)
		if clip=="death" and visual.droppedSword==null and ResourceLoader.exists(loose_path):
			var loose: Node3D = Appearance.instantiate_model(loose_path)
			add_child(loose)
			loose.position=visual.node.position+Vector3(0.75,0.06,0.2)
			loose.rotation=Vector3(PI*0.5,0.65,0.1)
			visual.droppedSword=loose

func _sync_loot() -> void:
	for loot: Dictionary in action_state.loot:
		var id: String = str(loot.id)
		if bool(loot.claimed):
			if _loot_nodes.has(id):
				_loot_nodes[id].queue_free()
				_loot_nodes.erase(id)
			continue
		if not _loot_nodes.has(id):
			var root: Node3D = Node3D.new()
			add_child(root)
			var offset: Vector3 = Vector3(-0.75+float(_loot_nodes.size())*0.5,0,0.8)
			root.position = Vector3(float(loot.pos[0]),0,float(loot.pos[1]))+offset
			var chest: Node3D = model("res://assets/models/treasure_chest/treasure_chest_lod.glb","",root,0.35)
			chest.rotation.y = float(_loot_nodes.size())*0.3
			_ring(root,0.43,Color("bca65b") if str(loot.kind)=="gold" else Color("82af73"),0.03)
			_loot_nodes[id] = root

func show_events(events: Array) -> void:
	for event: Dictionary in events:
		if str(event.type)=="damage" and actors.has(str(event.actorId)):
			actors[str(event.actorId)].hitTick = int(event.get("tick",action_state.tick))
	if feedback!=null:feedback.consume(events,action_state)

func pick(screen_position: Vector2) -> Dictionary:
	for actor: Dictionary in action_state.get("actors",[]):
		if bool(actor.isHero) or int(actor.hp)<=0:
			continue
		var head: Vector3 = Vector3(float(actor.pos[0]),1.0,float(actor.pos[1]))
		var projected: Vector2 = camera.unproject_position(head)
		if projected.distance_to(screen_position)<35:
			return {"kind":"enemy","targetId":str(actor.id),"pos":actor.pos}
	for id: String in _loot_nodes:
		var point: Vector2 = camera.unproject_position(_loot_nodes[id].position+Vector3(0,0.3,0))
		if point.distance_to(screen_position)<22:
			return {"kind":"loot","targetId":id}
	var point: Variant = ground_point(screen_position)
	if point == null:
		return {}
	if Vector2(point.x,point.z).distance_to(Vector2(0,10))<1.6:
		return {"kind":"exit","pos":[0,10]}
	return {"kind":"ground","pos":[point.x,point.z]}

func zoom(amount: float) -> void:
	_zoom = clampf(_zoom+amount,11.0,29.0)
