extends RefCounted
## Presentation-only, two-bone leg correction. Contact anchors are in world space;
## animation still supplies the knee bend, foot roll, swing and flight phases.
var skeleton: Skeleton3D
var ground_sampler: Callable
var plane_height := 0.0
var _legs: Array[Dictionary] = []
static var _support_cache: Dictionary = {}
var _sole_points: Array = []
var _binds: Array = []

func setup(value: Skeleton3D) -> void:
	skeleton=value
	for side: String in ["l","r"]:
		var ankle := skeleton.find_bone("foot_"+side)
		_legs.append({"hip":skeleton.find_bone("thigh_"+side),"knee":skeleton.find_bone("calf_"+side),"ankle":ankle,"ball":skeleton.find_bone("ball_"+side),"neutral_ankle":skeleton.get_bone_global_pose(ankle).origin,"locked":false,"has_anchor":false,"anchor":Vector3.ZERO,"ankle_offset":Vector3.ZERO,"toe_direction":Vector3.FORWARD,"weight":0.0,"correction":Vector3.ZERO,"age":0.0})
	_prepare_sole_support()

func _prepare_sole_support() -> void:
	# Select support vertices on the actual shipped boots once, then skin only
	# this small envelope each frame. An ankle/ball-height proxy cannot preserve
	# both heel strike and toe roll, which have different sole offsets.
	if _support_cache.is_empty():
		var mesh := skeleton.get_node("Ileana_LeatherBoots") as MeshInstance3D
		var binds: Array=[]
		for i: int in range(mesh.skin.get_bind_count()):
			var bone := skeleton.find_bone(mesh.skin.get_bind_name(i))
			if bone<0:bone=mesh.skin.get_bind_bone(i)
			binds.append({"bone":bone,"inverse":mesh.skin.get_bind_pose(i)})
		var vertices: Array=[[],[]]
		for surface: int in range(mesh.mesh.get_surface_count()):
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var influences := bones.size()/positions.size()
			for vertex: int in range(positions.size()):
				var point := Vector3.ZERO
				var ids: Array[int]=[]
				var values: Array[float]=[]
				var side := 0
				var largest := 0.0
				for influence: int in range(influences):
					var index := vertex*influences+influence
					var bind: Dictionary=binds[bones[index]]
					point+=(skeleton.global_transform*skeleton.get_bone_global_rest(int(bind.bone))*Transform3D(bind.inverse)*positions[vertex])*weights[index]
					ids.append(bones[index])
					values.append(weights[index])
					if weights[index]>largest:
						largest=weights[index]
						side=1 if skeleton.get_bone_name(int(bind.bone)).ends_with("_r") else 0
				vertices[side].append({"vertex":positions[vertex],"binds":ids,"weights":values,"reference":point})
		var points: Array=[[],[]]
		for side: int in range(2):
			var selected: Dictionary={}
			for x: float in [-2.0,-1.0,0.0,1.0,2.0]:
				for z: float in [-2.0,-1.0,-0.5,0.0,0.5,1.0,2.0]:
					var normal := Vector3(x,1,z).normalized()
					var minimum := INF
					var chosen := 0
					for index: int in range(vertices[side].size()):
						var dot := Vector3(vertices[side][index].reference).dot(normal)
						if dot<minimum:
							minimum=dot
							chosen=index
					selected[chosen]=true
			for index: int in selected:points[side].append(vertices[side][index])
		_support_cache={"points":points,"binds":binds}
	_sole_points=_support_cache.points
	_binds=_support_cache.binds

func _sole_clearance(side: int) -> float:
	var transforms: Dictionary={}
	var clearance := INF
	for point: Dictionary in _sole_points[side]:
		var position := Vector3.ZERO
		for influence: int in range(point.binds.size()):
			var index := int(point.binds[influence])
			var weight := float(point.weights[influence])
			if weight<=0.0:continue
			if not transforms.has(index):
				var bind: Dictionary=_binds[index]
				transforms[index]=skeleton.global_transform*skeleton.get_bone_global_pose(int(bind.bone))*Transform3D(bind.inverse)
			position+=Transform3D(transforms[index])*Vector3(point.vertex)*weight
		clearance=minf(clearance,position.y-_ground(position))
	return clearance

func reset() -> void:
	for leg: Dictionary in _legs:
		leg.locked=false
		leg.has_anchor=false
		leg.weight=0.0
		leg.correction=Vector3.ZERO
		leg.age=0.0

func _ground(point: Vector3) -> float:
	return float(ground_sampler.call(point.x,point.z)) if ground_sampler.is_valid() else plane_height

func apply(delta: float, contacts: Vector2, enabled: bool, turn_phase: float=0.0, turning: float=0.0) -> void:
	if skeleton==null:return
	if not enabled:
		reset()
		return
	skeleton.force_update_all_bone_transforms()
	for index: int in range(2):
		var leg: Dictionary=_legs[index]
		if turning>0.01:
			# Alternating planted pivots and short lifted steps. A forward walk
			# played on the spot would slide both soles instead of turning them.
			var phase := fposmod(turn_phase+index*0.5,1.0)
			var swing := clampf((phase-0.44)/0.56,0,1)
			# Lift before releasing horizontal contact; reposition only once the
			# boot is clear, then lower into its next plant. Holding the prior
			# ankle/yaw at toe-off avoids snapping back to a rotating idle pose.
			var lift := sin(PI*swing)*0.065
			var reposition := smoothstep(0.18,0.85,swing)
			var neutral: Vector3=skeleton.global_transform*Vector3(leg.neutral_ankle)
			var goal := neutral
			if bool(leg.has_anchor) and (phase>=0.44 or bool(leg.locked)):
				goal=(Vector3(leg.anchor)+Vector3(leg.ankle_offset)).lerp(neutral,reposition)
			goal.y+=lift
			var target := skeleton.global_transform.affine_inverse()*goal
			var current := skeleton.get_bone_global_pose(int(leg.ankle)).origin
			_solve(leg,current.lerp(target,turning))
			if bool(leg.has_anchor) and phase>=0.44:
				var foot := skeleton.get_bone_global_pose(int(leg.ankle))
				var toe: Vector3=skeleton.global_transform.basis*(skeleton.get_bone_global_pose(int(leg.ball)).origin-foot.origin)
				toe.y=0.0
				var confidence := smoothstep(0.045,0.09,toe.length())
				var yaw := 0.0
				if Vector3(leg.toe_direction).length_squared()>0.1:
					yaw=clampf(toe.normalized().signed_angle_to(Vector3(leg.toe_direction),Vector3.UP),-0.9,0.9)*(1.0-reposition)*turning*confidence
				foot.basis=Basis(Quaternion((skeleton.global_transform.basis.inverse()*Vector3.UP).normalized(),yaw))*foot.basis
				skeleton.set_bone_global_pose(int(leg.ankle),foot)
				skeleton.force_update_all_bone_transforms()
		var ball: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(int(leg.ball)).origin
		var ankle: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(int(leg.ankle)).origin
		var floor_y := _ground(ball)
		# A contact is never forced onto a raised swing foot or authored flight.
		var weight := clampf(contacts[index],0.0,1.0)*(1.0-smoothstep(0.065,0.115,ball.y-floor_y))
		if weight>0.04 and not bool(leg.locked):
			leg.anchor=Vector3(ball.x,floor_y+0.025,ball.z)
			leg.ankle_offset=ankle-ball
			leg.has_anchor=true
			var heading := Vector3(ball.x-ankle.x,0,ball.z-ankle.z)
			leg.toe_direction=heading.normalized() if heading.length()>0.06 else Vector3.ZERO
			leg.locked=true
			leg.age=0.0
		elif weight<0.015:
			leg.locked=false
			leg.age=0.0
		leg.weight=weight
		leg.age=float(leg.age)+delta if bool(leg.locked) else 0.0
		var correction := Vector3.ZERO
		if bool(leg.locked):
			# A planted sole holds its world yaw while retaining authored ankle
			# pitch/toe roll. This prevents skating around a stationary pivot.
			var toe := Vector3(ball.x-ankle.x,0,ball.z-ankle.z)
			if Vector3(leg.toe_direction).length_squared()<0.1 and toe.length()>0.085 and weight>0.8:leg.toe_direction=toe.normalized()
			var confidence := smoothstep(0.045,0.09,toe.length())
			var yaw := 0.0
			if Vector3(leg.toe_direction).length_squared()>0.1:
				yaw=clampf(toe.normalized().signed_angle_to(Vector3(leg.toe_direction),Vector3.UP),-0.9,0.9)*weight*confidence
			var foot := skeleton.get_bone_global_pose(int(leg.ankle))
			foot.basis=Basis(Quaternion((skeleton.global_transform.basis.inverse()*Vector3.UP).normalized(),yaw))*foot.basis
			skeleton.set_bone_global_pose(int(leg.ankle),foot)
			skeleton.force_update_all_bone_transforms()
			ball=skeleton.global_transform*skeleton.get_bone_global_pose(int(leg.ball)).origin
			var target: Vector3=leg.anchor
			target.y=_ground(target)+0.025
			correction=(target-ball).limit_length(0.16)*weight
		# Guard toe penetration without flattening the source run's flight arc.
		correction.y=maxf(correction.y,minf(0.06,maxf(0.0,floor_y+0.023-ball.y)))
		leg.correction=correction
		if correction.length_squared()>0.0000001:
			_solve(leg,skeleton.global_transform.affine_inverse()*(ankle+correction))
		# Recheck the deformed heel/outsole after planting. Correct only a real
		# penetration; lifted feet and the run's airborne phase stay untouched.
		var clearance := _sole_clearance(index)
		if clearance<0.002:
			var lift := minf(0.08,0.002-clearance)
			var final_ankle := skeleton.get_bone_global_pose(int(leg.ankle)).origin
			_solve(leg,final_ankle+skeleton.global_transform.basis.inverse()*Vector3(0,lift,0))
			leg.correction.y+=lift

func _solve(leg: Dictionary, target: Vector3) -> void:
	var hip_index := int(leg.hip)
	var knee_index := int(leg.knee)
	var ankle_index := int(leg.ankle)
	var hip := skeleton.get_bone_global_pose(hip_index)
	var knee := skeleton.get_bone_global_pose(knee_index)
	var ankle := skeleton.get_bone_global_pose(ankle_index)
	var upper_length := hip.origin.distance_to(knee.origin)
	var lower_length := knee.origin.distance_to(ankle.origin)
	var line := target-hip.origin
	var distance := clampf(line.length(),absf(upper_length-lower_length)+0.002,upper_length+lower_length-0.002)
	if line.length_squared()<0.000001:return
	var direction := line.normalized()
	var bend := knee.origin-hip.origin
	bend-=direction*bend.dot(direction)
	if bend.length_squared()<0.000001:
		bend=skeleton.global_transform.basis.inverse()*Vector3.FORWARD
		bend-=direction*bend.dot(direction)
	bend=bend.normalized()
	var cosine := clampf((upper_length*upper_length+distance*distance-lower_length*lower_length)/(2.0*upper_length*distance),-1.0,1.0)
	var desired_knee := hip.origin+direction*(upper_length*cosine)+bend*(upper_length*sqrt(maxf(0.0,1.0-cosine*cosine)))
	var upper_rotation := Quaternion((knee.origin-hip.origin).normalized(),(desired_knee-hip.origin).normalized())
	hip.basis=Basis(upper_rotation)*hip.basis
	skeleton.set_bone_global_pose(hip_index,hip)
	skeleton.force_update_all_bone_transforms()
	knee=skeleton.get_bone_global_pose(knee_index)
	var moved_ankle := skeleton.get_bone_global_pose(ankle_index)
	var reachable_target := hip.origin+direction*distance
	var lower_rotation := Quaternion((moved_ankle.origin-knee.origin).normalized(),(reachable_target-knee.origin).normalized())
	knee.basis=Basis(lower_rotation)*knee.basis
	skeleton.set_bone_global_pose(knee_index,knee)
	skeleton.force_update_all_bone_transforms()
	# Retain the authored ankle orientation and toe roll after moving the leg.
	var final_ankle := skeleton.get_bone_global_pose(ankle_index)
	final_ankle.basis=ankle.basis
	skeleton.set_bone_global_pose(ankle_index,final_ankle)
	skeleton.force_update_all_bone_transforms()

func diagnostics() -> Dictionary:
	if _legs.size()!=2:return {}
	return {"foot_l_locked":bool(_legs[0].locked),"foot_r_locked":bool(_legs[1].locked),"foot_weights":[float(_legs[0].weight),float(_legs[1].weight)],"foot_corrections":[_array(_legs[0].correction),_array(_legs[1].correction)],"foot_contact_age":[float(_legs[0].age),float(_legs[1].age)]}

func _array(value: Vector3) -> Array:
	return [value.x,value.y,value.z]
