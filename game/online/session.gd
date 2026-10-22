extends Node
## Small private-realm networking, with server-owned profiles and simulation.
## This is direct-IP co-op infrastructure, not a public account service.
const C = preload("res://game/online/catalog.gd")
const Realm = preload("res://game/online/realm.gd")
const SAVE_ROOT := "user://blackbriar"
const SERVER_FILE := SAVE_ROOT+"/realm_profiles.json"
const SOLO_FILE := SAVE_ROOT+"/solo_profile.json"
const CLIENT_FILE := SAVE_ROOT+"/realm_keys.json"
const PROTOCOL := 1
signal updated(state: Dictionary)
signal notice(text: String)
signal disconnected(reason: String)
signal event_received(event: Dictionary)

var state: Dictionary = {}
var local_id := 0
var mode := "idle"
var realm: RefCounted
var status := "Choose a journey"
var _peer: ENetMultiplayerPeer
var _profiles: Dictionary = {}
var _peer_tokens: Dictionary = {}
var _client_keys: Dictionary = {}
var _server_id := ""
var _display_name := "Wayfarer"
var _address_key := ""
var _snapshot_accum := 0.0
var _save_accum := 0.0
var _connect_age := 0.0
var _input_seq := 0
var _input_last: Dictionary = {}
var _rates: Dictionary = {}
var _pending: Dictionary = {}
var _signal_ready := false
var _welcomed := false
var _last_snapshot_tick := -1

func _ready() -> void:
	_ensure_signals()

func _ensure_signals() -> void:
	if _signal_ready:return
	_signal_ready=true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_solo(display_name: String) -> Error:
	stop()
	_ensure_signals()
	mode="solo"
	local_id=1
	_display_name=Realm.clean_name(display_name)
	realm=Realm.new()
	var saved := _read_json(SOLO_FILE)
	realm.add_player(1,_display_name,saved)
	status="Solo journey · local save"
	_publish()
	return OK

func host_game(display_name: String,port: int=C.PORT) -> Error:
	return _start_host(display_name,port,false)

func start_dedicated(port: int=C.PORT) -> Error:
	return _start_host("",port,true)

func _start_host(display_name: String,port: int,dedicated: bool) -> Error:
	stop()
	_ensure_signals()
	if port<1024 or port>65535:
		status="Use a port between 1024 and 65535."
		notice.emit(status)
		return ERR_INVALID_PARAMETER
	_peer=ENetMultiplayerPeer.new()
	var error := _peer.create_server(port,C.MAX_PLAYERS if dedicated else C.MAX_PLAYERS-1)
	if error!=OK:
		_peer=null
		status="Could not host on UDP port %d. Another realm may already use it."%port
		notice.emit(status)
		return error
	multiplayer.multiplayer_peer=_peer
	mode="dedicated" if dedicated else "host"
	local_id=0 if dedicated else 1
	_display_name=Realm.clean_name(display_name)
	realm=Realm.new()
	var saved := _read_json(SERVER_FILE)
	if saved.get("profiles") is Dictionary:_profiles=saved.profiles
	else:_profiles={}
	_server_id=str(saved.get("server_id",""))
	if not _valid_token(_server_id):_server_id=_new_token()
	if not dedicated:
		_peer_tokens[1]="local_host"
		var host_profile: Dictionary=_profiles.get("local_host",{}) if _profiles.get("local_host",{}) is Dictionary else {}
		realm.add_player(1,_display_name,host_profile)
	status=("Dedicated realm" if dedicated else "Hosting realm")+" · UDP %d · up to %d adventurers"%[port,C.MAX_PLAYERS]
	_save_server()
	_publish()
	return OK

func join_game(display_name: String,address: String,port: int=C.PORT) -> Error:
	stop()
	_ensure_signals()
	address=address.strip_edges()
	if address.is_empty() or address.length()>253 or port<1024 or port>65535:
		status="Enter a valid host address and port."
		notice.emit(status)
		return ERR_INVALID_PARAMETER
	_display_name=Realm.clean_name(display_name)
	_address_key=address.to_lower()+":"+str(port)
	_client_keys=_read_json(CLIENT_FILE)
	_peer=ENetMultiplayerPeer.new()
	var error := _peer.create_client(address,port)
	if error!=OK:
		_peer=null
		status="Could not connect to that host."
		notice.emit(status)
		return error
	multiplayer.multiplayer_peer=_peer
	mode="client"
	status="Connecting to "+address+":"+str(port)+"…"
	_connect_age=0.0
	_welcomed=false
	return OK

func _physics_process(dt: float) -> void:
	if mode in ["solo","host","dedicated"] and realm!=null:
		realm.step(minf(dt,0.1))
		_snapshot_accum+=dt
		_save_accum+=dt
		if _snapshot_accum>=1.0/15.0:
			_snapshot_accum=fmod(_snapshot_accum,1.0/15.0)
			_publish()
		if _save_accum>=10.0:
			_save_accum=0.0
			save_profile()
		for id: int in _pending.keys():
			if Time.get_ticks_msec()-int(_pending[id])>6000:
				_pending.erase(id)
				if _peer!=null:_peer.disconnect_peer(id)
	elif mode=="client" and not _welcomed:
		_connect_age+=dt
		if _connect_age>8.0:_lose_connection("The host did not answer. Check its address and UDP port.")

func send_input(command_data: Dictionary) -> void:
	if mode in ["solo","host"] and realm!=null:
		realm.input_player(local_id,command_data)
	elif mode=="client" and _welcomed:
		_input_seq+=1
		_remote_input.rpc_id(1,_input_seq,command_data)

func command(command_data: Dictionary) -> void:
	if mode in ["solo","host"] and realm!=null:
		var result: Dictionary=realm.act(local_id,command_data)
		if not result.ok:notice.emit(str(result.message))
		elif command_data.get("type","") in ["quest","equip","attribute","buy","loot","gather","respawn"]:
			notice.emit(str(result.message))
		_publish()
	elif mode=="client" and _welcomed:
		_remote_command.rpc_id(1,command_data)

func _publish() -> void:
	if realm==null:return
	state=realm.snapshot()
	updated.emit(state)
	var batch: Array=realm.events.duplicate(true)
	realm.events.clear()
	for event: Dictionary in batch:event_received.emit(event)
	if mode in ["host","dedicated"] and _peer!=null:
		for peer_id: int in _peer_tokens:
			if peer_id==1:continue
			_receive_snapshot.rpc_id(peer_id,state)
			if not batch.is_empty():_receive_events.rpc_id(peer_id,batch)

func _on_peer_connected(id: int) -> void:
	if mode in ["host","dedicated"]:_pending[id]=Time.get_ticks_msec()

func _on_peer_disconnected(id: int) -> void:
	if not mode in ["host","dedicated"] or realm==null:return
	_pending.erase(id)
	if _peer_tokens.has(id):
		_profiles[_peer_tokens[id]]=realm.profile(id)
		_peer_tokens.erase(id)
		realm.remove_player(id)
		_save_server()
	_input_last.erase(id)
	_rates.erase(id)
	_publish()

func _on_connected() -> void:
	if mode!="client":return
	local_id=multiplayer.get_unique_id()
	var entry: Variant=_client_keys.get(_address_key,{})
	var token := str(entry.get("token","")) if entry is Dictionary else ""
	if not _valid_token(token):token=""
	_register.rpc_id(1,PROTOCOL,_display_name,token)
	status="Connected; entering the March…"

@rpc("any_peer","call_remote","reliable",0)
func _register(protocol: int,display_name: String,token: String) -> void:
	if not mode in ["host","dedicated"] or realm==null:return
	var id := multiplayer.get_remote_sender_id()
	if id<=1 or not _pending.has(id) or _peer_tokens.has(id):return
	if protocol!=PROTOCOL or display_name.length()>80 or token.length()>64:
		_reject.rpc_id(id,"This client is not compatible with the realm.")
		return
	if realm.state.players.size()>=C.MAX_PLAYERS:
		_reject.rpc_id(id,"This realm is full.")
		return
	var existing := _valid_token(token) and _profiles.has(token)
	if existing and token in _peer_tokens.values():
		_reject.rpc_id(id,"That traveller is already connected to this realm.")
		return
	if not existing:token=_new_token()
	var saved: Dictionary=_profiles.get(token,{}) if _profiles.get(token,{}) is Dictionary else {}
	var player: Dictionary=realm.add_player(id,display_name,saved)
	if player.is_empty():
		_reject.rpc_id(id,"Could not enter this realm.")
		return
	_peer_tokens[id]=token
	_profiles[token]=realm.profile(id)
	_pending.erase(id)
	_input_last[id]=-1
	_welcome.rpc_id(id,token,_server_id,id)
	_save_server()
	_publish()

@rpc("authority","call_remote","reliable",0)
func _welcome(token: String,server_id: String,id: int) -> void:
	if mode!="client" or not _valid_token(token) or not _valid_token(server_id):return
	if id!=multiplayer.get_unique_id():return
	local_id=id
	_welcomed=true
	_client_keys[_address_key]={"token":token,"server_id":server_id}
	_write_json(CLIENT_FILE,_client_keys)
	status="Connected to a private realm · server-owned progress"
	notice.emit("Welcome to the Blackbriar March.")

@rpc("authority","call_remote","reliable",0)
func _reject(reason: String) -> void:
	if mode=="client":_lose_connection(reason.left(180))

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _remote_input(sequence: int,command_data: Dictionary) -> void:
	if not mode in ["host","dedicated"] or realm==null:return
	var id := multiplayer.get_remote_sender_id()
	if not _peer_tokens.has(id) or not _allow_rate(id,"input",65):return
	if sequence<=int(_input_last.get(id,-1)) or sequence<0:return
	_input_last[id]=sequence
	if command_data.size()>5:return
	realm.input_player(id,command_data)

@rpc("any_peer","call_remote","reliable",0)
func _remote_command(command_data: Dictionary) -> void:
	if not mode in ["host","dedicated"] or realm==null:return
	var id := multiplayer.get_remote_sender_id()
	if not _peer_tokens.has(id) or not _allow_rate(id,"action",10):return
	if command_data.size()>6:return
	var result: Dictionary=realm.act(id,command_data)
	if not result.ok or command_data.get("type","") in ["quest","equip","attribute","buy","loot","gather","respawn"]:
		_command_result.rpc_id(id,str(result.message))
	_publish()

func _allow_rate(id: int,kind: String,limit: int) -> bool:
	var now := Time.get_ticks_msec()
	if not _rates.has(id):_rates[id]={}
	if not _rates[id].has(kind):_rates[id][kind]={"time":now,"count":0}
	var bucket: Dictionary=_rates[id][kind]
	if now-int(bucket.time)>=1000:
		bucket.time=now
		bucket.count=0
	bucket.count+=1
	return int(bucket.count)<=limit

@rpc("authority","call_remote","reliable",0)
func _command_result(message: String) -> void:
	if mode=="client":notice.emit(message.left(180))

@rpc("authority","call_remote","unreliable_ordered",2)
func _receive_snapshot(snapshot_data: Dictionary) -> void:
	if mode!="client" or not _welcomed:return
	if not snapshot_data.get("players") is Dictionary or not snapshot_data.get("enemies") is Dictionary:return
	var tick := int(snapshot_data.get("tick",-1))
	if tick<_last_snapshot_tick:return
	_last_snapshot_tick=tick
	state=snapshot_data
	updated.emit(state)

@rpc("authority","call_remote","reliable",0)
func _receive_events(batch: Array) -> void:
	if mode!="client" or not _welcomed or batch.size()>128:return
	for event: Variant in batch:
		if event is Dictionary:event_received.emit(event)

func save_profile() -> void:
	if realm==null:return
	if mode=="solo":
		if not _write_json(SOLO_FILE,realm.profile(1)):notice.emit("The local save could not be written.")
	elif mode in ["host","dedicated"]:_save_server()

func _save_server() -> void:
	if realm==null:return
	for id: int in _peer_tokens:
		var saved: Dictionary=realm.profile(id)
		if not saved.is_empty():_profiles[_peer_tokens[id]]=saved
	if not _write_json(SERVER_FILE,{"version":1,"server_id":_server_id,"profiles":_profiles}):
		notice.emit("Realm profiles could not be saved.")

func stop() -> void:
	if mode in ["solo","host","dedicated"]:save_profile()
	mode="idle"
	if _peer!=null:_peer.close()
	_peer=null
	if is_inside_tree():multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	state={}
	realm=null
	local_id=0
	_peer_tokens.clear()
	_profiles.clear()
	_pending.clear()
	_rates.clear()
	_input_last.clear()
	_snapshot_accum=0.0
	_save_accum=0.0
	_connect_age=0.0
	_input_seq=0
	_last_snapshot_tick=-1
	_welcomed=false
	status="Choose a journey"

func _on_connection_failed() -> void:
	if mode=="client":_lose_connection("Could not reach the realm. Check the host address and UDP port.")

func _on_server_disconnected() -> void:
	if mode=="client":_lose_connection("The host closed the realm. Your last server save is retained.")

func _lose_connection(reason: String) -> void:
	stop()
	status=reason
	disconnected.emit(reason)
	notice.emit(reason)

func _exit_tree() -> void:
	stop()

static func _new_token() -> String:
	return Crypto.new().generate_random_bytes(24).hex_encode()

static func _valid_token(token: String) -> bool:
	if token.length()!=48:return false
	for c: String in token:
		if not c in "0123456789abcdef":return false
	return true

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):return {}
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>2*1024*1024:return {}
	var parsed: Variant=JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func _write_json(path: String,data: Dictionary) -> bool:
	var base := ProjectSettings.globalize_path(path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(base)!=OK:return false
	var temporary := path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))
	return error==OK
