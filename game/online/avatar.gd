extends Node3D
## The accepted Mara mesh and authored motions, unchanged. Presentation only.
const Catalog = preload("res://game/online/catalog.gd")
static var _scene: PackedScene
static var _materials: Dictionary = {}
static var _textures: Dictionary = {}
var body: Node3D
var animator: AnimationPlayer
var sword: Node3D
var actor: Dictionary = {}
var _clock := 0.0
var _clip := ""
var _hit_until := 0.0
var _last_action := ""
var _action_clock := 0.0
var _locomotion_phase := 0.0
var _skeleton: Skeleton3D
var _blend_source: Array[Transform3D] = []
var _blend_elapsed := 1.0

static func instantiate_body() -> Node3D:
	if _scene==null:_scene=load(Catalog.HERO_MODEL) as PackedScene
	var result := _scene.instantiate() as Node3D
	prepare_materials(result)
	return result

static func _filtered(texture: Texture2D, normal: bool=false) -> Texture2D:
	if texture==null:return null
	var key := str(texture.get_rid().get_id())+("n" if normal else "c")
	if _textures.has(key):return _textures[key]
	var pixels := texture.get_image()
	if pixels!=null and not pixels.has_mipmaps():
		if pixels.is_compressed():pixels.decompress()
		pixels.generate_mipmaps(normal)
		_textures[key]=ImageTexture.create_from_image(pixels)
	else:_textures[key]=texture
	return _textures[key]

static func prepare_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.mesh!=null:
			for i: int in range(mesh.mesh.get_surface_count()):
				var source := mesh.get_active_material(i) as StandardMaterial3D
				if source==null or source.has_meta("online_filtered"):continue
				var key := source.get_rid().get_id()
				if not _materials.has(key):
					var material := source.duplicate() as StandardMaterial3D
					material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					material.albedo_texture=_filtered(source.albedo_texture)
					material.normal_texture=_filtered(source.normal_texture,true)
					material.roughness_texture=_filtered(source.roughness_texture)
					material.ao_texture=_filtered(source.ao_texture)
					material.metallic_texture=_filtered(source.metallic_texture)
					material.set_meta("online_filtered",true)
					_materials[key]=material
				mesh.set_surface_override_material(i,_materials[key])
	for child: Node in node.get_children():prepare_materials(child)

static func find_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := find_animator(child)
		if found!=null:return found
	return null

func _ready() -> void:
	body=instantiate_body()
	add_child(body)
	animator=find_animator(body)
	sword=body.get_node_or_null("IleanaRig/Skeleton3D/Mara_Sword") as Node3D
	_skeleton=body.get_node_or_null("IleanaRig/Skeleton3D") as Skeleton3D
	if animator!=null:
		animator.speed_scale=0.0
		animator.play("idle")
		animator.seek(0.0,true)

func apply_state(value: Dictionary, _delta: float=0.0) -> void:
	var action := str(value.get("action","idle"))
	var elapsed := float(value.get("action_time",0.0))
	if action!=_last_action or elapsed+0.05<_action_clock:
		_action_clock=elapsed
	_last_action=action
	_action_clock=maxf(_action_clock,elapsed)
	actor=value

func hit() -> void:
	_hit_until=_clock+0.24

func _process(delta: float) -> void:
	_clock+=delta
	_action_clock+=delta
	var travel_speed := maxf(0.0,float(actor.get("speed",0.0)))
	# Integrate distance travelled instead of multiplying absolute time by speed.
	# Acceleration and network reconciliation therefore cannot jump the feet.
	if travel_speed>0.15:
		_locomotion_phase+=delta*travel_speed/(4.77 if travel_speed>1.45 else 0.89)
	if animator==null:return
	var action := str(actor.get("action","idle"))
	var dead := bool(actor.get("dead",false))
	var clip := "idle"
	var duration := maxf(0.01,float(actor.get("action_duration",1.0)))
	var elapsed := minf(_action_clock,duration)
	var normalized := clampf(elapsed/duration,0.0,1.0)
	var progress := -1.0
	if dead:
		clip="death"
		progress=minf(1.0,_action_clock/2.4167)
	elif action in ["strike","cleave","attack"]:
		clip="attack"
		var impact := float(Catalog.ABILITIES.get(action,Catalog.ABILITIES.strike).impact)
		progress=0.44*clampf(elapsed/impact,0,1) if elapsed<impact else 0.44+0.56*clampf((elapsed-impact)/maxf(0.01,duration-impact),0,1)
	elif action in ["roll","dodge"]:
		clip="dodge"
		progress=normalized
	elif action in ["ward","cast"]:
		if elapsed<0.55:
			clip="cast_start"
			progress=elapsed/0.55
		elif elapsed<1.05:
			clip="cast_release"
			progress=(elapsed-0.55)/0.5
		else:
			clip="cast_end"
			progress=clampf((elapsed-1.05)/0.35,0,1)
	elif action in ["run","walk"] or float(actor.get("speed",0.0))>0.15:
		clip="run" if float(actor.get("speed",4.7))>1.45 else "walk"
	elif _clock<_hit_until:
		clip="hit"
		progress=1.0-(_hit_until-_clock)/0.24
	elif float(actor.get("combat",0.0))>0.0:clip="combat_idle"
	if not animator.has_animation(clip):clip="idle"
	var length := animator.get_animation(clip).length
	var t := fmod(_clock,maxf(0.001,length))
	if progress>=0.0:t=minf(length*progress,maxf(0.0,length-0.001))
	elif clip in ["run","walk"]:t=fmod(_locomotion_phase,length)
	if clip!=_clip:
		_blend_source.clear()
		if _skeleton!=null:
			for i: int in range(_skeleton.get_bone_count()):_blend_source.append(_skeleton.get_bone_pose(i))
		_blend_elapsed=0.0
		animator.play(clip,0.0)
		_clip=clip
	animator.seek(t,true)
	# Seek preserves the server's contact timeline. Explicit short pose blending
	# supplies continuity because a paused AnimationPlayer cannot advance its
	# own crossfade clock. The mesh and source animation resources stay unchanged.
	_blend_elapsed+=delta
	if _skeleton!=null and _blend_elapsed<0.12 and _blend_source.size()==_skeleton.get_bone_count():
		var weight := smoothstep(0.0,0.12,_blend_elapsed)
		for i: int in range(_blend_source.size()):
			_skeleton.set_bone_pose(i,_blend_source[i].interpolate_with(_skeleton.get_bone_pose(i),weight))
	if sword!=null:sword.visible=not (clip.begins_with("cast_") or clip in ["dodge","death"])
