extends Node3D
## Third-person presentation/input. The realm owns movement and combat outcomes.
const C = preload("res://game/online/catalog.gd")
const Avatar = preload("res://game/online/avatar.gd")
const Scenery = preload("res://game/online/scenery.gd")
const WOLF := "res://assets/models/werewolf/werewolf.glb"
signal input_changed(command: Dictionary)
signal action_requested(command: Dictionary)
signal target_changed(id: String)
signal interaction_requested(id: String, kind: String)
var local_id := 1
var state: Dictionary = {}
var target_id := ""
var camera: Camera3D
var controls_enabled := true
var actors: Dictionary = {}
var npcs: Dictionary = {}
var drops: Dictionary = {}
var gathers: Dictionary = {}
var scenery: Node3D
var camera_yaw := 0.0
var camera_pitch := 0.22
var camera_distance := 6.8
var _camera_pivot: Node3D
var _arm: SpringArm3D
var _camera_ready := false
var _panel_open := false
var _orbit_left := false
var _orbit_right := false
var _orbit_distance := 0.0
var _mouse_down := Vector2.ZERO
var _jump_queued := false
var _input_clock := 0.0
var _snapshot_age := 0.0
var _clock := 0.0
var _last_move := Vector3.ZERO
var _last_yaw := PI
var _local_render := Vector3.ZERO
var _models: Dictionary = {}
var _rings: Dictionary = {}

func _ready() -> void:
	scenery=Scenery.new()
	scenery.name="BlackbriarMarch"
	add_child(scenery)
	_camera_pivot=Node3D.new()
	_camera_pivot.name="ThirdPersonRig"
	add_child(_camera_pivot)
	_arm=SpringArm3D.new()
	_arm.spring_length=camera_distance
	_arm.margin=0.24
	_arm.collision_mask=1
	var camera_shape := SphereShape3D.new()
	camera_shape.radius=0.2
	_arm.shape=camera_shape
	_camera_pivot.add_child(_arm)
	camera=Camera3D.new()
	camera.name="ThirdPersonCamera"
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	camera.fov=65.0
	camera.near=0.12
	camera.far=550
	camera.current=true
	_arm.add_child(camera)
	for npc: Dictionary in C.NPCS:_make_npc(npc)
	for gather: Dictionary in C.GATHERS:_make_gather(gather)
	if not state.is_empty():set_snapshot(state,local_id)

func create_character_preview() -> Node3D:
	return Avatar.new()

func set_snapshot(snapshot: Dictionary, player_id: int) -> void:
	state=snapshot
	local_id=player_id
	_snapshot_age=0.0
	if camera==null:return
	var present: Dictionary={}
	for key: String in state.get("players",{}):
		var player: Dictionary=state.players[key]
		var id := "p_"+key
		present[id]=true
		if not actors.has(id):_make_player(id,player)
		actors[id].data=player
		actors[id].label.text=str(player.get("name","Wayfarer"))
		actors[id].avatar.apply_state(player)
	for key: String in state.get("enemies",{}):
		var enemy: Dictionary=state.enemies[key]
		present[key]=true
		if not actors.has(key):_make_enemy(key,enemy)
		actors[key].data=enemy
	for id: String in actors.keys():
		if not present.has(id):
			actors[id].node.queue_free()
			if actors[id].get("telegraph")!=null:actors[id].telegraph.queue_free()
			actors.erase(id)
	for id: String in drops.keys():
		if not state.get("drops",{}).has(id) or int(state.drops[id].get("owner",0)) not in [0,local_id]:
			drops[id].queue_free()
			drops.erase(id)
	for id: String in state.get("drops",{}):
		if int(state.drops[id].get("owner",0)) in [0,local_id] and not drops.has(id):_make_drop(id,state.drops[id])
	for id: String in gathers:
		gathers[id].visible=bool(state.get("gathers",{}).get(id,{"available":true}).get("available",true))
	if not target_id.is_empty() and (not state.get("enemies",{}).has(target_id) or bool(state.enemies[target_id].get("dead",false))):select_target("")

func set_panel_open(open: bool) -> void:
	_panel_open=open
	if open:
		_release_mouse()
		input_changed.emit({"move":[0.0,0.0],"yaw":_last_yaw,"jump":false})

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_mouse()
		_jump_queued=false
		input_changed.emit({"move":[0.0,0.0],"yaw":_last_yaw,"jump":false})

func _release_mouse() -> void:
	_orbit_left=false
	_orbit_right=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		_release_mouse()
		return
	if not controls_enabled or _panel_open:return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			camera_distance=clampf(camera_distance+(-0.7 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 0.7),2.3,14.0)
			get_viewport().set_input_as_handled()
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
			if event.pressed:
				_mouse_down=event.position
				_orbit_distance=0.0
			if event.button_index==MOUSE_BUTTON_LEFT:_orbit_left=event.pressed
			else:_orbit_right=event.pressed
			if _orbit_left or _orbit_right:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
				Input.warp_mouse(_mouse_down)
				if event.button_index==MOUSE_BUTTON_LEFT and _orbit_distance<6.0:_pick_target(_mouse_down)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and (_orbit_left or _orbit_right):
		camera_yaw-=event.relative.x*0.0033
		camera_pitch=clampf(camera_pitch+event.relative.y*0.0027,-0.12,1.05)
		_orbit_distance+=event.relative.length()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB:
				cycle_target()
				get_viewport().set_input_as_handled()
			KEY_F:
				interact_nearest()
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_jump_queued=true
				get_viewport().set_input_as_handled()

func _process(dt: float) -> void:
	_clock+=dt
	_snapshot_age=minf(0.2,_snapshot_age+dt)
	_input_clock+=dt
	var local: Dictionary=state.get("players",{}).get(str(local_id),{})
	var input_active := controls_enabled and not _panel_open and not local.is_empty() and not bool(local.get("dead",false)) and get_window().has_focus()
	_last_move=Vector3.ZERO
	if not local.is_empty():_last_yaw=float(local.get("yaw",_last_yaw))
	if input_active:
		var side := float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
		var forward := float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S))
		_last_move=Vector3(cos(camera_yaw)*side-sin(camera_yaw)*forward,0,-sin(camera_yaw)*side-cos(camera_yaw)*forward).normalized()
		if _last_move.length_squared()>0.01:_last_yaw=atan2(_last_move.x,_last_move.z)
		elif _orbit_right:_last_yaw=wrapf(camera_yaw+PI,-PI,PI)
	if _input_clock>=1.0/30.0:
		_input_clock=0.0
		input_changed.emit({"move":[_last_move.x,_last_move.z],"yaw":_last_yaw,"jump":_jump_queued if input_active else false})
		_jump_queued=false
	if camera==null:return
	for id: String in actors:
		var visual: Dictionary=actors[id]
		var data: Dictionary=visual.data
		var node: Node3D=visual.node
		var desired := C.vector(data.get("pos",[0,0,0]))
		var is_local := id=="p_"+str(local_id)
		if not visual.placed:
			node.position=desired
			visual.placed=true
		elif node.position.distance_to(desired)>5.0:node.position=desired
		else:node.position=node.position.lerp(desired,1.0-exp(-dt*(24.0 if is_local else 16.0)))
		var yaw := float(data.get("yaw",PI))
		node.rotation.y=lerp_angle(node.rotation.y,yaw,1.0-exp(-dt*18.0))
		if is_local:_local_render=node.position
		var dead := bool(data.get("dead",false))
		visual.ring.visible=id==target_id and not dead
		visual.label.visible=not is_local and not dead and desired.distance_to(_local_render)<30.0
		if not bool(visual.hero):
			_sync_enemy(visual,dt)
			visual.health.visible=id==target_id and not dead
			visual.health.scale.x=maxf(0.01,float(data.get("hp",1))/maxf(1,float(data.get("max_hp",1))))
		else:
			visual.ward.visible=float(data.get("ward",0.0))>0.0 and not dead
			visual.ward.rotation.y=_clock*0.8
	if not local.is_empty():
		var anchor := _local_render+Vector3(0,1.25,0)
		if not _camera_ready:
			_camera_pivot.position=anchor
			_camera_ready=true
		else:_camera_pivot.position=_camera_pivot.position.lerp(anchor,1.0-exp(-dt*15.0))
		_camera_pivot.rotation=Vector3(-camera_pitch,camera_yaw,0)
		_arm.spring_length=lerpf(_arm.spring_length,camera_distance,1.0-exp(-dt*12.0))
		# When an obstruction pushes the spring arm into the character, keep the
		# world readable rather than showing the inside of her head or clothing.
		var local_key := "p_"+str(local_id)
		if actors.has(local_key):actors[local_key].avatar.visible=_arm.get_hit_length()>0.75
	for id: String in npcs:
		var npc: Dictionary=npcs[id]
		npc.upper.rotation.z=sin(_clock*0.85+float(npc.seed))*0.013
		npc.marker.position.y=2.08+sin(_clock*1.7+float(npc.seed))*0.06
		npc.label.visible=npc.node.position.distance_to(_local_render)<24
	for id: String in gathers:
		var flower: Node3D=gathers[id].get_node("Blossom")
		flower.rotation.y=_clock*0.26
		flower.position.y=0.75+sin(_clock*1.6+float(id.hash()%7))*0.07

func _ring(parent: Node3D, radius: float, color: Color, thickness: float=0.025) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius=radius-thickness
	torus.outer_radius=radius
	torus.rings=48
	torus.ring_segments=6
	var material := StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=color
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var node := MeshInstance3D.new()
	node.mesh=torus
	node.material_override=material
	node.position.y=0.065
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _label(parent: Node3D, text: String, height: float, color: Color, font_size: int=28) -> Label3D:
	var label := Label3D.new()
	label.text=text
	label.font=load("res://assets/cinzel.ttf")
	label.font_size=font_size
	label.pixel_size=0.0065
	label.modulate=color
	label.outline_modulate=Color(0.02,0.025,0.025,0.92)
	label.outline_size=8
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=false
	label.position.y=height
	parent.add_child(label)
	return label

func _make_player(id: String, data: Dictionary) -> void:
	var node := Node3D.new()
	node.name="Player_"+id
	add_child(node)
	var avatar := Avatar.new()
	node.add_child(avatar)
	var ring := _ring(node,0.66,Color("dfc87b"))
	ring.visible=false
	var ward := _ring(node,0.85,Color(0.94,0.68,0.31,0.7),0.055)
	ward.visible=false
	var label := _label(node,str(data.get("name","Wayfarer")),1.95,Color("a8cec0"))
	actors[id]={"node":node,"avatar":avatar,"data":data,"hero":true,"ring":ring,"ward":ward,"label":label,"placed":false}

func _make_enemy(id: String, data: Dictionary) -> void:
	var node := Node3D.new()
	node.name="Enemy_"+id
	add_child(node)
	if not _models.has(WOLF):_models[WOLF]=load(WOLF) as PackedScene
	var body := (_models[WOLF] as PackedScene).instantiate() as Node3D
	node.add_child(body)
	Avatar.prepare_materials(body)
	_tint_enemy(body)
	var bounds: AABB=scenery._bounds(body)
	var kind := str(data.get("kind","duskfang"))
	var height := 2.75 if kind=="hollow_king" else (2.05 if kind=="briarborn" else 1.6)
	var factor := height/maxf(0.01,bounds.size.y)
	body.scale=Vector3.ONE*factor
	body.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	var animator := Avatar.find_animator(body)
	if animator!=null:animator.speed_scale=0.0
	var ring := _ring(node,0.85 if kind=="hollow_king" else 0.65,Color("cd684d"),0.04)
	var label := _label(node,str(data.get("name","Duskfang")),height+0.38,Color("e3bb9c"))
	var background := _health_bar(node,height+0.15,Color("292627"))
	var health := _health_bar(node,height+0.15,Color("a2473b"))
	health.position.z+=0.001
	background.visible=false
	var telegraph_root := Node3D.new()
	add_child(telegraph_root)
	var telegraph := _ring(telegraph_root,1.0,Color(1.0,0.48,0.23,0.9),0.045)
	telegraph_root.visible=false
	if kind=="hollow_king":
		var crown := Node3D.new()
		crown.position.y=height-0.04
		node.add_child(crown)
		scenery.cylinder(crown,0.27,0.12,Vector3.ZERO,scenery.mat(Color("a49257"),0.45),0.27,12)
		for i: int in range(5):
			var a := float(i)/5*TAU
			scenery.cylinder(crown,0.075,0.28,Vector3(sin(a)*0.25,0.16,cos(a)*0.25),scenery.mat(Color("c1a36a"),0.45),0.0,4)
	elif kind=="briarborn":
		for side: int in [-1,1]:
			var thorn: MeshInstance3D = scenery.cylinder(node,0.11,0.85,Vector3(side*0.43,1.65,-0.2),scenery.mat(Color("454f35")),0.015,6)
			thorn.rotation.z=side*-0.6
	actors[id]={"node":node,"body":body,"data":data,"hero":false,"animator":animator,"clip":"","ring":ring,"label":label,"health":health,"health_bg":background,"telegraph":telegraph_root,"telegraph_ring":telegraph,"placed":false,"clock":0.0,"height":height}

func _tint_enemy(node: Node) -> void:
	if node is MeshInstance3D and node.mesh!=null:
		for i: int in range(node.mesh.get_surface_count()):
			var material := node.get_active_material(i) as StandardMaterial3D
			if material!=null:
				var dark := material.duplicate() as StandardMaterial3D
				dark.albedo_color*=Color(0.53,0.6,0.66)
				node.set_surface_override_material(i,dark)
	for child: Node in node.get_children():_tint_enemy(child)

func _health_bar(parent: Node3D, y: float, color: Color) -> MeshInstance3D:
	var shape := QuadMesh.new()
	shape.size=Vector2(0.9,0.065)
	var material := StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=color
	material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	var n := MeshInstance3D.new()
	n.mesh=shape
	n.material_override=material
	n.position.y=y
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(n)
	return n

func _sync_enemy(visual: Dictionary, dt: float) -> void:
	visual.clock+=dt
	var data: Dictionary=visual.data
	var dead := bool(data.get("dead",false))
	var action := str(data.get("action","idle"))
	var clip := "idle-loop"
	if dead:clip="death"
	elif action in ["windup","attack","strike"]:clip="attack"
	elif action in ["run","chase","return"]:clip="run-loop"
	var player: AnimationPlayer=visual.animator
	if player!=null:
		if not player.has_animation(clip):clip=player.get_animation_list()[0]
		var length := player.get_animation(clip).length
		var t := fmod(float(visual.clock),maxf(0.001,length))
		if dead:t=minf(maxf(0.0,float(data.get("action_time",0))+_snapshot_age),length-0.001)
		elif clip=="attack":
			var progress := clampf((float(data.get("action_time",0.0))+_snapshot_age)/maxf(0.01,float(data.get("action_duration",1.0))),0,1)
			# One continuous swing: windup ends at contact, recovery starts there.
			# The server changes state at impact; it must not rewind the animation.
			var phase := progress*0.44 if action=="windup" else 0.44+progress*0.56
			t=minf(length*phase,length-0.001)
		if str(visual.clip)!=clip:
			player.play(clip,0.12)
			visual.clip=clip
		player.seek(t,true)
	visual.health_bg.visible=visual.health.visible
	visual.telegraph.visible=not dead and action=="windup" and float(data.get("attack_radius",0.0))>0.0
	if visual.telegraph.visible:
		var point := C.vector(data.get("attack_point",data.pos))
		point.y=C.ground_y(point.x,point.z)
		visual.telegraph.position=point
		var radius := float(data.get("attack_radius",2.0))
		visual.telegraph.scale=Vector3(radius,1,radius)
		var material: StandardMaterial3D=visual.telegraph_ring.material_override
		material.albedo_color.a=0.65+sin(_clock*13)*0.22

func _make_npc(data: Dictionary) -> void:
	var node := Node3D.new()
	node.name="NPC_"+str(data.id)
	node.position=C.ground_position(float(data.pos[0]),float(data.pos[2]))
	# Each service NPC has a separate authored silhouette, rather than cloning Mara.
	node.rotation.y=-0.45 if str(data.id)=="steward" else (0.45 if str(data.id)=="keeper" else -PI*0.35)
	add_child(node)
	var upper := Node3D.new()
	node.add_child(upper)
	var steward := str(data.id)=="steward"
	var keeper := str(data.id)=="keeper"
	var cloth: Material=scenery.mat(Color("56615d") if steward else (Color("66584d") if keeper else Color("65747a")))
	var leather: Material=scenery.mat(Color("342d25"))
	var skin: Material=scenery.mat(Color("b69a7c"),0.85)
	var iron: Material=scenery.mat(Color("767b78"),0.42)
	for side: int in [-1,1]:
		scenery.cylinder(node,0.085,0.6,Vector3(side*0.11,0.43,0),leather,0.10,10)
		scenery.box(node,Vector3(0.16,0.13,0.31),Vector3(side*0.11,0.075,0.055),leather)
	scenery.cylinder(upper,0.24,0.75,Vector3(0,0.96,0),cloth,0.29,12)
	scenery.cylinder(upper,0.245,0.065,Vector3(0,0.8,0),leather,0.25,12)
	scenery.box(upper,Vector3(0.09,0.07,0.025),Vector3(0,0.8,0.245),scenery.mat(Color("a18d5e"),0.5))
	# Cloaks and pauldrons give the captain and elder recognisable profiles.
	if steward:
		scenery.box(upper,Vector3(0.43,0.82,0.09),Vector3(0,0.95,-0.24),scenery.mat(Color("4b3530")))
		for side: int in [-1,1]:scenery.cylinder(upper,0.17,0.13,Vector3(side*0.29,1.27,0),iron,0.14,8)
	elif keeper:
		scenery.cylinder(upper,0.3,0.8,Vector3(0,0.63,0),cloth,0.22,12)
		scenery.cylinder(node,0.032,1.8,Vector3(-0.43,0.9,0.16),scenery.mat(Color("5f4831")),0.027,8)
	for side: int in [-1,1]:
		var arm: MeshInstance3D = scenery.cylinder(upper,0.085,0.56,Vector3(side*0.32,1.0,0.015),cloth,0.10,10)
		arm.rotation.z=side*0.16
		scenery.cylinder(upper,0.065,0.16,Vector3(side*0.36,0.7,0.025),skin,0.065,8)
	scenery.cylinder(upper,0.07,0.15,Vector3(0,1.39,0),skin,0.07,10)
	var head := SphereMesh.new()
	head.radius=0.145
	head.height=0.35
	head.radial_segments=16
	head.rings=10
	scenery.mesh(upper,head,Vector3(0,1.56,0.015),skin)
	var hair: Material=scenery.mat(Color("46433a") if keeper else Color("392d24"))
	scenery.cylinder(upper,0.147,0.13,Vector3(0,1.69,-0.005),hair,0.12,12)
	if steward:
		scenery.cylinder(upper,0.16,0.13,Vector3(0,1.72,-0.005),iron,0.13,12)
		scenery.box(upper,Vector3(0.035,0.22,0.025),Vector3(0,1.65,0.15),iron)
	if keeper or steward:
		scenery.cylinder(upper,0.07,0.13,Vector3(0,1.42,0.09),hair,0.10,8)
	for side: int in [-1,1]:
		var eye := SphereMesh.new()
		eye.radius=0.014
		eye.height=0.028
		eye.radial_segments=8
		eye.rings=4
		scenery.mesh(upper,eye,Vector3(side*0.049,1.59,0.144),scenery.mat(Color("343a37")))
	var marker := _label(node,"!" if steward else ("◇" if keeper else "¤"),2.08,Color("e5ca79"),52)
	var label := _label(node,str(data.name)+"\n<"+str(data.title)+">",2.5,Color("b4d0b3"),27)
	npcs[str(data.id)]={"node":node,"upper":upper,"label":label,"marker":marker,"data":data,"seed":npcs.size()*3}

func _make_gather(data: Dictionary) -> void:
	var node := Node3D.new()
	node.name=str(data.id)
	node.position=C.ground_position(float(data.pos[0]),float(data.pos[2]))
	add_child(node)
	scenery.cylinder(node,0.025,0.7,Vector3(0,0.35,0),scenery.mat(Color("4a6641")),0.016,8)
	var flower := Node3D.new()
	flower.name="Blossom"
	flower.position.y=0.75
	node.add_child(flower)
	var petal := SphereMesh.new()
	petal.radius=0.11
	petal.height=0.1
	petal.radial_segments=10
	petal.rings=6
	for i: int in range(6):
		var angle := float(i)/6*TAU
		var n: MeshInstance3D=scenery.mesh(flower,petal,Vector3(sin(angle)*0.16,0,cos(angle)*0.16),scenery.mat(Color("eeab50"),0.8,0.35))
		n.rotation.y=angle
		n.scale.z=1.6
	scenery.cylinder(flower,0.085,0.06,Vector3(0,0.035,0),scenery.mat(Color("f6d485"),0.8,0.6),0.075,10)
	_ring(node,0.36,Color(0.86,0.68,0.3,0.55),0.018)
	gathers[str(data.id)]=node

func _make_drop(id: String, data: Dictionary) -> void:
	var node := Node3D.new()
	node.name="Loot_"+id
	var pos := C.vector(data.get("pos",[0,0,0]))
	node.position=C.ground_position(pos.x,pos.z)
	add_child(node)
	var chest: Node3D=scenery.model("res://assets/models/treasure_chest/treasure_chest_lod.glb",node,Vector3(0.48,0.32,0.35))
	chest.rotation.y=0.2
	_ring(node,0.43,Color("ddbd65"),0.025)
	drops[id]=node

func select_target(id: String) -> void:
	if not id.is_empty() and not state.get("enemies",{}).has(id):return
	target_id=id
	target_changed.emit(id)

func cycle_target() -> void:
	var options: Array[String]=[]
	for id: String in state.get("enemies",{}):
		var e: Dictionary=state.enemies[id]
		if not bool(e.get("dead",false)) and C.vector(e.pos).distance_to(_local_render)<35.0:options.append(id)
	options.sort_custom(func(a: String,b: String):return C.vector(state.enemies[a].pos).distance_squared_to(_local_render)<C.vector(state.enemies[b].pos).distance_squared_to(_local_render))
	if options.is_empty():select_target("")
	else:select_target(options[(options.find(target_id)+1)%options.size()])

func _pick_target(point: Vector2) -> void:
	var closest := 58.0
	var chosen := ""
	for id: String in state.get("enemies",{}):
		var e: Dictionary=state.enemies[id]
		if bool(e.get("dead",false)):continue
		var p := C.vector(e.pos)+Vector3(0,0.9,0)
		if camera.is_position_behind(p):continue
		var distance := camera.unproject_position(p).distance_to(point)
		if distance<closest:
			closest=distance
			chosen=id
	select_target(chosen)

func nearest_interaction() -> Dictionary:
	var best: Dictionary={}
	var distance := 3.6
	var origin := C.vector(state.get("players",{}).get(str(local_id),{}).get("pos",C.array(_local_render)))
	for npc: Dictionary in C.NPCS:
		var d := Vector2(float(npc.pos[0])-origin.x,float(npc.pos[2])-origin.z).length()
		if d<distance:
			distance=d
			best={"id":str(npc.id),"kind":"npc","name":str(npc.name),"role":str(npc.role),"distance":d}
	for id: String in state.get("gathers",{}):
		var g: Dictionary=state.gathers[id]
		if not bool(g.get("available",false)):continue
		var position := C.vector(g.pos)
		var d := Vector2(position.x-origin.x,position.z-origin.z).length()
		if d<distance and d<=3.0:
			distance=d
			best={"id":id,"kind":"gather","name":"Emberbloom","distance":d}
	for id: String in state.get("drops",{}):
		var drop: Dictionary=state.drops[id]
		if int(drop.get("owner",0)) not in [0,local_id]:continue
		var position := C.vector(drop.pos)
		var d := Vector2(position.x-origin.x,position.z-origin.z).length()
		if d<distance and d<=3.5:
			distance=d
			best={"id":id,"kind":"loot","name":"Spoils","distance":d}
	return best

func interact_nearest() -> void:
	var nearby := nearest_interaction()
	if nearby.is_empty():return
	var kind := str(nearby.kind)
	if kind in ["loot","gather"]:action_requested.emit({"type":kind,"id":str(nearby.id)})
	else:interaction_requested.emit(str(nearby.id),kind)

func show_event(event: Dictionary) -> void:
	if camera==null:return
	var type := str(event.get("type",""))
	var pos := C.vector(event.get("pos",[0,0,0]))
	var target := str(event.get("target",""))
	var actor := str(event.get("actor",""))
	var actor_key := actor if actors.has(actor) else "p_"+actor
	var target_key := target if actors.has(target) else "p_"+target
	if not event.has("pos") and actors.has(target_key):pos=actors[target_key].node.position
	if type in ["damage","hit","hurt"]:
		if type=="hurt" and actors.has(actor_key):
			pos=actors[actor_key].node.position
			if bool(actors[actor_key].hero):actors[actor_key].avatar.hit()
		elif actors.has(target_key) and bool(actors[target_key].hero):actors[target_key].avatar.hit()
		_floating(pos+Vector3(0,1.5,0),str(int(event.get("value",0))),Color("f0cda0"))
		_sparks(pos+Vector3(0,1.0,0),Color("d6bd82"))
	elif type in ["heal","healed","ward"]:
		_floating(pos+Vector3(0,1.6,0),"+"+str(int(event.get("value",0))),Color("9ed5a5"))
	elif type in ["level","level_up"]:
		_floating(pos+Vector3(0,2.0,0),"LEVEL UP",Color("edce75"))
		_sparks(pos+Vector3(0,1,0),Color("edce75"))
	var ability := type if type in ["cleave","strike","ward","roll"] else str(event.get("ability",""))
	if type in ["ability","cast","action","cleave","strike","ward","roll"] and actors.has(actor_key):
		var source: Node3D=actors[actor_key].node
		if ability in ["cleave","strike"]:_slash(source,ability=="cleave")
		elif ability=="ward":_pulse(source.position,Color("d8b36f"))
		elif ability=="roll":_sparks(source.position+Vector3(0,0.3,0),Color("8e9b97"))

func _floating(pos: Vector3, text: String, color: Color) -> void:
	var root := Node3D.new()
	root.position=pos
	add_child(root)
	var label := _label(root,text,0,color,38)
	label.pixel_size=0.005
	var tween := create_tween().set_parallel(true)
	tween.tween_property(root,"position:y",pos.y+0.9,1.0)
	tween.tween_property(label,"modulate:a",0.0,0.65).set_delay(0.35)
	tween.chain().tween_callback(root.queue_free)

func _sparks(pos: Vector3, color: Color) -> void:
	var root := Node3D.new()
	root.position=pos
	add_child(root)
	var shape := SphereMesh.new()
	shape.radius=0.025
	shape.height=0.05
	shape.radial_segments=6
	shape.rings=4
	var material: Material=scenery.mat(color,0.5,0.6)
	for i: int in range(6):
		var a := float(i)*2.399
		var spark: MeshInstance3D=scenery.mesh(root,shape,Vector3.ZERO,material)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(spark,"position",Vector3(sin(a)*0.55,0.1+float(i%3)*0.15,cos(a)*0.55),0.3)
		tween.tween_property(spark,"scale",Vector3.ZERO,0.3)
	create_tween().tween_callback(root.queue_free).set_delay(0.35)

func _pulse(pos: Vector3, color: Color) -> void:
	var root := Node3D.new()
	root.position=pos
	add_child(root)
	var ring := _ring(root,0.6,color,0.055)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ring,"scale",Vector3(2.5,1,2.5),0.6)
	tween.tween_property(ring.material_override,"albedo_color:a",0.0,0.6)
	tween.chain().tween_callback(root.queue_free)

func _slash(source: Node3D, wide: bool) -> void:
	var root := Node3D.new()
	root.position=source.position+Vector3(0,0.9,0)
	root.rotation.y=source.rotation.y
	add_child(root)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := 2.4 if wide else 1.5
	for i: int in range(18):
		var a := -1.1+float(i)/18*2.2
		var b := -1.1+float(i+1)/18*2.2
		for v: Vector3 in [Vector3(sin(a)*radius,0,cos(a)*radius),Vector3(sin(a)*(radius-0.18),0,cos(a)*(radius-0.18)),Vector3(sin(b)*radius,0,cos(b)*radius),Vector3(sin(b)*radius,0,cos(b)*radius),Vector3(sin(a)*(radius-0.18),0,cos(a)*(radius-0.18)),Vector3(sin(b)*(radius-0.18),0,cos(b)*(radius-0.18))]:surface.add_vertex(v)
	surface.generate_normals()
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(0.58,0.81,0.95,0.8) if wide else Color(0.88,0.86,0.71,0.65)
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	scenery.mesh(root,surface.commit(),Vector3.ZERO,material)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(root,"rotation:y",source.rotation.y+0.4,0.3)
	tween.tween_property(material,"albedo_color:a",0.0,0.3)
	tween.chain().tween_callback(root.queue_free)
