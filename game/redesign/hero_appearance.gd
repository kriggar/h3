class_name HeroAppearance
extends RefCounted
## Registered 3D equipment presentation. It never changes item or combat rules.

const Items = preload("res://game/redesign/item_rules.gd")
const MANIFEST: String = "res://assets/models/mara/equipment/manifest.json"
const SKELETON: String = "IleanaRig/Skeleton3D"
const BASE_SWORD: String = "IleanaRig/Skeleton3D/Mara_Sword"
const MODEL_PATHS: Array[String] = [
	"res://assets/models/mara/mara.glb",
	"res://assets/models/mara/sword.glb",
	"res://assets/models/mara/equipment/vowkeeper.glb",
	"res://assets/models/mara/equipment/bellworn-cowl.glb",
]
static var _model_scenes: Dictionary = {}
static var _filtered_textures: Dictionary = {}
static var _filtered_materials: Dictionary = {}

## Retain the four registered immutable source scenes. Without this bounded
## cache, closing the last view frees a PackedScene, and a subsequent load
## gives its materials new RIDs, retaining a redundant prepared texture set.
static func instantiate_model(path: String) -> Node3D:
	if not path in MODEL_PATHS:
		push_error("Unregistered hero model: "+path)
		return null
	if not _model_scenes.has(path):
		_model_scenes[path]=load(path) as PackedScene
	var scene: PackedScene=_model_scenes[path]
	if scene==null:return null
	var node: Node3D=scene.instantiate() as Node3D
	prepare_materials(node)
	return node

static func _filtered_texture(texture: Texture2D, normal_map: bool=false) -> Texture2D:
	if texture==null:return null
	var key: String=str(texture.get_rid().get_id())+("_normal" if normal_map else "_color")
	if _filtered_textures.has(key):return _filtered_textures[key]
	var pixels: Image=texture.get_image()
	if pixels==null or pixels.has_mipmaps():
		_filtered_textures[key]=texture
		return texture
	if pixels.is_compressed():pixels.decompress()
	pixels.generate_mipmaps(normal_map)
	var filtered: ImageTexture=ImageTexture.create_from_image(pixels)
	_filtered_textures[key]=filtered
	return filtered

## Imported glTF ImageTextures may omit mip levels even when their sampler
## requests them. Prepare one cached material per source for all hero views.
## Only filtering changes; albedo, channels, UV scale and shader factors remain.
static func prepare_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh: MeshInstance3D=node
		for surface: int in range(mesh.mesh.get_surface_count()):
			var source: StandardMaterial3D=mesh.get_active_material(surface) as StandardMaterial3D
			if source==null:continue
			if source.has_meta("draconia_filtered_pbr"):continue
			var key: int=source.get_rid().get_id()
			if not _filtered_materials.has(key):
				var material: StandardMaterial3D=source.duplicate() as StandardMaterial3D
				material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				material.albedo_texture=_filtered_texture(source.albedo_texture)
				material.normal_texture=_filtered_texture(source.normal_texture,true)
				material.roughness_texture=_filtered_texture(source.roughness_texture)
				material.metallic_texture=_filtered_texture(source.metallic_texture)
				material.ao_texture=_filtered_texture(source.ao_texture)
				material.set_meta("draconia_filtered_pbr",true)
				_filtered_materials[key]=material
			mesh.set_surface_override_material(surface,_filtered_materials[key])
	for child: Node in node.get_children():prepare_materials(child)

static func _mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child: Node in node.get_children():
		var found: MeshInstance3D = _mesh(child)
		if found!=null:return found
	return null

static func _transform(rows: Array) -> Transform3D:
	if rows.size()<3:return Transform3D.IDENTITY
	return Transform3D(Basis(Vector3(rows[0][0],rows[1][0],rows[2][0]),Vector3(rows[0][1],rows[1][1],rows[2][1]),Vector3(rows[0][2],rows[1][2],rows[2][2])),Vector3(rows[0][3],rows[1][3],rows[2][3]))

static func apply(body: Node3D, hero: Dictionary) -> Dictionary:
	prepare_materials(body)
	var base_sword: Node3D = body.get_node_or_null(BASE_SWORD) as Node3D
	var result: Dictionary = {"weaponNodes":[],"equipmentNodes":{},"visualClearanceByItem":{},"looseSword":"res://assets/models/mara/sword.glb"}
	if base_sword!=null:
		base_sword.visible=true
		result.weaponNodes.append(base_sword)
	if not FileAccess.file_exists(MANIFEST):return result
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not manifest is Dictionary or not manifest.get("equipment") is Dictionary:return result
	var skeleton: Skeleton3D = body.get_node_or_null(SKELETON) as Skeleton3D
	if skeleton==null:return result
	for child: Node in skeleton.get_children():
		if str(child.name).begins_with("Equipment_"):
			skeleton.remove_child(child)
			child.queue_free()
	for slot: String in hero.get("equipment",{}):
		var item: Dictionary = Items.find_instance(hero,str(hero.equipment[slot]))
		if item.is_empty():continue
		var id: String = str(item.equipmentId)
		if not manifest.equipment.has(id):continue
		var data: Dictionary = manifest.equipment[id]
		var path: String = str(data.get("scene",""))
		if not path.begins_with("res://assets/models/mara/equipment/") or not ResourceLoader.exists(path):continue
		var source: Node3D = instantiate_model(path)
		if source==null:continue
		var node: Node3D
		if str(data.type)=="bone_attachment":
			var attachment: BoneAttachment3D = BoneAttachment3D.new()
			attachment.name="Equipment_"+id
			attachment.bone_name=str(data.bone)
			skeleton.add_child(attachment)
			attachment.add_child(source)
			source.transform=_transform(data.get("transformMatrixRows",[]))
			node=attachment
			if slot=="main_hand":
				result.weaponNodes=[attachment]
				result.looseSword=path
		elif str(data.type)=="skinned_mesh":
			var original: MeshInstance3D = _mesh(source)
			if original==null:
				source.free()
				continue
			var fitted: MeshInstance3D = original.duplicate() as MeshInstance3D
			fitted.name="Equipment_"+id
			skeleton.add_child(fitted)
			fitted.skeleton=NodePath("..")
			node=fitted
			source.free()
		else:
			source.free()
			continue
		prepare_materials(node)
		for hidden: String in data.get("hideBaseMeshes",[]):
			var mesh: Node3D = body.get_node_or_null(hidden) as Node3D
			if mesh!=null:mesh.visible=false
		result.equipmentNodes[id]=node
		var clearance: Variant = data.get("visualGroundClearanceByClip",{})
		if clearance is Dictionary and not clearance.is_empty():
			result.visualClearanceByItem[id]=clearance
	return result

## Metres at model scale one, sampled at the actual authored animation time.
## Multiple fitted items request the highest clearance; their offsets do not add.
static func visual_clearance(appearance: Dictionary, clip: String, authored_seconds: float) -> float:
	var result: float = 0.0
	var items: Dictionary = appearance.get("visualClearanceByItem",{})
	for id: String in items:
		var clips: Dictionary = items[id]
		if not clips.has(clip):continue
		var curve: Dictionary = clips[clip]
		var duration: float = float(curve.get("durationSeconds",0.0))
		var offsets: Array = curve.get("offsetsMetres",[])
		if duration<=0.0 or offsets.is_empty():continue
		var index: float = clampf(authored_seconds/duration,0.0,1.0)*float(offsets.size()-1)
		var first: int = int(floor(index))
		var second: int = mini(first+1,offsets.size()-1)
		var offset: float = lerpf(float(offsets[first]),float(offsets[second]),index-float(first))
		result=maxf(result,offset)
	return result

static func weapon_visible(appearance: Dictionary, visible: bool) -> void:
	for node: Node3D in appearance.get("weaponNodes",[]):
		if is_instance_valid(node):node.visible=visible
