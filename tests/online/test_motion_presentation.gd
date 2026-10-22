extends SceneTree
## Drive the real realm at 60 Hz and the renderer from 15 Hz publications.
## Animation must follow displayed movement, including a stopped packet stream.
const World = preload("res://game/online/world.gd")
const Realm = preload("res://game/online/realm.gd")
const C = preload("res://game/online/catalog.gd")
const DT := 1.0 / 60.0
var world: Node3D
var realm: RefCounted
var checks := 0
var failures: Array[String] = []
var metrics: Dictionary = {}

class InteractionProbe:
	extends Node3D
	var received: Array[String] = []
	func interact(kind: String) -> void:received.append(kind)

func _initialize() -> void:call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition:
		failures.append(description)
		push_error(description)

func _fresh(x: float=0.0, z: float=28.0) -> Dictionary:
	realm=Realm.new()
	realm.state.enemies.clear()
	realm.add_player(1,"Motion Review")
	realm.state.players["1"].pos=C.array(C.ground_position(x,z))
	world.set_snapshot(realm.snapshot(),1)
	world._process(DT)
	return world.actors["p_1"]

func _step(move: Vector3, yaw: float, publish: bool, jump: bool=false) -> void:
	realm.input_player(1,{"move":[move.x,move.z],"yaw":yaw,"jump":jump})
	realm.step(DT)
	if publish:world.set_snapshot(realm.snapshot(),1)
	world._process(DT)

func _run() -> void:
	world=World.new()
	world.controls_enabled=false
	root.add_child(world)
	world.set_process(false)
	var visual := _fresh()
	visual.avatar.set_process(false)
	check(FileAccess.get_sha256(C.HERO_MODEL)==C.HERO_SHA256,"Motion presentation preserves the accepted Mara binary")
	check(bool(visual.motion.teleported) and visual.motion.velocity==Vector3.ZERO,"First placement publishes a zero-motion discontinuity")
	var distances_match := true
	var clearance_ok := true
	var slowest := INF
	var fastest := 0.0
	var total_speed := 0.0
	var samples := 0
	var worst_source_distance := 0.0
	for frame: int in range(180):
		var before: Vector3=visual.node.position
		_step(Vector3.FORWARD,PI,frame%4==3)
		var motion: Dictionary=visual.motion
		var displacement: Vector3=visual.node.position-before
		distances_match=distances_match and (motion.velocity*DT-displacement).length()<0.00001
		clearance_ok=clearance_ok and visual.node.position.y>=C.ground_y(visual.node.position.x,visual.node.position.z)-0.00001
		worst_source_distance=maxf(worst_source_distance,visual.node.position.distance_to(C.vector(visual.data.pos)))
		if frame>=60:
			var speed := Vector2(motion.velocity.x,motion.velocity.z).length()
			slowest=minf(slowest,speed)
			fastest=maxf(fastest,speed)
			total_speed+=speed
			samples+=1
	metrics.steady_speed={"mean":total_speed/samples,"minimum":slowest,"maximum":fastest,"spread":fastest-slowest,"max_distance_from_confirmed":worst_source_distance}
	check(absf(total_speed/samples-Realm.RUN_SPEED)<0.08,"Rendered steady movement matches the authoritative travel speed")
	check(fastest-slowest<0.25,"15 Hz snapshots do not pulse the rendered foot-speed source")
	check(distances_match,"Reported velocity integrates to the actual displayed displacement")
	check(clearance_ok,"Rendered locomotion stays above shared terrain")
	check(worst_source_distance<0.65,"Smoothing remains within a bounded distance of confirmed movement")
	var snapshot_json := JSON.stringify(world.state)
	world._process(DT)
	check(JSON.stringify(world.state)==snapshot_json,"Presentation does not mutate the authoritative snapshot")

	# A quest/chat/target update can republish an unchanged realm tick.
	var age_before := float(visual.motion.source_age)
	var retained_velocity: Vector3=visual.source_velocity
	for unused: int in range(4):
		world.set_snapshot(realm.snapshot(),1)
		world._process(DT)
	check(float(visual.motion.source_age)>age_before+DT*3.5,"Repeated same-tick publications do not reset the movement clock")
	check(visual.source_velocity.is_equal_approx(retained_velocity),"Same-tick publications preserve the last measured source velocity")

	# A delayed network stream may say run indefinitely. Render motion must stop.
	var confirmed := C.vector(visual.data.pos)
	for unused: int in range(120):world._process(DT)
	metrics.stalled_speed=visual.motion.velocity.length()
	metrics.stalled_prediction=visual.node.position.distance_to(confirmed)
	check(visual.motion.velocity.length()<0.001,"Feet receive zero speed after the bounded prediction settles during a packet stall")
	check(Vector2(visual.node.position.x-confirmed.x,visual.node.position.z-confirmed.z).length()<=Realm.RUN_SPEED*World.PRESENTATION_PREDICTION_LIMIT+0.001,"Packet loss cannot extrapolate movement beyond one snapshot interval")
	check(float(visual.data.speed)>4.7 and str(visual.data.action)=="run","Stall test retains a moving raw snapshot while displayed motion stops")

	for frame: int in range(60):_step(Vector3.ZERO,PI,frame%4==3)
	check(visual.motion.velocity.length()<0.005 and visual.node.position.distance_to(C.vector(visual.data.pos))<0.005,"An authoritative stop settles on the confirmed position")

	# RMB keeps the body facing the camera direction while translating sideways or backward.
	visual=_fresh()
	world.camera_yaw=0.0
	var backward: Dictionary=world._movement_intent(0.0,-1.0,true)
	check(backward.move.is_equal_approx(Vector3.BACK) and absf(wrapf(float(backward.yaw)-PI,-PI,PI))<0.00001,"RMB backward intent moves opposite the facing")
	for frame: int in range(60):_step(backward.move,backward.yaw,frame%4==3)
	check(float(visual.motion.local_velocity.z)<-4.65 and absf(float(visual.motion.local_velocity.x))<0.02,"Backward travel reaches the avatar as negative local forward velocity")
	check(absf(wrapf(float(realm.state.players["1"].yaw)-PI,-PI,PI))<0.00001,"RMB backpedaling preserves realm-approved facing")
	visual=_fresh()
	var sideways: Dictionary=world._movement_intent(1.0,0.0,true)
	for frame: int in range(48):_step(sideways.move,sideways.yaw,frame%4==3)
	check(absf(float(visual.motion.local_velocity.x))>4.65 and absf(float(visual.motion.local_velocity.z))<0.02,"RMB strafe has sideways local motion without turning the body toward travel")
	check(absf(wrapf(float(realm.state.players["1"].yaw)-PI,-PI,PI))<0.00001,"RMB strafing does not override authoritative facing with move direction")
	var ordinary: Dictionary=world._movement_intent(0.0,-1.0,false)
	check(absf(float(ordinary.yaw))<0.00001,"Without RMB the character faces the movement direction")
	var diagonal: Dictionary=world._movement_intent(1.0,1.0,true)
	check(is_equal_approx(diagonal.move.length(),1.0),"Diagonal steering is normalized")

	# Real jump integration includes the falling half and the eventual ground contact.
	visual=_fresh()
	var seen_air := false
	var seen_rising := false
	var seen_falling := false
	var maximum_height := 0.0
	clearance_ok=true
	for frame: int in range(120):
		_step(Vector3.FORWARD,PI,frame%4==3,frame==0)
		var motion: Dictionary=visual.motion
		seen_air=seen_air or not bool(motion.grounded)
		seen_rising=seen_rising or float(motion.vertical_speed)>0.2
		seen_falling=seen_falling or float(motion.vertical_speed)<-0.2
		maximum_height=maxf(maximum_height,float(motion.height))
		clearance_ok=clearance_ok and visual.node.position.y>=C.ground_y(visual.node.position.x,visual.node.position.z)-0.00001
	metrics.jump_peak_height=maximum_height
	check(seen_air and maximum_height>0.7,"Realm jump produces airborne telemetry and visible clearance")
	check(seen_rising and seen_falling,"Jump telemetry distinguishes ascending and descending motion")
	check(bool(visual.motion.grounded) and float(visual.motion.height)<0.005,"Landing returns to confirmed ground contact")
	check(clearance_ok,"Jump interpolation never crosses below terrain")

	# Camera presentation turns over time; combat direction in the snapshot stays exact.
	visual=_fresh()
	var start_yaw := float(visual.node.rotation.y)
	realm.input_player(1,{"move":[0.0,0.0],"yaw":0.0,"jump":false})
	realm.step(DT)
	world.set_snapshot(realm.snapshot(),1)
	world._process(DT)
	var yaw_step := absf(wrapf(float(visual.node.rotation.y)-start_yaw,-PI,PI))
	check(yaw_step>0.01 and yaw_step<=10.0*DT+0.00001,"Idle about-face has a bounded visible turn rather than an orientation snap")
	check(absf(absf(float(visual.motion.turn_rate))*DT-yaw_step)<0.00001,"Turn telemetry measures the displayed yaw change")
	check(is_zero_approx(float(visual.data.yaw)) and is_zero_approx(float(realm.state.players["1"].yaw)),"Smoothing never changes the authoritative facing")
	var death_yaw := float(visual.node.rotation.y)
	realm.state.players["1"].dead=true
	realm.state.players["1"].action="death"
	world.set_snapshot(realm.snapshot(),1)
	for unused: int in range(12):world._process(DT)
	check(is_equal_approx(float(visual.node.rotation.y),death_yaw),"A corpse does not rotate toward later facing corrections")
	realm.state.players["1"].dead=false
	realm.state.players["1"].action="idle"
	world.set_snapshot(realm.snapshot(),1)
	world._process(DT)
	check(bool(visual.motion.teleported) and visual.motion.velocity==Vector3.ZERO and is_zero_approx(float(visual.motion.turn_rate)),"Respawn resets presentation even without a distant teleport")

	# A positional correction resets motion rather than injecting impossible stride speed.
	realm.state.players["1"].pos=C.array(C.ground_position(0.0,45.0))
	world.set_snapshot(realm.snapshot(),1)
	world._process(DT)
	check(bool(visual.motion.teleported) and visual.node.position.is_equal_approx(C.vector(visual.data.pos)),"Large correction snaps once to the exact confirmed position")
	check(visual.motion.velocity==Vector3.ZERO and visual.motion.acceleration==Vector3.ZERO and is_zero_approx(float(visual.motion.vertical_speed)),"Teleport does not contaminate stride, acceleration or landing impulses")
	world._process(DT)
	check(not bool(visual.motion.teleported) and visual.motion.velocity==Vector3.ZERO,"Teleport flag lasts one rendered frame without a following speed spike")
	realm.state.time=-1.0
	world.set_snapshot(realm.snapshot(),1)
	world._process(DT)
	check(bool(visual.motion.teleported) and visual.motion.velocity==Vector3.ZERO,"A new realm time origin resets interpolation history")

	# Prediction and correction use the shared solid table footprint.
	visual=_fresh(9.0,26.43)
	realm.state.time=World.PRESENTATION_PREDICTION_LIMIT
	realm.state.players["1"].pos=C.array(C.ground_position(9.0,26.7466667))
	realm.state.players["1"].speed=Realm.RUN_SPEED
	realm.state.players["1"].action="run"
	realm.state.players["1"].yaw=0.0
	world.set_snapshot(realm.snapshot(),1)
	var avoided_solid := true
	for unused: int in range(90):
		world._process(DT)
		avoided_solid=avoided_solid and not C.blocked(visual.node.position,0.42)
	metrics.collision_prediction_stop=visual.node.position.z
	check(avoided_solid and float(visual.node.position.z)<26.78,"Extrapolation and smoothing cannot enter the shared market-table collision")
	check(visual.motion.velocity.length()<0.001,"Blocked extrapolation comes to rest instead of running against the obstacle")
	_test_confirmed_interactions()

	var report := {"suite":"motion_presentation","checks":checks,"failures":failures,"metrics":metrics}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var file := FileAccess.open(argument.trim_prefix("--report="),FileAccess.WRITE)
			if file!=null:file.store_string(JSON.stringify(report,"\t")+"\n")
	print(JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _present_realm_events() -> void:
	for event: Dictionary in realm.events:world.show_event(event)
	realm.events.clear()

func _test_confirmed_interactions() -> void:
	_fresh()
	realm.add_player(2,"Remote Gatherer")
	world.set_snapshot(realm.snapshot(),1)
	var local_avatar: Node3D=world.actors["p_1"].avatar
	var remote_avatar: Node3D=world.actors["p_2"].avatar
	var local_probe := InteractionProbe.new()
	var remote_probe := InteractionProbe.new()
	world.actors["p_1"].avatar=local_probe
	world.actors["p_2"].avatar=remote_probe
	realm.events.clear()
	var player: Dictionary=realm.state.players["1"]
	var bloom: Dictionary=realm.state.gathers.bloom_1
	player.quests={"lantern":{"state":"active","progress":0}}
	player.pos=C.array(C.vector(bloom.pos)+Vector3(8.0,0.0,0.0))
	var rejected: Dictionary=realm.act(1,{"type":"gather","id":"bloom_1"})
	_present_realm_events()
	check(not bool(rejected.ok) and local_probe.received.is_empty() and remote_probe.received.is_empty(),"Rejected out-of-range gathering does not play an interaction")
	player.pos=bloom.pos.duplicate()
	var accepted: Dictionary=realm.act(1,{"type":"gather","id":"bloom_1"})
	_present_realm_events()
	check(bool(accepted.ok) and local_probe.received==["gather"] and remote_probe.received.is_empty(),"Confirmed gather success animates the event's player only")
	check(int(player.quests.lantern.progress)==1 and not bool(bloom.available),"Interaction presentation preserves the confirmed gathering award")
	var other: Dictionary=realm.state.players["2"]
	var gold_before := int(other.gold)
	realm.state.drops["motion_spoils"]={"id":"motion_spoils","pos":other.pos.duplicate(),"gold":7,"item":"","owner":2}
	rejected=realm.act(1,{"type":"loot","id":"motion_spoils"})
	_present_realm_events()
	check(not bool(rejected.ok) and local_probe.received==["gather"] and remote_probe.received.is_empty(),"Rejected ownership check cannot trigger a loot animation")
	accepted=realm.act(2,{"type":"loot","id":"motion_spoils"})
	_present_realm_events()
	check(bool(accepted.ok) and remote_probe.received==["loot"] and local_probe.received==["gather"],"Remote loot success routes to the remote actor rather than the local hero or drop target")
	check(int(other.gold)==gold_before+7 and not realm.state.drops.has("motion_spoils"),"Loot presentation does not change reward amount or collection timing")
	world.show_event({"type":"gather_requested","actor":1,"target":"bloom_1"})
	world.show_event({"type":"loot","actor":999,"target":"motion_spoils"})
	check(local_probe.received==["gather"] and remote_probe.received==["loot"],"Unconfirmed request types and absent actors cannot animate another player")
	world.actors["p_1"].avatar=local_avatar
	world.actors["p_2"].avatar=remote_avatar
	local_probe.free()
	remote_probe.free()
