extends SceneTree
const World = preload("res://game/online/world.gd")
const Realm = preload("res://game/online/realm.gd")
const C = preload("res://game/online/catalog.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition:
		failures.append(description)
		push_error(description)

func _run() -> void:
	check(FileAccess.get_sha256(C.HERO_MODEL)==C.HERO_SHA256,"Accepted Mara binary must remain byte-identical")
	var realm := Realm.new()
	realm.add_player(1,"Wayfarer")
	var world := World.new()
	world.controls_enabled=false
	root.add_child(world)
	world.set_snapshot(realm.snapshot(),1)
	await process_frame
	check(world.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"Main camera is perspective, never orthographic")
	check(is_equal_approx(world.camera.fov,65.0),"Third-person field of view")
	check(world.actors.size()==8,"Player and seven shared enemies appear")
	var table_approach := C.move_slide(C.ground_position(9.0,25.8),Vector3(0,0,4.0))
	check(table_approach.z<26.8 and table_approach.z>26.4,"Visible market table blocks authoritative movement before its front edge")
	var collision_group: Node=world.scenery.get_node("SharedPropCollision")
	var first_tree: Dictionary=C.woodland_layout().trees[0]
	check(collision_group.get_child_count()==C.solid_props().size() and collision_group.has_node(str(first_tree.id)) and C.blocked(C.vector(first_tree.pos)),"Every shared solid prop has a camera collider and visible trunks block movement")
	var clear_spawns := true
	for points: Array in [C.NPCS,C.GATHERS,C.ENEMIES]:
		for point: Dictionary in points:
			if C.blocked(C.vector(point.pos),0.5):clear_spawns=false
	check(clear_spawns and not C.blocked(C.SPAWN),"Shared props leave player, NPC, enemy and gather spawns unobstructed")
	var avatar: Node3D=world.actors["p_1"].avatar
	check(avatar._skeleton.get_bone_count()==53,"Original 53-bone skeleton retained")
	for clip: String in ["idle","walk","run","attack","hit","death","combat_idle","cast_start","cast_hold","cast_release","cast_end","dodge"]:
		check(avatar.animator.has_animation(clip),"Preserve native motion "+clip)
	var p: Dictionary=realm.state.players["1"]
	p.name="Another Host"
	world.set_snapshot(realm.snapshot(),1)
	check(world.actors["p_1"].label.text=="Another Host","Title preview actor updates to the real host name")
	var pose: Dictionary=p.duplicate(true)
	pose.action="roll"
	pose.action_duration=0.85
	pose.action_time=0.2
	avatar.apply_state(pose)
	avatar._process(0.016)
	check(avatar._clip=="dodge" and not avatar.sword.visible,"Genuine roll clip stows the sword")
	pose.action="ward"
	pose.action_duration=1.4
	pose.action_time=0.1
	avatar.apply_state(pose)
	avatar._process(0.016)
	check(avatar._clip=="cast_start" and not avatar.sword.visible,"Cast windup uses retained open-handed clip")
	pose.action_time=0.7
	avatar.apply_state(pose)
	avatar._process(0.016)
	check(avatar._clip=="cast_release","Cast release uses its actual retained clip")
	pose.action_time=1.2
	avatar.apply_state(pose)
	avatar._process(0.016)
	check(avatar._clip=="cast_end","Cast recovery lowers the hand")
	pose.action="death"
	pose.dead=true
	pose.action_duration=2.4167
	pose.action_time=0.1
	avatar.apply_state(pose)
	avatar._process(0.016)
	check(avatar._clip=="death" and not avatar.sword.visible,"Death stows the held weapon at state entry")
	pose.action="idle"
	pose.dead=false
	pose.action_time=0.0
	pose.speed=0.0
	avatar.apply_state(pose)
	avatar._process(0.016)
	check(avatar._clip=="idle" and avatar.sword.visible,"Respawn restores the weapon and idle")
	var phase: float=avatar._locomotion_phase
	pose.action="run"
	pose.speed=4.77
	avatar.apply_state(pose)
	avatar._process(0.1)
	var phase_after: float=avatar._locomotion_phase
	check(absf(phase_after-phase-0.1)<0.0001,"Foot phase integrates velocity over elapsed time")
	pose.speed=2.385
	avatar.apply_state(pose)
	avatar._process(0.1)
	check(absf(avatar._locomotion_phase-phase_after-0.05)<0.0001,"Speed change does not jump the locomotion phase")
	for i: int in range(avatar._skeleton.get_bone_count()):
		check(avatar._skeleton.get_bone_pose(i).origin.is_finite(),"Blended bone pose remains finite: "+str(i))
	var bloom: Dictionary=realm.state.gathers.bloom_1
	p.pos=[float(bloom.pos[0])+3.4,float(bloom.pos[1]),float(bloom.pos[2])]
	world.set_snapshot(realm.snapshot(),1)
	check(world.nearest_interaction().is_empty(),"Gather prompt cannot advertise rejected 3.4-metre interaction")
	p.pos[0]=float(bloom.pos[0])+2.8
	world.set_snapshot(realm.snapshot(),1)
	check(world.nearest_interaction().get("kind")=="gather","Gather prompt appears within authoritative reach")
	realm.state.drops={"mine":{"id":"mine","pos":p.pos.duplicate(),"gold":2,"item":"","owner":1},"theirs":{"id":"theirs","pos":p.pos.duplicate(),"gold":2,"item":"","owner":2}}
	world.set_snapshot(realm.snapshot(),1)
	check(world.drops.has("mine") and not world.drops.has("theirs"),"Personal party rewards do not render intersecting unclaimable chests")
	var e: Dictionary=realm.state.enemies.fang_1
	e.action="windup"
	e.action_time=0.4
	e.action_duration=0.8
	e.attack_point=[4.0,0.0,-7.0]
	e.attack_radius=1.45
	world.set_snapshot(realm.snapshot(),1)
	world._snapshot_age=0.0
	world._sync_enemy(world.actors.fang_1,0.0)
	var enemy_visual: Dictionary=world.actors.fang_1
	check(enemy_visual.telegraph.visible,"Windup exposes danger area")
	check(absf(enemy_visual.telegraph.scale.x-1.45)<0.001,"Danger area uses exact server radius")
	check(absf(enemy_visual.telegraph.position.x-4.0)<0.001 and absf(enemy_visual.telegraph.position.z+7.0)<0.001,"Danger area uses locked server target position")
	var clip_length: float=enemy_visual.animator.get_animation("attack").length
	var windup_pose: float=enemy_visual.animator.current_animation_position
	check(absf(windup_pose-clip_length*0.22)<0.01,"Windup reaches half of pre-contact animation, not a full attack")
	e.action="attack"
	e.action_time=0.0
	e.action_duration=0.45
	e.attack_radius=0.0
	world.set_snapshot(realm.snapshot(),1)
	world._snapshot_age=0.0
	world._sync_enemy(world.actors.fang_1,0.0)
	check(absf(enemy_visual.animator.current_animation_position-clip_length*0.44)<0.01,"Recovery starts at contact without replaying windup")
	check(not enemy_visual.telegraph.visible,"Resolved attack removes telegraph")
	world.select_target("fang_1")
	check(world.target_id=="fang_1","Target selects an existing enemy")
	e.dead=true
	world.set_snapshot(realm.snapshot(),1)
	check(world.target_id=="","Dead target clears frame and selection")
	p.yaw=0.83
	world.set_snapshot(realm.snapshot(),1)
	world.set_panel_open(true)
	world._process(0.04)
	check(absf(world._last_yaw-0.83)<0.001,"Panel idle preserves confirmed combat facing")
	check(not world._orbit_left and not world._orbit_right,"Opening a panel releases mouse orbit")
	p.pos=C.array(C.ground_position(-8.5,17.0))
	world.camera_yaw=-PI*0.5
	world.camera_pitch=0.1
	world.set_snapshot(realm.snapshot(),1)
	world._process(1.0)
	for unused: int in range(3):await physics_frame
	world._process(0.016)
	check(world._arm.get_hit_length()<1.0,"Spring arm contracts against the watchhall wall")
	check(not avatar.visible,"Camera pushed into the character hides obstructing local geometry")
	print(JSON.stringify({"suite":"native_world_contract","checks":checks,"failures":failures}))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
