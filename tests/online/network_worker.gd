extends SceneTree
## Independent-process ENet integration fixture. No test hooks in runtime code.
const Session=preload("res://game/online/session.gd")
const C=preload("res://game/online/catalog.gd")
var role := ""
var output := ""
var port := 24572
var session: Node
var elapsed := 0.0
var phase_age := 0.0
var phase := ""
var checks := 0
var failures: Array[String]=[]
var flags: Dictionary={}
var player_a := 0
var player_b := 0
var initial_gold := 0
var last_drop := ""
var last_input := 0.0
var finishing := false

func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):role=arg.trim_prefix("--role=")
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
		if arg.begins_with("--port="):port=int(arg.trim_prefix("--port="))
	call_deferred("_boot")

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures.append(message)
		push_error("FAIL "+role+": "+message)

func _boot() -> void:
	var main := Node.new()
	main.name="Draconia"
	root.add_child(main)
	session=Session.new()
	session.name="Session"
	main.add_child(session)
	session.disconnected.connect(_disconnected)
	session.event_received.connect(func(event: Dictionary):
		if event.get("type","")=="chat":flags["chats"]=int(flags.get("chats",0))+1)
	session.notice.connect(func(text: String):
		if text.contains("already") or text.contains("do not own"):flags["rejection_received"]=true)
	var error: Error
	if role in ["server","resume_server"]:
		error=session.start_dedicated(port)
		check(error==OK,"Dedicated server opens ENet socket")
		_mark("ready",{"role":role,"port":port})
		_set_phase("movement" if role=="server" else "resume")
	else:
		error=session.join_game("Runner","127.0.0.1",port)
		check(error==OK,"Client creates ENet connection")
	if error!=OK:_finish()

func _process(delta: float) -> bool:
	if session==null or finishing:return false
	elapsed+=delta
	phase_age+=delta
	if elapsed>35.0:
		check(false,"Network scenario completed before timeout")
		_finish()
		return false
	if role in ["server","resume_server"]:_server()
	else:_client(delta)
	return false

func _set_phase(value: String) -> void:
	phase=value
	phase_age=0.0
	if session.realm!=null:session.realm.state["test_phase"]=value
	_mark("phase",{"phase":value})

func _server() -> void:
	if session.realm==null:return
	var players: Dictionary=session.realm.state.players
	if role=="resume_server":
		if players.size()==1 and not flags.has("restore"):
			var p: Dictionary=players.values()[0]
			check(p.gold==23,"Server reload restores prior client gold from disk")
			check(p.inventory==["travel_blade","travel_coat"],"Rejected forged equipment did not persist")
			check(session._peer_tokens.size()==1,"Reconnect has exactly one authoritative identity")
			flags.restore=true
			phase_age=0.0
		if flags.has("restore") and phase_age>1.0:
			session.stop()
			_finish()
		return
	if phase=="movement" and players.size()==1:
		player_a=int(players.values()[0].id)
		if float(players[str(player_a)].pos[0])>2.0:
			check(float(players[str(player_a)].pos[0])<3.1,"Server accepted bounded client movement")
			var p: Dictionary=players[str(player_a)]
			p.pos=C.array(C.ground_position(-4.0,-10.0))
			p.combat=0.0
			initial_gold=int(p.gold)
			session.realm.state.enemies.fang_1.hp=33.0
			_set_phase("combat")
	elif phase=="combat" and session.realm.state.enemies.fang_1.dead:
		check(session.realm.state.players[str(player_a)].xp==26,"Remote action awards one kill XP")
		check(session.realm.state.drops.size()==1,"Remote kill creates one personal drop")
		last_drop=str(session.realm.state.drops.keys()[0])
		session.realm.state["test_drop"]=last_drop
		_set_phase("loot")
	elif phase=="loot" and session.realm.state.drops.is_empty() and phase_age>0.4:
		check(int(players[str(player_a)].gold)==initial_gold+5,"Two RPC loot requests pay exactly once")
		check(players[str(player_a)].equipment.weapon=="travel_blade","Forged unowned equip action rejected by server")
		_set_phase("late")
		_mark("ready_late",{"ok":true})
	elif phase=="late" and players.size()==2:
		for p: Dictionary in players.values():
			if int(p.id)!=player_a:player_b=int(p.id)
		check(players[str(player_b)].gold==18,"Same display name does not share another client's profile")
		check(players[str(player_b)].id!=player_a,"Independent clients have separate server identities")
		_set_phase("observe")
	elif phase=="observe" and not players.has(str(player_a)) and players.has(str(player_b)):
		check(int(flags.get("chats",0))==2,"Server accepts two chat messages and rate-limits a third")
		check(not session._peer_tokens.has(player_a),"Disconnected peer removed from active identities")
		check(players.size()==1,"Disconnected remote actor removed from shared state")
		_set_phase("shutdown")
	elif phase=="shutdown" and phase_age>1.0:
		check(session.realm.state.players[str(player_b)].gold==18,"Late client's rejected claim did not duplicate first client's loot")
		session.save_profile()
		session.stop()
		_finish()

func _client(delta: float) -> void:
	if session.state.is_empty() or not session.state.get("players",{}).has(str(session.local_id)):return
	var current: String=session.state.get("test_phase","")
	var p: Dictionary=session.state.players[str(session.local_id)]
	if not flags.has("identity"):
		check(session.local_id>1,"Server assigns real remote peer identity")
		check(not JSON.stringify(session.state).contains("token"),"Snapshot contains no reconnect credential")
		flags.identity=true
	last_input+=delta
	if last_input>=1.0/30.0:
		last_input=0.0
		session.send_input({"move":[1.0,0.0] if role=="client_a" and current=="movement" else [0.0,0.0],"yaw":PI/2 if current=="movement" else PI,"jump":false})
	if role=="client_a":
		if current=="combat" and not flags.has("attack"):
			check(float(p.pos[2])<0.0,"Client received authoritative relocation fixture")
			session.command({"type":"ability","id":"strike","target":"fang_1"})
			flags.attack=true
		if current=="loot" and not flags.has("loot"):
			check(session.state.enemies.fang_1.dead,"Client observes server-confirmed enemy death")
			var drop: String=session.state.test_drop
			session.command({"type":"loot","id":drop})
			session.command({"type":"loot","id":drop})
			session.command({"type":"equip","id":"moon_blade","gold":999999})
			flags.loot=true
		if current=="observe" and not flags.has("observed"):
			check(p.gold==23,"Client receives exact once-only reward")
			check(session.state.players.size()==2,"Client sees independently connected second player")
			check(p.equipment.weapon=="travel_blade","Client sees rejected unowned equipment unchanged")
			check(flags.get("rejection_received",false),"Rejected RPC request has useful feedback")
			session.command({"type":"chat","text":"The road is clear."})
			session.command({"type":"chat","text":"Meet me by the lanterns."})
			session.command({"type":"chat","text":"This third message must be throttled."})
			flags.observed=elapsed
		if current=="observe" and flags.has("observed") and elapsed-float(flags.observed)>0.6:
			session.stop()
			_finish()
	elif role=="client_b":
		if current=="observe" and not flags.has("observed"):
			check(session.state.players.size()==2,"Late join receives both current players")
			check(session.state.enemies.fang_1.dead,"Late join sees enemy already dead")
			check(session.state.drops.is_empty(),"Late join does not resurrect claimed loot")
			check(p.gold==18,"Same-name fresh client has distinct progression")
			session.command({"type":"loot","id":str(session.state.test_drop)})
			flags.observed=true
		if current=="shutdown":
			if not flags.has("departed"):
				check(session.state.players.size()==1,"Other client sees disconnected actor removed")
				flags.departed=true
	elif role=="resume_client" and current=="resume" and not flags.has("restored"):
		check(p.gold==23,"Reconnect token restores same server-owned profile across host restart")
		check(p.xp==26,"Reconnect preserves earned XP")
		check(p.inventory==["travel_blade","travel_coat"],"Reconnect profile contains no forged inventory")
		flags.restored=true

func _disconnected(reason: String) -> void:
	if finishing:return
	if role=="client_b":
		check(flags.get("observed",false),"Late-join checks completed before host shutdown")
		check(flags.get("departed",false),"Disconnect replication observed before host shutdown")
		check(int(flags.get("chats",0))==2,"Late client receives two actual server-validated realm chat messages")
		check(session.mode=="idle" and session.state.is_empty(),"Host loss returns client to clean usable idle state")
		check(reason.contains("host") or reason.contains("Host"),"Host loss has a useful explanation")
	elif role=="resume_client":
		check(flags.get("restored",false),"Restored profile observed before host shutdown")
		check(session.mode=="idle","Restored client handles host loss")
	else:check(false,"Unexpected disconnect: "+reason)
	_finish()

func _mark(name: String,data: Dictionary) -> void:
	var file := FileAccess.open(output+"/"+role+"-"+name+".json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(data))

func _finish() -> void:
	if finishing:return
	finishing=true
	var report := {"role":role,"passed":failures.is_empty(),"checks":checks,"failures":failures}
	_mark("report",report)
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
