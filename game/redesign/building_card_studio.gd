class_name BuildingCardStudio
extends RefCounted
## Native card pixels from the same unmodified building factory as the town.
## This is an authoring tool, not a second source of building geometry.

const Visuals = preload("res://game/redesign/building_visuals.gd")
const Lighting = preload("res://game/redesign/pbr_lighting.gd")
const PIGMENT = preload("res://game/redesign/building_card_pigment.gdshader")
const PIPELINE_VERSION: String = "same-scene-native-card-v2"
const AMBIENT_ENERGY: float = 0.30
const KEY_ENERGY: float = 0.75
const FILL_ENERGY: float = 0.15

static func create_environment() -> Environment:
	# Shared by still cards and their live native previews. The original PBR
	# metal receives reflected radiance without painting a sky into the alpha.
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0,0,0,0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = AMBIENT_ENERGY
	environment.ambient_light_sky_contribution = 0.0
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	Lighting.apply_reflections(environment)
	return environment

static func render_card(host: Node, building_id: String, resolution: int = 512, treatment: String = "raw", azimuth_offset: float = 0.0) -> Dictionary:
	if host == null or not host.is_inside_tree():
		return {"ok":false,"reason":"A live native SceneTree host is required."}
	if DisplayServer.get_name() == "headless":
		return {"ok":false,"reason":"Card pixels require the native renderer; headless dummy output is not accepted."}
	if resolution < 128 or resolution > 2048 or not treatment in ["raw","pigment"] or not is_finite(azimuth_offset):
		return {"ok":false,"reason":"Unsupported card size or treatment."}
	var entry: Dictionary = Visuals.definition(building_id)
	if entry.is_empty() or not ResourceLoader.exists(str(entry.get("scenePath","")),"PackedScene"):
		return {"ok":false,"reason":"The registered Blender-export building scene is missing."}
	# Optional authoring inspection angle; runtime cards use the registered
	# default. This lets reviewers inspect rear access without altering assets.
	entry.camera.azimuthDegrees=float(entry.camera.azimuthDegrees)+azimuth_offset
	var tree: SceneTree = host.get_tree()
	var viewport: SubViewport = SubViewport.new()
	viewport.name = "BuildingCard_" + building_id
	viewport.size = Vector2i(resolution,resolution)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.mesh_lod_threshold = 0.0
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(viewport)
	var world: Node3D = Node3D.new()
	world.name = "CardWorld"
	viewport.add_child(world)
	var environment: Environment = create_environment()
	var environment_node: WorldEnvironment = WorldEnvironment.new()
	environment_node.environment = environment
	world.add_child(environment_node)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "CardKeyLight"
	sun.rotation_degrees = Vector3(-44,-28,0)
	sun.light_color = Color(1.0,0.98,0.94)
	sun.light_energy = KEY_ENERGY
	sun.shadow_enabled = true
	world.add_child(sun)
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.name = "CardFillLight"
	fill.rotation_degrees = Vector3(-25,140,0)
	fill.light_color = Color(0.94,0.97,1.0)
	fill.light_energy = FILL_ENERGY
	world.add_child(fill)
	var model: Node3D = Visuals.create(building_id,world)
	if model == null:
		viewport.queue_free()
		await tree.process_frame
		return {"ok":false,"reason":"The registered scene could not be instantiated."}
	_freeze_pose(model)
	var before: Dictionary = Visuals.signature(model)
	var box: AABB = Visuals.bounds(model)
	if int(before.get("meshCount",0)) == 0 or box.size.length() <= 0.01:
		viewport.queue_free()
		await tree.process_frame
		return {"ok":false,"reason":"The source contains no renderable building geometry."}
	var camera: Camera3D = Camera3D.new()
	camera.name = "CardCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.05
	camera.far = maxf(100.0,box.size.length()*12.0)
	world.add_child(camera)
	var azimuth: float = deg_to_rad(float(entry.camera.azimuthDegrees))
	var elevation: float = deg_to_rad(float(entry.camera.elevationDegrees))
	var direction: Vector3 = Vector3(sin(azimuth)*cos(elevation),sin(elevation),cos(azimuth)*cos(elevation))
	var target: Vector3 = box.get_center()
	camera.position = target + direction*maxf(10.0,box.size.length()*3.0)
	camera.look_at(target,Vector3.UP)
	var extent: Vector2 = _camera_extent(camera,box)
	camera.size = maxf(extent.x,extent.y)/(1.0-2.0*float(entry.camera.paddingFraction))
	camera.make_current()
	# Obtain the ViewportTexture before rendering, and wait for actual native
	# frames. A merely instantiated scene is not evidence of a rendered card.
	var viewport_texture: ViewportTexture = viewport.get_texture()
	await tree.process_frame
	await tree.process_frame
	await RenderingServer.frame_post_draw
	var raw_image: Image = viewport_texture.get_image()
	if raw_image == null or raw_image.is_empty():
		viewport.queue_free()
		await tree.process_frame
		return {"ok":false,"reason":"The native viewport returned no image."}
	raw_image.convert(Image.FORMAT_RGBA8)
	var image: Image = raw_image
	var processed: SubViewport
	if treatment == "pigment":
		processed = SubViewport.new()
		processed.name = "BuildingPigment_" + building_id
		processed.size = viewport.size
		processed.transparent_bg = true
		processed.disable_3d = true
		processed.gui_disable_input = true
		processed.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		host.add_child(processed)
		var plate: TextureRect = TextureRect.new()
		plate.texture = viewport_texture
		plate.size = Vector2(resolution,resolution)
		plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var pigment: ShaderMaterial = ShaderMaterial.new()
		pigment.shader = PIGMENT
		plate.material = pigment
		processed.add_child(plate)
		var processed_texture: ViewportTexture = processed.get_texture()
		await tree.process_frame
		await tree.process_frame
		await RenderingServer.frame_post_draw
		image = processed_texture.get_image()
		if image != null:
			image.convert(Image.FORMAT_RGBA8)
	var after: Dictionary = Visuals.signature(model)
	var alpha: Dictionary = _alpha_metrics(image)
	var projection: Rect2 = _projected_bounds(camera,box)
	var result: Dictionary = {
		"ok":true,"reason":"", "id":building_id,
		"image":image, "rawImage":raw_image,
		"sourceSha256":FileAccess.get_sha256(str(entry.scenePath)),
		"signature":before, "sourceUnchanged":before == after,
		"alpha":alpha, "alphaMatchesRaw":_alpha_matches(raw_image,image),
		"render":{
			"pipelineVersion":PIPELINE_VERSION,"renderer":RenderingServer.get_current_rendering_method(),
			"engine":Engine.get_version_info().string,"resolution":[resolution,resolution],
			"transparentBackground":true,"pose":str(entry.pose),"restPose":Visuals.rest_pose(model),"treatment":treatment,
			"camera":entry.camera.duplicate(true),"orthographicSize":camera.size,
			"cameraPosition":[camera.position.x,camera.position.y,camera.position.z],
			"cameraTarget":[target.x,target.y,target.z],
			"projectedBounds":[projection.position.x,projection.position.y,projection.size.x,projection.size.y],
			"ambientEnergy":AMBIENT_ENERGY,"keyEnergy":KEY_ENERGY,"fillEnergy":FILL_ENERGY,"msaa":4,
			"reflection":Lighting.descriptor()
		}
	}
	var safe: Rect2 = Rect2(Vector2(2,2),Vector2(resolution-4,resolution-4))
	if not bool(result.sourceUnchanged) or not bool(result.alphaMatchesRaw) or int(alpha.get("opaquePixels",0)) == 0 or not safe.encloses(projection) or int(alpha.get("borderPixels",1)) != 0:
		result.ok = false
		result.reason = "Card validation failed: source mutation, silhouette change, empty pixels or clipped bounds."
	if processed != null:
		processed.queue_free()
	viewport.queue_free()
	await tree.process_frame
	await tree.process_frame
	return result

static func _freeze_pose(node: Node) -> void:
	# The completed/rest pose is authored in Blender. Do not invent an angle,
	# swap a mesh/material, or play an arbitrary animation for the card.
	if node is AnimationPlayer:
		node.stop(true)
	node.process_mode = Node.PROCESS_MODE_DISABLED
	for child: Node in node.get_children():
		_freeze_pose(child)

static func _camera_extent(camera: Camera3D, box: AABB) -> Vector2:
	var low: Vector2 = Vector2(INF,INF)
	var high: Vector2 = Vector2(-INF,-INF)
	var inverse: Transform3D = camera.global_transform.affine_inverse()
	for index: int in range(8):
		var point: Vector3 = inverse * box.get_endpoint(index)
		low = low.min(Vector2(point.x,point.y))
		high = high.max(Vector2(point.x,point.y))
	return high-low

static func _projected_bounds(camera: Camera3D, box: AABB) -> Rect2:
	var low: Vector2 = Vector2(INF,INF)
	var high: Vector2 = Vector2(-INF,-INF)
	for index: int in range(8):
		var point: Vector2 = camera.unproject_position(box.get_endpoint(index))
		low = low.min(point)
		high = high.max(point)
	return Rect2(low,high-low)

static func _alpha_matches(first: Image, second: Image) -> bool:
	if first == null or second == null or first.get_size() != second.get_size():
		return false
	var a: PackedByteArray = first.get_data()
	var b: PackedByteArray = second.get_data()
	for index: int in range(3,a.size(),4):
		if absi(int(a[index])-int(b[index])) > 1:
			return false
	return true

static func _alpha_metrics(image: Image) -> Dictionary:
	if image == null or image.is_empty():
		return {}
	var data: PackedByteArray = image.get_data()
	var opaque: int = 0
	var transparent: int = 0
	var border: int = 0
	var width: int = image.get_width()
	var height: int = image.get_height()
	for index: int in range(3,data.size(),4):
		if data[index] > 0:
			opaque += 1
			var pixel: int = int(index/4)
			var x: int = pixel % width
			var y: int = int(pixel/width)
			if x <= 1 or y <= 1 or x >= width-2 or y >= height-2:
				border += 1
		else:
			transparent += 1
	var used: Rect2i = image.get_used_rect()
	return {"opaquePixels":opaque,"transparentPixels":transparent,"borderPixels":border,"usedRect":[used.position.x,used.position.y,used.size.x,used.size.y]}
