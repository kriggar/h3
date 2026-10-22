extends SceneTree
## Native avatar regression gates. The realm still owns combat and movement.
## Presentation is measured from actual bone poses, not mocked clips.
const Avatar = preload("res://game/online/avatar.gd")
const C = preload("res://game/online/catalog.gd")
const Realm = preload("res://game/online/realm.gd")
const DT := 1.0/60.0
var checks := 0
var failures: Array[String] = []
var metrics: Dictionary = {}
var avatars: Array[Node3D] = []
var finite_poses := true
var greatest_render_overwrite := 0.0

func _initialize() -> void:call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures.append(message)
		push_error(message)

func _state(action: String="idle", elapsed: float=0.0, speed: float=0.0) -> Dictionary:
	return {"id":1,"name":"Motion Review","pos":[0.0,0.0,0.0],"yaw":0.0,"speed":speed,"action":action,"action_time":elapsed,"action_duration":float(C.ABILITIES.get(action,{}).get("duration",1.0)),"dead":action=="death","grounded":true,"combat":0.0}

func _spawn() -> Node3D:
	var avatar: Node3D=Avatar.new()
	root.add_child(avatar)
	avatar.set_process(false)
	avatar.apply_state(_state())
	avatars.append(avatar)
	return avatar

func _skeleton(avatar: Node3D) -> Skeleton3D:
	return avatar.body.get_node("IleanaRig/Skeleton3D") as Skeleton3D

func _motion(velocity: Vector3=Vector3.ZERO) -> Dictionary:
	return {"velocity":velocity,"local_velocity":velocity,"acceleration":Vector3.ZERO,"turn_rate":0.0,"grounded":true,"height":0.0,"vertical_speed":0.0,"teleported":false,"source_age":0.0}

func _tick(avatar: Node3D, motion: Dictionary, dt: float=DT) -> Dictionary:
	avatar.position+=motion.velocity*dt
	avatar.position.y=float(motion.height)
	avatar.set_presentation_motion(motion)
	avatar._process(dt)
	var skeleton:=_skeleton(avatar)
	for index in range(skeleton.get_bone_count()):
		var transform:=skeleton.get_bone_pose(index)
		var rotation:=transform.basis.get_rotation_quaternion()
		finite_poses=finite_poses and transform.origin.is_finite() and transform.basis.is_finite() and rotation.is_finite() and absf(rotation.length()-1.0)<0.001
	return avatar.animation_diagnostics()

func _pose(avatar: Node3D, names: Array[String]=[]) -> Array[Quaternion]:
	var result: Array[Quaternion]=[]
	var skeleton:=_skeleton(avatar)
	if names.is_empty():
		for index in range(skeleton.get_bone_count()):result.append(skeleton.get_bone_pose_rotation(index))
	else:
		for name in names:result.append(skeleton.get_bone_pose_rotation(skeleton.find_bone(name)))
	return result

func _difference(a: Array[Quaternion], b: Array[Quaternion]) -> float:
	var result:=0.0
	for index in range(mini(a.size(),b.size())):result=maxf(result,a[index].angle_to(b[index]))
	return result

func _world_feet(avatar: Node3D) -> Array[Quaternion]:
	var result: Array[Quaternion]=[]
	var skeleton:=_skeleton(avatar)
	skeleton.force_update_all_bone_transforms()
	for name: String in ["foot_l","foot_r"]:
		var basis:=skeleton.global_transform.basis*skeleton.get_bone_global_pose(skeleton.find_bone(name)).basis
		result.append(basis.orthonormalized().get_rotation_quaternion())
	return result

func _boot_data(avatar: Node3D) -> Dictionary:
	var mesh: MeshInstance3D=avatar.body.get_node("IleanaRig/Skeleton3D/Ileana_LeatherBoots")
	var skeleton:=_skeleton(avatar)
	var surfaces: Array=[]
	for index in range(mesh.mesh.get_surface_count()):
		var arrays:=mesh.mesh.surface_get_arrays(index)
		surfaces.append({"v":arrays[Mesh.ARRAY_VERTEX],"b":arrays[Mesh.ARRAY_BONES],"w":arrays[Mesh.ARRAY_WEIGHTS]})
	var binds: Array=[]
	for index in range(mesh.skin.get_bind_count()):
		var bone:=skeleton.find_bone(mesh.skin.get_bind_name(index))
		if bone<0:bone=mesh.skin.get_bind_bone(index)
		binds.append({"bone":bone,"inverse":mesh.skin.get_bind_pose(index)})
	return {"surfaces":surfaces,"binds":binds}

func _sole_min(avatar: Node3D, data: Dictionary) -> float:
	var skeleton:=_skeleton(avatar)
	skeleton.force_update_all_bone_transforms()
	var transforms: Array[Transform3D]=[]
	for bind: Dictionary in data.binds:transforms.append(skeleton.global_transform*skeleton.get_bone_global_pose(bind.bone)*bind.inverse)
	var result:=INF
	for surface: Dictionary in data.surfaces:
		var influences: int=surface.b.size()/surface.v.size()
		for vertex in range(surface.v.size()):
			var point:=Vector3.ZERO
			for influence in range(influences):
				var index:=vertex*influences+influence
				point+=(transforms[surface.b[index]]*surface.v[vertex])*surface.w[index]
			result=minf(result,point.y)
	return result

func _run() -> void:
	var avatar:=_spawn()
	check(FileAccess.get_sha256(C.HERO_MODEL)==C.HERO_SHA256,"Accepted Mara model and materials are byte-for-byte preserved")
	check(_skeleton(avatar).get_bone_count()==53,"Accepted Mara retains its 53-bone rig")
	check(avatar.has_method("set_presentation_motion") and avatar.has_method("animation_diagnostics") and avatar.has_method("interact"),"Public avatar presentation hooks are available")
	if not avatar.has_method("set_presentation_motion") or not avatar.has_method("animation_diagnostics") or not avatar.has_method("interact"):
		await _finish()
		return
	if "--turn-transition-only" in OS.get_cmdline_user_args():
		_run_to_turn_continuity()
		await _finish()
		return
	check(avatar.animator.callback_mode_process==AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL,"Animation mixer cannot automatically overwrite composed bone poses")
	await _render_ownership(avatar)
	_clock_reconciliation()
	_actual_displacement()
	_locomotion_transitions()
	_run_to_turn_continuity()
	_air_and_landing()
	_moving_hit()
	_directional_recovery()
	_interaction()
	_authority_contacts()
	_death_and_respawn()
	_geometry_and_contact()
	check(finite_poses,"All sampled motion, action and transition bone transforms remain finite and normalized")
	await _finish()

func _render_ownership(avatar: Node3D) -> void:
	var transitions: Array=[{"action":"idle","speed":0.0},{"action":"walk","speed":0.89},{"action":"run","speed":4.77},{"action":"strike","speed":0.0},{"action":"ward","speed":0.0},{"action":"roll","speed":0.0},{"action":"death","speed":0.0},{"action":"idle","speed":0.0}]
	for transition: Dictionary in transitions:
		avatar.apply_state(_state(transition.action,0.0,transition.speed))
		_tick(avatar,_motion(Vector3(0,0,transition.speed)))
		var before:=_pose(avatar)
		await process_frame
		greatest_render_overwrite=maxf(greatest_render_overwrite,_difference(before,_pose(avatar)))
	metrics.render_pose_overwrite_radians=greatest_render_overwrite
	check(greatest_render_overwrite<0.002,"Rendered skeleton retains manually composed transitions and layers")

func _clock_reconciliation() -> void:
	var avatar:=_spawn()
	avatar.apply_state(_state("strike",0.0))
	var previous:=0.0
	var monotonic:=true
	for frame in range(42):
		if frame%4==0:avatar.apply_state(_state("strike",0.0))
		var elapsed:=float(_tick(avatar,_motion()).action_elapsed)
		monotonic=monotonic and elapsed>=previous-0.00001
		previous=elapsed
	check(monotonic and previous>0.65,"Republished same-action snapshots never repeatedly restart the attack")
	avatar.apply_state(_state("strike",0.85))
	var advanced:=float(_tick(avatar,_motion()).action_elapsed)
	avatar.apply_state(_state("strike",0.78))
	var after_old:=float(_tick(avatar,_motion()).action_elapsed)
	check(after_old>=advanced-0.00001,"Small stale action-time corrections do not rewind the displayed action")
	avatar.apply_state(_state("strike",0.01))
	var restarted:=float(_tick(avatar,_motion()).action_elapsed)
	check(restarted<0.1,"A genuinely repeated same ability starts a new action timeline")
	metrics.action_clock={"same_snapshot_elapsed":previous,"before_old_snapshot":advanced,"after_old_snapshot":after_old,"new_action_elapsed":restarted}

func _actual_displacement() -> void:
	var avatar:=_spawn()
	avatar.apply_state(_state("run",0.0,4.77))
	for frame in range(60):_tick(avatar,_motion(Vector3(0,0,4.77)))
	var before:=float(avatar.animation_diagnostics().gait_phase)
	for frame in range(60):_tick(avatar,_motion())
	var stopped: Dictionary=avatar.animation_diagnostics()
	var settled_phase:=float(stopped.gait_phase)
	for frame in range(30):_tick(avatar,_motion())
	var final: Dictionary=avatar.animation_diagnostics()
	check(float(final.speed)<0.05,"A stale run snapshot cannot keep the feet running after displayed movement stops")
	check(absf(float(final.gait_phase)-settled_phase)<0.002,"Settled feet do not advance the gait phase without movement")
	metrics.gait_stop={"moving_phase":before,"settled_phase":settled_phase,"final_phase":final.gait_phase,"reported_speed":final.speed}

func _air_and_landing() -> void:
	var avatar:=_spawn()
	avatar.apply_state(_state("run",0.0,2.6))
	for frame in range(30):_tick(avatar,_motion(Vector3(0,0,2.6)))
	var clips: Dictionary={}
	var airborne_locks:=false
	var airborne_ground_clip:=false
	for frame in range(1,46):
		var time:=frame*DT
		var motion:=_motion(Vector3(0,0,2.6))
		motion.grounded=false
		motion.height=maxf(0.001,5.1*time-6.75*time*time)
		motion.vertical_speed=5.1-13.5*time
		var d:=_tick(avatar,motion)
		clips[str(d.clip)]=true
		airborne_locks=airborne_locks or bool(d.foot_l_locked) or bool(d.foot_r_locked)
		airborne_ground_clip=airborne_ground_clip or str(d.clip) in ["idle","walk","run","combat_idle"]
	check(not airborne_locks,"Airborne poses never retain planted-foot locks")
	check(not airborne_ground_clip,"Jumping no longer plays a ground locomotion clip in the air")
	var landing_seen:=false
	var landing_weapon_hidden:=true
	for frame in range(40):
		var d:=_tick(avatar,_motion(Vector3(0,0,2.6)))
		landing_seen=landing_seen or float(d.landing_weight)>0.05 or "land" in str(d.clip)
		if str(d.state)=="landing" and float(d.landing_weight)>0.1:landing_weapon_hidden=landing_weapon_hidden and not avatar.sword.visible
	check(landing_seen,"Ground contact produces a visible landing recovery")
	check(landing_weapon_hidden,"Unarmed landing keeps the sword stowed until the landing pose recovers")
	check(bool(avatar.animation_diagnostics().grounded),"Landing returns the presentation to grounded motion")
	metrics.airborne_clips=clips.keys()

func _locomotion_transitions() -> void:
	var first_step_max:=0.0
	# Cover both feet's stance/swing phases instead of accepting a lucky single
	# transition. This is a visible-pose gate at the review video's 24 Hz rate.
	for warmup_frames: int in [15,30,45,60,75,90]:
		var avatar:=_spawn()
		avatar.apply_state(_state("walk",0.0,0.89))
		for frame in range(warmup_frames):_tick(avatar,_motion(Vector3(0,0,0.89)))
		var before:=_pose(avatar)
		avatar.apply_state(_state("run",0.0,4.77))
		_tick(avatar,_motion(Vector3(0,0,4.77)),1.0/24.0)
		first_step_max=maxf(first_step_max,_difference(before,_pose(avatar)))
	check(first_step_max<0.7,"Walk-to-run speed changes do not cause a large one-frame bone jump at 24 fps")
	var avatar:=_spawn()
	for frame in range(30):_tick(avatar,_motion())
	var idle:=_pose(avatar)
	avatar.apply_state(_state("walk",0.0,0.89))
	_tick(avatar,_motion(Vector3(0,0,0.89)),1.0/24.0)
	var start_step:=_difference(idle,_pose(avatar))
	check(start_step<0.7,"Starting a walk blends from the standing pose at 24 fps")
	metrics.locomotion_transitions={"maximum_walk_to_run_first_frame_radians":first_step_max,"idle_to_walk_first_frame_radians":start_step,"maximum_allowed_radians":0.7,"tested_gait_phases":6,"sample_delta_seconds":1.0/24.0}

func _run_to_turn_continuity() -> void:
	# A steady idle pivot misses run-to-stop entry: while the running pose is
	# fading, its raised foot can point almost vertically. Projecting that toe
	# onto the floor used to introduce a 116-degree yaw flip and reversal.
	# Measure actual world foot rotation, not a local IK compensation rotation.
	const SAMPLE_DT:=1.0/24.0
	var worst:=0.0
	var worst_case: Dictionary={}
	var finite:=true
	var case_count:=0
	for run_frames: int in [42,46,50,54,58,60,62,66]:
		for direction: float in [-1.0,1.0]:
			var avatar:=_spawn()
			for frame in range(24):_tick(avatar,_motion(),SAMPLE_DT)
			avatar.apply_state(_state("walk",0.0,0.89))
			for frame in range(36):_tick(avatar,_motion(Vector3(0,0,0.89)),SAMPLE_DT)
			avatar.apply_state(_state("run",0.0,4.77))
			for frame in range(run_frames):_tick(avatar,_motion(Vector3(0,0,4.77)),SAMPLE_DT)
			var previous:=_world_feet(avatar)
			avatar.apply_state(_state())
			for frame in range(13):
				# Match the review stage's continuous 135-degrees-per-second pivot.
				avatar.rotation.y=direction*float(frame)*SAMPLE_DT*PI*0.75
				var motion:=_motion()
				motion.turn_rate=0.0 if frame==0 else direction*PI*0.75
				var d:=_tick(avatar,motion,SAMPLE_DT)
				var current:=_world_feet(avatar)
				for foot in range(2):
					finite=finite and current[foot].is_finite() and absf(current[foot].length()-1.0)<0.001
					var step:=previous[foot].angle_to(current[foot])
					if step>worst:
						worst=step
						worst_case={"run_frames":run_frames,"direction":direction,"frame_after_stop":frame,"foot":"left" if foot==0 else "right","gait_weights":d.gait_weights}
				previous=current
			case_count+=1
	check(worst<PI/3.0,"Run-to-turn entry does not flip a foot more than 60 degrees in one frame at 24 fps")
	check(finite and finite_poses,"Run-to-turn entry keeps all bone transforms and both world foot rotations finite and normalized")
	metrics.run_to_turn_transition={"maximum_world_foot_step_radians":worst,"maximum_allowed_radians":PI/3.0,"sample_delta_seconds":SAMPLE_DT,"cases":case_count,"gait_offsets":8,"turn_directions":2,"worst_case":worst_case,"finite_world_foot_rotations":finite,"finite_bone_transforms":finite_poses}

func _moving_hit() -> void:
	var struck:=_spawn()
	var control:=_spawn()
	for avatar: Node3D in [struck,control]:avatar.apply_state(_state("run",0.0,3.0))
	for frame in range(60):
		_tick(struck,_motion(Vector3(0,0,3)))
		_tick(control,_motion(Vector3(0,0,3)))
	struck.hit()
	var upper_delta:=0.0
	var lower_delta:=0.0
	var hit_weight:=0.0
	var phases_match:=true
	for frame in range(24):
		var a:=_tick(struck,_motion(Vector3(0,0,3)))
		var b:=_tick(control,_motion(Vector3(0,0,3)))
		upper_delta=maxf(upper_delta,_difference(_pose(struck,["spine_01","spine_02","spine_03","upperarm_l","upperarm_r","head"]),_pose(control,["spine_01","spine_02","spine_03","upperarm_l","upperarm_r","head"])))
		lower_delta=maxf(lower_delta,_difference(_pose(struck,["calf_l","foot_l","calf_r","foot_r"]),_pose(control,["calf_l","foot_l","calf_r","foot_r"])))
		hit_weight=maxf(hit_weight,float(a.hit_weight))
		phases_match=phases_match and absf(float(a.gait_phase)-float(b.gait_phase))<0.00001
	check(upper_delta>0.04 and hit_weight>0.1,"A moving hit visibly affects the upper body")
	check(lower_delta<0.005 and phases_match,"Moving hit preserves leg gait and phase against a no-hit control")
	for frame in range(30):
		_tick(struck,_motion(Vector3(0,0,3)))
		_tick(control,_motion(Vector3(0,0,3)))
	var residual:=_difference(_pose(struck,["spine_01","spine_02","spine_03","neck_01","head","clavicle_l","clavicle_r"]),_pose(control,["spine_01","spine_02","spine_03","neck_01","head","clavicle_l","clavicle_r"]))
	check(residual<0.015,"Hit recovery returns to the matching no-hit pose without accumulated torso rotation")
	metrics.moving_hit={"upper_body_difference_radians":upper_delta,"lower_leg_difference_radians":lower_delta,"peak_weight":hit_weight,"gait_phases_match":phases_match,"recovered_upper_body_difference_radians":residual}

func _interaction() -> void:
	var avatar:=_spawn()
	for frame in range(15):_tick(avatar,_motion())
	avatar.interact()
	var seen:=false
	var hidden_during_interaction:=true
	for frame in range(120):
		var d:=_tick(avatar,_motion())
		if float(d.interaction_weight)>0.1:
			seen=true
			hidden_during_interaction=hidden_during_interaction and not avatar.sword.visible
	check(seen,"Public interact event produces the authored interaction motion")
	check(hidden_during_interaction,"Unarmed interaction does not retain a floating sword")
	check(float(avatar.animation_diagnostics().interaction_weight)<0.01,"Interaction finishes and returns control to idle")

func _directional_recovery() -> void:
	var turning:=_spawn()
	var control:=_spawn()
	for avatar: Node3D in [turning,control]:avatar.apply_state(_state("run",0.0,3.0))
	var peak_warp:=0.0
	for frame in range(150):
		var d:=_tick(turning,_motion(Vector3(3,0,0)))
		_tick(control,_motion(Vector3(0,0,3)))
		peak_warp=maxf(peak_warp,absf(float(d.stride_yaw)))
	for frame in range(90):
		_tick(turning,_motion(Vector3(0,0,3)))
		_tick(control,_motion(Vector3(0,0,3)))
	var forward_residual:=_difference(_pose(turning,["spine_01","spine_02","spine_03","neck_01","head"]),_pose(control,["spine_01","spine_02","spine_03","neck_01","head"]))
	for avatar: Node3D in [turning,control]:avatar.apply_state(_state())
	for frame in range(90):
		_tick(turning,_motion())
		_tick(control,_motion())
	var idle_residual:=_difference(_pose(turning,["spine_01","spine_02","spine_03","neck_01","head"]),_pose(control,["spine_01","spine_02","spine_03","neck_01","head"]))
	check(peak_warp>0.5,"Sideways travel produces a directional leg stride")
	check(forward_residual<0.015 and idle_residual<0.015,"Directional stride counter-rotation does not accumulate after returning forward or idle")
	metrics.directional_recovery={"peak_stride_yaw_radians":peak_warp,"forward_upper_body_difference_radians":forward_residual,"idle_upper_body_difference_radians":idle_residual}

func _authority_contacts() -> void:
	var reports: Dictionary={}
	for ability: String in ["strike","cleave","ward"]:
		var realm:=Realm.new()
		var player: Dictionary=realm.add_player(1,"Contact Review")
		var enemy: Dictionary=realm.state.enemies.values()[0]
		realm.state.enemies={enemy.id:enemy}
		var position:=C.vector(player.pos)
		enemy.pos=C.array(position+Vector3(0,0,1.5))
		enemy.hp=1000.0
		enemy.max_hp=1000.0
		player.hp=float(player.max_hp)-60.0
		player.combat=10.0
		check(bool(realm.act(1,{"type":"ability","id":ability,"target":enemy.id}).ok),"Real realm accepts contact scenario: "+ability)
		var avatar:=_spawn()
		avatar.apply_state(player.duplicate(true))
		var first_time:=-1.0
		var first_phase:=-1.0
		var first_clip:=""
		var impacts:=0
		var last_hp:=float(enemy.hp)
		var previous_events:=realm.events.size()
		for frame in range(int(float(C.ABILITIES[ability].duration)*120.0)+2):
			# Freeze enemy AI only; use the actual authoritative player/impact code.
			realm.state.time+=1.0/120.0
			realm._step_player(player,1.0/120.0)
			avatar.apply_state(player.duplicate(true))
			var d:=_tick(avatar,_motion(),1.0/120.0)
			var occurred:=float(enemy.hp)<last_hp-0.001
			for index in range(previous_events,realm.events.size()):
				if ability=="ward" and str(realm.events[index].type)=="ward":occurred=true
			previous_events=realm.events.size()
			if occurred:
				impacts+=1
				if first_time<0.0:
					first_time=float(realm.state.time)
					first_phase=float(d.action_progress)
					first_clip=str(d.clip)
			last_hp=float(enemy.hp)
		var contact:=float(C.ABILITIES[ability].impact)
		check(impacts==1 and first_time>=contact-0.00001 and first_time<=contact+1.0/120.0+0.00001,"Authoritative impact occurs once at its defined contact time: "+ability)
		if ability!="ward":check(absf(first_phase-0.44)<0.025,"Visual blade contact agrees with authoritative damage: "+ability)
		else:check("cast_release" in first_clip,"Iron Vow applies when the authored release phase begins")
		reports[ability]={"authority_impact_seconds":first_time,"source_visual_phase":first_phase,"clip_at_impact":first_clip,"impact_count":impacts}
	metrics.authority_contacts=reports

func _death_and_respawn() -> void:
	var avatar:=_spawn()
	avatar.apply_state(_state("death",0.0))
	for frame in range(180):_tick(avatar,_motion())
	var held:=_pose(avatar)
	for frame in range(60):_tick(avatar,_motion())
	var drift:=_difference(held,_pose(avatar))
	check(drift<0.002,"Death holds its final pose without looping or breathing")
	check(not avatar.sword.visible,"Death stows the unanimated held sword")
	avatar.apply_state(_state())
	var reset:=_motion()
	reset.teleported=true
	_tick(avatar,reset)
	for frame in range(30):_tick(avatar,_motion())
	var d: Dictionary=avatar.animation_diagnostics()
	check(not "death" in str(d.state) and avatar.sword.visible,"Respawn restores a living idle pose and held weapon")
	check(not bool(d.foot_l_locked) or bool(d.grounded),"Respawn never carries an airborne planted foot")
	metrics.death_hold_difference_radians=drift

func _geometry_and_contact() -> void:
	var results: Dictionary={}
	for scenario: String in ["walk","run","strafe","turn"]:
		var avatar:=_spawn()
		var speed:=0.89 if scenario=="walk" else (0.0 if scenario=="turn" else 4.77)
		avatar.apply_state(_state("run" if speed>1.45 else ("walk" if speed>0 else "idle"),0.0,speed))
		var boots:=_boot_data(avatar)
		var lowest:=INF
		var locked_frames: Array[int]=[0,0]
		var previous_balls: Array[Vector3]=[]
		var previous_weights: Array[float]=[0.0,0.0]
		var drift: Array[float]=[]
		var blended_contact_drift: Array[float]=[]
		for frame in range(180):
			var motion:=_motion(Vector3(speed if scenario=="strafe" else 0.0,0,0.0 if scenario=="strafe" else speed))
			if scenario=="turn":
				avatar.rotation.y+=1.5*DT
				motion.turn_rate=1.5
			var d:=_tick(avatar,motion)
			var skeleton:=_skeleton(avatar)
			var balls: Array[Vector3]=[]
			for name: String in ["ball_l","ball_r"]:balls.append(skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone(name)).origin)
			for foot in range(2):
				var locked:=bool(d.foot_l_locked if foot==0 else d.foot_r_locked)
				locked_frames[foot]=locked_frames[foot]+1 if locked else 0
				if frame>30 and locked_frames[foot]>2 and previous_balls.size()==2:
					var foot_speed:=Vector2(balls[foot].x-previous_balls[foot].x,balls[foot].z-previous_balls[foot].z).length()/DT
					# A fading contact intentionally gives motion back to the source
					# toe roll and swing. Count rigid-plant drift only when both ends
					# of the measured interval have at least 80% plant weight.
					if float(d.foot_weights[foot])>=0.8 and previous_weights[foot]>=0.8:drift.append(foot_speed)
					else:blended_contact_drift.append(foot_speed)
				previous_weights[foot]=float(d.foot_weights[foot])
			previous_balls=balls
			if frame%3==0:lowest=minf(lowest,_sole_min(avatar,boots))
		check(lowest>=-0.012,"Skinned boots stay within 12 mm of the floor during "+scenario)
		drift.sort()
		blended_contact_drift.sort()
		var median: float=drift[drift.size()/2] if not drift.is_empty() else -1.0
		var p90: float=drift[mini(drift.size()-1,int(drift.size()*0.9))] if not drift.is_empty() else -1.0
		var blended_median: float=blended_contact_drift[blended_contact_drift.size()/2] if not blended_contact_drift.is_empty() else -1.0
		var blended_p90: float=blended_contact_drift[mini(blended_contact_drift.size()-1,int(blended_contact_drift.size()*0.9))] if not blended_contact_drift.is_empty() else -1.0
		if scenario=="run":check(drift.size()>6 and median<0.20 and p90<0.50,"Run planted-toe drift improves materially over the measured baseline")
		results[scenario]={"lowest_skinned_sole_metres":lowest,"strong_plant_samples":drift.size(),"strong_plant_toe_speed_median_mps":median,"strong_plant_toe_speed_p90_mps":p90,"blended_contact_samples":blended_contact_drift.size(),"blended_contact_toe_speed_median_mps":blended_median,"blended_contact_toe_speed_p90_mps":blended_p90,"plant_measurement":"Both consecutive samples have foot weight >=0.8 and contact age exceeds two frames. Blended acquisition/release is reported separately."}
	metrics.geometry=results

func _finish() -> void:
	var report: Dictionary={"suite":"animation_controller","checks":checks,"failures":failures,"metrics":metrics,"mara_sha256":FileAccess.get_sha256(C.HERO_MODEL),"scope":"Native skeleton presentation plus actual realm contact simulation. Geometry uses original CPU-skinned boot vertices. Visual quality still requires reviewing native motion footage."}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var file:=FileAccess.open(argument.trim_prefix("--report="),FileAccess.WRITE)
			if file!=null:file.store_string(JSON.stringify(report,"  ")+"\n")
	print(JSON.stringify(report))
	for avatar: Node3D in avatars:avatar.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
