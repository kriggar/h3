extends Node3D
## Authored third-person region. Collision footprints share Catalog with the host.
const C = preload("res://game/online/catalog.gd")
const Avatar = preload("res://game/online/avatar.gd")
const GroundMaterials = preload("res://game/online/environment_materials.gd")
var materials: Dictionary = {}
var _models: Dictionary = {}
var _lamps: Array[OmniLight3D] = []
var _time := 0.0

func _ready() -> void:
	_lighting()
	_terrain()
	_horizon()
	_village()
	_woodland()
	_landmarks()
	_prop_collisions()

func _process(dt: float) -> void:
	_time+=dt
	for i: int in range(_lamps.size()):
		_lamps[i].light_energy=1.15+sin(_time*4.1+float(i)*7.4)*0.08+sin(_time*9.3+float(i))*0.04

func mat(color: Color, roughness: float=0.9, emission: float=0.0) -> StandardMaterial3D:
	var key := str(color)+str(roughness)+str(emission)
	if materials.has(key):return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	if emission>0:
		m.emission_enabled=true
		m.emission=color
		m.emission_energy_multiplier=emission
	materials[key]=m
	return m

func mesh(parent: Node3D, shape: Mesh, position: Vector3, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh=shape
	n.material_override=material
	n.position=position
	parent.add_child(n)
	return n

func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size=size
	return mesh(parent,shape,pos,material)

func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material, top: float=-1.0, segments: int=12) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius=radius
	shape.top_radius=radius if top<0 else top
	shape.height=height
	shape.radial_segments=segments
	return mesh(parent,shape,pos,material)

func _lighting() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode=Environment.BG_SKY
	var sky := Sky.new()
	var air := ProceduralSkyMaterial.new()
	air.sky_top_color=Color("546e80")
	air.sky_horizon_color=Color("d5d3b5")
	air.ground_bottom_color=Color("273537")
	air.ground_horizon_color=Color("a8aaa0")
	air.sun_angle_max=7.0
	air.sun_curve=0.08
	sky.sky_material=air
	settings.sky=sky
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color("96a9b7")
	settings.ambient_light_energy=0.43
	settings.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	settings.fog_enabled=true
	settings.fog_light_color=Color("748d98")
	settings.fog_light_energy=0.45
	settings.fog_density=0.0031
	settings.fog_sky_affect=0.10
	settings.fog_height=3.0
	settings.fog_height_density=0.008
	env.environment=settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name="LateAutumnSun"
	sun.rotation_degrees=Vector3(-33,-41,0)
	sun.light_color=Color("ead8b8")
	sun.light_energy=0.86
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=88.0
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias=0.04
	sun.shadow_normal_bias=1.5
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-45,140,0)
	fill.light_color=Color("8aa4c7")
	fill.light_energy=0.11
	add_child(fill)

func _terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEG := 140
	const EXTENT := 224.0
	for iz: int in range(SEG+1):
		for ix: int in range(SEG+1):
			var x := -EXTENT+float(ix)/SEG*EXTENT*2
			var z := -EXTENT+float(iz)/SEG*EXTENT*2
			var height := C.ground_y(x,z)
			if maxf(absf(x),absf(z))>110:
				height+=smoothstep(110.0,220.0,maxf(absf(x),absf(z)))*(12.0+sin(x*0.04)*cos(z*0.045)*8)
			surface.set_uv(Vector2(x,z))
			surface.add_vertex(Vector3(x,height,z))
	for iz: int in range(SEG):
		for ix: int in range(SEG):
			var a := iz*(SEG+1)+ix
			for n: int in [a,a+SEG+1,a+1,a+1,a+SEG+1,a+SEG+2]:surface.add_index(n)
	surface.generate_normals()
	var terrain := mesh(self,surface.commit(),Vector3.ZERO,_ground_material())
	terrain.name="BlackbriarGround"
	var body := StaticBody3D.new()
	body.collision_layer=1
	body.collision_mask=0
	var shape := CollisionShape3D.new()
	shape.shape=terrain.mesh.create_trimesh_shape()
	body.add_child(shape)
	add_child(body)

func _ground_material() -> ShaderMaterial:
	return GroundMaterials.terrain()

func _horizon() -> void:
	var noise := FastNoiseLite.new()
	noise.seed=194731
	noise.frequency=0.014
	noise.fractal_octaves=4
	noise.fractal_gain=0.52
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const AROUND := 240
	const BANDS := 30
	for band: int in range(BANDS+1):
		var radius := 126.0+float(band)/BANDS*230.0
		for i: int in range(AROUND+1):
			var angle := float(i)/AROUND*TAU
			var x := sin(angle)*radius
			var z := cos(angle)*radius
			var envelope := sin(float(band)/BANDS*PI)
			var ridge := 0.7+absf(sin(angle*5.0+0.7))*0.3
			var height := 5.0+pow(envelope,1.25)*(21.0+ridge*27.0+noise.get_noise_2d(x,z)*37.0)
			surface.set_uv(Vector2(x,z)*0.07)
			surface.set_color(Color("526972").lerp(Color("819293"),clampf(height/100.0,0.0,1.0)).srgb_to_linear())
			surface.add_vertex(Vector3(x,height,z))
	for band: int in range(BANDS):
		for i: int in range(AROUND):
			var a := band*(AROUND+1)+i
			for index: int in [a,a+1,a+AROUND+1,a+1,a+AROUND+2,a+AROUND+1]:surface.add_index(index)
	surface.generate_normals()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.albedo_texture=Avatar._filtered(load("res://assets/models/rock_moss_set_02/textures/rock_moss_set_02_diff_1k.jpg"))
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.roughness=1.0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var mountains := mesh(self,surface.commit(),Vector3.ZERO,material)
	mountains.name="CarpathianRidges"
	mountains.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _bounds(node: Node3D, transform: Transform3D=Transform3D.IDENTITY) -> AABB:
	var t := transform*node.transform
	var result := AABB()
	if node is MeshInstance3D and node.mesh!=null:result=t*node.get_aabb()
	for child: Node in node.get_children():
		if child is Node3D:
			var b := _bounds(child,t)
			if b.size.length_squared()>0.0:result=b if result.size.length_squared()==0.0 else result.merge(b)
	return result

func model(path: String, parent: Node3D, size: Vector3=Vector3.ZERO) -> Node3D:
	if not _models.has(path):_models[path]=load(path) as PackedScene
	var n := (_models[path] as PackedScene).instantiate() as Node3D
	parent.add_child(n)
	Avatar.prepare_materials(n)
	if size.length_squared()>0.0:
		var b := _bounds(n)
		if b.size.length_squared()>0:
			var scaling := Vector3(size.x/maxf(b.size.x,0.01),size.y/maxf(b.size.y,0.01),size.z/maxf(b.size.z,0.01))
			n.scale*=scaling
			n.position=-Vector3(b.get_center().x,b.position.y,b.get_center().z)*scaling
	return n

func _rock(parent: Node3D, size: Vector3, variant: int=0) -> Node3D:
	const PATH := "res://assets/models/rock_moss_set_02/rock_moss_set_02_1k.gltf"
	if not _models.has(PATH):_models[PATH]=load(PATH) as PackedScene
	var source := (_models[PATH] as PackedScene).instantiate() as Node3D
	var n := source.get_child(variant%source.get_child_count()).duplicate() as Node3D
	source.free()
	parent.add_child(n)
	Avatar.prepare_materials(n)
	var b := _bounds(n)
	var scaling := Vector3(size.x/maxf(b.size.x,0.01),size.y/maxf(b.size.y,0.01),size.z/maxf(b.size.z,0.01))
	n.scale*=scaling
	n.position=-Vector3(b.get_center().x,b.position.y,b.get_center().z)*scaling
	return n

func _prop_collisions() -> void:
	var group := Node3D.new()
	group.name="SharedPropCollision"
	add_child(group)
	for prop: Dictionary in C.solid_props():
		var body := StaticBody3D.new()
		body.name=str(prop.id)
		body.position=C.ground_position(float(prop.pos[0]),float(prop.pos[2]))
		body.collision_layer=1
		body.collision_mask=0
		var collision := CollisionShape3D.new()
		if str(prop.kind)=="box":
			var shape := BoxShape3D.new()
			shape.size=C.vector(prop.size)
			collision.shape=shape
			collision.position.y=float(prop.size[1])*0.5
		else:
			var shape := CylinderShape3D.new()
			shape.radius=float(prop.radius)
			shape.height=float(prop.height)
			collision.shape=shape
			collision.position.y=float(prop.height)*0.5
		body.add_child(collision)
		group.add_child(body)

func _warm_windows(node: Node) -> void:
	if node is MeshInstance3D and node.mesh!=null:
		for surface: int in range(node.mesh.get_surface_count()):
			var source := node.get_active_material(surface) as StandardMaterial3D
			if source==null or not "window" in source.resource_name.to_lower():continue
			var shader := Shader.new()
			shader.code="""shader_type spatial;
uniform sampler2D glass_texture:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
void fragment(){
 vec3 painted=texture(glass_texture,UV).rgb;
 float luminance=dot(painted,vec3(0.299,0.587,0.114));
 ALBEDO=vec3(luminance)*vec3(0.85,0.58,0.25);
 EMISSION=ALBEDO*0.12;
 ROUGHNESS=0.5;
}"""
			var material := ShaderMaterial.new()
			material.shader=shader
			material.set_shader_parameter("glass_texture",source.albedo_texture)
			node.set_surface_override_material(surface,material)
	for child: Node in node.get_children():_warm_windows(child)

func _village() -> void:
	var house_index := 0
	for b: Dictionary in C.BUILDINGS:
		var anchor := Node3D.new()
		anchor.name="Landmark_"+str(b.id)
		anchor.position=C.ground_position(float(b.pos[0]),float(b.pos[2]))
		add_child(anchor)
		var w := float(b.size[0])
		var d := float(b.size[1])
		var h := float(b.height)
		if str(b.kind) in ["tower","ruin"]:
			_tower(anchor,w,d,h,str(b.kind)=="ruin")
		else:
			house_index+=1
			var variant := 1+((house_index-1)%4)
			var house := model("res://assets/models/medieval_village/medieval_house_%02d.glb"%variant,anchor,Vector3(w,h,d))
			_warm_windows(house)
			# Reinforce a grounded foundation and add lived-in details to the raw kit.
			box(anchor,Vector3(w,0.16,d),Vector3(0,0.035,0),mat(Color("4d4d44")))
			for side: int in [-1,1]:
				var window := box(anchor,Vector3(0.68,0.84,0.03),Vector3(side*w*0.25,h*0.38,d*0.5+0.04),mat(Color("dc9942"),0.8,0.6))
				box(anchor,Vector3(0.06,0.9,0.05),window.position+Vector3(0,0,0.03),mat(Color("3c2f22")))
				box(anchor,Vector3(0.72,0.06,0.05),window.position+Vector3(0,0,0.03),mat(Color("3c2f22")))
			_lantern(anchor,Vector3(-w*0.25,2.1,d*0.5+0.25),false)
		var body := StaticBody3D.new()
		body.collision_layer=1
		body.collision_mask=0
		anchor.add_child(body)
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		var camera_height := h*1.22 if str(b.kind)=="tower" else h
		shape.size=Vector3(w,camera_height,d)
		collider.shape=shape
		collider.position.y=camera_height*0.5
		body.add_child(collider)
	# A covered gate beam frames the road while leaving the centre traversable.
	var gate := Node3D.new()
	gate.position=C.ground_position(0,3)
	add_child(gate)
	box(gate,Vector3(13.0,0.45,1.1),Vector3(0,5.45,0),mat(Color("4c3827")))
	for x: int in [-5,5]:
		box(gate,Vector3(0.26,4.8,0.3),Vector3(x,2.6,0),mat(Color("4b3424")))
		_lantern(gate,Vector3(x,2.8,0.5),true)
	var banner := box(gate,Vector3(2.3,2.1,0.05),Vector3(0,4.3,0),mat(Color("683831")))
	banner.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sigil := cylinder(gate,0.37,0.04,Vector3(0,4.37,0.06),mat(Color("b9a779")),0.37,6)
	sigil.rotation.x=PI/2
	# Roadside sign and stone well are outside traversable main lanes.
	var sign := Node3D.new()
	sign.position=C.ground_position(5.3,13)
	add_child(sign)
	cylinder(sign,0.09,2.5,Vector3(0,1.25,0),mat(Color("4c3928")))
	box(sign,Vector3(1.7,0.45,0.12),Vector3(0,2.0,0),mat(Color("6b5136")))
	var label := Label3D.new()
	label.text="THORNWATCH"
	label.font=load("res://assets/cinzel.ttf")
	label.font_size=25
	label.pixel_size=0.0018
	label.modulate=Color("d8c895")
	label.outline_size=2
	label.position=Vector3(0,2.0,0.07)
	sign.add_child(label)
	# Small market awning adds a recognisable service landmark.
	var stall := Node3D.new()
	stall.position=C.ground_position(9.0,28.0)
	add_child(stall)
	for x: float in [-1.5,1.5]:
		for z: float in [-0.7,0.7]:cylinder(stall,0.055,2.7,Vector3(x,1.35,z),mat(Color("55412b")),0.05,8)
	var awning := box(stall,Vector3(3.6,0.05,2.2),Vector3(0,2.65,0),mat(Color("5d7362")))
	awning.rotation.x=0.1
	box(stall,Vector3(2.8,0.14,1.2),Vector3(0,0.82,0),mat(Color("755738")))
	for x: float in [-0.8,0.0,0.8]:box(stall,Vector3(0.58,0.3,0.65),Vector3(x,1.01,0.12),mat(Color("4e3b27")))
	for x: float in [-8.0,7.0]:
		var post := Node3D.new()
		post.position=C.ground_position(x,31)
		add_child(post)
		_lantern(post,Vector3(0,2.7,0),true)
		cylinder(post,0.09,2.9,Vector3(0,1.45,0),mat(Color("3d3326")))

func _tower(parent: Node3D, w: float, d: float, h: float, ruined: bool) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color=Color("aca58c")
	stone.albedo_texture=load("res://assets/models/medieval_village/medieval_house_01_GreyBricks2.jpg")
	stone.uv1_scale=Vector3(2.0,3.0,2.0)
	stone.roughness=1.0
	if ruined:stone=GroundMaterials.weathered_stone()
	box(parent,Vector3(w,h*0.75,d),Vector3(0,h*0.375,0),stone)
	box(parent,Vector3(w+0.36,0.35,d+0.36),Vector3(0,h*0.71,0),stone if ruined else mat(Color("635f50")))
	if not ruined:
		box(parent,Vector3(w+0.15,h*0.17,d+0.15),Vector3(0,h*0.81,0),mat(Color("59432d")))
		var roof := CylinderMesh.new()
		roof.bottom_radius=w*0.87
		roof.top_radius=0
		roof.height=h*0.38
		roof.radial_segments=4
		var r := mesh(parent,roof,Vector3(0,h*1.025,0),mat(Color("374347")))
		r.rotation.y=PI/4
		# Visible timber edging breaks up the silhouette of the steep roof.
		for side: int in [-1,1]:
			box(parent,Vector3(w+0.55,0.16,0.17),Vector3(0,h*0.835,side*(d*0.5+0.3)),mat(Color("302b23")))
		for x: float in [-w*0.36,0.0,w*0.36]:
			box(parent,Vector3(0.2,h*0.2,0.18),Vector3(x,h*0.81,d*0.5+0.15),mat(Color("30291e")))
		_lantern(parent,Vector3(0,h*0.45,d*0.5+0.1),false)
	else:
		for i: int in range(4):
			box(parent,Vector3(0.6,0.7+float(i%2)*0.45,0.7),Vector3(-w*0.4+float(i)*w*0.26,h*0.78,d*0.36),stone)
		for i: int in range(5):
			var rubble := box(parent,Vector3(0.7,0.5,0.5),Vector3((float(i)-2)*0.85,0.25,d*0.5+0.4),stone)
			rubble.rotation=Vector3(0.1*i,0.8*i,0.23*i)
	for z: float in [-d*0.5-0.035,d*0.5+0.035]:
		box(parent,Vector3(0.18,1.4,0.03),Vector3(0,h*0.45,z),mat(Color("242c29")))

func _lantern(parent: Node3D, pos: Vector3, light: bool) -> void:
	var steel := mat(Color("302f25"),0.55)
	box(parent,Vector3(0.27,0.38,0.24),pos,mat(Color("e8a64b"),0.7,1.0))
	box(parent,Vector3(0.34,0.06,0.3),pos+Vector3(0,0.22,0),steel)
	box(parent,Vector3(0.34,0.06,0.3),pos+Vector3(0,-0.22,0),steel)
	for x: float in [-0.12,0.12]:box(parent,Vector3(0.04,0.42,0.28),pos+Vector3(x,0,0),steel)
	if light:
		var glow := OmniLight3D.new()
		glow.position=pos+Vector3(0,0,0.16)
		glow.light_color=Color("ffbc60")
		glow.light_energy=1.2
		glow.omni_range=5.0
		glow.shadow_enabled=false
		parent.add_child(glow)
		_lamps.append(glow)

func _woodland() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed=738927
	var layout := C.woodland_layout()
	for tree_data: Dictionary in layout.trees:
		var holder := Node3D.new()
		holder.name=str(tree_data.id)
		holder.position=C.ground_position(float(tree_data.pos[0]),float(tree_data.pos[2]))
		add_child(holder)
		var tree := model("res://assets/models/forest/pine.glb" if bool(tree_data.pine) else "res://assets/models/forest/broadleaf.glb",holder)
		tree.scale=Vector3.ONE*float(tree_data.height)
		tree.rotation.y=float(tree_data.yaw)
	for rock_data: Dictionary in layout.rocks:
		var holder := Node3D.new()
		holder.name=str(rock_data.id)
		holder.position=C.ground_position(float(rock_data.pos[0]),float(rock_data.pos[2]))
		add_child(holder)
		_rock(holder,C.vector(rock_data.size),int(rock_data.variant))
		holder.rotation.y=float(rock_data.yaw)
	# Sparse close ground cover keeps the road readable and the forest rich.
	var blade := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for angle: float in [0.0,0.9,1.9,2.8]:
		var side := Vector3(cos(angle),0,sin(angle))*0.018
		var bend := Vector3(sin(angle)*0.045,0.17,cos(angle)*0.045)
		var tip := Vector3(sin(angle)*0.11,0.27,cos(angle)*0.11)
		for v: Vector3 in [-side,side,bend+side*0.65,-side,bend+side*0.65,bend-side*0.65,bend-side*0.65,bend+side*0.65,tip]:
			vertices.append(v)
			normals.append(Vector3.UP)
			colors.append((Color("7d7952") if v.y>0.1 else Color("394631")).srgb_to_linear())
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colors
	blade.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var blades := MultiMesh.new()
	blades.transform_format=MultiMesh.TRANSFORM_3D
	blades.mesh=blade
	blades.instance_count=4800
	for i: int in range(4800):
		var x := rng.randf_range(-80,80)
		var z := rng.randf_range(-100,82)
		if absf(x)<5.5 or C.blocked(Vector3(x,0,z),0.5) or (absf(z-26)<5 and absf(x)<28):x+=signf(x)*8.0
		var s := rng.randf_range(0.6,1.3)
		var t := Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*s),C.ground_position(x,z))
		blades.set_instance_transform(i,t)
	var patch := MultiMeshInstance3D.new()
	patch.multimesh=blades
	patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var grass := StandardMaterial3D.new()
	grass.vertex_color_use_as_albedo=true
	grass.cull_mode=BaseMaterial3D.CULL_DISABLED
	grass.roughness=1.0
	patch.material_override=grass
	add_child(patch)

func _landmarks() -> void:
	# Carved waystones and a broken royal seal mark the old watchtower clearing.
	var root := Node3D.new()
	root.position=C.ground_position(0,-76)
	add_child(root)
	var seal := CylinderMesh.new()
	seal.top_radius=5.4
	seal.bottom_radius=5.4
	seal.height=0.12
	seal.radial_segments=40
	mesh(root,seal,Vector3(0,-0.052,0),GroundMaterials.weathered_stone())
	for i: int in range(8):
		var a := float(i)/8*TAU
		var obelisk := box(root,Vector3(0.6,1.5,0.45),Vector3(sin(a)*7.0,0.75,cos(a)*7.0),GroundMaterials.weathered_stone())
		obelisk.rotation.z=sin(a)*0.12
		obelisk.rotation.y=a
	for p: Vector2 in [Vector2(-4,-7),Vector2(5,-39),Vector2(-6,-54)]:
		var post := Node3D.new()
		post.position=C.ground_position(p.x,p.y)
		add_child(post)
		box(post,Vector3(0.35,1.2,0.3),Vector3(0,0.6,0),GroundMaterials.weathered_stone())
		box(post,Vector3(0.75,0.22,0.3),Vector3(0,1.05,0),GroundMaterials.weathered_stone())
		_lantern(post,Vector3(0,1.5,0),false)
