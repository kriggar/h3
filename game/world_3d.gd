extends Node3D
## Native three-dimensional campaign presentation. Placement has a separate,
## deterministic visual noise function and never changes campaign RNG or rules.
const FORT: String = "res://assets/models/modular_fort_01/modular_fort_01_1k.gltf"
const FIR: String = "res://assets/models/fir_sapling/fir_sapling_lod.glb"
const ROCK: String = "res://assets/models/rock_moss_set_02/rock_moss_set_02_1k.gltf"
const HOUSE: String = "res://assets/models/medieval_house/medieval_house.gltf"
const FOREST_GROUND: String = "res://assets/models/materials/forrest_ground_01/"
const EARTH_GROUND: String = "res://assets/models/materials/brown_mud_leaves_01/"
const MARGIN: int = 24
const SUBDIVISIONS: int = 3
const WATER_LEVEL: float = -0.08

var campaign: Dictionary = {}
var _seed: int = -1
var _width: int = 36
var _depth: int = 26
var _camera: Camera3D
var _environment: Environment
var _sky: ProceduralSkyMaterial
var _sun: DirectionalLight3D
var _geometry: Node3D
var _objects: Node3D
var _overlays: Node3D
var _hero: Node3D
var _height_values: PackedFloat32Array = PackedFloat32Array()
var _height_width: int = 0
var _height_depth: int = 0
var _parts: Dictionary = {}
var _locations: Dictionary = {}
var _actors: Array = []
var _flames: Array = []
var _foliage: Array = []
var _land_material: ShaderMaterial
var _road_material: ShaderMaterial
var _reveal_texture: ImageTexture
var _map_texture: ImageTexture
var _time: float = 0.0
var _hero_walking: bool = false
var _phase: String = ""
var _wood: StandardMaterial3D
var _stone: StandardMaterial3D
var _bronze: StandardMaterial3D
var _linen: StandardMaterial3D

func _ready() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.near = 0.1
	_camera.far = 160.0
	_camera.current = true
	add_child(_camera)
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	_sky = ProceduralSkyMaterial.new()
	_sky.sky_top_color = Color("617986")
	_sky.sky_horizon_color = Color("9ea99d")
	_sky.ground_bottom_color = Color("343d31")
	_sky.ground_horizon_color = Color("9da493")
	_sky.sky_curve = 0.2
	var sky: Sky = Sky.new()
	sky.sky_material = _sky
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("b4c1c2")
	_environment.ambient_light_energy = 0.56
	_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_environment.tonemap_exposure = 1.13
	_environment.fog_enabled = true
	_environment.fog_light_color = Color("a3b1af")
	_environment.fog_light_energy = 0.4
	_environment.fog_density = 0.009
	_environment.fog_sky_affect = 0.5
	var atmosphere: WorldEnvironment = WorldEnvironment.new()
	atmosphere.environment = _environment
	add_child(atmosphere)
	_sun = DirectionalLight3D.new()
	_sun.name = "LateAfternoonSun"
	_sun.rotation_degrees = Vector3(-32.0, -35.0, 0.0)
	_sun.light_color = Color("ffe5b5")
	_sun.light_energy = 1.45
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_sun.directional_shadow_max_distance = 65.0
	_sun.shadow_bias = 0.025
	_sun.shadow_normal_bias = 0.7
	add_child(_sun)
	_geometry = Node3D.new()
	_geometry.name = "TerrainAndLandscape"
	add_child(_geometry)
	_objects = Node3D.new()
	_objects.name = "CampaignLocations"
	add_child(_objects)
	_overlays = Node3D.new()
	_overlays.name = "TravelAndSelection"
	add_child(_overlays)
	_wood = _material(Color("635342"), 0.96)
	_wood.albedo_texture = _repeat_texture("res://assets/models/medieval_village/medieval_house_02_Wood.jpg")
	_stone = _material(Color("77786a"), 0.94)
	_bronze = _material(Color("ad8d49"), 0.55)
	_bronze.metallic = 0.35
	_linen = _material(Color("b9a582"), 0.92)
	if not campaign.is_empty():
		set_campaign(campaign)

func configure_camera(projected: Vector2, zoom: float, viewport_size: Vector2, pixels_per_unit: float, elevation: float) -> void:
	if _camera == null:
		return
	var horizontal: float = projected.x / pixels_per_unit
	var forward: float = projected.y / pixels_per_unit / sin(elevation)
	var target: Vector3 = Vector3((horizontal + forward) / sqrt(2.0), 0.0, (forward - horizontal) / sqrt(2.0))
	_camera.size = maxf(0.5, viewport_size.y / (pixels_per_unit * zoom))
	_camera.position = target + Vector3(cos(elevation) / sqrt(2.0), sin(elevation), cos(elevation) / sqrt(2.0)) * 38.0
	_camera.look_at(target, Vector3.UP)

func set_campaign(value: Dictionary) -> void:
	campaign = value
	if _geometry == null:
		return
	if _seed != int(campaign.seed):
		_seed = int(campaign.seed)
		_width = int(campaign.world.w)
		_depth = int(campaign.world.h)
		_build_world()
	_update_knowledge()
	_update_phase()
	for object: Dictionary in campaign.world.objects:
		var node: Node3D = _locations.get(str(object.id)) as Node3D
		if node != null:
			node.visible = _known(int(object.x), int(object.y)) and not bool(object.get("removed", false)) and not (str(object.type) == "enemy" and bool(object.get("defeated", false)))
			var banner: Node3D = node.get_node_or_null("OwnershipBanner") as Node3D
			if banner != null:
				var color: Color = Color("a58b4e") if str(object.get("owner", "neutral")) == "player" else Color("623d35")
				for piece: Node in banner.get_children():
					if piece is MeshInstance3D and piece.name == "Cloth":
						piece.material_override = _material(color, 0.95)

func _known(x: int, z: int) -> bool:
	return x >= 0 and z >= 0 and x < _width and z < _depth and bool(campaign.revealed[z][x])

func _noise(x: float, z: float) -> float:
	return sin(x * 1.419 + z * 4.127 + float(_seed % 3001)) * 0.5 + sin(x * 0.603 - z * 0.819) * 0.3 + sin(x * 2.173 + z * 0.671) * 0.2

func _random(x: float, z: float, salt: float = 0.0) -> float:
	return fposmod(sin(x * 127.1 + z * 311.7 + salt * 74.7 + float(_seed % 4096)) * 43758.5453, 1.0)

func _tile(x: int, z: int) -> Dictionary:
	return campaign.world.tiles[clampi(z, 0, _depth - 1)][clampi(x, 0, _width - 1)]

func _base_height(x: int, z: int) -> float:
	if x < 0 or z < 0 or x >= _width or z >= _depth:
		var outside: float = maxf(maxf(-float(x), -float(z)), maxf(float(x - _width + 1), float(z - _depth + 1)))
		return 0.2 + outside * (0.11 if x < 0 or z >= _depth else 0.22) + 0.12 * _noise(x * 0.2, z * 0.2)
	var terrain: String = str(_tile(x, z).terrain)
	var base: float = 0.16
	match terrain:
		"water": return -0.36
		"hill": base = 0.55
		"mountain": base = 1.15 + 0.25 * _noise(x * 0.8, z * 0.8)
		"snow": base = 0.32
		"dirt": base = 0.2
	return base + _noise(x * 0.45, z * 0.45) * 0.045

func _sample_height(x: float, z: float) -> float:
	var px: int = floori(x)
	var pz: int = floori(z)
	var fx: float = smoothstep(0.0, 1.0, x - float(px))
	var fz: float = smoothstep(0.0, 1.0, z - float(pz))
	return lerpf(lerpf(_base_height(px, pz), _base_height(px + 1, pz), fx), lerpf(_base_height(px, pz + 1), _base_height(px + 1, pz + 1), fx), fz)

func height_at(x: float, z: float) -> float:
	if _height_values.is_empty():
		return 0.0
	var sx: float = clampf((x + MARGIN) * SUBDIVISIONS, 0.0, float(_height_width - 1) - 0.001)
	var sz: float = clampf((z + MARGIN) * SUBDIVISIONS, 0.0, float(_height_depth - 1) - 0.001)
	var ix: int = floori(sx)
	var iz: int = floori(sz)
	var a: float = lerpf(_height_values[iz * _height_width + ix], _height_values[iz * _height_width + ix + 1], sx - ix)
	var b: float = lerpf(_height_values[(iz + 1) * _height_width + ix], _height_values[(iz + 1) * _height_width + ix + 1], sx - ix)
	return lerpf(a, b, sz - iz)

func walk_height(x: float, z: float) -> float:
	var cell: Dictionary = _tile(roundi(x), roundi(z)) if not campaign.is_empty() else {}
	return maxf(height_at(x, z), 0.11) if bool(cell.get("bridge", false)) else height_at(x, z)

func _normal(x: float, z: float) -> Vector3:
	return Vector3(height_at(x - 0.05, z) - height_at(x + 0.05, z), 0.1, height_at(x, z - 0.05) - height_at(x, z + 0.05)).normalized()

func tile_at_screen(screen: Vector2) -> Vector2i:
	if _camera == null or campaign.is_empty():
		return Vector2i(-1, -1)
	var origin: Vector3 = _camera.project_ray_origin(screen)
	var direction: Vector3 = _camera.project_ray_normal(screen)
	var low: float = 0.0
	var high: float = 150.0
	for iteration: int in range(22):
		var distance: float = (low + high) * 0.5
		var point: Vector3 = origin + direction * distance
		if point.y > walk_height(point.x, point.z):
			low = distance
		else:
			high = distance
	var hit: Vector3 = origin + direction * ((low + high) * 0.5)
	return Vector2i(roundi(hit.x), roundi(hit.z))

func _build_world() -> void:
	for parent: Node3D in [_geometry, _objects, _overlays]:
		for child: Node in parent.get_children():
			child.free()
	_locations.clear()
	_actors.clear()
	_flames.clear()
	_foliage.clear()
	_phase = ""
	_height_width = (_width + MARGIN * 2) * SUBDIVISIONS + 1
	_height_depth = (_depth + MARGIN * 2) * SUBDIVISIONS + 1
	_height_values.resize(_height_width * _height_depth)
	for z: int in range(_height_depth):
		for x: int in range(_height_width):
			_height_values[z * _height_width + x] = _sample_height(float(x) / SUBDIVISIONS - MARGIN, float(z) / SUBDIVISIONS - MARGIN)
	_make_masks()
	_make_materials()
	_make_terrain()
	_make_water()
	_make_roads()
	_make_landscape()
	for object: Dictionary in campaign.world.objects:
		_make_location(object)
	_hero = Node3D.new()
	_hero.name = "IleanaAndRetinue"
	_objects.add_child(_hero)
	_actor(_hero, "knight", Vector3.ZERO, 0.78, true)
	_actor(_hero, "spearman", Vector3(-0.25, 0.0, 0.15), 0.44, true)
	_actor(_hero, "archer", Vector3(0.2, 0.0, 0.2), 0.44, true)
	_banner(_hero, Vector3(-0.2, 0.0, -0.1), 0.92, Color("ae9153"))
	_ring(_hero, Vector3.ZERO, 0.36, Color(0.67, 0.55, 0.31, 0.9), 0.014)

func _make_masks() -> void:
	var mask: Image = Image.create(_width, _depth, false, Image.FORMAT_RGBA8)
	var known: Image = Image.create(_width, _depth, false, Image.FORMAT_RGBA8)
	for z: int in range(_depth):
		for x: int in range(_width):
			var terrain: String = str(_tile(x, z).terrain)
			mask.set_pixel(x, z, Color(1.0 if terrain in ["dirt", "forest"] else 0.0, 1.0 if terrain in ["mountain", "hill"] else 0.0, 0.8 if terrain == "snow" else 0.0, 1.0 if terrain == "water" else 0.0))
			known.set_pixel(x, z, Color.WHITE if _known(x, z) else Color.BLACK)
	_map_texture = ImageTexture.create_from_image(mask)
	_reveal_texture = ImageTexture.create_from_image(known)

func _update_knowledge() -> void:
	if _reveal_texture == null:
		return
	var known: Image = Image.create(_width, _depth, false, Image.FORMAT_RGBA8)
	for z: int in range(_depth):
		for x: int in range(_width):
			known.set_pixel(x, z, Color.WHITE if _known(x, z) else Color.BLACK)
	_reveal_texture.update(known)

func _texture(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _repeat_texture(path: String) -> Texture2D:
	var texture: Texture2D = _texture(path)
	if texture == null:
		return null
	var image: Image = texture.get_image()
	if image != null and not image.has_mipmaps():
		if image.is_compressed():
			image.decompress()
		image.generate_mipmaps()
		return ImageTexture.create_from_image(image)
	return texture

func _make_materials() -> void:
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terrain_mask : filter_linear, repeat_disable;
uniform sampler2D knowledge : filter_linear, repeat_disable;
uniform vec2 map_size = vec2(36.0,26.0);
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 uv=world_pos.xz*0.56;
 vec4 mask=texture(terrain_mask,(world_pos.xz+vec2(0.5))/map_size);
 vec3 grass=texture(grass_tex,uv).rgb*vec3(0.65,0.72,0.57);
 vec3 earth=texture(earth_tex,uv*0.85).rgb*vec3(0.69,0.66,0.60);
 vec3 soil=mix(grass,earth,0.24+mask.r*0.66);
 soil=mix(soil,vec3(0.30,0.32,0.28)*texture(earth_tex,uv*0.4).r*2.0,mask.g*0.55);
 soil=mix(soil,vec3(0.65,0.66,0.60),mask.b*0.6);
 float known=texture(knowledge,(world_pos.xz+vec2(0.5))/map_size).r;
 float grey=dot(soil,vec3(0.3,0.59,0.11));
 ALBEDO=mix(vec3(grey*0.34,grey*0.39,grey*0.37),soil,smoothstep(0.02,0.85,known));

 ROUGHNESS=0.96; SPECULAR=0.12;
}"""
	_land_material = ShaderMaterial.new()
	_land_material.shader = shader
	_land_material.set_shader_parameter("grass_tex", _repeat_texture("res://assets/generated/terrain-grass.png") if ResourceLoader.exists("res://assets/generated/terrain-grass.png") else _repeat_texture(FOREST_GROUND + "albedo.jpg"))
	_land_material.set_shader_parameter("earth_tex", _repeat_texture(EARTH_GROUND + "albedo.jpg"))
	_land_material.set_shader_parameter("ground_normal", _repeat_texture(FOREST_GROUND + "normal.jpg"))
	_land_material.set_shader_parameter("terrain_mask", _map_texture)
	_land_material.set_shader_parameter("knowledge", _reveal_texture)
	_land_material.set_shader_parameter("map_size", Vector2(_width, _depth))
	var road_shader: Shader = Shader.new()
	road_shader.code = """shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform sampler2D earth_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D knowledge : filter_linear, repeat_disable;
uniform vec2 map_size=vec2(36.0,26.0);
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec3 earth=texture(earth_tex,world_pos.xz*1.4).rgb;
 float edge=smoothstep(0.0,0.12,UV.x)*smoothstep(0.0,0.12,1.0-UV.x);
 float rut=0.85+0.15*cos(UV.x*19.0);
 float known=texture(knowledge,(world_pos.xz+vec2(0.5))/map_size).r;
 ALBEDO=earth*vec3(0.81,0.73,0.59)*rut*mix(0.26,1.0,known);
 ROUGHNESS=0.97; SPECULAR=0.05; ALPHA=edge*0.98;
}"""
	_road_material = ShaderMaterial.new()
	_road_material.shader = road_shader
	_road_material.set_shader_parameter("earth_tex", _repeat_texture(EARTH_GROUND + "albedo.jpg"))
	_road_material.set_shader_parameter("knowledge", _reveal_texture)
	_road_material.set_shader_parameter("map_size", Vector2(_width, _depth))

func _mesh(vertices: PackedVector3Array, normals: PackedVector3Array, uv: PackedVector2Array, indices: PackedInt32Array, material: Material, parent: Node3D, name_text: String) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = name_text
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _make_terrain() -> void:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uv: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for z: int in range(_height_depth):
		for x: int in range(_height_width):
			var px: float = float(x) / SUBDIVISIONS - MARGIN
			var pz: float = float(z) / SUBDIVISIONS - MARGIN
			vertices.append(Vector3(px, _height_values[z * _height_width + x], pz))
			normals.append(_normal(px, pz))
			uv.append(Vector2(px, pz))
			if x + 1 < _height_width and z + 1 < _height_depth:
				var i: int = z * _height_width + x
				indices.append_array(PackedInt32Array([i, i + 1, i + _height_width, i + 1, i + _height_width + 1, i + _height_width]))
	_mesh(vertices, normals, uv, indices, _land_material, _geometry, "ContinuousHeightfield")

func _make_water() -> void:
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D knowledge : filter_linear, repeat_disable;
uniform vec2 map_size=vec2(36.0,26.0);
varying vec3 world_pos;
void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; VERTEX.y+=sin(VERTEX.x*3.0+TIME*0.5)*cos(VERTEX.z*4.0+TIME*0.4)*0.004; }
void fragment(){
 float ripple=sin(world_pos.x*21.0+world_pos.z*7.0+TIME*0.6)*cos(world_pos.z*16.0+TIME*0.5);
 float known=texture(knowledge,(world_pos.xz+vec2(0.5))/map_size).r;
 ALBEDO=vec3(0.105,0.185,0.166)*(0.95+ripple*0.08)*mix(0.35,1.0,known);
 NORMAL=normalize(NORMAL+vec3(ripple*0.012,0.0,sin(world_pos.z*23.0+TIME)*0.012));
 METALLIC=0.28; ROUGHNESS=0.22; SPECULAR=0.7;
}"""
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("knowledge", _reveal_texture)
	material.set_shader_parameter("map_size", Vector2(_width, _depth))
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(_width + MARGIN * 2, _depth + MARGIN * 2)
	plane.subdivide_width = _width * 2
	plane.subdivide_depth = _depth * 2
	var water: MeshInstance3D = MeshInstance3D.new()
	water.name = "RiverAndLakeSurface"
	water.mesh = plane
	water.material_override = material
	water.position = Vector3(float(_width) * 0.5, WATER_LEVEL, float(_depth) * 0.5)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_geometry.add_child(water)

func _make_roads() -> void:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uv: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for z: int in range(_depth):
		for x: int in range(_width):
			if not bool(_tile(x, z).road):
				continue
			if bool(_tile(x, z).bridge):
				_bridge(x, z)
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				if x + offset.x >= _width or z + offset.y >= _depth or not bool(_tile(x + offset.x, z + offset.y).road):
					continue
				var start: int = vertices.size()
				var across: Vector2 = Vector2(-offset.y, offset.x)
				for segment: int in range(9):
					var t: float = float(segment) / 8.0
					var center: Vector2 = Vector2(x, z) + Vector2(offset) * t + across * sin(t * PI) * _noise(x, z) * 0.035
					for side: int in range(2):
						var p: Vector2 = center + across * (float(side) - 0.5) * 0.4
						vertices.append(Vector3(p.x, height_at(p.x, p.y) + 0.016, p.y))
						normals.append(_normal(p.x, p.y))
						uv.append(Vector2(side, t))
					if segment < 8:
						var i: int = start + segment * 2
						indices.append_array(PackedInt32Array([i, i + 2, i + 1, i + 1, i + 2, i + 3]))
	var roads: MeshInstance3D = _mesh(vertices, normals, uv, indices, _road_material, _geometry, "WornEarthRoadNetwork")
	roads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _bridge(x: int, z: int) -> void:
	var bridge: Node3D = Node3D.new()
	bridge.name = "TimberBridge"
	bridge.position = Vector3(x, 0.11, z)
	if not bool(_tile(x + 1, z).road):
		bridge.rotation.y = PI * 0.5
	_geometry.add_child(bridge)
	for plank: int in range(8):
		_box(bridge, Vector3((plank - 3.5) * 0.126, -0.025, 0), Vector3(0.119, 0.05, 0.51), _wood)
	for side: float in [-0.27, 0.27]:
		_box(bridge, Vector3(0, 0.17, side), Vector3(1.03, 0.025, 0.025), _wood)
		for along: float in [-0.45, 0.45]:
			_box(bridge, Vector3(along, 0.07, side), Vector3(0.032, 0.27, 0.032), _wood)

func _make_landscape() -> void:
	var tree_count: int = 0
	for z: int in range(_depth):
		for x: int in range(_width):
			var tile: Dictionary = _tile(x, z)
			var terrain: String = str(tile.terrain)
			if bool(tile.road) or terrain == "water" or _near_location(x, z, 1.1):
				continue
			var chance: float = _random(x, z, 2.0)
			if (terrain == "forest" and chance < 0.76) or (terrain == "grass" and chance < 0.065):
				var px: float = float(x) + (_random(x, z, 3.0) - 0.5) * 0.66
				var pz: float = float(z) + (_random(x, z, 4.0) - 0.5) * 0.66
				var variant: String = ["a", "b", "c"][int(_random(x, z, 5.0) * 3.0) % 3]
				var broadleaf: bool = _random(x, z, 8.0) > 0.63
				var tree_path: String = "res://assets/models/forest/broadleaf.glb" if broadleaf else FIR
				var tree: Node3D = _model(tree_path, "" if broadleaf else "fir_sapling_" + variant, _geometry, 1.65 + _random(x, z, 6.0) * 1.0)
				if tree != null:
					tree.position = Vector3(px, height_at(px, pz) - 0.025, pz)
					tree.rotation.y = _random(x, z, 7.0) * TAU
					tree_count += 1
					_foliage.append({"node": tree, "height": 1.65 + _random(x, z, 6.0) * 1.0})
			if terrain in ["mountain", "hill"] and chance < 0.38:
				var rock: Node3D = _model(ROCK, "rock_moss_set_02_rock" + str(7 + int(_random(x, z, 11.0) * 7.0) % 7).pad_zeros(2), _geometry, 0.22 + _random(x, z, 12.0) * (0.9 if terrain == "mountain" else 0.25))
				if rock != null:
					rock.position = Vector3(x, height_at(x, z) - 0.06, z)
					rock.rotation.y = chance * TAU
	_geometry.set_meta("tree_count", tree_count)

func _near_location(x: float, z: float, distance: float) -> bool:
	for object: Dictionary in campaign.world.objects:
		var radius: float = 2.1 if str(object.type) == "town" or bool(object.get("final", false)) else distance * 0.45
		if Vector2(x, z).distance_to(Vector2(object.x, object.y)) < radius:
			return true
	return false

func _collect_meshes(node: Node, transform: Transform3D, match_name: String, found: bool, output: Array) -> void:
	var current: Transform3D = transform
	if node is Node3D:
		current = transform * node.transform
	var matches: bool = found or match_name.is_empty() or str(node.name) == match_name
	if matches and node is MeshInstance3D and node.mesh != null:
		output.append({"mesh": node.mesh, "transform": current, "override": node.material_override})
	for child: Node in node.get_children():
		_collect_meshes(child, current, match_name, matches, output)

func _model(path: String, piece: String, parent: Node3D, height: float) -> Node3D:
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
		return null
	var bounds: AABB
	var first: bool = true
	for item: Dictionary in parts:
		var mesh: Mesh = item.mesh as Mesh
		var box: AABB = item.transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var scale_factor: float = height / maxf(0.001, bounds.size.y)
	var root: Node3D = Node3D.new()
	root.name = piece if not piece.is_empty() else "TimberDwelling"
	parent.add_child(root)
	var normalizer: Node3D = Node3D.new()
	normalizer.scale = Vector3.ONE * scale_factor
	normalizer.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
	root.add_child(normalizer)
	for item: Dictionary in parts:
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.mesh = item.mesh
		instance.transform = item.transform
		instance.material_override = item.override
		instance.lod_bias = 0.65
		normalizer.add_child(instance)
	return root

func _make_location(object: Dictionary) -> void:
	var node: Node3D = Node3D.new()
	node.name = str(object.id).replace("-", "_")
	node.position = Vector3(object.x, walk_height(float(object.x), float(object.y)), object.y)
	_objects.add_child(node)
	_locations[str(object.id)] = node
	if str(object.type) == "town" or bool(object.get("final", false)):
		_settlement(node, object)
	elif str(object.type) == "enemy":
		var enemies: Array = object.get("enemies", [])
		for index: int in range(mini(3, enemies.size() + 1) if not enemies.is_empty() else 0):
			var kind: String = str(enemies[index % enemies.size()].type)
			_actor(node, kind, Vector3((index - 1) * 0.23, 0.0, float(index % 2) * 0.14), 0.65 if kind == "wolf" else 0.52)
		_banner(node, Vector3(0.25, 0, -0.1), 0.7, Color("693c31"))
	elif str(object.type) == "mine":
		if str(object.get("resource", "")) == "wood":
			_house(node, Vector3(-0.2, 0, -0.15), 0.67, 0.3, 0, true)
			for log_index: int in range(6):
				_cylinder(node, Vector3(0.3 + float(log_index % 3) * 0.13, 0.07 + float(log_index / 3) * 0.12, 0.25), 0.06, 0.48, _wood, Vector3(PI * 0.5, 0, 0))
		else:
			for index: int in range(3):
				var boulder: Node3D = _model(ROCK, "rock_moss_set_02_rock" + str(8 + index).pad_zeros(2), node, 0.4 + float(index) * 0.13)
				if boulder != null:
					boulder.position = Vector3((index - 1) * 0.33, -0.08, -0.15)
			_box(node, Vector3(0, 0.28, 0.28), Vector3(0.62, 0.075, 0.09), _wood)
			for side: float in [-0.25, 0.25]:
				_box(node, Vector3(side, 0.12, 0.28), Vector3(0.065, 0.3, 0.08), _wood)
		_banner(node, Vector3(0.45, 0, 0.1), 0.68, Color("716544"))
	elif str(object.type) in ["shrine", "obelisk"]:
		_shrine(node, object)
	else:
		_supply(node, object)

func _settlement(parent: Node3D, object: Dictionary) -> void:
	var fortress: bool = bool(object.get("final", false))
	var monastery: bool = str(object.id) == "white-monastery"
	var center: Vector3 = Vector3(0.0, 0.0, -0.22)
	for point: Vector2 in [Vector2(-0.72, -0.72), Vector2(0.72, -0.72), Vector2(-0.72, 0.72), Vector2(0.72, 0.72)]:
		var tower: Node3D = _model(FORT, "modular_fort_01_tower_round", parent, 0.65)
		if tower != null:
			tower.position = center + Vector3(point.x, 0.0, point.y)
	for edge: int in range(4):
		var wall: Node3D = _model(FORT, "modular_fort_01_wall_thin_gate_01" if edge == 3 else "modular_fort_01_wall_thin_straight_01", parent, 0.63)
		if wall != null:
			wall.position = center + [Vector3(-0.72, 0, 0), Vector3(0.72, 0, 0), Vector3(0, 0, -0.72), Vector3(0, 0, 0.72)][edge]
			wall.rotation.y = 0.0 if edge < 2 else PI * 0.5
	var keep: Node3D = _model(FORT, "modular_fort_01_tower_round", parent, 1.14 if not fortress else 1.5)
	if keep != null:
		keep.position = center + Vector3(0, 0, -0.08)
	if monastery:
		_house(parent, center + Vector3(0.0, 0.0, 0.0), 1.18, 0.0, 2)
		_box(parent, Vector3(0, 1.42, -0.12), Vector3(0.035, 0.28, 0.035), _wood)
		_box(parent, Vector3(0, 1.46, -0.12), Vector3(0.18, 0.035, 0.035), _wood)
	var placements: Array = [Vector3(-1.5, 0, 0.55), Vector3(-1.48, 0, -0.68), Vector3(0.25, 0, -1.66), Vector3(1.3, 0, -1.26)]
	for index: int in range(placements.size()):
		var position: Vector3 = placements[index]
		position.y = height_at(parent.position.x + position.x, parent.position.z + position.z) - parent.position.y
		_house(parent, position, 0.75 + float(index % 2) * 0.14, float(index) * 0.81, index)
	_fence(parent, Vector3(-1.7, 0.0, 1.25), Vector3(0.25, 0.0, 1.25))
	_fence(parent, Vector3(-1.9, 0.0, -1.3), Vector3(-1.9, 0.0, 1.25))
	var color: Color = Color("a58b4e") if str(object.get("owner", "neutral")) == "player" else Color("623d35")
	var banner: Node3D = _banner(parent, Vector3(0.05, 1.0, -0.28), 0.68, color)
	banner.name = "OwnershipBanner"
	_fire(parent, Vector3(-0.58, 0.14, 0.88), 0.55)
	_fire(parent, Vector3(0.58, 0.14, 0.88), 0.55)

func _house(parent: Node3D, position: Vector3, height: float, rotation: float, index: int = 0, shack: bool = false) -> void:
	var path: String = HOUSE if shack else "res://assets/models/medieval_village/medieval_house_%02d.glb" % (index % 4 + 1)
	var house: Node3D = _model(path, "", parent, height)
	if house == null:
		house = _model(HOUSE, "", parent, height)
	if house != null:
		house.position = position
		house.rotation.y = rotation

func _fence(parent: Node3D, start: Vector3, end: Vector3) -> void:
	var count: int = maxi(2, roundi(start.distance_to(end) / 0.24))
	for index: int in range(count + 1):
		var point: Vector3 = start.lerp(end, float(index) / count)
		point.y = height_at(parent.position.x + point.x, parent.position.z + point.z) - parent.position.y
		_box(parent, point + Vector3(0, 0.13, 0), Vector3(0.025, 0.29, 0.025), _wood)
		if index < count:
			var next: Vector3 = start.lerp(end, float(index + 1) / count)
			for rail_height: float in [0.1, 0.22]:
				var rail: MeshInstance3D = _box(parent, (point + next) * 0.5 + Vector3(0, rail_height, 0), Vector3(point.distance_to(next), 0.02, 0.024), _wood)
				rail.rotation.y = -atan2(next.z - point.z, next.x - point.x)

func _supply(parent: Node3D, object: Dictionary) -> void:
	var resource: String = str(object.get("resource", ""))
	if resource == "wood":
		for index: int in range(4):
			_cylinder(parent, Vector3((index % 2) * 0.12 - 0.06, float(index / 2) * 0.11 + 0.06, 0), 0.058, 0.43, _wood, Vector3(0, 0, PI * 0.5))
	else:
		var barrel: bool = resource in ["ore", "mercury", "sulfur"]
		var path: String = "res://assets/models/wine_barrel_01/wine_barrel_lod.glb" if barrel else "res://assets/models/treasure_chest/treasure_chest_lod.glb"
		var prop: Node3D = _model(path, "", parent, 0.31 if barrel else 0.24)
		if prop != null:
			prop.rotation.y = _random(float(object.x), float(object.y), 19.0) * 1.6 - 0.8

func _shrine(parent: Node3D, object: Dictionary) -> void:
	for index: int in range(7):
		var angle: float = float(index) * TAU / 7.0
		var stone: Node3D = _model(ROCK, "rock_moss_set_02_rock09", parent, 0.32 + float(index % 2) * 0.18)
		if stone != null:
			stone.position = Vector3(cos(angle) * 0.42, -0.05, sin(angle) * 0.42)
			stone.rotation.y = angle
	_cylinder(parent, Vector3(0, 0.14, 0), 0.22, 0.28, _stone)
	_box(parent, Vector3(0, 0.43, 0), Vector3(0.055, 0.44, 0.055), _wood)
	_box(parent, Vector3(0, 0.52, 0), Vector3(0.25, 0.055, 0.055), _wood)
	_fire(parent, Vector3(0.0, 0.26, 0.1), 0.38 if bool(object.get("warded", false)) else 0.18)

func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _box(parent: Node3D, position: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = dimensions
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _cylinder(parent: Node3D, position: Vector3, radius: float, height: float, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _banner(parent: Node3D, position: Vector3, height: float, color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = position
	parent.add_child(root)
	_cylinder(root, Vector3(0, height * 0.5, 0), 0.009, height, _wood)
	var cloth: MeshInstance3D = _box(root, Vector3(0.1, height * 0.78, 0.0), Vector3(0.2, height * 0.28, 0.007), _material(color, 0.95))
	cloth.name = "Cloth"
	return root

func _fire(parent: Node3D, position: Vector3, energy: float) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.position = position + Vector3(0, 0.2, 0)
	light.light_color = Color("e8ad60")
	light.light_energy = energy
	light.omni_range = 1.7
	light.omni_attenuation = 1.8
	parent.add_child(light)
	var ember: StandardMaterial3D = _material(Color("a36029"))
	ember.emission_enabled = true
	ember.emission = Color("d7943a")
	ember.emission_energy_multiplier = 1.4
	_cylinder(parent, position, 0.032, 0.12, ember)
	_flames.append({"light": light, "energy": energy, "phase": float(_flames.size()) * 1.7})

func _actor(parent: Node3D, kind: String, position: Vector3, height: float, hero: bool = false) -> void:
	var data: Dictionary = DraconiaArt.unit_data(kind)
	if data.is_empty():
		return
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = DraconiaArt.texture(str(data.image))
	sprite.region_enabled = true
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.35
	sprite.shaded = true
	sprite.no_depth_test = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.position = position + Vector3(0.0, 0.015, 0.0)
	var bounds: Array = data.get("contentBounds", [0, 0, 144, 144])
	sprite.pixel_size = height / maxf(1.0, float(bounds[3]))
	parent.add_child(sprite)
	_actors.append({"sprite": sprite, "kind": kind, "data": data, "hero": hero, "offset": float(_actors.size()) * 0.17})
	_actor_frame(_actors[-1])

func _actor_frame(actor: Dictionary) -> void:
	var sprite: Sprite3D = actor.sprite as Sprite3D
	if not is_instance_valid(sprite):
		return
	var data: Dictionary = actor.data
	var state: String = "move" if bool(actor.hero) and _hero_walking else "idle"
	var states: Dictionary = data.states
	if not states.has(state):
		state = "idle"
	var frames: Array = states[state].frames
	if frames.is_empty():
		return
	var duration: float = 0.0
	for frame: Dictionary in frames:
		duration += float(frame.duration) / 1000.0
	var time: float = fposmod(_time + float(actor.offset), maxf(0.01, duration))
	var frame: Dictionary = frames[-1]
	for candidate: Dictionary in frames:
		frame = candidate
		time -= float(candidate.duration) / 1000.0
		if time < 0:
			break
	sprite.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
	sprite.offset = Vector2(float(frame.w) * 0.5 - float(data.anchor.x), float(data.anchor.y) - float(frame.h) * 0.5)

func set_hero_position(point: Vector2, walking: bool) -> void:
	_hero_walking = walking
	if is_instance_valid(_hero):
		_hero.position = Vector3(point.x, walk_height(point.x, point.y) + 0.018, point.y)
		# A few foreground crowns can completely conceal the selected company.
		# Fade only those occluders; the landscape placement remains unchanged.
		for item: Dictionary in _foliage:
			var tree: Node3D = item.node as Node3D
			var dx: float = tree.position.x - point.x
			var dz: float = tree.position.z - point.y
			var across: float = absf(dx - dz) / sqrt(2.0)
			var forward: float = (dx + dz) * 0.5
			var occludes: bool = forward > 0.1 and forward < float(item.height) * 0.72 and across < float(item.height) * 0.28
			_fade_tree(tree, occludes)

func _fade_tree(tree: Node3D, fade: bool) -> void:
	if bool(tree.get_meta("faded", false)) == fade:
		return
	tree.set_meta("faded", fade)
	for pivot: Node in tree.get_children():
		for child: Node in pivot.get_children():
			if not child is MeshInstance3D:
				continue
			var mesh: MeshInstance3D = child as MeshInstance3D
			for surface: int in range(mesh.mesh.get_surface_count()):
				if fade:
					var original: Material = mesh.get_active_material(surface)
					if original is StandardMaterial3D:
						var ghost: StandardMaterial3D = original.duplicate() as StandardMaterial3D
						ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
						ghost.albedo_color.a = 0.14
						mesh.set_surface_override_material(surface, ghost)
				else:
					mesh.set_surface_override_material(surface, null)

func _update_phase() -> void:
	var phase: String = str(CampaignCore.get_world_phase(campaign).id)
	if phase == _phase:
		return
	_phase = phase
	var night: bool = phase == "night"
	_sun.light_color = Color("a5b5c4") if night else Color("d9dfd5")
	_sun.light_energy = 0.38 if night else 0.98
	_environment.ambient_light_color = Color("788c9c") if night else Color("a8b6ae")
	_environment.ambient_light_energy = 0.32 if night else 0.64
	_environment.fog_light_color = Color("354954") if night else Color("60766d")
	_environment.fog_density = 0.006 if night else 0.0035
	_environment.tonemap_exposure = 1.0 if night else 1.0
	_sky.sky_top_color = Color("152831") if night else Color("637974")
	_sky.sky_horizon_color = Color("35474f") if night else Color("8b9b8f")
	_sky.ground_horizon_color = _sky.sky_horizon_color

func _ring(parent: Node3D, point: Vector3, radius: float, color: Color, thickness: float = 0.018) -> void:
	var material: StandardMaterial3D = _material(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius
	mesh.rings = 40
	mesh.ring_segments = 5
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = point + Vector3(0, 0.022, 0)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

func set_overlays(path: Array, selected: Vector2i, hover: Vector2i, grid: bool, movement: int) -> void:
	for child: Node in _overlays.get_children():
		child.free()
	var accumulated: int = 0
	for step: Dictionary in path:
		accumulated = int(step.get("totalCost", accumulated + int(step.get("cost", 65))))
		var color: Color = Color("bda05f") if accumulated <= movement else Color("86645b")
		var point: Vector3 = Vector3(step.x, walk_height(float(step.x), float(step.y)), step.y)
		_ring(_overlays, point, 0.07, color, 0.022)
	for entry: Array in [[selected, Color(0.82, 0.69, 0.4, 0.88), 0.39], [hover, Color(0.75, 0.73, 0.61, 0.45), 0.43]]:
		var tile: Vector2i = entry[0]
		if tile.x >= 0 and tile.y >= 0 and tile.x < _width and tile.y < _depth:
			_ring(_overlays, Vector3(tile.x, walk_height(tile.x, tile.y), tile.y), float(entry[2]), entry[1], 0.014)
	if grid:
		var lines: ImmediateMesh = ImmediateMesh.new()
		var material: StandardMaterial3D = _material(Color(0.55, 0.53, 0.43, 0.23))
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lines.surface_begin(Mesh.PRIMITIVE_LINES, material)
		for z: int in range(_depth):
			for x: int in range(_width):
				if not _known(x, z):
					continue
				for pair: Array in [[Vector2(-0.5, -0.5), Vector2(0.5, -0.5)], [Vector2(-0.5, -0.5), Vector2(-0.5, 0.5)]]:
					for offset: Vector2 in pair:
						var point: Vector2 = Vector2(x, z) + offset
						lines.surface_add_vertex(Vector3(point.x, walk_height(point.x, point.y) + 0.026, point.y))
		lines.surface_end()
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.mesh = lines
		_overlays.add_child(instance)

func _process(delta: float) -> void:
	_time += delta
	for actor: Dictionary in _actors:
		_actor_frame(actor)
	for flame: Dictionary in _flames:
		var light: OmniLight3D = flame.light as OmniLight3D
		if is_instance_valid(light):
			light.light_energy = float(flame.energy) * (1.6 if _phase == "night" else 0.35) * (0.94 + sin(_time * 8.1 + float(flame.phase)) * 0.06)
