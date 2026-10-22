extends Node3D
## Shared native 3D presentation helpers. Geometry never changes authoritative rules.

const FORT: String = "res://assets/models/modular_fort_01/modular_fort_01_1k.gltf"
const ROCKS: String = "res://assets/models/rock_moss_set_02/rock_moss_set_02_1k.gltf"
const BARREL: String = "res://assets/models/wine_barrel_01/wine_barrel_lod.glb"
const CHEST: String = "res://assets/models/treasure_chest/treasure_chest_1k.gltf"
const WOOD_TEX: String = "res://assets/models/medieval_village/medieval_house_02_Wood.jpg"
const STONE_TEX: String = "res://assets/models/medieval_village/medieval_house_02_Stone.jpg"

var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var wood: StandardMaterial3D
var stone: StandardMaterial3D
var bronze: StandardMaterial3D
var cloth: StandardMaterial3D
var _parts: Dictionary = {}
var _textures: Dictionary = {}
var _materials: Dictionary = {}
var _fires: Array = []
var _time: float = 0.0

func material(color: Color, roughness: float = 0.9, texture_path: String = "") -> StandardMaterial3D:
	var result: StandardMaterial3D = StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		result.albedo_texture = filtered_texture(load(texture_path))
		result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return result

func filtered_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var key: int = texture.get_rid().get_id()
	if _textures.has(key):
		return _textures[key]
	var pixels: Image = texture.get_image()
	if pixels != null and not pixels.has_mipmaps():
		if pixels.is_compressed():
			pixels.decompress()
		pixels.generate_mipmaps()
		_textures[key] = ImageTexture.create_from_image(pixels)
	else:
		_textures[key] = texture
	return _textures[key]

func filtered_material(source: Material) -> Material:
	if not source is StandardMaterial3D:
		return source
	var key: int = source.get_rid().get_id()
	if not _materials.has(key):
		var result: StandardMaterial3D = source.duplicate() as StandardMaterial3D
		result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		result.albedo_texture = filtered_texture(result.albedo_texture)
		result.normal_texture = filtered_texture(result.normal_texture)
		result.roughness_texture = filtered_texture(result.roughness_texture)
		_materials[key] = result
	return _materials[key]

func setup_light(interior: bool = false, with_sky: bool = true) -> void:
	wood = material(Color("887059"), 0.94, WOOD_TEX)
	stone = material(Color("8c897c"), 0.96, STONE_TEX)
	bronze = material(Color("9e8049"), 0.48)
	bronze.metallic = 0.65
	cloth = material(Color("b29b76"), 0.97)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 36.0
	camera.near = 0.1
	camera.far = 180.0
	camera.current = true
	add_child(camera)
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR if interior or not with_sky else Environment.BG_SKY
	environment.background_color = Color("131a1b")
	if with_sky:
		var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
		sky_material.sky_top_color = Color("758d94")
		sky_material.sky_horizon_color = Color("b8b8a0")
		sky_material.ground_bottom_color = Color("293c2b")
		sky_material.ground_horizon_color = Color("869386")
		var sky: Sky = Sky.new()
		sky.sky_material = sky_material
		environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8fa5b3") if interior else Color("c6cfbd")
	environment.ambient_light_energy = 0.42 if interior else 0.46
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.tonemap_exposure = 1.0
	environment.fog_enabled = true
	environment.fog_light_color = Color("3d5154") if interior else Color("9aafa4")
	environment.fog_density = 0.006 if interior else 0.0035
	environment.fog_light_energy = 0.4
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -36, 0)
	sun.light_color = Color("98b8cb") if interior else Color("ffe5b6")
	sun.light_energy = 0.68 if interior else 0.98
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 75.0
	sun.shadow_bias = 0.025
	sun.shadow_normal_bias = 0.7
	add_child(sun)

func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	parent.add_child(instance)
	return instance

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, top_radius: float = -1.0) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0 else top_radius
	mesh.height = height
	mesh.radial_segments = 12
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	parent.add_child(instance)
	return instance

func plane(parent: Node3D, pos: Vector3, size: Vector2, mat: Material) -> MeshInstance3D:
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	parent.add_child(instance)
	return instance

func _collect_meshes(node: Node, transform: Transform3D, match_name: String, found: bool, output: Array) -> void:
	var current: Transform3D = transform * node.transform if node is Node3D else transform
	var matches: bool = found or match_name.is_empty() or str(node.name) == match_name
	if matches and node is MeshInstance3D and node.mesh != null:
		output.append({"mesh":node.mesh, "transform":current, "override":node.material_override})
	for child: Node in node.get_children():
		_collect_meshes(child, current, match_name, matches, output)

func model(path: String, piece: String, parent: Node3D, height: float) -> Node3D:
	var key: String = path + "::" + piece
	if not _parts.has(key):
		var descriptors: Array = []
		if ResourceLoader.exists(path):
			var packed: PackedScene = load(path) as PackedScene
			if packed != null:
				var source: Node = packed.instantiate()
				_collect_meshes(source, Transform3D.IDENTITY, piece, false, descriptors)
				source.free()
		_parts[key] = descriptors
	var parts: Array = _parts[key]
	if parts.is_empty():
		push_warning("Missing model presentation: " + path + " / " + piece)
		var missing: Node3D = Node3D.new()
		parent.add_child(missing)
		return missing
	var bounds: AABB
	var first: bool = true
	for item: Dictionary in parts:
		var bounds_part: AABB = item.transform * item.mesh.get_aabb()
		bounds = bounds_part if first else bounds.merge(bounds_part)
		first = false
	var factor: float = height / maxf(0.001, bounds.size.y)
	var root: Node3D = Node3D.new()
	root.name = piece if not piece.is_empty() else path.get_file().get_basename()
	parent.add_child(root)
	var normalized: Node3D = Node3D.new()
	normalized.scale = Vector3.ONE * factor
	normalized.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	root.add_child(normalized)
	for item: Dictionary in parts:
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = item.mesh
		mesh_instance.transform = item.transform
		mesh_instance.material_override = item.override
		for surface: int in range(mesh_instance.mesh.get_surface_count()):
			mesh_instance.set_surface_override_material(surface,filtered_material(mesh_instance.mesh.surface_get_material(surface)))
		mesh_instance.lod_bias = 0.6
		normalized.add_child(mesh_instance)
	root.set_meta("normalized_size", bounds.size * factor)
	return root

func house(parent: Node3D, pos: Vector3, height: float, variant: int = 0, yaw: float = 0.0) -> Node3D:
	var root: Node3D = model("res://assets/models/medieval_village/medieval_house_%02d.glb" % (variant % 4 + 1), "", parent, height)
	root.position = pos
	root.rotation.y = yaw
	return root

func terrain(size: Vector2, divisions: int = 50, interior: bool = false) -> MeshInstance3D:
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = size
	mesh.subdivide_width = divisions
	mesh.subdivide_depth = divisions
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D soil : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool inside = false;
varying vec3 world;
void vertex(){ world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec3 a=texture(soil,world.xz*0.28).rgb;
 vec3 b=texture(moss,world.xz*0.33).rgb;
 float road=1.0-smoothstep(1.4,2.6,abs(world.x+sin(world.z*0.12)*0.7));
 float crossroad=1.0-smoothstep(1.3,2.4,abs(world.z-1.8));
 float yard=1.0-smoothstep(5.0,12.0,length(world.xz-vec2(0,-8)));
 ALBEDO=mix(b*vec3(0.71,0.78,0.56),a*vec3(0.77,0.69,0.56),max(max(road,crossroad),yard*0.7));
 if(inside){
  vec2 tile=fract(world.xz*0.5);
  float seam=1.0-smoothstep(0.012,0.035,min(min(tile.x,1.0-tile.x),min(tile.y,1.0-tile.y)));
  float variation=fract(sin(dot(floor(world.xz*0.5),vec2(12.9898,78.233)))*43758.5453);
  float detail=dot(a,vec3(0.3,0.59,0.11));
  ALBEDO=vec3(0.27,0.29,0.28)*(0.85+variation*0.22)*(0.9+detail*0.25)*(1.0-seam*0.40);
 }
 ROUGHNESS=0.95; SPECULAR=0.12;
}"""
	var ground: ShaderMaterial = ShaderMaterial.new()
	ground.shader = shader
	ground.set_shader_parameter("soil", filtered_texture(load("res://assets/models/materials/brown_mud_leaves_01/albedo.jpg")))
	ground.set_shader_parameter("moss", filtered_texture(load("res://assets/models/materials/forrest_ground_01/albedo.jpg")))
	ground.set_shader_parameter("inside", interior)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "NativeGround"
	instance.mesh = mesh
	instance.material_override = ground
	add_child(instance)
	return instance

func water(parent: Node3D, pos: Vector3, size: Vector2) -> void:
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode diffuse_burley;
varying vec3 world;
void vertex(){ world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 float ripple=sin(world.x*6.0+world.z*3.0+TIME*0.8)*cos(world.z*12.0+TIME*0.5);
 ALBEDO=vec3(0.10,0.19,0.19)*(1.0+ripple*0.08);
 NORMAL=normalize(NORMAL+vec3(ripple*0.035,0.0,cos(world.z*6.0+TIME)*0.02));
 ROUGHNESS=0.18; METALLIC=0.25; SPECULAR=0.85;
}"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	plane(parent, pos, size, mat).name = "LivingRiver"

func banner(parent: Node3D, pos: Vector3, height: float = 3.5, color: Color = Color("7a2f28")) -> void:
	cylinder(parent, pos + Vector3(0, height * 0.5, 0), 0.045, height, wood)
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth_color:source_color=vec4(0.4,0.12,0.1,1);
void vertex(){VERTEX.z+=sin(TIME*1.6+UV.x*4.0+UV.y*2.0)*UV.x*0.08;}
void fragment(){ALBEDO=cloth_color.rgb*(0.88+0.12*cos(UV.x*30.0));ROUGHNESS=1.0;}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("cloth_color", color)
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(height * 0.35, height * 0.48)
	mesh.orientation = PlaneMesh.FACE_Z
	mesh.subdivide_width = 10
	mesh.subdivide_depth = 8
	var flag: MeshInstance3D = MeshInstance3D.new()
	flag.mesh = mesh
	flag.material_override = mat
	flag.position = pos + Vector3(height * 0.175, height * 0.73, 0)
	parent.add_child(flag)

func fire(parent: Node3D, pos: Vector3, strength: float = 1.0) -> void:
	var mat: StandardMaterial3D = material(Color("e5a34c"), 0.9)
	mat.emission_enabled = true
	mat.emission = Color("ff9c35")
	mat.emission_energy_multiplier = 2.3
	var flame: MeshInstance3D = cylinder(parent, pos + Vector3(0, 0.22, 0), 0.1 * strength, 0.55 * strength, mat, 0.015)
	var light: OmniLight3D = OmniLight3D.new()
	light.position = pos + Vector3(0, 0.5, 0)
	light.light_color = Color("ffae64")
	light.light_energy = 1.7 * strength
	light.omni_range = 7.0 * strength
	light.omni_attenuation = 1.1
	parent.add_child(light)
	_fires.append({"mesh":flame, "light":light, "base":strength, "phase":float(_fires.size()) * 2.39})

func _process(delta: float) -> void:
	_time += delta
	for index: int in range(_fires.size() - 1, -1, -1):
		var item: Dictionary = _fires[index]
		if not is_instance_valid(item.mesh):
			_fires.remove_at(index)
			continue
		item.mesh.scale.y = 0.92 + sin(_time * 8.0 + item.phase) * 0.12 + sin(_time * 19.0) * 0.04
		item.light.light_energy = float(item.base) * (1.7 + sin(_time * 7.0 + item.phase) * 0.16)

func ground_point(screen_position: Vector2) -> Variant:
	return Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))
