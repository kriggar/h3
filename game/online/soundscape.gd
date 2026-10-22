extends Node
## Original modest development audio, driven only by confirmed world events.
var _streams: Dictionary={}
var _voices: Array[AudioStreamPlayer]=[]
var _loops: Array[AudioStreamPlayer]=[]
var _next_voice := 0
var _footstep := 0.0
var _last_blade := 0
var _contact_down := [false,false]
var _contacts_ready := false
var _was_grounded := true
var _landing_pending := false
const CONTACT_ON := 0.65
const CONTACT_OFF := 0.2
var enabled := true
var _shut_down := false

func _ready() -> void:
	for sound: String in ["blade","impact","step","ward","reward","level","heal"]:
		_streams[sound]=load("res://assets/online/audio/"+sound+".wav")
	for i: int in range(8):
		var player:=AudioStreamPlayer.new()
		add_child(player)
		_voices.append(player)
	_loop("briar_air",-23.0)
	_loop("watchfire_theme",-27.0)

func _loop(id: String,volume: float) -> void:
	var stream: AudioStreamWAV=load("res://assets/online/audio/"+id+".wav").duplicate() as AudioStreamWAV
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=int(stream.get_length()*stream.mix_rate)
	var player:=AudioStreamPlayer.new()
	player.stream=stream
	player.volume_db=volume
	add_child(player)
	_loops.append(player)
	player.play()

func shutdown() -> void:
	if _shut_down:return
	_shut_down=true
	enabled=false
	# The audio server may still hold playback references for a stopped loop.
	# Detach streams while the tree is alive, then let main's quit path drain frames.
	for player: AudioStreamPlayer in _voices+_loops:
		if is_instance_valid(player):
			player.stop()
			player.stream=null
	_voices.clear()
	_loops.clear()
	_streams.clear()

func _exit_tree() -> void:
	shutdown()

func _play(id: String,volume: float=-12.0,pitch: float=1.0) -> void:
	if not enabled or _voices.is_empty() or not _streams.has(id):return
	var voice:=_voices[_next_voice]
	_next_voice=(_next_voice+1)%_voices.size()
	voice.stream=_streams[id]
	voice.volume_db=volume
	voice.pitch_scale=pitch
	voice.play()

func update_player(player: Dictionary,delta: float,presentation: Dictionary={}) -> void:
	if presentation.get("foot_weights") is Array and presentation.foot_weights.size()==2:
		_update_contact_audio(player,presentation)
		return
	# Compatibility for previews without a live avatar/foot-contact source.
	_contacts_ready=false
	_landing_pending=false
	_footstep-=delta
	if not player.get("dead",false) and player.get("grounded",true) and float(player.get("speed",0))>0.5 and player.get("action","") in ["run","walk"] and _footstep<=0.0:
		_footstep=0.3 if float(player.speed)>2.0 else 0.56
		_play("step",-25.0,randf_range(0.92,1.08))

func _update_contact_audio(player: Dictionary,presentation: Dictionary) -> void:
	var grounded := bool(presentation.get("grounded",player.get("grounded",true)))
	var dead := bool(player.get("dead",false)) or str(presentation.get("state",""))=="death"
	var reset := bool(presentation.get("teleported",false))
	var weights: Array=presentation.foot_weights
	if not _contacts_ready or reset or dead:
		# Prime existing plants silently: spawning, resuming or correcting an
		# already planted pose is not a new footfall.
		for foot: int in range(2):_contact_down[foot]=float(weights[foot])>=CONTACT_ON
		_contacts_ready=true
		_was_grounded=grounded
		_landing_pending=false
		return
	if grounded and not _was_grounded:_landing_pending=true
	if not grounded:_landing_pending=false
	_was_grounded=grounded
	var entered: Array[int]=[]
	for foot: int in range(2):
		var weight := clampf(float(weights[foot]),0.0,1.0)
		if weight<=CONTACT_OFF:_contact_down[foot]=false
		elif weight>=CONTACT_ON and not bool(_contact_down[foot]):
			_contact_down[foot]=true
			entered.append(foot)
	if not grounded:return
	if _landing_pending and not entered.is_empty():
		_play("step",-27.0,0.88)
		_landing_pending=false
		return
	var state := str(presentation.get("state","idle"))
	var speed := float(presentation.get("motion_speed",presentation.get("speed",0.0)))
	if speed<=0.15 or state in ["idle","turn","takeoff","airborne","landing","roll","death"]:return
	for _foot: int in entered:_play("step",-25.0,randf_range(0.92,1.08))

func play_event(event: Dictionary,local_id: int) -> void:
	var type:=str(event.get("type",""))
	var local:=int(event.get("actor",0))==local_id
	match type:
		"strike","cleave":
			if Time.get_ticks_msec()-_last_blade>80:
				_last_blade=Time.get_ticks_msec()
				_play("blade",-16.0 if local else -25.0,0.8 if type=="cleave" else 1.0)
		"hit","hurt":_play("impact",-16.0 if local else -25.0,0.85 if type=="hurt" else 1.1)
		"ward":_play("ward",-16.0 if local else -28.0)
		"roll":
			if local:_play("step",-14.0,0.7)
		"heal":
			if local:_play("heal",-15.0)
		"level":
			if local:_play("level",-13.0)
		"loot","quest_complete","gather":
			if local:_play("reward",-20.0)
