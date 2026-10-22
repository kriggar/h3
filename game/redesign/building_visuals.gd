class_name BuildingVisuals
extends RefCounted
## The original painted atlas governs cards; Blender scenes govern constructed
## world geometry. Models must match the painting, never replace it in the UI.
## The placement wrapper may move; its imported model is never reconstructed.

const Art=preload("res://game/redesign/manuscript_art.gd")
const IDS: Array[String] = ["granary", "barracks", "market", "smithy", "shrine", "palisade", "wharf", "water_gate"]
const MODEL_ROOT: String = "res://assets/models/towns/ashen_crown/"
## Historical rendered outputs only. Kept for preserved diagnostic tooling;
## neither card_path nor card_texture reads these files or their manifest.
const CARD_ROOT: String = "res://assets/ui/buildings/ashen_crown/"
const MANIFEST_PATH: String = CARD_ROOT + "manifest.json"
const SIGNATURE_VERSION: String = "godot-mesh-morph-pose-material-v2"
const CARD_ATLAS_SIZE: Vector2i=Vector2i(1774,887)

static func definition(building_id: String) -> Dictionary:
	if not IDS.has(building_id):
		return {}
	var index: int=IDS.find(building_id)
	var cell_size: Vector2=Vector2(CARD_ATLAS_SIZE)/Vector2(4,2)
	var origin: Vector2=Vector2(index%4,index/4)*cell_size
	return {
		"id": building_id, "factionId": "ashen_crown",
		"scenePath": MODEL_ROOT + building_id + ".glb",
		"cardPath": Art.BUILDING_ATLAS,
		"cardAuthority": "original_painted_atlas",
		"cardAtlasSha256": Art.BUILDING_ATLAS_SHA256,
		"cardCell": {"index":index,"column":index%4,"row":index/4,"columns":4,"rows":2},
		"cardRegion": {"x":origin.x,"y":origin.y,"width":cell_size.x,"height":cell_size.y},
		"cardRequiresModelProof": false,
		"status": "painted_card_authoritative_reconstruction_integrated",
		"modelStatus": "reviewed_for_development_integration",
		"productionAccepted": false,
		"pose": "authored_completed_rest",
		# Retained for historical model-render inspection, not card display.
		"cameraPurpose": "historical_model_render_diagnostic_only",
		"camera": {"azimuthDegrees": 35.0, "elevationDegrees": 28.0, "paddingFraction": 0.10}
	}

static func create(building_id: String, parent: Node) -> Node3D:
	var entry: Dictionary = definition(building_id)
	if entry.is_empty() or parent == null or not ResourceLoader.exists(str(entry.scenePath), "PackedScene"):
		return null
	var scene: PackedScene = load(str(entry.scenePath)) as PackedScene
	if scene == null:
		return null
	var model: Node3D = scene.instantiate() as Node3D
	if model == null:
		return null
	var wrapper: Node3D = Node3D.new()
	wrapper.name = "Building_" + building_id
	wrapper.set_meta("building_visual_id", building_id)
	wrapper.set_meta("building_scene_path", str(entry.scenePath))
	wrapper.set_meta("building_model_name", str(model.name))
	wrapper.add_child(model)
	parent.add_child(wrapper)
	wrapper.set_meta("building_rest_pose",_authored_rest(model))
	return wrapper

static func _authored_rest(node: Node) -> Dictionary:
	# The single factory applies only the source's own RESET clip, if present.
	# World instances and model inspection begin at the authored rest even if
	# an importer chooses a different frame. Painted cards do not use this pose.
	if node is AnimationPlayer:
		for clip: StringName in node.get_animation_list():
			if str(clip)=="RESET" or str(clip).ends_with("/RESET"):
				node.play(clip)
				node.seek(0,true)
				node.stop(true)
				return {"strategy":"authored_RESET","clip":str(clip),"seconds":0.0}
	for child: Node in node.get_children():
		var result: Dictionary=_authored_rest(child)
		if not result.is_empty():return result
	return {}

static func rest_pose(instance: Node3D) -> Dictionary:
	if instance==null:return {}
	var result: Dictionary=instance.get_meta("building_rest_pose",{})
	return result.duplicate(true) if not result.is_empty() else {"strategy":"authored_import_rest","clip":"","seconds":0.0}

static func model_node(instance: Node3D) -> Node3D:
	if instance == null or not instance.has_meta("building_model_name"):
		return null
	return instance.get_node_or_null(NodePath(str(instance.get_meta("building_model_name")))) as Node3D

static func bounds(instance: Node3D) -> AABB:
	if instance == null:
		return AABB()
	var boxes: Array[AABB] = []
	for child: Node in instance.get_children():
		_collect_bounds(child, Transform3D.IDENTITY, true, boxes)
	if boxes.is_empty():
		return AABB()
	var result: AABB = boxes[0]
	for index: int in range(1, boxes.size()):
		result = result.merge(boxes[index])
	return result

static func _collect_bounds(node: Node, parent_transform: Transform3D, parent_visible: bool, result: Array[AABB]) -> void:
	var transform: Transform3D = parent_transform
	var visible: bool = parent_visible
	if node is Node3D:
		transform = parent_transform * node.transform
		visible = parent_visible and node.visible
	if visible and node is MeshInstance3D and node.mesh != null:
		result.append(transform * node.mesh.get_aabb())
	for child: Node in node.get_children():
		_collect_bounds(child, transform, visible, result)

static func evaluated_bounds(instance: Node3D) -> AABB:
	## Authoring/QA only: read back actual native morph vertices. This stalls
	## the renderer and must not run in the per-frame town/card input path.
	if instance == null:return AABB()
	var boxes: Array[AABB]=[]
	for child: Node in instance.get_children():
		_collect_evaluated_bounds(child,Transform3D.IDENTITY,true,boxes)
	if boxes.is_empty():return AABB()
	var result: AABB=boxes[0]
	for index: int in range(1,boxes.size()):result=result.merge(boxes[index])
	return result

static func _collect_evaluated_bounds(node: Node, parent_transform: Transform3D, parent_visible: bool, result: Array[AABB]) -> void:
	var transform: Transform3D=parent_transform
	var visible: bool=parent_visible
	if node is Node3D:
		transform=parent_transform*node.transform
		visible=parent_visible and node.visible
	if visible and node is MeshInstance3D and node.mesh!=null:
		var actual_mesh: Mesh=node.mesh
		if node.get_blend_shape_count()>0:
			var baked: ArrayMesh=node.bake_mesh_from_current_blend_shape_mix()
			if baked!=null:actual_mesh=baked
		result.append(transform*actual_mesh.get_aabb())
	for child: Node in node.get_children():
		_collect_evaluated_bounds(child,transform,visible,result)

static func _sha(data: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()

static func _json_sha(value: Variant) -> String:
	return _sha(JSON.stringify(value, "", true, true).to_utf8_buffer())

static func _stable_value(value: Variant, textures: Dictionary, depth: int = 0) -> Variant:
	if value == null or value is bool or value is int or value is float or value is String:
		return value
	if value is StringName or value is NodePath:
		return str(value)
	if value is Vector2 or value is Vector2i:
		return [value.x, value.y]
	if value is Vector3 or value is Vector3i:
		return [value.x, value.y, value.z]
	if value is Vector4 or value is Vector4i:
		return [value.x, value.y, value.z, value.w]
	if value is Color:
		return [value.r, value.g, value.b, value.a]
	if value is Transform3D:
		return [_stable_value(value.basis.x,textures), _stable_value(value.basis.y,textures), _stable_value(value.basis.z,textures), _stable_value(value.origin,textures)]
	if value is Texture2D:
		var texture_id: int = value.get_instance_id()
		if textures.has(texture_id):
			return textures[texture_id]
		var pixels: Image = value.get_image()
		var descriptor: Dictionary = {"kind": value.get_class(), "width": value.get_width(), "height": value.get_height()}
		if pixels != null:
			descriptor["pixelFormat"] = pixels.get_format()
			descriptor["pixelSha256"] = _sha(pixels.get_data())
		else:
			descriptor["sourcePath"] = value.resource_path
		textures[texture_id] = descriptor
		return descriptor
	if value is Material and depth < 2:
		return _material_descriptor(value,textures,depth+1)
	if value is Shader:
		return {"kind":"Shader", "codeSha256":_sha(value.code.to_utf8_buffer())}
	if value is Resource:
		return {"kind":value.get_class(), "sourcePath":value.resource_path}
	if value is Array:
		var array: Array = []
		for member: Variant in value:
			array.append(_stable_value(member,textures,depth))
		return array
	if value is Dictionary:
		var dictionary: Dictionary = {}
		for key: Variant in value:
			dictionary[str(key)] = _stable_value(value[key],textures,depth)
		return dictionary
	return {"variantType":typeof(value), "bytesSha256":_sha(var_to_bytes(value))}

static func _material_descriptor(material: Material, textures: Dictionary, depth: int = 0) -> Dictionary:
	if material == null:
		return {"kind":"null"}
	var properties: Dictionary = {"kind":material.get_class()}
	for property: Dictionary in material.get_property_list():
		var key: String = str(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or key.begins_with("resource_") or key in ["script", "metadata/_edit_lock_"]:
			continue
		properties[key] = _stable_value(material.get(key),textures,depth)
	return properties

static func signature(instance: Node3D) -> Dictionary:
	var model: Node3D = model_node(instance)
	if model == null:
		return {}
	var geometry: Array = []
	var materials: Array = []
	var textures: Dictionary = {}
	var totals: Dictionary = {"meshes":0,"surfaces":0,"vertices":0,"indices":0}
	for child: Node in instance.get_children():
		_scan(child,Transform3D.IDENTITY,"",geometry,materials,textures,totals)
	var mesh_data: Array=[]
	var poses: Array=[]
	for record: Dictionary in geometry:
		var data: Dictionary=record.duplicate(true)
		for key: String in ["transform","visible","blendShapeWeights"]:data.erase(key)
		mesh_data.append(data)
		poses.append({"node":record.node,"transform":record.transform,"visible":record.visible,"blendShapeWeights":record.blendShapeWeights})
	var box: AABB = bounds(instance)
	return {
		"signatureVersion":SIGNATURE_VERSION,
		"id":str(instance.get_meta("building_visual_id","")),
		"scenePath":str(instance.get_meta("building_scene_path","")),
		"instantiatedScenePath":model.scene_file_path,
		"geometrySha256":_json_sha(geometry), "materialSha256":_json_sha(materials),
		"meshDataSha256":_json_sha(mesh_data), "poseSha256":_json_sha(poses),
		"meshCount":int(totals.meshes), "surfaceCount":int(totals.surfaces),
		"vertexCount":int(totals.vertices), "indexCount":int(totals.indices),
		"bounds":{"position":[box.position.x,box.position.y,box.position.z],"size":[box.size.x,box.size.y,box.size.z]}
	}

static func _scan(node: Node, parent_transform: Transform3D, parent_path: String, geometry: Array, materials: Array, textures: Dictionary, totals: Dictionary) -> void:
	var transform: Transform3D = parent_transform * node.transform if node is Node3D else parent_transform
	var path: String = parent_path + "/" + str(node.name)
	if node is MeshInstance3D and node.mesh != null:
		var mesh: Mesh = node.mesh
		var names: Array=[]
		var weights: Array=[]
		for index: int in range(node.get_blend_shape_count()):
			names.append(str(mesh.get_blend_shape_name(index)) if mesh is ArrayMesh else str(index))
			weights.append(node.get_blend_shape_value(index))
		var mesh_record: Dictionary = {"node":path,"transform":_stable_value(transform,textures),"visible":node.visible,"surfaces":[],"blendShapeNames":names,"blendShapeWeights":weights,"blendShapeMode":mesh.blend_shape_mode if mesh is ArrayMesh else -1}
		totals.meshes += 1
		for index: int in range(mesh.get_surface_count()):
			var arrays: Array = mesh.surface_get_arrays(index)
			mesh_record.surfaces.append({"primitive":mesh.surface_get_primitive_type(index),"arraysSha256":_sha(var_to_bytes(arrays)),"blendShapeArraysSha256":_sha(var_to_bytes(mesh.surface_get_blend_shape_arrays(index)))})
			materials.append({"node":path,"surface":index,"material":_material_descriptor(node.get_active_material(index),textures)})
			totals.surfaces += 1
			if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] != null:
				totals.vertices += arrays[Mesh.ARRAY_VERTEX].size()
			if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null:
				totals.indices += arrays[Mesh.ARRAY_INDEX].size()
		geometry.append(mesh_record)
	for child: Node in node.get_children():
		_scan(child,transform,path,geometry,materials,textures,totals)

static func _manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	return value if value is Dictionary and int(value.get("schemaVersion",0)) == 1 else {}

static func source_fingerprint(building_id: String) -> Dictionary:
	## Deprecated compatibility name: historical model-to-render provenance.
	## This cannot approve art or gate a painted card.
	return historical_render_fingerprint(building_id)

static func historical_render_fingerprint(building_id: String) -> Dictionary:
	var entry: Dictionary = definition(building_id)
	if entry.is_empty():
		return {}
	var recorded: Dictionary = _manifest().get("buildings",{}).get(building_id,{})
	var result: Dictionary = recorded.duplicate(true)
	result["scope"] = "historical_model_to_render_provenance_only"
	result["artAcceptance"] = false
	result["scenePath"] = str(entry.scenePath)
	result["sourceAvailable"] = FileAccess.file_exists(str(entry.scenePath))
	result["observedSourceSha256"] = FileAccess.get_sha256(str(entry.scenePath)) if bool(result.sourceAvailable) else ""
	var matches: bool = record_matches_source(building_id,recorded,str(result.observedSourceSha256),bool(result.sourceAvailable))
	for dependency: Dictionary in recorded.get("dependencies",[]):
		var path: String = "res://" + str(dependency.get("path",""))
		if FileAccess.file_exists(path) and FileAccess.get_sha256(path) != str(dependency.get("sha256","")):
			matches = false
	result["sourceMatches"] = matches
	return result

static func record_matches_source(building_id: String, recorded: Dictionary, observed_sha: String, source_available: bool = true) -> bool:
	## Historical model/render provenance only; never a painting availability
	## or acceptance check. Kept for old evidence without mutating actual files.
	var entry: Dictionary=definition(building_id)
	if entry.is_empty() or recorded.is_empty():return false
	var matches: bool=str(recorded.get("scenePath",""))==str(entry.scenePath)
	matches=matches and str(recorded.get("blendSha256","")).length()==64 and str(recorded.get("sourceSha256","")).length()==64
	matches=matches and str(recorded.get("signature",{}).get("instantiatedScenePath",""))==str(entry.scenePath)
	return matches and (not source_available or str(recorded.get("sourceSha256",""))==observed_sha)

static func card_path(building_id: String) -> String:
	## The path identifies the atlas. Use card_texture for the exact cell.
	return Art.BUILDING_ATLAS if IDS.has(building_id) else ""

static func card_texture(building_id: String) -> Texture2D:
	## No model, rendered PNG, fingerprint or legacy manifest is required.
	return Art.building(building_id)
