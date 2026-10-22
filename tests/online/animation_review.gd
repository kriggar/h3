extends SceneTree
## Native motion inspection, not a gameplay or network simulation.
## The same scripted presentation path supports before/after visual comparison.
const C = preload("res://game/online/catalog.gd")
var output := "/tmp/draconia-animation-review"
var avatar_script := "res://game/online/avatar.gd"
var label_text := "Current animation controller"
var capture_frames := true
var avatar: Node3D
var stage: Node3D
var camera: Camera3D
var caption: Label
var detail: Label
var samples: Array = []
var current_position := Vector3.ZERO
var previous_velocity := Vector3.ZERO
var previous_yaw := 0.0
var previous_segment := ""
var previous_pose: Array[Quaternion] = []
var snapshot_clock := 0.0
var observations: Dictionary = {}
const FPS := 24
const DURATION := 18.5

func _initialize() -> void:call_deferred("_run")

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="):output=arg.trim_prefix("--output-dir=")
		elif arg.begins_with("--avatar-script="):avatar_script=arg.trim_prefix("--avatar-script=")
		elif arg.begins_with("--label="):label_text=arg.trim_prefix("--label=")
		elif arg=="--metrics-only":capture_frames=false
	if DisplayServer.get_name()=="headless":capture_frames=false
	DirAccess.make_dir_recursive_absolute(output+"/frames")
	root.size=Vector2i(960,720)
	_build_stage()
	for unused: int in range(5):await process_frame
	avatar.set_process(false)
	var skeleton: Skeleton3D=avatar.get_node("IleanaRig/Skeleton3D") if avatar.has_node("IleanaRig/Skeleton3D") else avatar.body.get_node("IleanaRig/Skeleton3D")
	var left_foot:=skeleton.find_bone("foot_l")
	var right_foot:=skeleton.find_bone("foot_r")
	var left_ball:=skeleton.find_bone("ball_l")
	var right_ball:=skeleton.find_bone("ball_r")
	var previous_feet: Array[Vector3]=[]
	var previous_balls: Array[Vector3]=[]
	var snapshots: Array=[]
	for frame: int in range(int(DURATION*FPS)):
		var time:=float(frame)/FPS
		var dt:=1.0/FPS
		var pose:=_scenario(time)
		var velocity: Vector3=pose.move
		current_position+=velocity*dt
		current_position.y=float(pose.height)
		avatar.position=current_position
		avatar.rotation.y=float(pose.yaw)
		var motion := {"velocity":velocity,"local_velocity":velocity.rotated(Vector3.UP,-avatar.rotation.y),"acceleration":(velocity-previous_velocity)/dt,"turn_rate":wrapf(avatar.rotation.y-previous_yaw,-PI,PI)/dt,"grounded":bool(pose.grounded),"height":float(pose.height),"vertical_speed":float(pose.vertical_speed),"teleported":false,"source_age":0.0}
		if avatar.has_method("set_presentation_motion"):avatar.set_presentation_motion(motion)
		var state: Dictionary={"id":1,"name":"Mara","pos":C.array(current_position),"yaw":float(pose.yaw),"speed":velocity.length(),"action":pose.action,"action_time":pose.elapsed,"action_duration":pose.duration,"dead":pose.action=="death","grounded":pose.grounded,"combat":5.0 if time>=8.0 and time<15.0 else 0.0}
		snapshot_clock+=dt
		if pose.segment!=previous_segment or snapshot_clock>=1.0/15.0:
			avatar.apply_state(state,dt)
			snapshot_clock=0.0
		if bool(pose.hit) and not observations.has(str(pose.segment)+"_hit_sent"):
			avatar.hit()
			observations[str(pose.segment)+"_hit_sent"]=true
		if pose.segment=="Interact" and not observations.has("interact_sent"):
			if avatar.has_method("interact"):avatar.interact()
			observations.interact_sent=true
		avatar._process(dt)
		var before_render_pose: Array[Quaternion]=[]
		for bone: int in range(skeleton.get_bone_count()):before_render_pose.append(skeleton.get_bone_pose(bone).basis.get_rotation_quaternion())
		camera.position=current_position+Vector3(2.45,1.85,3.7)
		camera.look_at(current_position+Vector3(0,0.83,0))
		caption.text=label_text+"  |  "+str(pose.segment)
		detail.text="Scripted presentation review · %.2f s · %.2f m/s · %s"%[time,velocity.length(),"grounded" if pose.grounded else "airborne"]
		if capture_frames:await RenderingServer.frame_post_draw
		else:await process_frame
		var feet: Array[Vector3]=[]
		for index: int in [left_foot,right_foot]:feet.append(skeleton.global_transform*skeleton.get_bone_global_pose(index).origin)
		var balls: Array[Vector3]=[]
		for index: int in [left_ball,right_ball]:balls.append(skeleton.global_transform*skeleton.get_bone_global_pose(index).origin)
		var largest_bone_step:=0.0
		var largest_bone_step_name:=""
		var largest_render_overwrite:=0.0
		var rotations: Array[Quaternion]=[]
		var joints: Dictionary={}
		var finite:=true
		for bone: int in range(skeleton.get_bone_count()):
			var transform:=skeleton.get_bone_pose(bone)
			var rotation:=transform.basis.get_rotation_quaternion()
			rotations.append(rotation)
			finite=finite and transform.origin.is_finite() and rotation.is_finite()
			if previous_pose.size()==skeleton.get_bone_count():
				var step:=previous_pose[bone].angle_to(rotation)
				if step>largest_bone_step:
					largest_bone_step=step
					largest_bone_step_name=skeleton.get_bone_name(bone)
			largest_render_overwrite=maxf(largest_render_overwrite,before_render_pose[bone].angle_to(rotation))
			if skeleton.get_bone_name(bone) in ["pelvis","thigh_l","calf_l","foot_l","thigh_r","calf_r","foot_r","spine_01","spine_02","spine_03","upperarm_l","upperarm_r","head"]:
				joints[skeleton.get_bone_name(bone)]=[rotation.x,rotation.y,rotation.z,rotation.w]
		var foot_velocities: Array=[]
		if previous_feet.size()==2:
			for foot: int in range(2):foot_velocities.append(Vector2(feet[foot].x-previous_feet[foot].x,feet[foot].z-previous_feet[foot].z).length()/dt)
		var ball_velocities: Array=[]
		if previous_balls.size()==2:
			for foot: int in range(2):ball_velocities.append(Vector2(balls[foot].x-previous_balls[foot].x,balls[foot].z-previous_balls[foot].z).length()/dt)
		var diagnostics: Dictionary=avatar.animation_diagnostics() if avatar.has_method("animation_diagnostics") else {}
		var sample: Dictionary={"time":time,"segment":pose.segment,"action":pose.action,"action_elapsed":pose.elapsed,"grounded":pose.grounded,"speed":velocity.length(),"position":C.array(current_position),"clip":avatar._clip,"clip_time":diagnostics.get("clip_time",avatar.animator.current_animation_position),"sword_visible":avatar.sword.visible,"feet_y":[feet[0].y,feet[1].y],"feet_world":[C.array(feet[0]),C.array(feet[1])],"balls_world":[C.array(balls[0]),C.array(balls[1])],"pelvis_world":C.array(skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("pelvis")).origin),"head_world":C.array(skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("head")).origin),"foot_horizontal_speed":foot_velocities,"ball_horizontal_speed":ball_velocities,"largest_bone_step_radians":largest_bone_step,"largest_bone_step_name":largest_bone_step_name,"render_pose_overwrite_radians":largest_render_overwrite,"joints":joints,"finite":finite,"diagnostics":diagnostics}
		samples.append(sample)
		if capture_frames:
			var pixels:=root.get_texture().get_image()
			pixels.save_jpg(output+"/frames/%05d.jpg"%frame,0.88)
			var capture_at := {"Idle":0.5,"Walk":1.85,"Run":3.4,"Turn in place":5.5,"Strafe":6.5,"Jump and land":7.35,"Swordfall":8.5,"Mooncleave":9.6,"Iron Vow":10.95,"Roll":12.1,"Moving hit":12.85,"Stationary hit":13.5,"Death":16.2}
			if capture_at.has(pose.segment) and absf(time-float(capture_at[pose.segment]))<0.5/FPS:
				var filename:=str(pose.segment).to_lower().replace(" ","-")+".png"
				pixels.save_png(output+"/"+filename)
				snapshots.append(filename)
		previous_feet=feet
		previous_balls=balls
		previous_pose=rotations
		previous_velocity=velocity
		previous_yaw=avatar.rotation.y
		previous_segment=pose.segment
	var report := {"label":label_text,"scope":"Native review stage with actual Mara and scripted presentation states; not gameplay footage or a network test.","avatar_script":avatar_script,"avatar_source_sha256":FileAccess.get_sha256(avatar_script),"mara_sha256":FileAccess.get_sha256(C.HERO_MODEL),"bone_count":skeleton.get_bone_count(),"fps":FPS,"duration":DURATION,"frames":samples.size(),"captured":capture_frames,"snapshots":snapshots,"samples":samples}
	var file:=FileAccess.open(output+"/animation-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("ANIMATION_REVIEW_COMPLETE "+str(samples.size())+" frames")
	stage.queue_free()
	for unused: int in range(4):await process_frame
	quit()

func _scenario(time: float) -> Dictionary:
	var value: Dictionary={"segment":"Idle","action":"idle","elapsed":time,"duration":1.0,"move":Vector3.ZERO,"yaw":0.0,"height":0.0,"vertical_speed":0.0,"grounded":true,"hit":false}
	if time>=1.0 and time<2.5:
		value.merge({"segment":"Walk","action":"walk","elapsed":time-1.0,"move":Vector3(0,0,0.89)},true)
	elif time>=2.5 and time<5.0:
		value.merge({"segment":"Run","action":"run","elapsed":time-2.5,"move":Vector3(0,0,4.77)},true)
	elif time>=5.0 and time<6.0:
		value.merge({"segment":"Turn in place","elapsed":time-5.0,"yaw":(time-5.0)*PI*0.75},true)
	elif time>=6.0 and time<7.0:
		# Return to the forward-facing strafe at the world's bounded steering
		# rate; an instantaneous 135-degree fixture reset would create an
		# impossible production input and falsely flag a planted-foot pop.
		value.merge({"segment":"Strafe","action":"run","elapsed":time-6.0,"move":Vector3(2.6,0,0),"yaw":maxf(0.0,PI*0.75-(time-6.0)*10.0)},true)
	elif time>=7.0 and time<8.0:
		var t:=time-7.0
		var height:=maxf(0.0,5.1*t-6.75*t*t)
		value.merge({"segment":"Jump and land","action":"run","elapsed":t,"move":Vector3(0,0,2.6),"height":height,"vertical_speed":5.1-13.5*t if height>0.0 else 0.0,"grounded":t>0.75},true)
	elif time>=8.0 and time<9.1:value.merge({"segment":"Swordfall","action":"strike","elapsed":time-8.0,"duration":1.1},true)
	elif time>=9.1 and time<10.3:value.merge({"segment":"Mooncleave","action":"cleave","elapsed":time-9.1,"duration":1.2},true)
	elif time>=10.3 and time<11.7:value.merge({"segment":"Iron Vow","action":"ward","elapsed":time-10.3,"duration":1.4},true)
	elif time>=11.7 and time<12.55:value.merge({"segment":"Roll","action":"roll","elapsed":time-11.7,"duration":0.85,"move":Vector3(0,0,6.5 if time<12.35 else 0.0)},true)
	elif time>=12.55 and time<13.3:value.merge({"segment":"Moving hit","action":"run","elapsed":time-12.55,"move":Vector3(0,0,3.0),"hit":time>12.65},true)
	elif time>=13.3 and time<14.1:value.merge({"segment":"Stationary hit","elapsed":time-13.3,"hit":time>13.35},true)
	elif time>=14.1 and time<15.0:value.merge({"segment":"Interact","action":"idle","elapsed":time-14.1,"duration":0.9},true)
	elif time>=15.0 and time<17.5:value.merge({"segment":"Death","action":"death","elapsed":time-15.0,"duration":2.4167},true)
	elif time>=17.5:value.merge({"segment":"Respawn","elapsed":time-17.5},true)
	return value

func _build_stage() -> void:
	stage=Node3D.new()
	root.add_child(stage)
	var world_env:=WorldEnvironment.new()
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("242a31")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("bac7d1")
	environment.ambient_light_energy=0.65
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world_env.environment=environment
	stage.add_child(world_env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-42,-28,0)
	sun.light_energy=1.8
	sun.shadow_enabled=true
	stage.add_child(sun)
	var floor:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(120,120)
	floor.mesh=plane
	var material:=ShaderMaterial.new()
	var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode specular_disabled; varying vec3 p; void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){vec2 g=abs(fract(p.xz)-0.5); float line=smoothstep(0.475,0.49,max(g.x,g.y)); ALBEDO=mix(vec3(0.19,0.22,0.24),vec3(0.31,0.34,0.36),line); ROUGHNESS=1.0;}"
	material.shader=shader
	floor.material_override=material
	stage.add_child(floor)
	avatar=load(avatar_script).new()
	stage.add_child(avatar)
	camera=Camera3D.new()
	camera.fov=41.0
	camera.near=0.05
	camera.current=true
	stage.add_child(camera)
	var layer:=CanvasLayer.new()
	stage.add_child(layer)
	var panel:=ColorRect.new()
	panel.color=Color(0.02,0.025,0.035,0.85)
	panel.position=Vector2(0,0)
	panel.size=Vector2(960,86)
	layer.add_child(panel)
	caption=Label.new()
	caption.position=Vector2(24,15)
	caption.add_theme_font_size_override("font_size",23)
	layer.add_child(caption)
	detail=Label.new()
	detail.position=Vector2(25,49)
	detail.add_theme_font_size_override("font_size",15)
	detail.add_theme_color_override("font_color",Color("b5c0c9"))
	layer.add_child(detail)
