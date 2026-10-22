class_name SpellFeedback
extends Node3D
## Read-only presentation of ActionRules. No timer here can hit, heal, bind,
## spend Focus, extend a status, or advance the action simulation.

const Action = preload("res://game/redesign/action_rules.gd")
const AUDIO_ROOT: String = "res://assets/audio/spells/"
const MAX_VOICES: int = 8
const MAX_BURSTS: int = 36
const MAX_HISTORY: int = 10
const COLORS: Dictionary = {"cleave":Color("d95032"),"ember":Color("ed812e"),"ward":Color("629ccc"),"roots":Color("839553")}
const GOLD: Color = Color("c9aa62")

var sound_enabled: bool = true
var status_nodes: Dictionary = {}
var projectile_nodes: Dictionary = {}
var cast_nodes: Dictionary = {}
var blade_nodes: Dictionary = {}
var guard_nodes: Dictionary = {}
var bursts: Array = []
var sound_log: Array = []
var _state: Dictionary = {}
var _visuals: Dictionary = {}
var _seen: Dictionary = {}
var _last_sound: Dictionary = {}
var _projectile_info: Dictionary = {}
var _voices: Array[AudioStreamPlayer3D] = []
var _streams: Dictionary = {}
var _listener: AudioListener3D
var _bus_name: String = ""
var _paused: bool = false
var _tick: int = 0
var _last_sync_tick: int = -1
var _sound_count_tick: int = -1
var _sounds_this_tick: int = 0
var duplicate_events: int = 0
var voice_drops: int = 0

func _ready() -> void:
	name = "SpellFeedback"
	_bus_name = "DraconiaSpells_" + str(get_instance_id())
	AudioServer.add_bus()
	var bus: int = AudioServer.bus_count-1
	AudioServer.set_bus_name(bus,_bus_name)
	AudioServer.set_bus_send(bus,"Master")
	var limiter: AudioEffectHardLimiter = AudioEffectHardLimiter.new()
	limiter.ceiling_db = -3.0
	limiter.pre_gain_db = 0.0
	limiter.release = 0.08
	AudioServer.add_bus_effect(bus,limiter)
	_listener = AudioListener3D.new()
	add_child(_listener)
	get_viewport().audio_listener_enable_3d = true
	_listener.make_current()

func _exit_tree() -> void:
	for voice: AudioStreamPlayer3D in _voices:
		if is_instance_valid(voice):voice.stop()
	var bus: int = AudioServer.get_bus_index(_bus_name)
	if bus>0:AudioServer.remove_bus(bus)

func audio_bus_name() -> String:
	return _bus_name

func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	if not enabled:
		for voice: AudioStreamPlayer3D in _voices:
			if is_instance_valid(voice):
				voice.stop()
				voice.queue_free()
		_voices.clear()

func _set_paused(paused: bool) -> void:
	_paused = paused
	for voice: AudioStreamPlayer3D in _voices:
		if is_instance_valid(voice):voice.stream_paused=paused

func _actor(id: String) -> Dictionary:
	return Action.get_actor(_state,id)

func _pos(value: Array, height: float = 0.0) -> Vector3:
	return Vector3(float(value[0]),height,float(value[1]))

func _actor_pos(id: String, height: float = 0.9) -> Vector3:
	var actor: Dictionary = _actor(id)
	return _pos(actor.pos,height) if not actor.is_empty() else Vector3.ZERO

func _material(color: Color, alpha: float = 1.0, emissive: bool = false) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(color,alpha)
	mat.roughness = 0.87
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if alpha<1.0:mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.set_meta("base_alpha",alpha)
	return mat

func _mesh(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=material
	node.position=pos
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _sphere(parent: Node3D, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var shape: SphereMesh = SphereMesh.new()
	shape.radius=radius
	shape.height=radius*2.0
	shape.radial_segments=12
	shape.rings=6
	return _mesh(parent,shape,material,pos)

func _line(parent: Node3D, a: Vector3, b: Vector3, width: float, material: Material, top: float = -1.0) -> MeshInstance3D:
	var offset: Vector3 = b-a
	var shape: CylinderMesh = CylinderMesh.new()
	shape.bottom_radius=width
	shape.top_radius=width if top<0 else top
	shape.height=maxf(.001,offset.length())
	shape.radial_segments=7
	var node: MeshInstance3D = _mesh(parent,shape,material,(a+b)*.5)
	if offset.length_squared()>.0001:
		node.quaternion=Quaternion(Vector3.UP,offset.normalized())
	return node

func _curve(parent: Node3D, points: Array[Vector3], width: float, material: Material, taper: float = .6) -> void:
	# One continuous tube per stroke keeps the silhouette smooth and the draw
	# count bounded; it is not a chain of independently lit cylinder joints.
	if points.size()<2:return
	var vertices: PackedVector3Array=PackedVector3Array()
	var normals: PackedVector3Array=PackedVector3Array()
	var indices: PackedInt32Array=PackedInt32Array()
	const SIDES: int=7
	for i: int in range(points.size()):
		var tangent: Vector3=(points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
		var sideways: Vector3=tangent.cross(Vector3.UP).normalized()
		if sideways.length_squared()<.01:sideways=tangent.cross(Vector3.RIGHT).normalized()
		var upward: Vector3=sideways.cross(tangent).normalized()
		var radius: float=width*(1.0-float(i)/float(points.size()-1)*taper)
		for side: int in range(SIDES):
			var angle: float=TAU*float(side)/float(SIDES)
			var normal: Vector3=sideways*cos(angle)+upward*sin(angle)
			vertices.append(points[i]+normal*radius)
			normals.append(normal)
			if i>0:
				var a: int=(i-1)*SIDES+side
				var b: int=(i-1)*SIDES+(side+1)%SIDES
				var c: int=i*SIDES+side
				var d: int=i*SIDES+(side+1)%SIDES
				indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh: ArrayMesh=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	_mesh(parent,mesh,material)

func _arc(parent: Node3D, radius: float, degrees: float, width: float, material: Material, height: float = .04) -> void:
	var points: Array[Vector3] = []
	for i: int in range(25):
		var angle: float=deg_to_rad(-degrees*.5+degrees*float(i)/24.0)
		points.append(Vector3(sin(angle)*radius,height,cos(angle)*radius))
	_curve(parent,points,width,material)

func _fade(node: Node, factor: float) -> void:
	if node is MeshInstance3D and node.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D=node.material_override
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a=float(mat.get_meta("base_alpha",1.0))*clampf(factor,0,1)
	for child: Node in node.get_children():_fade(child,factor)

func _remove_missing(nodes: Dictionary, present: Dictionary) -> void:
	for id: String in nodes.keys():
		if not present.has(id):
			var value: Variant=nodes[id]
			var node: Node=value.node if value is Dictionary else value
			if is_instance_valid(node):node.queue_free()
			nodes.erase(id)

func _sound(id: String, actor_id: String, position: Vector3, volume: float = -8.0, tag: String = "") -> void:
	if not sound_enabled or _paused:return
	if _sound_count_tick!=_tick:
		_sound_count_tick=_tick
		_sounds_this_tick=0
	var key: String=id+":"+actor_id
	if _tick-int(_last_sound.get(key,-1000))<3:return
	for index: int in range(_voices.size()-1,-1,-1):
		if not is_instance_valid(_voices[index]) or _voices[index].is_queued_for_deletion():_voices.remove_at(index)
	if _voices.size()>=MAX_VOICES or _sounds_this_tick>=4:
		voice_drops+=1
		return
	var path: String=AUDIO_ROOT+id+".wav"
	if not _streams.has(id):
		if not ResourceLoader.exists(path):return
		_streams[id]=load(path)
	var voice: AudioStreamPlayer3D=AudioStreamPlayer3D.new()
	voice.stream=_streams[id]
	voice.bus=_bus_name
	voice.volume_db=volume
	voice.unit_size=6.0
	voice.max_distance=35.0
	voice.max_db=-6.0
	voice.panning_strength=.65
	voice.attenuation_filter_cutoff_hz=9500.0
	voice.position=position
	voice.set_meta("feedback_tag",tag)
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	_voices.append(voice)
	voice.play()
	_last_sound[key]=_tick
	_sounds_this_tick+=1
	sound_log.append({"tick":_tick,"id":id,"actorId":actor_id,"pos":[position.x,position.y,position.z]})
	if sound_log.size()>96:sound_log.pop_front()

func _stop_tag(tag: String) -> void:
	for voice: AudioStreamPlayer3D in _voices:
		if is_instance_valid(voice) and str(voice.get_meta("feedback_tag",""))==tag:
			voice.stop()
			voice.queue_free()

func consume(events: Array, state: Dictionary) -> void:
	_state=state
	_tick=int(state.get("tick",0))
	_set_paused(bool(state.get("paused",false)) or str(state.get("phase",""))=="finished")
	var evades: Dictionary={}
	for event: Dictionary in events:
		if str(event.get("type",""))=="evaded":evades[str(event.actorId)+":"+str(event.tick)]=true
	for event: Dictionary in events:
		var key: String=JSON.stringify(event,"",true,true)
		if _seen.has(key):
			duplicate_events+=1
			continue
		_seen[key]=int(event.get("tick",_tick))
		if _tick-int(event.get("tick",_tick))>45:continue
		var type: String=str(event.get("type",""))
		var id: String=str(event.get("actorId",""))
		var point: Vector3=_actor_pos(id)
		match type:
			"action_started":
				var action: Dictionary=event.action
				var ability: String=str(action.get("ability",""))
				if str(action.kind)=="cast" and ability in COLORS:
					_sound("cleave_draw" if ability=="cleave" else ability+"_cast",id,point,-12.0,id+":windup")
				elif str(action.kind)=="dodge":_sound("dodge",id,point,-9.0)
			"action_cancelled":_stop_tag(id+":windup")
			"action_committed":
				if str(event.get("ability",""))=="cleave":_sound("cleave_release",id,point,-6.0)
			"projectile_spawned":
				var projectile: Dictionary=event.projectile
				_projectile_info[str(projectile.id)]=projectile.duplicate(true)
				if str(projectile.element)=="fire":_sound("ember_launch",str(projectile.sourceId),_pos(projectile.pos,.85),-8.0)
			"projectile_hit", "projectile_removed":
				var projectile_id: String=str(event.projectileId)
				var known: Dictionary=_projectile_info.get(projectile_id,{})
				if str(known.get("element","fire"))=="fire":
					var contact: bool=type=="projectile_hit" and not evades.has(str(event.get("targetId",""))+":"+str(event.tick))
					_burst("ember_hit" if contact else "ember_end",_pos(event.pos,.8),int(event.tick),15 if contact else 8)
					_sound("ember_hit" if contact else "ember_end",str(event.get("targetId",projectile_id)),_pos(event.pos,.8),-8.0 if contact else -15.0)
				_projectile_info.erase(projectile_id)
			"status_applied":
				if str(event.status)=="ward":_sound("ward_raise",id,point,-11.0)
				elif str(event.status)=="rooted":_sound("roots_bind",id,point,-10.0)
			"status_expired", "ward_broken":
				var status: String="ward" if type=="ward_broken" else str(event.get("status",""))
				if status in ["ward","rooted"]:
					_burst("ward_end" if status=="ward" else "roots_end",point,int(event.tick),10)
					_sound("ward_end" if status=="ward" else "roots_end",id,point,-15.0)
			"damage":
				if int(event.get("absorbed",0))>0:
					_burst("ward_absorb",point,int(event.tick),9)
					_sound("ward_absorb",id,point,-9.0)
				if int(event.get("blocked",0))>0:
					_burst("guard_block",point,int(event.tick),7)
					_sound("guard_block",id,point,-10.0)
				elif int(event.get("amount",0))>0 and str(event.get("element",""))=="physical":
					_burst("steel_contact",point,int(event.tick),7)
					_sound("steel_contact",id,point,-13.0)
			"ground_effect":
				if str(event.effect)=="roots":_burst("roots_ground",_pos(event.pos,.03),int(event.tick),10,float(event.radius))
				elif str(event.effect)=="impact":_burst("impact",_pos(event.pos,.03),int(event.tick),12,float(event.radius))
			"guard_changed":
				if bool(event.guarding):_sound("guard_ready",id,point,-15.0)
			"evaded":
				_burst("evade",point,int(event.tick),6)
				_sound("evade",id,point,-15.0)
	for old: String in _seen.keys():
		if _tick-int(_seen[old])>180:_seen.erase(old)

func sync(state: Dictionary, visuals: Dictionary, camera: Camera3D) -> void:
	_state=state
	_visuals=visuals
	_tick=int(state.get("tick",0))
	_set_paused(bool(state.get("paused",false)) or str(state.get("phase",""))=="finished")
	var hero: Dictionary=_actor(str(state.get("heroId","")))
	if _listener!=null and not hero.is_empty():
		_listener.position=_pos(hero.pos,1.2)
		if camera!=null:_listener.rotation.y=camera.rotation.y
	_sync_projectiles()
	_sync_statuses()
	_sync_actions()
	_sync_bursts()
	_last_sync_tick=_tick

func _sync_projectiles() -> void:
	var present: Dictionary={}
	for projectile: Dictionary in _state.get("projectiles",[]):
		var id: String=str(projectile.id)
		present[id]=true
		_projectile_info[id]=projectile.duplicate(true)
		if not projectile_nodes.has(id):
			var node: Node3D=Node3D.new()
			node.name="Projectile_"+id
			add_child(node)
			_flame(node,.25,1.20,Color("d84d1d"),.58)
			_flame(node,.18,.90,Color("fa8d27"),.88)
			_flame(node,.105,.55,Color("ffe5a5"),.98)
			var core: StandardMaterial3D=_material(Color("ffe4a1"),.97,true)
			core.render_priority=3
			_sphere(node,Vector3(0,0,.04),.13,core)
			for i: int in range(3):
				var curl: Array[Vector3]=[]
				for j: int in range(10):
					var t: float=float(j)/9.0
					var phase: float=TAU*float(i)/3.0+t*2.6
					curl.append(Vector3(sin(phase)*(.12+t*.10),cos(phase)*(.12+t*.10),-.05-t*.90))
				_curve(node,curl,.023,_material(Color("f5a442"),.62,true),.95)
			projectile_nodes[id]=node
		var node: Node3D=projectile_nodes[id]
		node.position=_pos(projectile.pos,.85)
		node.rotation.y=atan2(float(projectile.direction[0]),float(projectile.direction[1]))
		node.scale=Vector3.ONE*(.97+.03*sin(float(_tick)*2.1))
	_remove_missing(projectile_nodes,present)

func _flame(parent: Node3D, radius: float, length: float, color: Color, alpha: float) -> void:
	var vertices: PackedVector3Array=PackedVector3Array()
	var indices: PackedInt32Array=PackedInt32Array()
	var colors: PackedColorArray=PackedColorArray()
	const RINGS: int=10
	const SIDES: int=12
	for ring: int in range(RINGS):
		var t: float=float(ring)/float(RINGS-1)
		var width: float=radius*pow(maxf(.002,sin(PI*t)),1.1)*(1.0-t*.5)
		for side: int in range(SIDES):
			var angle: float=TAU*float(side)/float(SIDES)
			var ripple: float=1.0+.14*sin(angle*3.0+t*9.0)
			vertices.append(Vector3(cos(angle)*width*ripple+.035*sin(t*8.0)*t,sin(angle)*width*ripple,.16-t*length))
			colors.append(Color(color,alpha*(1.0-t*.7)))
			if ring>0:
				var a: int=(ring-1)*SIDES+side
				var b: int=(ring-1)*SIDES+(side+1)%SIDES
				var c: int=ring*SIDES+side
				var d: int=ring*SIDES+(side+1)%SIDES
				indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_INDEX]=indices
	var shape: ArrayMesh=ArrayMesh.new()
	shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material: StandardMaterial3D=_material(Color.WHITE,.99,true)
	material.vertex_color_use_as_albedo=true
	_mesh(parent,shape,material)

func _shield(parent: Node3D) -> void:
	var shape: ArrayMesh=ArrayMesh.new()
	var vertices: PackedVector3Array=PackedVector3Array([Vector3(0,.47,0),Vector3(.38,.31,0),Vector3(.34,-.12,.025),Vector3(0,-.57,.09),Vector3(-.34,-.12,.025),Vector3(-.38,.31,0),Vector3(0,-.02,.06)])
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([6,0,1,6,1,2,6,2,3,6,3,4,6,4,5,6,5,0])
	shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	_mesh(parent,shape,_material(Color("417caf"),.58,true))
	var border: Array[Vector3]=[]
	for i: int in range(7):border.append(vertices[i%6]+Vector3(0,0,.014))
	var gold: StandardMaterial3D=_material(GOLD,.98,true)
	gold.render_priority=3
	_curve(parent,border,.024,gold,0)
	# Four interwoven lobes and a small central boss echo the manuscript oath
	# knot. This is the finite magical ward, never an equipped physical shield.
	for petal: int in range(4):
		var curve: Array[Vector3]=[]
		for i: int in range(33):
			var angle: float=TAU*float(i)/32.0
			var point: Vector3=Vector3(.116*sin(angle),.105+.153*cos(angle),0).rotated(Vector3.FORWARD,PI*.5*float(petal))
			curve.append(Vector3(point.x,point.y-.025,.085+.017*sin(angle*2.0+petal*PI*.5)))
		_curve(parent,curve,.018,gold,0)
	_sphere(parent,Vector3(0,-.025,.10),.037,gold)
	for side: float in [-1.0,1.0]:
		var wisp: Array[Vector3]=[]
		for i: int in range(15):
			var t: float=float(i)/14.0
			wisp.append(Vector3(side*(.39+.09*sin(PI*t)),.45-t*.98,.01+.04*sin(t*PI)))
		_curve(parent,wisp,.017,_material(Color("96c8ef"),.54,true),.8)

func _roots(parent: Node3D, radius: float) -> void:
	for i: int in range(3):
		var phase: float=TAU*float(i)/3.0+.35
		var points: Array[Vector3]=[]
		for j: int in range(22):
			var progress: float=float(j)/21.0
			var angle: float=phase+progress*1.48+.12*sin(progress*13.0+i)
			var distance: float=lerpf(radius+.38,radius*.58,progress)+.055*sin(progress*19.0+i)
			points.append(Vector3(sin(angle)*distance,progress*1.35,cos(angle)*distance))
		_curve(parent,points,.10,_material(Color("936541")),.83)
		var grain: Array[Vector3]=[]
		for point: Vector3 in points:grain.append(point+Vector3(.025,.015,.025))
		_curve(parent,grain,.018,_material(Color("bc9763")),.75)
		var tip: Vector3=points[14]
		var branch: Array[Vector3]=[tip,tip+Vector3(cos(phase)*.14,.12,-sin(phase)*.14),tip+Vector3(cos(phase)*.29,.26,-sin(phase)*.29)]
		_curve(parent,branch,.034,_material(Color("936541")),.85)
		for j: int in range(2):
			var leaf: MeshInstance3D=_sphere(parent,points[13+j*5]+Vector3(.07,0,0),.11,_material(Color("8eaa58")))
			leaf.scale=Vector3(.5,.22,1.4)
			leaf.rotation.y=phase+float(j)
		var wisp: Array[Vector3]=[]
		for j: int in range(19):
			var progress: float=float(j)/18.0
			var angle: float=phase+progress*2.5
			wisp.append(Vector3(sin(angle)*(radius+.13),.12+progress*1.18,cos(angle)*(radius+.13)))
		_curve(parent,wisp,.018,_material(Color("b1c97e"),.42,true),.85)

func _sync_statuses() -> void:
	var present: Dictionary={}
	for actor: Dictionary in _state.get("actors",[]):
		if int(actor.hp)<=0:continue
		for kind: String in ["ward","rooted","burn"]:
			var effect: Dictionary=actor.statuses.get(kind,{})
			if effect.is_empty() or int(effect.get("until",0))<=_tick:continue
			var id: String=str(actor.id)+":"+kind
			present[id]=true
			if not status_nodes.has(id):
				var node: Node3D=Node3D.new()
				node.name="Status_"+str(actor.id)+"_"+kind
				add_child(node)
				if kind=="ward":
					var shield: Node3D=Node3D.new()
					shield.position=Vector3(0,1.12,float(actor.radius)+.18)
					node.add_child(shield)
					_shield(shield)
					_arc(node,float(actor.radius)+.25,360,.018,_material(COLORS.ward,.40,true),.08)
				elif kind=="rooted":_roots(node,float(actor.radius))
				else:
					for i: int in range(3):
						var ember: MeshInstance3D=_sphere(node,Vector3(sin(i*2.1)*.3,.3+float(i)*.19,cos(i*2.1)*.3),.075,_material(COLORS.ember,.85,true))
						ember.scale.y=1.8
				status_nodes[id]=node
			var node: Node3D=status_nodes[id]
			node.position=_pos(actor.pos)
			if kind=="ward":
				node.rotation.y=atan2(float(actor.facing[0]),float(actor.facing[1]))
				var maximum: float=maxf(1,35+5*int(actor.get("power",2))+int(actor.get("wardBonus",0)))
				_fade(node,.55+.45*clampf(float(effect.pool)/maximum,0,1))
			elif kind=="rooted":
				var age: int=_tick-(int(effect.until)-75)
				node.scale.y=clampf(float(age)/6.0,.05,1.0)
			else:
				node.rotation.y=float(_tick)*.08
				node.scale=Vector3.ONE*(.9+.10*sin(float(_tick)*1.7))
	_remove_missing(status_nodes,present)

func _sync_actions() -> void:
	var casts: Dictionary={}
	var blades: Dictionary={}
	var guards: Dictionary={}
	for actor: Dictionary in _state.get("actors",[]):
		if int(actor.hp)<=0:continue
		var id: String=str(actor.id)
		var active: Dictionary=actor.action
		if bool(actor.guarding):
			guards[id]=true
			if not guard_nodes.has(id):
				var marker: Node3D=Node3D.new()
				add_child(marker)
				_arc(marker,float(actor.radius)+.35,rad_to_deg(acos(.25))*2,.018,_material(GOLD,.55,true))
				guard_nodes[id]=marker
			guard_nodes[id].position=_pos(actor.pos)
			guard_nodes[id].rotation.y=atan2(float(actor.facing[0]),float(actor.facing[1]))
		if active.is_empty():continue
		var ability: String=str(active.get("ability",""))
		if str(active.kind)=="cast" and ability in ["ember","ward","roots"] and _tick<int(active.commitTick):
			casts[id]=true
			if not cast_nodes.has(id) or str(cast_nodes[id].ability)!=ability:
				if cast_nodes.has(id):cast_nodes[id].node.queue_free()
				var node: Node3D=Node3D.new()
				add_child(node)
				_sphere(node,Vector3.ZERO,.11,_material(COLORS[ability],.55,true))
				for i: int in range(3):_sphere(node,Vector3(sin(i*2.1)*.20,.04,cos(i*2.1)*.20),.035,_material(COLORS[ability],.8,true))
				cast_nodes[id]={"node":node,"ability":ability}
			var node: Node3D=cast_nodes[id].node
			node.position=_pos(actor.pos,1.08)+Vector3(float(actor.facing[0]),0,float(actor.facing[1]))*.38
			node.rotation.y=float(_tick)*.20
			node.scale=Vector3.ONE*clampf(float(_tick-int(active.startTick))/maxf(1,float(int(active.commitTick)-int(active.startTick))),.15,1)
		if ability=="cleave" and _tick>=int(active.commitTick)-6 and _tick<int(active.endTick)-3 and _visuals.has(id):
			blades[id]=true
			_sync_blade(id,actor,_visuals[id])
		if str(active.kind)=="dodge" and _tick!=_last_sync_tick and _tick-int(active.startTick) in [1,5,9,13,17]:
			_burst("dodge",_pos(actor.pos,.08),_tick,9,.4)
	_remove_missing(cast_nodes,casts)
	_remove_missing(blade_nodes,blades)
	_remove_missing(guard_nodes,guards)

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.visible and node.mesh!=null:return node
	for child: Node in node.get_children():
		var found: MeshInstance3D=_find_mesh(child)
		if found!=null:return found
	return null

func weapon_segment(visual: Dictionary) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	var body: Node3D=visual.get("body")
	if body==null:return result
	var skeleton: Skeleton3D=body.get_node_or_null("IleanaRig/Skeleton3D") as Skeleton3D
	if skeleton==null:return result
	var hand: int=skeleton.find_bone("hand_r")
	if hand<0:
		for bone: int in range(skeleton.get_bone_count()):
			var name_text: String=skeleton.get_bone_name(bone).to_lower()
			if name_text in ["righthand","hand.r","hand_r","r_hand"]:hand=bone
	if hand<0:return result
	var grip: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(hand).origin
	var farthest: Vector3=grip
	var distance: float=0.0
	for weapon: Node3D in visual.get("appearance",{}).get("weaponNodes",[]):
		if not is_instance_valid(weapon) or not weapon.visible:continue
		var mesh: MeshInstance3D=_find_mesh(weapon)
		if mesh==null:continue
		for surface: int in range(mesh.mesh.get_surface_count()):
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES]!=null else PackedInt32Array()
			var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS] if arrays[Mesh.ARRAY_WEIGHTS]!=null else PackedFloat32Array()
			for index: int in range(vertices.size()):
				var point: Vector3=mesh.global_transform*vertices[index]
				if mesh.skin!=null and bones.size()>=vertices.size()*4:
					var local: Vector3=Vector3.ZERO
					for weight: int in range(4):
						var bind: int=bones[index*4+weight]
						var amount: float=weights[index*4+weight]
						if amount<=0 or bind>=mesh.skin.get_bind_count():continue
						var bone: int=mesh.skin.get_bind_bone(bind)
						if bone<0:bone=skeleton.find_bone(mesh.skin.get_bind_name(bind))
						if bone>=0:local+=(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind)*vertices[index])*amount
					point=skeleton.global_transform*local
				var candidate: float=point.distance_squared_to(grip)
				if candidate>distance:
					distance=candidate
					farthest=point
	if distance>.01 and distance<9.0:
		result.append(to_local(grip))
		result.append(to_local(farthest))
	return result

func _sync_blade(id: String, actor: Dictionary, visual: Dictionary) -> void:
	var segment: Array[Vector3]=weapon_segment(visual)
	if segment.size()!=2:return
	if not blade_nodes.has(id):
		var mesh: MeshInstance3D=MeshInstance3D.new()
		var mat: StandardMaterial3D=_material(Color.WHITE,.99,true)
		mat.vertex_color_use_as_albedo=true
		mesh.material_override=mat
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
		blade_nodes[id]={"node":mesh,"history":[],"tick":-1,"startTick":int(actor.action.startTick)}
	var data: Dictionary=blade_nodes[id]
	if int(data.startTick)!=int(actor.action.startTick):
		data.history=[]
		data.startTick=int(actor.action.startTick)
	if int(data.tick)!=_tick:
		# The narrow leading edge sits on the sampled blade. The pigment wake
		# extends only a little beyond that blade, so it reads at the play camera
		# without becoming a detached projectile or an invented area of damage.
		var direction: Vector3=(segment[1]-segment[0]).normalized()
		data.history.append({"grip":segment[0].lerp(segment[1],.62),"tip":segment[1],"outer":segment[1]+direction*.18,"tick":_tick})
		data.tick=_tick
		while data.history.size()>MAX_HISTORY:data.history.pop_front()
	if data.history.size()<2:return
	var vertices: PackedVector3Array=PackedVector3Array()
	var colors: PackedColorArray=PackedColorArray()
	var indices: PackedInt32Array=PackedInt32Array()
	# Interpolate only measured blade samples. A smoother pigment stroke avoids
	# large triangular corners while retaining the actual animated sword path.
	var stroke: Array=[]
	for index: int in range(data.history.size()-1):
		var a: Dictionary=data.history[index]
		var b: Dictionary=data.history[index+1]
		var before: Dictionary=data.history[maxi(0,index-1)]
		var after: Dictionary=data.history[mini(data.history.size()-1,index+2)]
		for step: int in range(3):
			var t: float=float(step)/3.0
			var sample: Dictionary={}
			for key: String in ["grip","tip","outer"]:
				var value: Vector3=a[key]
				sample[key]=value.cubic_interpolate(b[key],before[key],after[key],t)
			stroke.append(sample)
	stroke.append(data.history[-1])
	for index: int in range(stroke.size()):
		var sample: Dictionary=stroke[index]
		var strength: float=pow(float(index+1)/float(stroke.size()),1.75)
		vertices.append(sample.grip)
		vertices.append(sample.tip)
		vertices.append(sample.outer)
		colors.append(Color(.70,.11,.035,strength*.12))
		colors.append(Color(1.0,.26,.10,strength*.90))
		colors.append(Color(1.0,.61,.30,strength*.78))
		if index>0:
			var i: int=index*3
			indices.append_array(PackedInt32Array([i-3,i-2,i,i-2,i+1,i,i-2,i-1,i+1,i-1,i+2,i+1]))
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_INDEX]=indices
	var trail: ArrayMesh=ArrayMesh.new()
	trail.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	data.node.mesh=trail
	data.node.visible=_tick>=int(actor.action.commitTick)-2

func _burst(kind: String, position: Vector3, tick: int, duration: int, radius: float = .6) -> void:
	if bursts.size()>=MAX_BURSTS:
		bursts[0].node.queue_free()
		bursts.pop_front()
	var node: Node3D=Node3D.new()
	node.name="Feedback_"+kind
	node.position=position
	add_child(node)
	var color: Color=COLORS.ember if kind.begins_with("ember") else COLORS.ward if kind.begins_with("ward") else Color("889b59") if kind.begins_with("roots") else GOLD if kind=="guard_block" else Color("ae9d83")
	var sparks: int=9 if kind=="ember_hit" else 6
	if kind in ["roots_ground","impact"]:
		_arc(node,radius,360,.025,_material(color,.55,true))
		for i: int in range(3):
			var angle: float=TAU*float(i)/3.0
			_line(node,Vector3.ZERO,Vector3(sin(angle)*radius,.05,cos(angle)*radius),.035,_material(color,.5))
	elif kind=="ward_absorb":
		for i: int in range(2):
			var ring: Node3D=Node3D.new()
			node.add_child(ring)
			ring.rotation.x=PI*.5
			_arc(ring,.45+float(i)*.16,360,.018,_material(color,.8,true),0)
	else:
		if kind=="ember_hit":
			var flare: MeshInstance3D=_sphere(node,Vector3.ZERO,.24,_material(Color("ffe0a1"),.92,true))
			flare.set_meta("flash",true)
			var halo: MeshInstance3D=_sphere(node,Vector3.ZERO,.38,_material(Color("f19034"),.35,true))
			halo.set_meta("flash",true)
		for i: int in range(sparks):
			var piece: MeshInstance3D=_sphere(node,Vector3.ZERO,.025 if kind in ["steel_contact","guard_block","evade"] else .055,_material(color,.75,true))
			var angle: float=TAU*float(i)/float(sparks)+float(tick%13)*.17
			piece.set_meta("velocity",Vector3(sin(angle),.3+float(i%3)*.35,cos(angle))*(.7 if kind=="dodge" else 1.2))
			piece.scale=Vector3(.55,1.6,.55)
	bursts.append({"node":node,"kind":kind,"start":tick,"end":tick+duration,"radius":radius})

func _sync_bursts() -> void:
	for index: int in range(bursts.size()-1,-1,-1):
		var effect: Dictionary=bursts[index]
		if _tick>=int(effect.end):
			effect.node.queue_free()
			bursts.remove_at(index)
			continue
		var age: float=maxf(0,float(_tick-int(effect.start)))/Action.TICK_RATE
		var progress: float=clampf(float(_tick-int(effect.start))/maxf(1,float(int(effect.end)-int(effect.start))),0,1)
		for child: Node in effect.node.get_children():
			if child is Node3D and child.has_meta("velocity"):
				child.position=child.get_meta("velocity")*age+Vector3(0,-age*age*.7,0)
				child.scale=Vector3(.55,1.6,.55)*(1.0-progress*.65)
			elif child is Node3D and child.has_meta("flash"):
				child.scale=Vector3.ONE*(.7+minf(progress*3.0,1.0)*.7)
				child.visible=progress<.55
		if str(effect.kind) in ["ward_absorb","roots_ground","impact"]:effect.node.scale=Vector3.ONE*(.75+progress*.45)
		_fade(effect.node,1.0-progress)

func inspection() -> Dictionary:
	var active_voices: int=0
	for voice: AudioStreamPlayer3D in _voices:
		if is_instance_valid(voice) and not voice.is_queued_for_deletion():active_voices+=1
	return {"tick":_tick,"paused":_paused,"soundEnabled":sound_enabled,"statusKeys":status_nodes.keys(),"projectileIds":projectile_nodes.keys(),"castingActors":cast_nodes.keys(),"bladeActors":blade_nodes.keys(),"guardActors":guard_nodes.keys(),"bursts":bursts.size(),"voices":active_voices,"voiceLimit":MAX_VOICES,"voiceDrops":voice_drops,"duplicateEvents":duplicate_events,"soundLog":sound_log.duplicate(true)}
