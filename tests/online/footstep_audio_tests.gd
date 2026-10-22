extends SceneTree
## Actual 60 Hz Mara contact diagnostics drive a recording audio sink. The test
## evaluates scheduling of the existing step asset, not recording/art quality.
const Avatar = preload("res://game/online/avatar.gd")
const DT := 1.0/60.0
var avatar: Node3D
var audio: Node
var player: Dictionary = {}
var checks := 0
var failures: Array[String] = []
var metrics: Dictionary = {}
var frame := 0
var previous_height := 0.0

class RecordingSoundscape:
	extends "res://game/online/soundscape.gd"
	var played: Array[Dictionary] = []
	var frame := 0
	var diagnostics: Dictionary = {}
	func _ready() -> void:pass
	func _play(id: String,volume: float=-12.0,pitch: float=1.0) -> void:
		if enabled:played.append({"sound":id,"volume":volume,"pitch":pitch,"frame":frame,"weights":diagnostics.get("foot_weights",[]).duplicate(),"grounded":diagnostics.get("grounded",true)})

func _initialize() -> void:call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition:
		failures.append(description)
		push_error(description)

func _fresh(action: String, speed: float) -> void:
	if audio!=null:audio.free()
	audio=RecordingSoundscape.new()
	root.add_child(audio)
	player={"action":action,"action_time":0.0,"action_duration":1.0,"speed":speed,"grounded":true,"dead":false}
	avatar.apply_state(player)
	avatar.position=Vector3.ZERO
	previous_height=0.0
	_tick(Vector3(0,0,speed),true,0.0,true)

func _tick(velocity: Vector3, grounded: bool=true, height: float=0.0, teleport: bool=false) -> Dictionary:
	frame+=1
	avatar.position+=velocity*DT
	avatar.position.y=height
	avatar.set_presentation_motion({"velocity":velocity,"local_velocity":velocity,"acceleration":Vector3.ZERO,"turn_rate":0.0,"grounded":grounded,"height":height,"vertical_speed":(height-previous_height)/DT,"teleported":teleport,"source_age":0.0,"dt":DT})
	avatar._process(DT)
	previous_height=height
	var diagnostics: Dictionary=avatar.animation_diagnostics()
	diagnostics.motion_speed=Vector2(velocity.x,velocity.z).length()
	diagnostics.teleported=teleport
	audio.frame=frame
	audio.diagnostics=diagnostics
	audio.update_player(player,DT,diagnostics)
	return diagnostics

func _run() -> void:
	avatar=Avatar.new()
	root.add_child(avatar)
	avatar.set_process(false)
	_gait("run",4.77,8,10,0.45876)
	_gait("walk",0.89,5,7,0.66685)
	_jump_and_land()
	_suppression()
	_fallback()
	var report := {"suite":"footstep_audio_contacts","checks":checks,"failures":failures,"metrics":metrics,"scope":"Existing step.wav scheduled from actual native Avatar foot diagnostics; recording sink replaces playback for deterministic verification."}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var file := FileAccess.open(argument.trim_prefix("--report="),FileAccess.WRITE)
			if file!=null:file.store_string(JSON.stringify(report,"\t")+"\n")
	print(JSON.stringify(report))
	audio.queue_free()
	avatar.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _gait(action: String,speed: float,minimum: int,maximum: int,expected_interval: float) -> void:
	_fresh(action,speed)
	var velocity := Vector3(0,0,speed)
	for unused: int in range(120):_tick(velocity)
	audio.played.clear()
	var held_contacts_do_not_repeat := true
	for unused: int in range(240):
		var diagnostics := _tick(velocity)
		var count: int=audio.played.size()
		# A second consumer update of the same actual plant is not another step.
		audio.update_player(player,0.0,diagnostics)
		held_contacts_do_not_repeat=held_contacts_do_not_repeat and audio.played.size()==count
	var contacts_valid := true
	var alternates := true
	var last_foot := -1
	var intervals: Array[float] = []
	var previous_frame := -1
	for sound: Dictionary in audio.played:
		var weights: Array=sound.weights
		var foot := 0 if float(weights[0])>=float(weights[1]) else 1
		contacts_valid=contacts_valid and bool(sound.grounded) and float(weights[foot])>=0.65 and str(sound.sound)=="step"
		alternates=alternates and foot!=last_foot
		last_foot=foot
		if previous_frame>=0:intervals.append(float(int(sound.frame)-previous_frame)*DT)
		previous_frame=int(sound.frame)
	var mean_interval := 0.0
	for interval: float in intervals:mean_interval+=interval
	mean_interval/=maxi(1,intervals.size())
	check(audio.played.size()>=minimum and audio.played.size()<=maximum,"Actual "+action+" gait has the expected number of alternating footfalls in four seconds")
	check(contacts_valid and alternates,"Every "+action+" step sound coincides with a strong alternating foot contact")
	check(absf(mean_interval-expected_interval)<0.035,"Footstep cadence follows the "+action+" stride rather than the previous fixed timer")
	check(held_contacts_do_not_repeat,"Repeated "+action+" contact diagnostics never replay a held plant")
	metrics[action]={"sounds_in_four_seconds":audio.played.size(),"mean_interval_seconds":mean_interval,"intervals_seconds":intervals,"contact_order_alternates":alternates}
	var count_before_stop: int=audio.played.size()
	for unused: int in range(90):_tick(Vector3.ZERO)
	check(audio.played.size()==count_before_stop,"Stopped rendered motion is silent even while the raw "+action+" snapshot still reports travel")

func _jump_and_land() -> void:
	_fresh("run",2.6)
	for unused: int in range(60):_tick(Vector3(0,0,2.6))
	audio.played.clear()
	for step: int in range(1,46):
		var time := float(step)*DT
		_tick(Vector3(0,0,2.6),false,maxf(0.001,5.1*time-6.75*time*time))
	check(audio.played.is_empty(),"Airborne animation contacts produce no footsteps")
	for unused: int in range(90):_tick(Vector3.ZERO)
	var quiet_landings := 0
	var contact_valid := true
	for sound: Dictionary in audio.played:
		if is_equal_approx(float(sound.volume),-27.0):quiet_landings+=1
		contact_valid=contact_valid and bool(sound.grounded) and maxf(float(sound.weights[0]),float(sound.weights[1]))>=0.65
	check(quiet_landings==1 and audio.played.size()==1,"Jump landing produces one quiet step and no repeated idle sounds")
	check(contact_valid,"Landing sound waits for the actual feet to regain strong contact")
	metrics.landing={"sounds":audio.played.size(),"quiet_landing_count":quiet_landings}

func _suppression() -> void:
	_fresh("idle",0.0)
	for unused: int in range(90):_tick(Vector3.ZERO)
	check(audio.played.is_empty(),"Standing idle is silent despite two planted feet")
	_fresh("run",4.77)
	for unused: int in range(90):_tick(Vector3(0,0,4.77))
	audio.played.clear()
	for unused: int in range(12):_tick(Vector3(0,0,4.77),true,0.0,true)
	check(audio.played.is_empty(),"Teleport and correction frames cannot trigger footsteps")
	player=player.duplicate(true)
	player.dead=true
	player.action="death"
	player.action_duration=2.4167
	avatar.apply_state(player)
	for unused: int in range(45):_tick(Vector3(0,0,4.77))
	check(audio.played.is_empty(),"Dead actors cannot produce footstep contacts")

func _fallback() -> void:
	_fresh("run",4.77)
	audio.played.clear()
	audio.update_player(player,0.31)
	check(audio.played.size()==1,"Callers without avatar diagnostics retain the existing movement fallback")
	player=player.duplicate(true)
	player.grounded=false
	audio.update_player(player,0.6)
	check(audio.played.size()==1,"Legacy fallback retains its airborne suppression")
