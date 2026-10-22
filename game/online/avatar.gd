extends Node3D
## Mara's original mesh, rig and twelve clips are preserved. This controller
## samples authored motion explicitly, then layers presentation-only corrections.
const Catalog = preload("res://game/online/catalog.gd")
const FootPlacement = preload("res://game/online/foot_placement.gd")
const EXTENDED = preload("res://assets/online/animations/mara_extended.tres")
const WALK_STRIDE := 1.1869857069
const RUN_STRIDE := 4.3765276054
const RUN_PHASE_OFFSET := 0.024
static var _scene: PackedScene
static var _materials: Dictionary = {}
static var _textures: Dictionary = {}
var body: Node3D
var animator: AnimationPlayer
var sword: Node3D
var actor: Dictionary = {}
var _clock := 0.0
var _clip := ""
var _last_action := ""
var _confirmed_action_time := 0.0
var _confirmed_action_origin := -INF
var _confirmed_source_time := -1.0
var _action_clock := 0.0
# Normalized cycles, never unrelated raw seconds from different source clips.
var _locomotion_phase := 0.0
var _skeleton: Skeleton3D
var _blend_source: Array[Transform3D] = []
var _blend_elapsed := 1.0
var _blend_duration := 0.16
var _blend_gait_lower := false
var _pose_state := ""
var _motion: Dictionary = {}
var _ground_sampler: Callable
var _feet = FootPlacement.new()
var _bones: Dictionary = {}
var _rest_reference: Array[Transform3D] = []
var _idle_reference: Array[Transform3D] = []
var _gait_speed := 0.0
var _run_weight := 0.0
var _move_weight := 0.0
var _turn_weight := 0.0
var _stride := WALK_STRIDE
var _stride_yaw := 0.0
var _backward := 1.0
var _body_yaw := 0.0
var _body_basis := Basis.IDENTITY
var _lean := Vector2.ZERO
var _grounded := true
var _air_clock := 0.0
var _land_clock := 10.0
var _landing_weight := 0.0
var _hit_clock := 10.0
var _hit_weight := 0.0
var _hit_serial := 0
var _interact_clock := 10.0
var _interaction_weight := 0.0
var _reset_pending := false
var _clip_time := 0.0
var _action_progress := -1.0
var _state := "idle"

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
	_body_basis=body.basis
	add_child(body)
	animator=find_animator(body)
	sword=body.get_node_or_null("IleanaRig/Skeleton3D/Mara_Sword") as Node3D
	_skeleton=body.get_node_or_null("IleanaRig/Skeleton3D") as Skeleton3D
	if animator!=null:
		# A paused automatic mixer still re-applies its pose at render time. Manual
		# evaluation is essential: otherwise it silently discards every layer below.
		animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		animator.speed_scale=0.0
		animator.add_animation_library("extended",EXTENDED)
		animator.play("idle")
		animator.seek(0.0,true)
	if _skeleton!=null:
		for i: int in range(_skeleton.get_bone_count()):
			_bones[_skeleton.get_bone_name(i)]=i
			_rest_reference.append(_skeleton.get_bone_rest(i))
		_feet.setup(_skeleton)
		_feet.ground_sampler=_ground_sampler
		_idle_reference=_capture()

func apply_state(value: Dictionary, _delta: float=0.0, source_time: float=-1.0) -> void:
	var action := str(value.get("action","idle"))
	var elapsed := float(value.get("action_time",0.0))
	var source_reset := source_time>=0.0 and _confirmed_source_time>=0.0 and source_time+0.001<_confirmed_source_time
	if source_time>=0.0:_confirmed_source_time=source_time
	if source_reset:_reset_pending=true
	# Compare confirmed samples with each other, never with the locally advanced
	# render clock. A delayed 15 Hz snapshot must not replay an attack's windup.
	var new_instance := elapsed+0.35<_confirmed_action_time or (elapsed<0.2 and elapsed+0.2<_confirmed_action_time)
	if source_time>=0.0 and action in ["strike","cleave","attack","ward","cast","roll","dodge","death"]:
		var origin := source_time-elapsed
		new_instance=is_finite(_confirmed_action_origin) and absf(origin-_confirmed_action_origin)>0.05
		_confirmed_action_origin=origin
	elif action!=_last_action:_confirmed_action_origin=-INF
	if action!=_last_action or new_instance or source_reset:
		_action_clock=elapsed
	if bool(actor.get("dead",false)) and not bool(value.get("dead",false)):
		_reset_pending=true
	_last_action=action
	_confirmed_action_time=elapsed
	_action_clock=maxf(_action_clock,elapsed)
	actor=value

func set_presentation_motion(motion: Dictionary) -> void:
	_motion=motion
	if bool(motion.get("teleported",false)):_reset_pending=true

func set_ground_sampler(sampler: Callable) -> void:
	_ground_sampler=sampler
	_feet.ground_sampler=sampler

func hit() -> void:
	if bool(actor.get("dead",false)):return
	_hit_clock=0.0
	_hit_serial+=1

func interact(_kind: String="gather") -> void:
	if bool(actor.get("dead",false)):return
	_interact_clock=0.0

func _capture() -> Array[Transform3D]:
	var pose: Array[Transform3D]=[]
	if _skeleton!=null:
		for i: int in range(_skeleton.get_bone_count()):pose.append(_skeleton.get_bone_pose(i))
	return pose

func _write(pose: Array[Transform3D]) -> void:
	for i: int in range(pose.size()):_skeleton.set_bone_pose(i,pose[i])

func _sample(clip: String, time: float) -> Array[Transform3D]:
	if not animator.has_animation(clip):clip="idle"
	# Godot removes constant imported tracks. Without a clean base, an omitted
	# spine/root channel inherits last frame's additive twist and accumulates it.
	_write(_rest_reference)
	if animator.current_animation!=clip:animator.play(clip,0.0)
	var animation := animator.get_animation(clip)
	var t := fposmod(time,animation.length) if animation.loop_mode!=Animation.LOOP_NONE else clampf(time,0.0,animation.length-0.0001)
	animator.seek(t,true)
	return _capture()

func _mix(a: Array[Transform3D], b: Array[Transform3D], weight: float) -> Array[Transform3D]:
	var result: Array[Transform3D]=[]
	for i: int in range(a.size()):result.append(a[i].interpolate_with(b[i],weight))
	return result

func _upper_body(base: Array[Transform3D], upper: Array[Transform3D], weight: float) -> Array[Transform3D]:
	var result: Array[Transform3D]=base.duplicate()
	# The spine subtree contains the arms, head and every grip bone; the pelvis
	# and complete legs stay on the gait or airborne pose underneath it.
	for i: int in range(base.size()):
		if i>=2 and i<=44:result[i]=base[i].interpolate_with(upper[i],weight)
	return result

func _window(phase: float, start: float, end: float, edge: float) -> float:
	return smoothstep(start,start+edge,phase)*(1.0-smoothstep(end-edge,end,phase))

func _contact(phase: float) -> float:
	var walk := _window(fposmod(phase,1.0),0.055,0.555,0.055)
	var run := _window(fposmod(phase+RUN_PHASE_OFFSET,1.0),0.033,0.183,0.022)
	return lerpf(walk,run,_run_weight)

func _rotate_world(bone: String, axis: Vector3, radians: float) -> void:
	if absf(radians)<0.00001:return
	var index := int(_bones[bone])
	var transform := _skeleton.get_bone_global_pose(index)
	var local_axis := (_skeleton.global_transform.basis.inverse()*axis).normalized()
	transform.basis=Basis(Quaternion(local_axis,radians))*transform.basis
	_skeleton.set_bone_global_pose(index,transform)
	_skeleton.force_update_all_bone_transforms()

func _shift_pelvis(distance: float) -> void:
	var index := int(_bones.pelvis)
	var transform := _skeleton.get_bone_global_pose(index)
	transform.origin+=_skeleton.global_transform.basis.inverse()*Vector3(0,distance,0)
	_skeleton.set_bone_global_pose(index,transform)
	_skeleton.force_update_all_bone_transforms()

func _reset_motion() -> void:
	_feet.reset()
	_blend_source.clear()
	_blend_elapsed=1.0
	_blend_gait_lower=false
	_pose_state=""
	_gait_speed=0.0
	_run_weight=0.0
	_move_weight=0.0
	_turn_weight=0.0
	_locomotion_phase=0.0
	_backward=1.0
	_body_yaw=0.0
	_stride_yaw=0.0
	_lean=Vector2.ZERO
	_air_clock=0.0
	_land_clock=10.0
	_hit_clock=10.0
	_interact_clock=10.0
	_grounded=bool(_motion.get("grounded",actor.get("grounded",true)))
	_reset_pending=false

func _process(delta: float) -> void:
	if animator==null or _skeleton==null:return
	delta=maxf(0.0,delta)
	var reset_pose := _reset_pending
	if reset_pose:_reset_motion()
	# A teleport/respawn invalidates the prior pose and its foot anchors. Do not
	# immediately restore that history as the source of the next transition.
	var previous_pose: Array[Transform3D]=[]
	if not reset_pose:previous_pose=_capture()
	_clock+=delta
	_action_clock+=delta
	_hit_clock+=delta
	_interact_clock+=delta
	_land_clock+=delta
	var local_velocity: Vector3=_motion.get("local_velocity",Vector3(0,0,maxf(0.0,float(actor.get("speed",0.0)))))
	var travel_speed := Vector2(local_velocity.x,local_velocity.z).length()
	var turn_rate := float(_motion.get("turn_rate",0.0))
	var action := str(actor.get("action","idle"))
	# The source shoulder roll travels along +Z. Match its visual facing to
	# displayed travel while world-facing reconciliation catches up behind it.
	if action in ["roll","dodge"]:
		if travel_speed>0.5:_body_yaw=atan2(local_velocity.x,local_velocity.z)
	else:_body_yaw=lerp_angle(_body_yaw,0.0,1.0-exp(-delta*20.0))
	body.basis=Basis(Vector3.UP,_body_yaw)*_body_basis
	var grounded := bool(_motion.get("grounded",actor.get("grounded",true)))
	if grounded and not _grounded:_land_clock=0.0
	if not grounded and _grounded:
		_air_clock=0.0
		_feet.reset()
	if not grounded:_air_clock+=delta
	_grounded=grounded
	_gait_speed=lerpf(_gait_speed,travel_speed,1.0-exp(-delta*16.0))
	# Speed and pose weights have separate time constants: smooth speed alone
	# still crosses most of a smoothstep threshold in one frame at a hard start.
	_run_weight=move_toward(_run_weight,smoothstep(1.25,3.4,_gait_speed),delta*4.5)
	_move_weight=move_toward(_move_weight,smoothstep(0.04,0.62,_gait_speed),delta*6.0)
	var desired_turn := smoothstep(0.3,1.6,absf(turn_rate))*(1.0-smoothstep(0.15,0.7,travel_speed))
	_turn_weight=lerpf(_turn_weight,desired_turn,1.0-exp(-delta*14.0))
	_stride=lerpf(WALK_STRIDE,RUN_STRIDE,_run_weight)
	var backward := -1.0 if local_velocity.z< -0.15 and absf(local_velocity.z)>absf(local_velocity.x)*0.7 else 1.0
	_backward=lerpf(_backward,backward,1.0-exp(-delta*14.0))
	if grounded and travel_speed>0.015:
		# During acceleration the blended walk must not race through four times
		# its natural cadence before the run pose arrives. A short speed filter
		# shapes that start; stopping still freezes phase immediately.
		_locomotion_phase+=delta*minf(travel_speed,_gait_speed)/_stride*_backward
	elif grounded and _turn_weight>0.01:
		_locomotion_phase+=delta*absf(turn_rate)/1.8
	var phase := fposmod(_locomotion_phase,1.0)
	var idle_clip := "combat_idle" if float(actor.get("combat",0.0))>0.0 else "idle"
	var idle := _sample(idle_clip,_clock)
	var walk := _sample("walk",phase*animator.get_animation("walk").length)
	var run := _sample("run",fposmod(phase+RUN_PHASE_OFFSET,1.0)*animator.get_animation("run").length)
	var gait := _mix(walk,run,_run_weight)
	var locomotion := _mix(idle,gait,_move_weight)
	var dead := bool(actor.get("dead",false))
	var duration := maxf(0.01,float(actor.get("action_duration",1.0)))
	var elapsed := minf(_action_clock,duration)
	var normalized := clampf(elapsed/duration,0.0,1.0)
	var pose: Array[Transform3D]=locomotion
	var key := "ground"
	_clip="run" if _run_weight>0.5 and _move_weight>0.1 else ("walk" if _move_weight>0.1 or _turn_weight>0.1 else idle_clip)
	_clip_time=fposmod(phase+(RUN_PHASE_OFFSET if _clip=="run" else 0.0),1.0)*animator.get_animation(_clip).length if _clip in ["walk","run"] else fposmod(_clock,animator.get_animation(_clip).length)
	_action_progress=-1.0
	_landing_weight=0.0
	_interaction_weight=0.0
	_state="locomotion" if _move_weight>0.1 else ("turn" if _turn_weight>0.1 else "idle")
	# The world supplies the ballistic trajectory. These clips articulate the
	# body in the air without applying a second root jump to that trajectory.
	if not grounded:
		if _air_clock<0.6:
			_clip="extended/jump_start"
			_clip_time=lerpf(0.03,0.3,clampf(_air_clock/0.18,0,1)) if _air_clock<0.18 else lerpf(0.3,1.333333,clampf((_air_clock-0.18)/0.42,0,1))
			key="takeoff"
		else:
			_clip="extended/jump_loop"
			_clip_time=_air_clock-0.6
			key="airborne"
		pose=_sample(_clip,_clip_time)
		var vertical_speed := float(_motion.get("vertical_speed",0.0))
		var height := float(_motion.get("height",1.0))
		if vertical_speed< -0.2 and height<0.28:
			pose=_mix(pose,_sample("extended/jump_land",0.0),(1.0-smoothstep(0.02,0.28,height))*0.65)
		_state=key
	elif _land_clock<0.4:
		_clip="extended/jump_land"
		_clip_time=0.167*clampf(_land_clock/0.09,0,1) if _land_clock<0.09 else lerpf(0.167,1.25,clampf((_land_clock-0.09)/0.31,0,1))
		_landing_weight=(1.0-smoothstep(0.11,0.4,_land_clock))*(1.0-0.35*_move_weight)
		pose=_mix(locomotion,_sample(_clip,_clip_time),_landing_weight)
		key="landing"
		_state=key
	if dead:
		_clip="death"
		_clip_time=minf(_action_clock,animator.get_animation("death").length-0.0001)
		pose=_sample(_clip,_clip_time)
		key="death"
		_state=key
	elif action in ["roll","dodge"]:
		_clip="dodge"
		_clip_time=normalized*animator.get_animation(_clip).length
		pose=_sample(_clip,_clip_time)
		key="roll"
		_state=key
	elif action in ["strike","cleave","attack"]:
		_clip="attack"
		var impact := float(Catalog.ABILITIES.get(action,Catalog.ABILITIES.strike).impact)
		# Anticipation accelerates into the source contact pose at the exact
		# authority impact; the follow-through decelerates into recovery.
		_action_progress=0.44*pow(clampf(elapsed/impact,0,1),1.55) if elapsed<impact else 0.44+0.56*(1.0-pow(1.0-clampf((elapsed-impact)/maxf(0.01,duration-impact),0,1),1.65))
		_clip_time=_action_progress*animator.get_animation(_clip).length
		var attack := _sample(_clip,_clip_time)
		pose=_mix(attack,_upper_body(pose,attack,1.0),_move_weight if grounded else 1.0)
		key=action
		_state=action
	elif action in ["ward","cast"]:
		if elapsed<0.55:
			_clip="cast_start"
			_clip_time=elapsed/0.55*animator.get_animation(_clip).length
		elif elapsed<1.05:
			_clip="cast_release"
			_clip_time=elapsed-0.55
		else:
			_clip="cast_end"
			_clip_time=clampf((elapsed-1.05)/0.35,0,1)*animator.get_animation(_clip).length
		var cast := _sample(_clip,_clip_time)
		pose=_mix(cast,_upper_body(pose,cast,1.0),_move_weight if grounded else 1.0)
		key=_clip
		_state="ward"
	elif _interact_clock<0.83 or action=="interact":
		_clip="extended/interact"
		_clip_time=minf(_interact_clock if action!="interact" else elapsed,0.8332)
		_interaction_weight=1.0-smoothstep(0.65,0.83,_clip_time)
		var reach := _sample(_clip,_clip_time)
		var interaction := _mix(reach,_upper_body(pose,reach,1.0),_move_weight)
		pose=_mix(pose,interaction,_interaction_weight)
		key="interact"
		_state=key
	var moving_action := grounded and travel_speed>0.15 and key in ["strike","cleave","attack","cast_start","cast_release","cast_end"]
	var blend_key := key+"_moving" if moving_action else key
	if key=="ground":blend_key="ground_fast" if smoothstep(1.25,3.4,_gait_speed)>0.5 else "ground_slow"
	if blend_key!=_pose_state:
		_blend_gait_lower=grounded and travel_speed>0.15 and (moving_action or (key=="ground" and _pose_state.ends_with("_moving")))
		_blend_source=previous_pose
		_blend_elapsed=0.0
		_blend_duration=0.18 if key=="ground" else (0.07 if key=="roll" else (0.1 if key in ["strike","cleave","attack","landing"] else 0.16))
		_pose_state=blend_key
	_blend_elapsed+=delta
	if _blend_elapsed<_blend_duration and _blend_source.size()==pose.size():
		pose=_mix(_blend_source,pose,smoothstep(0.0,_blend_duration,_blend_elapsed))
	# Committed upper-body actions must not capture/replay old planted legs.
	# Keep the current gait below the spine through both action entry and exit;
	# stationary attacks/casts retain their complete authored lower-body pose.
	if moving_action or (_blend_gait_lower and _blend_elapsed<_blend_duration):
		pose=_upper_body(locomotion,pose,1.0)
	_hit_weight=0.0
	if _hit_clock<0.34 and not dead and key!="roll":
		_hit_weight=smoothstep(0.0,0.035,_hit_clock)*pow(1.0-_hit_clock/0.34,0.7)
		if action in ["strike","cleave","attack","ward","cast"]:_hit_weight*=0.35
		var hit_clip := "extended/hit_head" if _hit_serial%2==0 else "hit"
		var recoil := _sample(hit_clip,_hit_clock/0.34*animator.get_animation(hit_clip).length)
		for bone: String in ["spine_01","spine_02","spine_03","neck_01","head","clavicle_l","clavicle_r"]:
			var index := int(_bones[bone])
			var base_rotation := _idle_reference[index].basis.get_rotation_quaternion()
			var recoil_rotation := recoil[index].basis.get_rotation_quaternion()
			var offset := base_rotation.inverse()*recoil_rotation
			var strength := 0.38 if bone.begins_with("clavicle") else 0.8
			var rotation := pose[index].basis.get_rotation_quaternion()*Quaternion.IDENTITY.slerp(offset,_hit_weight*strength)
			pose[index].basis=Basis(rotation).scaled(pose[index].basis.get_scale())
	_write(pose)
	_skeleton.force_update_all_bone_transforms()
	var free_gait := key=="ground" or moving_action
	var desired_yaw := 0.0
	if free_gait and travel_speed>0.2:
		desired_yaw=clampf(atan2(local_velocity.x*backward,absf(local_velocity.z)),-1.35,1.35)
	_stride_yaw=lerpf(_stride_yaw,desired_yaw,1.0-exp(-delta*12.0))
	if free_gait:
		# Directional stride warping and distributed counter-rotation keep the
		# upper body facing the target while the legs follow lateral movement.
		_rotate_world("pelvis",Vector3.UP,_stride_yaw)
		_rotate_world("spine_01",Vector3.UP,-_stride_yaw*0.45)
		_rotate_world("spine_02",Vector3.UP,-_stride_yaw*0.35)
		_rotate_world("spine_03",Vector3.UP,-_stride_yaw*0.2)
		_shift_pelvis(0.002+0.017*_run_weight)
		var acceleration: Vector3=global_transform.basis.inverse()*Vector3(_motion.get("acceleration",Vector3.ZERO))
		var desired_lean := Vector2(clampf(acceleration.z*0.005,-0.065,0.065),clampf(-acceleration.x*0.004-turn_rate*travel_speed*0.003,-0.09,0.09))
		_lean=_lean.lerp(desired_lean,1.0-exp(-delta*9.0))
		for bone: String in ["spine_01","spine_02","spine_03"]:
			_rotate_world(bone,global_transform.basis.x,_lean.x/3.0)
			_rotate_world(bone,global_transform.basis.z,_lean.y/3.0)
	if key=="cleave":
		# A wider torso-led cut derived from the retained strike. The grip and
		# contact timestamp stay unchanged; this is not a second source attack.
		var arc := sin(clampf(elapsed/0.5,0,1)*PI*0.5)*-0.2 if elapsed<0.5 else lerpf(-0.2,0.48,smoothstep(0.5,0.83,elapsed))*(1.0-smoothstep(0.83,duration,elapsed))
		_rotate_world("spine_01",Vector3.UP,arc*0.4)
		_rotate_world("spine_02",Vector3.UP,arc*0.35)
		_rotate_world("spine_03",Vector3.UP,arc*0.25)
	var contacts := Vector2(_contact(phase),_contact(phase+0.5))
	contacts=Vector2.ONE.lerp(contacts,_move_weight)
	var turning := _turn_weight*(1.0-smoothstep(0.03,0.4,_move_weight)) if key=="ground" and travel_speed<0.2 else 0.0
	# Finish lowering the running leg before asking it to become a pivot.
	# A steep airborne toe has no stable heading for a planted-foot yaw solve.
	turning*=smoothstep(0.6,1.0,clampf(_blend_elapsed/maxf(0.01,_blend_duration),0,1))
	if turning>0.04:
		contacts=Vector2(_window(phase,0.0,0.5,0.045),_window(fposmod(phase+0.5,1.0),0.0,0.5,0.045))
	if key=="landing":contacts=Vector2.ONE*smoothstep(0.08,0.18,_land_clock)
	elif not free_gait:contacts=Vector2.ZERO
	_feet.plane_height=global_position.y-float(_motion.get("height",0.0))
	_feet.apply(delta,contacts,grounded and not dead and key!="roll" and float(_motion.get("height",0.0))<0.14,phase,turning)
	if sword!=null:
		sword.visible=not (dead or key=="roll" or not grounded or _state in ["ward","interact","landing"])

func animation_diagnostics() -> Dictionary:
	var result := {"state":_state,"clip":_clip,"clip_time":_clip_time,"action_elapsed":_action_clock,"action_progress":_action_progress,"grounded":_grounded,"gait_phase":_locomotion_phase,"gait_weights":{"idle":1.0-_move_weight,"walk":_move_weight*(1.0-_run_weight),"run":_move_weight*_run_weight,"turn":_turn_weight},"speed":_gait_speed,"stride_metres":_stride,"stride_yaw":_stride_yaw,"hit_weight":_hit_weight,"interaction_weight":_interaction_weight,"landing_weight":_landing_weight}
	result.merge(_feet.diagnostics())
	return result
