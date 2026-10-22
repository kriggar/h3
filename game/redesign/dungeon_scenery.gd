extends "res://game/redesign/environment_kit.gd"
## Native dressing for registered hunt layouts. Interior solids stay inside
## their authoritative obstacle rectangles; extra scenery lives beyond bounds.

const FIR: String = "res://assets/models/fir_sapling/fir_sapling_lod.glb"
var registered_obstacle_visuals: Array[Node3D] = []
var _motes: Array[Dictionary] = []

func build_hunt_scenery(arena: Dictionary) -> void:
	var layout: String = str(arena.get("layoutId", "bell_crypt"))
	var bounds: Array = arena.bounds
	var center := Vector3((float(bounds[0])+float(bounds[2]))*0.5, 0, (float(bounds[1])+float(bounds[3]))*0.5)
	var span := Vector2(float(bounds[2])-float(bounds[0]), float(bounds[3])-float(bounds[1]))
	_configure_hunt_light(layout)
	# The ground continues beyond the playable boundary and camera zoom range;
	# its mesh edge must never masquerade as a cliff into an unlit void.
	var floor_mesh := plane(self, center, span+Vector2(110, 110), _hunt_floor(layout))
	floor_mesh.name = "RegisteredHuntGround"
	_build_perimeter(arena, layout)
	for index: int in range(arena.obstacles.size()):
		var obstacle: Dictionary = arena.obstacles[index]
		var rect: Array = obstacle.rect
		var root := Node3D.new()
		root.name = "RegisteredObstacle%02d" % index
		root.set_meta("collision_rect", rect.duplicate())
		root.set_meta("kind", str(obstacle.get("kind", "rubble")))
		add_child(root)
		registered_obstacle_visuals.append(root)
		match str(obstacle.get("kind", "rubble")):
			"fence": _timber_barrier(root, rect, index)
			"pier": _stone_pier(root, rect, index)
			_: _rock_obstacle(root, rect, index, layout)
	_build_outer_dressing(arena, layout)
	_build_ambient_motes(arena, layout)

func _configure_hunt_light(layout: String) -> void:
	match layout:
		"briar_kennels":
			environment.background_color = Color("25382c")
			environment.ambient_light_color = Color("c8d4b7")
			environment.ambient_light_energy = 0.49
			environment.fog_light_color = Color("687e61")
			environment.fog_density = 0.0028
			sun.light_color = Color("ffe3ad")
			sun.light_energy = 0.88
			sun.rotation_degrees = Vector3(-53, -43, 0)
		"ashen_cellar":
			environment.background_color = Color("252020")
			environment.ambient_light_color = Color("c0b3a1")
			environment.ambient_light_energy = 0.55
			environment.fog_light_color = Color("5d4d42")
			environment.fog_density = 0.0035
			sun.light_color = Color("e3c7a7")
			sun.light_energy = 0.78
		"moonfang_underpass":
			environment.background_color = Color("17272f")
			environment.ambient_light_color = Color("a9c4cf")
			environment.ambient_light_energy = 0.57
			environment.fog_light_color = Color("3c5968")
			environment.fog_density = 0.004
			sun.light_color = Color("b9e1f1")
			sun.light_energy = 0.87
			sun.rotation_degrees = Vector3(-64, 28, 0)

func _hunt_floor(layout: String) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D earth : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D forest : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D forest_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform int location = 0;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = world.xz;
 vec3 soil = texture(earth, p * 0.29).rgb;
 vec3 moss = texture(forest, p * 0.32).rgb;
 float patches = smoothstep(-0.45, 0.75, sin(p.x * 0.37) * cos(p.y * 0.31));
 float trail = 1.0 - smoothstep(0.8, 2.9, abs(p.x - sin(p.y * 0.19) * 2.0));
 ALBEDO = mix(moss * vec3(0.55, 0.65, 0.50), soil * vec3(0.65, 0.58, 0.48), max(trail * 0.85, patches * 0.46));
 NORMAL_MAP = mix(texture(forest_normal, p * 0.32).rgb, texture(earth_normal, p * 0.29).rgb, trail);
 NORMAL_MAP_DEPTH = 0.45;
 if (location > 0) {
  vec2 grid = p * vec2(0.65, 0.52);
  grid.x += mod(floor(grid.y), 2.0) * 0.5;
  vec2 tile = fract(grid);
  float seam = 1.0 - smoothstep(0.015, 0.045, min(min(tile.x, 1.0-tile.x), min(tile.y, 1.0-tile.y)));
  float grain = fract(sin(dot(floor(grid), vec2(12.9898, 78.233))) * 43758.5453);
  vec3 stone_detail = texture(rock, p * 0.19).rgb;
  vec3 tint = location == 1 ? vec3(0.56, 0.46, 0.36) : vec3(0.38, 0.48, 0.52);
  ALBEDO = stone_detail * tint * (0.86 + grain * 0.22) * (1.0 - seam * 0.35);
  if (location == 2) ALBEDO = mix(ALBEDO, soil * vec3(0.39, 0.50, 0.48), patches * 0.38);
  NORMAL_MAP = texture(earth_normal, p * 0.35).rgb;
  NORMAL_MAP_DEPTH = 0.20;
 }
 ROUGHNESS = location == 2 ? 0.79 : 0.96;
 SPECULAR = 0.18;
}"""
	var result := ShaderMaterial.new()
	result.shader = shader
	var base := "res://assets/models/materials/"
	result.set_shader_parameter("earth", filtered_texture(load(base+"brown_mud_leaves_01/albedo.jpg")))
	result.set_shader_parameter("forest", filtered_texture(load(base+"forrest_ground_01/albedo.jpg")))
	result.set_shader_parameter("rock", filtered_texture(load(STONE_TEX)))
	result.set_shader_parameter("earth_normal", filtered_texture(load(base+"brown_mud_leaves_01/normal.jpg")))
	result.set_shader_parameter("forest_normal", filtered_texture(load(base+"forrest_ground_01/normal.jpg")))
	result.set_shader_parameter("location", 0 if layout=="briar_kennels" else (1 if layout=="ashen_cellar" else 2))
	return result

func _rect_center(rect: Array, height: float = 0.0) -> Vector3:
	return Vector3(float(rect[0])+float(rect[2])*0.5, height, float(rect[1])+float(rect[3])*0.5)

func _timber_barrier(parent: Node3D, rect: Array, index: int) -> void:
	var width := float(rect[2])
	var depth := float(rect[3])
	var along_x := width >= depth
	var length := width if along_x else depth
	var base_mat := material(Color("736953"), 0.98, STONE_TEX)
	var timber := material(Color("6e5943"), 0.96, WOOD_TEX)
	box(parent, _rect_center(rect, 0.18), Vector3(width, 0.36, depth), base_mat)
	var count := maxi(2, ceili(length/0.68))
	for post: int in range(count+1):
		var offset := lerpf(-length*0.5+0.16, length*0.5-0.16, float(post)/float(count))
		var at := _rect_center(rect)
		at += Vector3(offset, 0, 0) if along_x else Vector3(0, 0, offset)
		var height := 1.35+0.12*sin(float(post+index)*1.8)
		box(parent, at+Vector3(0, height*0.5, 0), Vector3(0.19, height, 0.19), timber)
		cylinder(parent, at+Vector3(0, height+0.09, 0), 0.13, 0.18, timber, 0.025)
	for height: float in [0.58, 1.03]:
		box(parent, _rect_center(rect, height), Vector3(width-0.08, 0.13, 0.16) if along_x else Vector3(0.16, 0.13, depth-0.08), timber)

func _stone_pier(parent: Node3D, rect: Array, index: int) -> void:
	var width := float(rect[2])
	var depth := float(rect[3])
	var worn := material(Color("9a8870"), 0.94, STONE_TEX)
	var dark := material(Color("5a4c3e"), 0.98, STONE_TEX)
	box(parent, _rect_center(rect, 0.15), Vector3(width, 0.3, depth), dark)
	box(parent, _rect_center(rect, 1.22), Vector3(width-0.27, 2.14, depth-0.27), worn)
	for height: float in [0.45, 1.0, 1.57, 2.2]:
		box(parent, _rect_center(rect, height), Vector3(width-0.14, 0.12, depth-0.14), dark)
	box(parent, _rect_center(rect, 2.41), Vector3(width, 0.3, depth), worn)
	cylinder(parent, _rect_center(rect, 2.63), 0.3, 0.14, bronze, 0.24)
	fire(parent, _rect_center(rect, 2.73), 0.57 if index%2==0 else 0.45)

func _fitted_model(parent: Node3D, source: String, piece: String, rect: Array, height: float) -> Node3D:
	var fitted := Node3D.new()
	parent.add_child(fitted)
	var piece_node := model(source, piece, fitted, height)
	var bounds: Vector3 = piece_node.get_meta("normalized_size", Vector3.ONE)
	# The fort wall is authored along Z. Rotate the child before fitting its
	# parent so horizontal walls retain their masonry and crenellation form.
	if source==FORT and ((float(rect[2])>float(rect[3])) != (bounds.x>bounds.z)):
		piece_node.rotation.y=PI*0.5
		bounds=Vector3(bounds.z,bounds.y,bounds.x)
	fitted.scale.x = float(rect[2])/maxf(0.001, bounds.x)
	fitted.scale.z = float(rect[3])/maxf(0.001, bounds.z)
	fitted.position = _rect_center(rect)
	return fitted

func _rock_obstacle(parent: Node3D, rect: Array, index: int, layout: String) -> void:
	var width := float(rect[2])
	var depth := float(rect[3])
	var stone_color := Color("6d7774") if layout=="moonfang_underpass" else Color("7b7760")
	box(parent, _rect_center(rect, 0.22), Vector3(width, 0.44, depth), material(stone_color, 0.98, STONE_TEX))
	var along_x := width>=depth
	var count := maxi(1, ceili(maxf(width, depth)/2.3))
	for part: int in range(count):
		var area := rect.duplicate()
		if along_x:
			area[0] = float(rect[0])+width*float(part)/float(count)+0.035
			area[2] = width/float(count)-0.07
		else:
			area[1] = float(rect[1])+depth*float(part)/float(count)+0.035
			area[3] = depth/float(count)-0.07
		_fitted_model(parent, ROCKS, "rock_moss_set_02_rock%02d" % (7+(index+part)%7), area, 1.25+0.25*float((index+part)%3))

func _build_perimeter(arena: Dictionary, layout: String) -> void:
	var b: Array = arena.bounds
	var width := float(b[2])-float(b[0])
	var depth := float(b[3])-float(b[1])
	var sides: Array = [
		[float(b[0])-0.8, float(b[1])-0.8, 0.8, depth+1.6],
		[float(b[2]), float(b[1])-0.8, 0.8, depth+1.6],
		[float(b[0]), float(b[1])-0.8, width, 0.8],
		[float(b[0]), float(b[3]), width, 0.8]
	]
	for side: int in range(sides.size()):
		var rect: Array = sides[side]
		var wall := Node3D.new()
		wall.name = "Boundary%d" % side
		add_child(wall)
		if layout=="briar_kennels":
			_timber_barrier(wall, rect, side)
		else:
			var along_x := float(rect[2])>=float(rect[3])
			var length := maxf(float(rect[2]), float(rect[3]))
			var count := maxi(1, ceili(length/3.0))
			for part: int in range(count):
				var area := rect.duplicate()
				if along_x:
					area[0] = float(rect[0])+length*float(part)/float(count)
					area[2] = length/float(count)
				else:
					area[1] = float(rect[1])+length*float(part)/float(count)
					area[3] = length/float(count)
				_fitted_model(wall, FORT, "modular_fort_01_wall_thin_straight_01", area, 0.85 if side==3 else (2.7 if side==2 else 2.25))

func _build_outer_dressing(arena: Dictionary, layout: String) -> void:
	var b: Array = arena.bounds
	var min_z := float(b[1])
	var max_z := float(b[3])
	for side: float in [-1, 1]:
		var edge := float(b[0])-1.2 if side<0 else float(b[2])+1.2
		for index: int in range(5):
			var z := lerpf(min_z+0.6, max_z-1.4, float(index)/4.0)
			if layout=="briar_kennels":
				# The source scene contains three separated trees. Use one named
				# sapling so group normalization cannot put a trunk inside the arena.
				var tree := model(FIR, "fir_sapling_a", self, 4.2+0.45*float(index%3))
				tree.position = Vector3(edge+side*2.7, 0, z)
				tree.rotation.y = float(index)*1.7+side
				var outer_tree := model(FIR, "fir_sapling_a", self, 5.2+0.3*float(index%3))
				outer_tree.position = Vector3(edge+side*5.4, 0, z-1.9)
				outer_tree.rotation.y = float(index)*2.1
			elif layout=="moonfang_underpass":
				_fitted_model(self, ROCKS, "rock_moss_set_02_rock%02d" % (7+index%7), [edge-0.8, z-1.5, 1.6, 3.0], 2.8+0.35*float(index%3))
			else:
				var barrel := model(BARREL, "", self, 1.1+0.1*float(index%2))
				barrel.position = Vector3(edge, 0, z)
				barrel.rotation.y = float(index)*0.9
		for z: float in [min_z+3.0, max_z-3.0]:
			var post := Vector3(edge, 0, z)
			cylinder(self, post+Vector3(0, 0.65, 0), 0.12, 1.3, bronze)
			cylinder(self, post+Vector3(0, 1.34, 0), 0.29, 0.15, bronze, 0.22)
			fire(self, post+Vector3(0, 1.46, 0), 0.62 if layout=="moonfang_underpass" else 0.78)
	var middle := (float(b[0])+float(b[2]))*0.5
	var color := Color("52643e") if layout=="briar_kennels" else (Color("833f29") if layout=="ashen_cellar" else Color("496e7f"))
	for offset: float in [-3.0, 3.0]:
		banner(self, Vector3(middle+offset, 0, min_z-1.1), 3.6, color)
	if layout=="briar_kennels":
		for index: int in range(8):
			var tree := model(FIR,"fir_sapling_a",self,4.9+0.4*float(index%3))
			tree.position=Vector3(lerpf(float(b[0])-4,float(b[2])+4,float(index)/7.0),0,min_z-4.6-float(index%2)*1.3)
			tree.rotation.y=float(index)*1.3
		for side: float in [-1,1]:
			_kennel_shelter(Vector3(middle+side*6.2,0,min_z-2.5))
	if layout=="ashen_cellar":
		var charred := material(Color("3d332c"), 0.99, WOOD_TEX)
		for side: float in [-1, 1]:
			var x := float(b[0])-1.4 if side<0 else float(b[2])+1.4
			box(self, Vector3(x, 1.7, min_z-1.9), Vector3(0.6, 3.4, 0.6), charred)
		box(self, Vector3(middle, 3.2, min_z-1.9), Vector3(float(b[2])-float(b[0])+3.5, 0.48, 0.6), charred)

func _kennel_shelter(position: Vector3) -> void:
	var root := Node3D.new()
	root.position=position
	add_child(root)
	var timber := material(Color("5c4936"),0.98,WOOD_TEX)
	var roof := material(Color("3c3b30"),0.99,WOOD_TEX)
	box(root,Vector3(0,0.12,0),Vector3(3.4,0.24,2.4),stone)
	box(root,Vector3(0,0.86,-1.0),Vector3(3.2,1.5,0.18),timber)
	for side: float in [-1,1]:
		box(root,Vector3(side*1.5,0.86,0),Vector3(0.17,1.5,2.1),timber)
		box(root,Vector3(side*1.5,0.95,0.98),Vector3(0.2,1.9,0.2),timber)
		var pitch := box(root,Vector3(side*0.83,2.0,0),Vector3(1.9,0.16,2.8),roof)
		pitch.rotation.z=-side*0.35
	box(root,Vector3(0,2.3,0),Vector3(0.18,0.18,2.85),timber)

func _build_ambient_motes(arena: Dictionary, layout: String) -> void:
	var b: Array = arena.bounds
	var mat := material(Color("a8c17b") if layout=="briar_kennels" else (Color("d9a670") if layout=="ashen_cellar" else Color("96c8d3")))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 1.25
	for index: int in range(12):
		var mote := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.024 if layout=="briar_kennels" else 0.014
		mesh.height = mesh.radius*2.0
		mesh.radial_segments = 6
		mesh.rings = 3
		mote.mesh = mesh
		mote.material_override = mat
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var at := Vector3(lerpf(float(b[0])+1, float(b[2])-1, fmod(float(index)*0.618, 1.0)), 0.6+fmod(float(index)*0.37, 1.5), lerpf(float(b[1])+1, float(b[3])-1, fmod(float(index)*0.423, 1.0)))
		mote.position = at
		add_child(mote)
		_motes.append({"node":mote, "base":at, "phase":float(index)*1.73})

func _process(delta: float) -> void:
	super._process(delta)
	for mote: Dictionary in _motes:
		var phase := float(mote.phase)
		mote.node.position = mote.base+Vector3(sin(_time*0.36+phase)*0.3, sin(_time*0.65+phase)*0.18, cos(_time*0.29+phase)*0.2)
