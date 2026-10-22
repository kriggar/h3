extends SceneTree
## Integration regressions found during movement/controller review. These cases
## use real accepted realm actions and the final displayed model orientation.
const Avatar = preload("res://game/online/avatar.gd")
const World = preload("res://game/online/world.gd")
const Realm = preload("res://game/online/realm.gd")
const C = preload("res://game/online/catalog.gd")
const DT := 1.0/60.0
var checks := 0
var failures: Array[String] = []
var metrics: Dictionary = {}
var avatar: Node3D

func _initialize() -> void:call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition:
		failures.append(description)
		push_error(description)

func _motion(velocity: Vector3, reset: bool=false) -> Dictionary:
	return {"velocity":velocity,"local_velocity":velocity,"acceleration":Vector3.ZERO,"turn_rate":0.0,"grounded":true,"height":0.0,"vertical_speed":0.0,"teleported":reset,"source_age":0.0,"dt":DT}

func _tick(velocity: Vector3=Vector3.ZERO, reset: bool=false) -> void:
	avatar.position+=velocity*DT
	avatar.position.y=C.ground_y(avatar.position.x,avatar.position.z)
	avatar.set_presentation_motion(_motion(velocity,reset))
	avatar._process(DT)

func _run() -> void:
	avatar=Avatar.new()
	root.add_child(avatar)
	avatar.set_process(false)
	avatar.set_ground_sampler(C.ground_y)
	_late_repeated_action()
	_diagonal_and_reset()
	_moving_action_layers()
	_full_body_action_exits()
	await _roll_direction()
	_measure_cpu()
	var report := {"suite":"animation_movement_regressions","checks":checks,"failures":failures,"metrics":metrics,"avatar_sha256":FileAccess.get_sha256("res://game/online/avatar.gd"),"foot_placement_sha256":FileAccess.get_sha256("res://game/online/foot_placement.gd")}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var file := FileAccess.open(argument.trim_prefix("--report="),FileAccess.WRITE)
			if file!=null:file.store_string(JSON.stringify(report,"\t")+"\n")
	print(JSON.stringify(report))
	avatar.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _late_repeated_action() -> void:
	var reports: Array = []
	for delay_frames: int in [18,42]:reports.append(_late_second_strike(delay_frames))
	metrics.late_repeats=reports
	var realm := Realm.new()
	var player: Dictionary=realm.add_player(1,"Origin Review")
	var enemy: Dictionary=realm.state.enemies.values()[0]
	enemy.pos=C.array(C.vector(player.pos)+Vector3(0,0,1.5))
	enemy.hp=1000.0
	enemy.max_hp=1000.0
	realm.state.enemies={enemy.id:enemy}
	realm.act(1,{"type":"ability","id":"strike","target":enemy.id})
	avatar.apply_state(player.duplicate(true),0.0,float(realm.state.time))
	var previous := float(avatar._action_clock)
	var monotonic := true
	for frame: int in range(56):
		realm.state.time+=DT
		realm._step_player(player,DT)
		if frame%4==3:avatar.apply_state(player.duplicate(true),0.0,float(realm.state.time))
		_tick()
		monotonic=monotonic and float(avatar._action_clock)>=previous-0.00001
		previous=float(avatar._action_clock)
	for frame: int in range(4):
		avatar.apply_state(player.duplicate(true),0.0,float(realm.state.time))
		_tick()
		monotonic=monotonic and float(avatar._action_clock)>=previous-0.00001
		previous=float(avatar._action_clock)
	check(monotonic and previous>0.95,"Same-origin moving snapshots and repeated publications advance without replaying the action")
	# This new realm starts its strike at time zero too. The matching origin
	# must not conceal the fact that the source clock itself restarted.
	var restarted := Realm.new()
	var fresh_player: Dictionary=restarted.add_player(1,"Restart Review")
	var fresh_enemy: Dictionary=restarted.state.enemies.values()[0]
	fresh_enemy.pos=C.array(C.vector(fresh_player.pos)+Vector3(0,0,1.5))
	var accepted: Dictionary=restarted.act(1,{"type":"ability","id":"strike","target":fresh_enemy.id})
	avatar.apply_state(fresh_player.duplicate(true),0.0,float(restarted.state.time))
	_tick(Vector3.ZERO,true)
	check(bool(accepted.ok) and float(avatar._action_clock)<0.05,"Realm-time reset restarts action time even when the new action origin equals the old origin")
	metrics.source_clock={"same_origin_elapsed_after_republications":previous,"elapsed_after_realm_restart":avatar._action_clock}

func _late_second_strike(delay_frames: int) -> Dictionary:
	var realm := Realm.new()
	var player: Dictionary=realm.add_player(1,"Clock Review")
	var enemy: Dictionary=realm.state.enemies.values()[0]
	enemy.pos=C.array(C.vector(player.pos)+Vector3(0,0,1.5))
	enemy.hp=1000.0
	enemy.max_hp=1000.0
	realm.state.enemies={enemy.id:enemy}
	var first: Dictionary=realm.act(1,{"type":"ability","id":"strike","target":enemy.id})
	avatar.apply_state(player.duplicate(true),0.0,float(realm.state.time))
	_tick(Vector3.ZERO,true)
	for frame: int in range(57):
		realm.state.time+=DT
		realm._step_player(player,DT)
		_tick()
	avatar.apply_state(player.duplicate(true),0.0,float(realm.state.time))
	var previous_confirmed := float(player.action_time)
	# Drop the end of strike one, the idle gap, and the next action's early packets.
	for frame: int in range(31):
		realm.state.time+=DT
		realm._step_player(player,DT)
		_tick()
	var second: Dictionary=realm.act(1,{"type":"ability","id":"strike","target":enemy.id})
	for frame: int in range(delay_frames):
		realm.state.time+=DT
		realm._step_player(player,DT)
		_tick()
	avatar.apply_state(player.duplicate(true),0.0,float(realm.state.time))
	_tick()
	var diagnostics: Dictionary=avatar.animation_diagnostics()
	check(bool(first.ok) and bool(second.ok),"Both repeated strike actions are accepted by the actual realm")
	check(previous_confirmed>0.9 and float(player.action_time)>0.29,"Repeated-action fixture misses the idle gap and first 0.2 seconds of the new attack: "+str(delay_frames))
	check(absf(float(diagnostics.action_elapsed)-float(player.action_time)-DT)<0.00001,"Late first packet of a repeated ability resets to its new confirmed timeline")
	check(float(diagnostics.action_progress)>0.0 and float(diagnostics.action_progress)<0.99,"Late repeated strike presents the remaining motion rather than holding the preceding attack's last pose")
	return {"previous_confirmed":previous_confirmed,"new_confirmed":player.action_time,"displayed_elapsed":diagnostics.action_elapsed,"visual_progress":diagnostics.action_progress,"source_time":realm.state.time}

func _diagonal_and_reset() -> void:
	avatar.apply_state({"action":"run","action_time":0.0,"speed":4.75,"grounded":true,"dead":false})
	var reports: Array = []
	for lateral: float in [-1.0,1.0]:
		var direction := Vector3(lateral,0,-1).normalized()
		_tick(direction*4.75,true)
		for frame: int in range(90):_tick(direction*4.75)
		# Reverse playback changes the source gait's travel axis from +Z to -Z.
		var gait_direction := (Basis(Vector3.UP,float(avatar._stride_yaw))*Vector3(0,0,float(avatar._backward))).normalized()
		var error := rad_to_deg(direction.angle_to(gait_direction))
		check(error<0.1,"Diagonal backpedal stride follows its requested lateral direction: "+str(lateral))
		reports.append({"lateral":lateral,"direction_error_degrees":error,"stride_yaw":avatar._stride_yaw,"playback_sign":avatar._backward})
	_tick(Vector3(0,0,4.75),true)
	check(float(avatar._backward)>0.99,"A motion reset cannot retain reverse gait direction during forward travel")
	check(float(avatar._locomotion_phase)>0.0 and float(avatar._locomotion_phase)<0.2,"Motion reset starts a fresh forward stride instead of inheriting reverse cycles")
	metrics.backward_diagonals=reports
	metrics.forward_reset={"playback_sign":avatar._backward,"normalized_phase":avatar._locomotion_phase}

func _moving_action_layers() -> void:
	var control: Node3D=Avatar.new()
	root.add_child(control)
	control.set_process(false)
	control.set_ground_sampler(C.ground_y)
	avatar.position=C.ground_position(0.0,28.0)
	control.position=avatar.position
	avatar.apply_state({"action":"strike","action_time":0.0,"action_duration":1.1,"speed":1.425,"grounded":true,"dead":false})
	control.apply_state({"action":"run","action_time":0.0,"speed":1.425,"grounded":true,"dead":false})
	var velocity := Vector3(0,0,1.425)
	for frame: int in range(30):
		_tick(velocity,frame==0)
		control.position=avatar.position
		control.set_presentation_motion(_motion(velocity,frame==0))
		control._process(DT)
	var leg_difference := 0.0
	for name: String in ["pelvis","thigh_l","calf_l","foot_l","thigh_r","calf_r","foot_r"]:
		var index: int=avatar._skeleton.find_bone(name)
		var a: Quaternion=avatar._skeleton.get_bone_pose_rotation(index)
		var b: Quaternion=control._skeleton.get_bone_pose_rotation(index)
		leg_difference=maxf(leg_difference,a.angle_to(b))
	var arm_index: int=avatar._skeleton.find_bone("upperarm_r")
	var attack_arm: Quaternion=avatar._skeleton.get_bone_pose_rotation(arm_index)
	var gait_arm: Quaternion=control._skeleton.get_bone_pose_rotation(arm_index)
	check(leg_difference<0.002,"A moving attack preserves the same lower-body gait and planted legs as travel")
	check(attack_arm.angle_to(gait_arm)>0.1,"A moving attack still presents its authored upper-body strike")
	metrics.moving_attack={"maximum_lower_body_difference_radians":leg_difference,"upperarm_difference_radians":attack_arm.angle_to(gait_arm)}
	control.free()

func _full_body_action_exits() -> void:
	var reports: Dictionary = {}
	for action: String in ["death","roll"]:
		avatar.position=C.ground_position(0.0,28.0)
		avatar.apply_state({"action":"idle","action_time":0.0,"grounded":true,"dead":false})
		avatar.apply_state({"action":"strike","action_time":0.0,"action_duration":1.1,"speed":1.425,"grounded":true,"dead":false})
		for frame: int in range(30):_tick(Vector3(0,0,1.425),frame==0)
		var previous: Array[Transform3D]=avatar._capture()
		var duration := 2.4167 if action=="death" else 0.85
		avatar.apply_state({"action":action,"action_time":0.0,"action_duration":duration,"speed":1.425,"grounded":true,"dead":action=="death"})
		# Displayed translation can still be nonzero on the first confirmed death
		# or roll frame. That must not mask out the full body's new motion.
		_tick(Vector3(0,0,1.425))
		var displayed: Array[Transform3D]=avatar._capture()
		var clip := "death" if action=="death" else "dodge"
		var sample_time: float=DT if action=="death" else DT/duration*avatar.animator.get_animation(clip).length
		var authored: Array[Transform3D]=avatar._sample(clip,sample_time)
		var transition_seconds := 0.16 if action=="death" else 0.07
		var weight := smoothstep(0.0,transition_seconds,DT)
		var rotation_error := 0.0
		var position_error := 0.0
		for bone: int in range(displayed.size()):
			var expected := previous[bone].interpolate_with(authored[bone],weight)
			rotation_error=maxf(rotation_error,displayed[bone].basis.get_rotation_quaternion().angle_to(expected.basis.get_rotation_quaternion()))
			position_error=maxf(position_error,displayed[bone].origin.distance_to(expected.origin))
		check(rotation_error<0.002 and position_error<0.0001,"Moving attack to "+action+" blends the complete authored pose without restoring gait legs")
		check(str(avatar._state)==action and not avatar.sword.visible,"Moving attack to "+action+" uses its correct full-body state and stows the sword")
		reports[action]={"maximum_full_pose_rotation_error_radians":rotation_error,"maximum_full_pose_position_error_metres":position_error,"transition_seconds":transition_seconds}
	metrics.moving_action_full_body_exits=reports

func _roll_direction() -> void:
	var realm := Realm.new()
	realm.state.enemies.clear()
	realm.add_player(1,"Roll Review")
	var world := World.new()
	world.controls_enabled=false
	root.add_child(world)
	world.set_process(false)
	world.set_snapshot(realm.snapshot(),1)
	var visual: Dictionary=world.actors["p_1"]
	visual.avatar.set_process(false)
	world._process(DT)
	visual.avatar._process(DT)
	# Already backpedaling when roll is requested: translation starts before the
	# smoothed actor container can finish its 180 degree facing correction.
	for frame: int in range(60):
		realm.input_player(1,{"move":[0.0,1.0],"yaw":PI,"jump":false})
		realm.step(DT)
		if frame%4==3:world.set_snapshot(realm.snapshot(),1)
		world._process(DT)
		visual.avatar._process(DT)
	var accepted: Dictionary=realm.act(1,{"type":"ability","id":"roll"})
	world.set_snapshot(realm.snapshot(),1)
	var smallest_alignment := 1.0
	var container_opposed := false
	var sword_hidden := true
	for frame: int in range(18):
		realm.step(DT)
		if frame%4==3:world.set_snapshot(realm.snapshot(),1)
		world._process(DT)
		visual.avatar._process(DT)
		var velocity: Vector3=visual.motion.velocity
		velocity.y=0.0
		var container_forward := Vector3(sin(visual.node.rotation.y),0,cos(visual.node.rotation.y))
		var model_forward: Vector3=(visual.avatar.body.global_transform.basis*visual.avatar._body_basis.inverse()*Vector3.BACK).normalized()
		if velocity.length()>0.5:
			container_opposed=container_opposed or container_forward.dot(velocity.normalized())<0.0
			smallest_alignment=minf(smallest_alignment,model_forward.dot(velocity.normalized()))
		sword_hidden=sword_hidden and not visual.avatar.sword.visible
	check(bool(accepted.ok) and container_opposed,"Real backward-input roll exercises facing reconciliation while already translating")
	check(smallest_alignment>0.999,"Authored forward roll faces actual displayed travel throughout reconciliation")
	check(sword_hidden,"Directional roll keeps the sword stowed")
	for frame: int in range(90):
		realm.input_player(1,{"move":[0.0,0.0],"yaw":0.0,"jump":false})
		realm.step(DT)
		if frame%4==3:world.set_snapshot(realm.snapshot(),1)
		world._process(DT)
		visual.avatar._process(DT)
	check(absf(float(visual.avatar._body_yaw))<0.001 and visual.avatar.sword.visible,"Roll body correction returns to neutral and restores the sword after recovery")
	metrics.roll={"minimum_model_facing_travel_dot":smallest_alignment,"container_needed_reconciliation":container_opposed,"body_yaw_after_recovery":visual.avatar._body_yaw}
	world.queue_free()
	await process_frame

func _measure_cpu() -> void:
	var timings: Dictionary = {}
	for label: String in ["idle","run","strike","ward"]:
		var velocity := Vector3(0,0,4.75) if label=="run" else Vector3.ZERO
		avatar.position=C.ground_position(0.0,28.0)
		avatar.apply_state({"action":label,"action_time":0.25,"action_duration":1.4,"speed":velocity.length(),"grounded":true,"dead":false})
		_tick(velocity,true)
		for frame: int in range(40):_tick(velocity)
		var started := Time.get_ticks_usec()
		for frame: int in range(600):
			avatar._action_clock=0.25
			_tick(velocity)
		timings[label]=float(Time.get_ticks_usec()-started)/600.0/1000.0
	metrics.cpu_milliseconds_per_avatar_frame=timings
	metrics.sole_support_vertices=[avatar._feet._sole_points[0].size(),avatar._feet._sole_points[1].size()]
	metrics.cpu_scope="Headless native CPU; final sole support and shared terrain enabled; includes pose evaluation and motion/terrain update, excludes GPU rendering. Timings are observations, not hardware-independent assertions."
