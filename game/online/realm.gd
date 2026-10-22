extends RefCounted
## Deterministic server simulation. Clients send intentions, never results.
const C = preload("res://game/online/catalog.gd")
const SAVE_VERSION := 1
const MAX_LEVEL := 20
const RUN_SPEED := 4.75
var state: Dictionary = {"tick":0,"time":0.0,"players":{},"enemies":{},"drops":{},"gathers":{}}
var events: Array = []
var _inputs: Dictionary = {}
var _actions: Dictionary = {}
var _enemy_private: Dictionary = {}
var _gather_ready: Dictionary = {}
var _chat_times: Dictionary = {}
var _drop_number := 0
var _event_number := 0

func _init() -> void:
	for spec: Dictionary in C.ENEMIES:_spawn_enemy(spec)
	for spec: Dictionary in C.GATHERS:
		var p := C.vector(spec.pos)
		state.gathers[spec.id]={"id":spec.id,"pos":C.array(C.ground_position(p.x,p.z)),"available":true}

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _safe_int(value: Variant, fallback: int, low: int, high: int) -> int:
	if not _number(value):return fallback
	return clampi(int(value),low,high)

static func clean_name(value: String) -> String:
	var result := ""
	for character: String in value.strip_edges():
		var code := character.unicode_at(0)
		if (code>=65 and code<=90) or (code>=97 and code<=122) or (code>=48 and code<=57) or character in [" ","-","'"]:
			result+=character
		if result.length()>=20:break
	return result.strip_edges() if result.strip_edges().length()>=2 else "Wayfarer"

static func xp_needed(level: int) -> int:
	return 100+(level-1)*60 if level<MAX_LEVEL else 0

func _spawn_enemy(spec: Dictionary) -> void:
	var data: Dictionary=C.ENEMY_TYPES[spec.kind]
	var origin := C.vector(spec.pos)
	origin=C.ground_position(origin.x,origin.z)
	state.enemies[spec.id]={"id":spec.id,"kind":spec.kind,"name":data.name,"level":data.level,"pos":C.array(origin),"yaw":0.0,"hp":float(data.hp),"max_hp":float(data.hp),"action":"idle","action_time":0.0,"action_duration":0.0,"dead":false,"respawn":0.0,"attack_point":C.array(origin),"attack_radius":0.0,"target":0}
	_enemy_private[spec.id]={"origin":origin,"cooldown":0.0,"contributors":{},"target":0,"attack_point":origin}

func add_player(id: int, display_name: String, saved: Dictionary={}) -> Dictionary:
	if id<=0 or state.players.has(str(id)) or state.players.size()>=C.MAX_PLAYERS:return {}
	var level := _safe_int(saved.get("level",1),1,1,MAX_LEVEL)
	var attributes: Dictionary={"might":5,"vitality":5,"spirit":5}
	var allocated := 0
	if saved.get("attributes") is Dictionary:
		for key: String in attributes:
			var available := (level-1)*2-allocated
			attributes[key]=_safe_int(saved.attributes.get(key),5,5,5+maxi(0,available))
			allocated+=int(attributes[key])-5
	var inventory: Array=["travel_blade","travel_coat"]
	if saved.get("inventory") is Array:
		for item: Variant in saved.inventory:
			if item is String and C.ITEMS.has(item) and not item in inventory:inventory.append(item)
	var equipment: Dictionary={"weapon":"travel_blade","chest":"travel_coat","ring":""}
	if saved.get("equipment") is Dictionary:
		for slot: String in equipment:
			var item: Variant=saved.equipment.get(slot,"")
			if item is String and C.ITEMS.has(item) and item in inventory and C.ITEMS[item].slot==slot:equipment[slot]=item
	var quests: Dictionary={}
	if saved.get("quests") is Dictionary:
		for key: String in C.QUESTS:
			if not saved.quests.get(key) is Dictionary:continue
			var prereq: String=C.QUESTS[key].requires
			if prereq!="" and quests.get(prereq,{}).get("state","")!="complete":continue
			var q: Dictionary=saved.quests[key]
			if not q.get("state","") in ["active","complete"]:continue
			quests[key]={"state":q.state,"progress":_safe_int(q.get("progress"),0,0,int(C.QUESTS[key].goal))}
			if q.state=="complete":quests[key].progress=int(C.QUESTS[key].goal)
	var p: Dictionary={"id":id,"name":clean_name(display_name),"pos":C.array(C.ground_position(C.SPAWN.x,C.SPAWN.z)),"yaw":PI,"hp":1.0,"max_hp":1.0,"energy":100.0,"max_energy":100.0,"level":level,"xp":_safe_int(saved.get("xp",0),0,0,maxi(0,xp_needed(level)-1)),"next_xp":xp_needed(level),"gold":_safe_int(saved.get("gold",18),18,0,999999),"points":maxi(0,(level-1)*2-allocated),"attributes":attributes,"inventory":inventory,"equipment":equipment,"quests":quests,"cooldowns":{},"action":"idle","action_time":0.0,"action_duration":0.0,"ward":0.0,"dead":false,"grounded":true,"potions":_safe_int(saved.get("potions",3),3,0,20),"speed":0.0,"power":0.0,"armor":0.0,"combat":0.0,"target":""}
	state.players[str(id)]=p
	_recalculate(p)
	p.hp=p.max_hp
	p.energy=p.max_energy
	_inputs[id]={"move":Vector2.ZERO,"yaw":PI,"jump":false,"last":float(state.time),"vertical":0.0}
	_actions[id]={"hit":false,"target":"","roll":Vector3.ZERO}
	_emit("join",p.name+" entered the Blackbriar March.",id,"",C.vector(p.pos),0)
	return p

func remove_player(id: int) -> void:
	if not state.players.has(str(id)):return
	_emit("leave",str(state.players[str(id)].name)+" left the March.",id)
	state.players.erase(str(id))
	_inputs.erase(id)
	_actions.erase(id)
	_chat_times.erase(id)
	for drop: Dictionary in state.drops.values():
		if int(drop.owner)==id:drop.owner=0
	for private_data: Dictionary in _enemy_private.values():
		private_data.contributors.erase(id)
		if int(private_data.target)==id:private_data.target=0

func _recalculate(p: Dictionary) -> void:
	var item_power := 0.0
	var item_armor := 0.0
	var item_vitality := 0.0
	for id: String in p.equipment.values():
		if C.ITEMS.has(id):
			item_power+=float(C.ITEMS[id].power)
			item_armor+=float(C.ITEMS[id].armor)
			item_vitality+=float(C.ITEMS[id].vitality)
	p.max_hp=100.0+float(p.attributes.vitality)*12.0+item_vitality*12.0+float(p.level)*8.0
	p.max_energy=100.0+float(p.attributes.spirit)*3.0
	p.power=float(p.attributes.might)*0.8+item_power+float(p.level-1)*1.5
	p.armor=item_armor+float(p.attributes.vitality)*0.25
	p.hp=minf(float(p.hp),float(p.max_hp))
	p.energy=minf(float(p.energy),float(p.max_energy))

func input_player(id: int, command: Dictionary) -> void:
	if not _inputs.has(id):return
	var direction: Variant=command.get("move")
	if not direction is Array or direction.size()!=2 or not _number(direction[0]) or not _number(direction[1]):return
	if not _number(command.get("yaw")):return
	if absf(float(direction[0]))>2.0 or absf(float(direction[1]))>2.0:return
	var move := Vector2(float(direction[0]),float(direction[1])).limit_length(1.0)
	_inputs[id].move=move
	_inputs[id].yaw=wrapf(float(command.yaw),-PI,PI)
	_inputs[id].last=float(state.time)
	if command.get("jump",false) is bool and command.get("jump",false):_inputs[id].jump=true

func act(id: int, command: Dictionary) -> Dictionary:
	if not state.players.has(str(id)):return _no("You are not in a realm.")
	if not command.get("type") is String:return _no("Invalid action.")
	var p: Dictionary=state.players[str(id)]
	var type: String=command.type
	if type=="chat":return _chat(p,command.get("text"))
	if p.dead:
		if type=="respawn":
			if float(p.action_time)<2.5:return _no("Your spirit is finding the road home.")
			p.dead=false
			p.hp=p.max_hp
			p.energy=p.max_energy
			p.pos=C.array(C.ground_position(C.SPAWN.x,C.SPAWN.z))
			p.action="idle"
			p.action_time=0.0
			p.action_duration=0.0
			p.combat=0.0
			p.ward=2.0
			p.grounded=true
			_inputs[id].vertical=0.0
			_inputs[id].move=Vector2.ZERO
			_emit("respawn","You awaken beneath Thornwatch's lanterns.",id,"",C.vector(p.pos),0)
			return _yes("Returned to Thornwatch.")
		return _no("Return to Thornwatch before acting.")
	var key: Variant=command.get("id","")
	if not key is String or key.length()>64:return _no("Invalid action identifier.")
	match type:
		"ability":return _ability(p,key,command)
		"interact":
			var npc := _npc(key)
			if npc.is_empty() or _distance(p.pos,npc.pos)>4.5:return _no("Move closer to speak.")
			return _yes(str(npc.name))
		"quest":return _quest(p,key)
		"gather":return _gather(p,key)
		"loot":return _loot(p,key)
		"equip":
			if float(p.combat)>0.0:return _no("Change equipment after combat.")
			if not key in p.inventory or not C.ITEMS.has(key):return _no("You do not own that item.")
			p.equipment[C.ITEMS[key].slot]=key
			_recalculate(p)
			_emit("equip","Equipped "+str(C.ITEMS[key].name)+".",id)
			return _yes("Equipped "+str(C.ITEMS[key].name)+".")
		"attribute":
			if not key in ["might","vitality","spirit"] or int(p.points)<=0:return _no("No attribute point available.")
			p.attributes[key]+=1
			p.points-=1
			_recalculate(p)
			_emit("attribute",key.capitalize()+" increased.",id)
			return _yes(key.capitalize()+" increased.")
		"buy":return _buy(p,key)
		_:return _no("Unknown action.")

func _chat(p: Dictionary,raw: Variant) -> Dictionary:
	if not raw is String or raw.length()>160:return _no("Realm chat is limited to 160 characters.")
	var message := ""
	for character: String in raw:
		var code := character.unicode_at(0)
		if code>=32 and code!=127 and not (code>=0x202A and code<=0x202E) and not (code>=0x2066 and code<=0x2069):message+=character
	message=message.strip_edges()
	if message.is_empty():return _no("Write a message first.")
	var id := int(p.id)
	if not _chat_times.has(id):_chat_times[id]=[]
	var times: Array=_chat_times[id]
	while not times.is_empty() and float(state.time)-float(times[0])>=1.0:times.pop_front()
	if times.size()>=2:return _no("Please wait a moment before chatting again.")
	times.append(float(state.time))
	_emit("chat",str(p.name)+": "+message,id)
	return _yes("Message sent.")

func _ability(p: Dictionary, key: String, command: Dictionary) -> Dictionary:
	if not C.ABILITIES.has(key):return _no("Unknown ability.")
	if float(p.cooldowns.get(key,0.0))>0.001:return _no("That ability is recovering.")
	if not str(p.action) in ["idle","run","walk","combat_idle"]:return _no("Finish your current action first.")
	var data: Dictionary=C.ABILITIES[key]
	if float(p.energy)<float(data.cost):return _no("Not enough resolve.")
	var target: Variant=command.get("target","")
	if not target is String or target.length()>64:return _no("Invalid target.")
	if key=="strike":
		if not state.enemies.has(target) or state.enemies[target].dead:return _no("Select a living enemy with Tab or click.")
		if _distance(p.pos,state.enemies[target].pos)>float(data.range):return _no("Move within 3 metres of your target.")
	if key in ["strike","cleave"] and state.enemies.has(target) and not state.enemies[target].dead:
		var toward := C.vector(state.enemies[target].pos)-C.vector(p.pos)
		p.yaw=atan2(toward.x,toward.z)
		_inputs[int(p.id)].yaw=p.yaw
	if key=="potion":
		if int(p.potions)<=0:return _no("No rowan draughts left. Visit Mira Rowan.")
		if float(p.hp)>=float(p.max_hp):return _no("Your health is already full.")
		p.potions-=1
		p.hp=minf(float(p.max_hp),float(p.hp)+65.0)
		_emit("heal","Rowan Draught restores 65 health.",int(p.id),"",C.vector(p.pos),65)
	p.energy-=float(data.cost)
	p.cooldowns[key]=float(data.cooldown)
	p.action=key
	p.action_time=0.0
	p.action_duration=float(data.duration)
	p.target=target
	_actions[int(p.id)]={"hit":key in ["roll","potion"],"target":target,"roll":Vector3.ZERO}
	if key=="roll":
		var move: Vector2=_inputs[int(p.id)].move
		var direction := Vector3(move.x,0,move.y)
		if direction.length()<0.1:direction=Vector3(sin(float(p.yaw)),0,cos(float(p.yaw)))
		_actions[int(p.id)].roll=direction.normalized()
		p.yaw=atan2(direction.x,direction.z)
		_emit("roll","",int(p.id),"",C.vector(p.pos),0)
	return _yes(str(data.name))

func _quest(p: Dictionary, key: String) -> Dictionary:
	if not C.QUESTS.has(key):return _no("Unknown quest.")
	if _distance(p.pos,_npc("steward").pos)>4.5:return _no("Speak to Captain Elric in Thornwatch.")
	var definition: Dictionary=C.QUESTS[key]
	var prereq: String=definition.requires
	if prereq!="" and p.quests.get(prereq,{}).get("state","")!="complete":return _no("Complete the previous chapter first.")
	if not p.quests.has(key):
		p.quests[key]={"state":"active","progress":0}
		_emit("quest","Accepted: "+str(definition.name),int(p.id))
		return _yes("Quest accepted.")
	if p.quests[key].state=="complete":return _no("This reward has already been claimed.")
	if int(p.quests[key].progress)<int(definition.goal):return _no("Your task is not yet complete.")
	## Commit completion before awards; replay cannot pay twice.
	p.quests[key].state="complete"
	p.gold+=int(definition.gold)
	_award_item(p,str(definition.item))
	_award_xp(p,int(definition.xp))
	if key=="lantern":p.potions=mini(20,int(p.potions)+2)
	_emit("quest_complete","Completed: "+str(definition.name)+" · "+str(definition.xp)+" XP",int(p.id),"",C.vector(p.pos),int(definition.xp))
	return _yes("Reward claimed: "+str(C.ITEMS[definition.item].name))

func _gather(p: Dictionary, key: String) -> Dictionary:
	if not state.gathers.has(key):return _no("Unknown gathering node.")
	var node: Dictionary=state.gathers[key]
	if not node.available:return _no("This emberbloom is regrowing.")
	if _distance(p.pos,node.pos)>3.0:return _no("Move closer to the emberbloom.")
	if p.quests.get("lantern",{}).get("state","")!="active":return _no("Captain Elric knows a use for these flowers.")
	if int(p.quests.lantern.progress)>=int(C.QUESTS.lantern.goal):return _no("You have enough emberblooms. Return to Elric.")
	node.available=false
	_gather_ready[key]=float(state.time)+20.0
	p.quests.lantern.progress+=1
	_emit("gather","Emberbloom gathered: %d / 3"%int(p.quests.lantern.progress),int(p.id),key,C.vector(node.pos),1)
	return _yes("An emberbloom warms your palm.")

func _loot(p: Dictionary, key: String) -> Dictionary:
	if not state.drops.has(key):return _no("That spoils pile has already been claimed.")
	var drop: Dictionary=state.drops[key]
	if int(drop.owner)!=0 and int(drop.owner)!=int(p.id):return _no("These spoils belong to another adventurer.")
	if _distance(p.pos,drop.pos)>3.5:return _no("Move closer to collect the spoils.")
	state.drops.erase(key)
	p.gold+=int(drop.gold)
	var item: String=drop.item
	var text := "+%d crowns"%int(drop.gold)
	if item!="":
		_award_item(p,item)
		text+=" · "+str(C.ITEMS[item].name)
	_emit("loot",text,int(p.id),key,C.vector(drop.pos),int(drop.gold))
	return _yes(text)

func _buy(p: Dictionary, key: String) -> Dictionary:
	if _distance(p.pos,_npc("merchant").pos)>4.5:return _no("Visit Mira Rowan to trade.")
	if float(p.combat)>0.0:return _no("Finish combat before trading.")
	if key=="potion":
		if int(p.potions)>=20:return _no("Your draught pouch is full.")
		if int(p.gold)<8:return _no("A rowan draught costs 8 crowns.")
		p.gold-=8
		p.potions+=1
		return _yes("Bought a rowan draught.")
	if key!="watch_coat":return _no("That item is not for sale.")
	if key in p.inventory:return _no("You already own this hauberk.")
	if int(p.gold)<38:return _no("The hauberk costs 38 crowns.")
	p.gold-=38
	_award_item(p,key)
	return _yes("Bought a Blackbriar Hauberk.")

func step(dt: float) -> void:
	if not is_finite(dt) or dt<=0.0:return
	## Reject giant caller deltas rather than moving through the entire world.
	dt=minf(dt,0.1)
	state.tick+=1
	state.time+=dt
	for p: Dictionary in state.players.values():_step_player(p,dt)
	for e: Dictionary in state.enemies.values():_step_enemy(e,dt)
	for key: String in _gather_ready.keys():
		if float(state.time)>=float(_gather_ready[key]):
			state.gathers[key].available=true
			_gather_ready.erase(key)
	for key: String in state.drops.keys():
		if float(state.time)>float(state.drops[key].get("expires",INF)):state.drops.erase(key)

func _step_player(p: Dictionary, dt: float) -> void:
	var id := int(p.id)
	p.action_time+=dt
	for key: String in p.cooldowns.keys():p.cooldowns[key]=maxf(0.0,float(p.cooldowns[key])-dt)
	p.ward=maxf(0.0,float(p.ward)-dt)
	p.combat=maxf(0.0,float(p.combat)-dt)
	if p.dead:
		p.speed=0.0
		return
	p.energy=minf(float(p.max_energy),float(p.energy)+(12.0+float(p.attributes.spirit)*0.6)*dt)
	if float(p.combat)<=0.0:p.hp=minf(float(p.max_hp),float(p.hp)+5.0*dt)
	if C.ABILITIES.has(str(p.action)):
		var data: Dictionary=C.ABILITIES[p.action]
		if not _actions[id].hit and float(p.action_time)>=float(data.impact):
			_actions[id].hit=true
			_impact(p,str(p.action),str(_actions[id].target))
		if float(p.action_time)>=float(p.action_duration):
			p.action="idle"
			p.action_time=0.0
			p.action_duration=0.0
	var input: Dictionary=_inputs[id]
	var direction: Vector2=input.move
	if float(state.time)-float(input.last)>0.3:direction=Vector2.ZERO
	var motion := Vector3(direction.x,0.0,direction.y)
	var speed := RUN_SPEED
	if p.action=="roll":
		motion=_actions[id].roll
		speed=6.5 if float(p.action_time)<0.65 else 0.0
	elif C.ABILITIES.has(str(p.action)):
		speed*=0.3
	else:
		p.yaw=float(input.yaw)
		p.action="run" if motion.length()>0.05 else ("combat_idle" if float(p.combat)>0.0 else "idle")
	var current := C.vector(p.pos)
	var floor_before := C.ground_y(current.x,current.z)
	var relative_height := maxf(0.0,current.y-floor_before)
	var moved := C.move_slide(current,motion*speed*dt)
	p.speed=Vector2(moved.x-current.x,moved.z-current.z).length()/dt
	if bool(input.jump) and p.grounded and not C.ABILITIES.has(str(p.action)):
		input.vertical=5.1
		p.grounded=false
	input.jump=false
	if not p.grounded:
		input.vertical-=13.5*dt
		relative_height+=float(input.vertical)*dt
		if relative_height<=0.0:
			relative_height=0.0
			input.vertical=0.0
			p.grounded=true
	moved.y+=relative_height
	p.pos=C.array(moved)

func _impact(p: Dictionary, key: String, target: String) -> void:
	if key=="ward":
		p.ward=5.0
		p.hp=minf(float(p.max_hp),float(p.hp)+35.0)
		_emit("ward","Iron Vow: 35 health restored; damage halved for 5 seconds.",int(p.id),"",C.vector(p.pos),35)
		return
	if not key in ["strike","cleave"]:return
	var data: Dictionary=C.ABILITIES[key]
	var position := C.vector(p.pos)
	var forward := Vector3(sin(float(p.yaw)),0.0,cos(float(p.yaw)))
	var hits := 0
	for e: Dictionary in state.enemies.values():
		if e.dead or (key=="strike" and str(e.id)!=target):continue
		var toward := C.vector(e.pos)-position
		toward.y=0.0
		if toward.length()>float(data.range)+0.25:continue
		if key=="cleave" and toward.length()>0.1 and forward.dot(toward.normalized())<0.15:continue
		_damage_enemy(e,p,float(data.damage)+float(p.power))
		hits+=1
	_emit(key,"" if hits>0 else "Your blade finds only air.",int(p.id),target,position,hits)

func _damage_enemy(e: Dictionary, p: Dictionary, damage: float) -> void:
	if e.dead:return
	e.hp=maxf(0.0,float(e.hp)-damage)
	p.combat=6.0
	_enemy_private[e.id].contributors[int(p.id)]=float(state.time)
	_enemy_private[e.id].target=int(p.id)
	_emit("hit","%d"%int(round(damage)),int(p.id),str(e.id),C.vector(e.pos),int(round(damage)))
	if float(e.hp)>0.0:return
	e.dead=true
	e.action="death"
	e.action_time=0.0
	e.action_duration=2.4
	e.respawn=90.0 if e.kind=="hollow_king" else 45.0
	e.attack_radius=0.0
	e.target=0
	var data: Dictionary=C.ENEMY_TYPES[e.kind]
	for contributor: int in _enemy_private[e.id].contributors:
		if not state.players.has(str(contributor)):continue
		var recipient: Dictionary=state.players[str(contributor)]
		if recipient.dead or _distance(recipient.pos,e.pos)>30.0:continue
		_award_xp(recipient,int(data.xp))
		for quest_key: String in recipient.quests:
			var quest: Dictionary=recipient.quests[quest_key]
			var definition: Dictionary=C.QUESTS[quest_key]
			if quest.state=="active" and definition.kind=="kill" and definition.target==e.kind:
				quest.progress=mini(int(definition.goal),int(quest.progress)+1)
				_emit("objective",str(definition.objective)+": %d / %d"%[int(quest.progress),int(definition.goal)],contributor,str(e.id),C.vector(e.pos),int(quest.progress))
		_drop_number+=1
		var drop_id := "spoils_%d"%_drop_number
		var item := "kings_signet" if e.kind=="hollow_king" else ("watch_coat" if e.kind=="briarborn" else "")
		state.drops[drop_id]={"id":drop_id,"pos":e.pos.duplicate(),"gold":int(data.gold),"item":item,"owner":contributor,"expires":float(state.time)+180.0}
	_emit("kill",str(e.name)+" defeated.",int(p.id),str(e.id),C.vector(e.pos),int(data.xp))

func _step_enemy(e: Dictionary, dt: float) -> void:
	var private_data: Dictionary=_enemy_private[e.id]
	var data: Dictionary=C.ENEMY_TYPES[e.kind]
	e.action_time+=dt
	if e.dead:
		e.respawn=maxf(0.0,float(e.respawn)-dt)
		if float(e.respawn)<=0.0:
			for spec: Dictionary in C.ENEMIES:
				if spec.id==e.id:
					_spawn_enemy(spec)
					break
		return
	private_data.cooldown=maxf(0.0,float(private_data.cooldown)-dt)
	var position := C.vector(e.pos)
	var origin: Vector3=private_data.origin
	var target_id := int(private_data.target)
	var target: Dictionary=state.players.get(str(target_id),{})
	if target.is_empty() or target.get("dead",true) or _distance(target.get("pos",[]),C.array(origin))>float(data.leash)+5.0:
		target={}
		target_id=0
		var nearest := float(data.aggro)
		for candidate: Dictionary in state.players.values():
			if candidate.dead:continue
			var d := _distance(e.pos,candidate.pos)
			if d<nearest and _distance(candidate.pos,C.array(origin))<=float(data.leash):
				nearest=d
				target=candidate
				target_id=int(candidate.id)
		private_data.target=target_id
	e.target=target_id
	if position.distance_to(origin)>float(data.leash)+2.0:
		target={}
		private_data.target=0
		e.target=0
	if target.is_empty():
		e.attack_radius=0.0
		if position.distance_to(origin)>0.25:
			e.action="run"
			var direction := origin-position
			direction.y=0.0
			direction=direction.normalized()
			e.yaw=atan2(direction.x,direction.z)
			e.pos=C.array(C.move_slide(position,direction*float(data.speed)*dt,0.5))
		else:e.action="idle"
		e.hp=minf(float(e.max_hp),float(e.hp)+float(e.max_hp)*0.1*dt)
		return
	target.combat=maxf(float(target.combat),1.0)
	if e.action=="windup":
		if float(e.action_time)>=float(e.action_duration):
			_enemy_impact(e,data,private_data)
			e.action="attack"
			e.action_time=0.0
			e.action_duration=0.55
			e.attack_radius=0.0
			private_data.cooldown=float(data.cooldown)
		return
	if e.action=="attack" and float(e.action_time)<float(e.action_duration):return
	var toward := C.vector(target.pos)-position
	toward.y=0.0
	if toward.length()>0.05:e.yaw=atan2(toward.x,toward.z)
	if toward.length()<=float(data.reach) and float(private_data.cooldown)<=0.0:
		e.action="windup"
		e.action_time=0.0
		e.action_duration=float(data.windup)
		var point := position+toward.normalized()*minf(1.6,toward.length())
		point.y=C.ground_y(point.x,point.z)
		private_data.attack_point=point
		e.attack_point=C.array(point)
		e.attack_radius=3.3 if e.kind=="hollow_king" else 1.45
		_emit("telegraph","",0,str(e.id),point,float(e.attack_radius))
	elif toward.length()>float(data.reach)*0.75:
		e.action="run"
		e.pos=C.array(C.move_slide(position,toward.normalized()*float(data.speed)*dt,0.5))
	else:e.action="combat_idle"

func _enemy_impact(e: Dictionary, data: Dictionary, private_data: Dictionary) -> void:
	var point: Vector3=private_data.attack_point
	for p: Dictionary in state.players.values():
		if p.dead or _distance(p.pos,C.array(point))>float(e.attack_radius):continue
		if p.action=="roll" and float(p.action_time)<0.5:
			_emit("evade","Evaded",int(p.id),str(e.id),C.vector(p.pos),0)
			continue
		var damage := maxf(1.0,float(data.damage)-float(p.armor)*0.45)
		if float(p.ward)>0.0:damage*=0.5
		p.hp=maxf(0.0,float(p.hp)-damage)
		p.combat=6.0
		_emit("hurt","-%d"%int(round(damage)),int(p.id),str(e.id),C.vector(p.pos),int(round(damage)))
		if float(p.hp)<=0.0:
			p.dead=true
			p.action="death"
			p.action_time=0.0
			p.action_duration=2.4167
			p.ward=0.0
			p.speed=0.0
			_inputs[int(p.id)].move=Vector2.ZERO
			_emit("death","The lanterns of Thornwatch call you home.",int(p.id),str(e.id),C.vector(p.pos),0)

func _award_xp(p: Dictionary, amount: int) -> void:
	if int(p.level)>=MAX_LEVEL:return
	p.xp+=maxi(0,amount)
	while int(p.level)<MAX_LEVEL and int(p.xp)>=xp_needed(int(p.level)):
		p.xp-=xp_needed(int(p.level))
		p.level+=1
		p.points+=2
		_recalculate(p)
		p.hp=p.max_hp
		p.energy=p.max_energy
		_emit("level","Level %d · 2 attribute points available"%int(p.level),int(p.id),"",C.vector(p.pos),int(p.level))
	p.next_xp=xp_needed(int(p.level))
	if int(p.level)>=MAX_LEVEL:p.xp=0

func _award_item(p: Dictionary, key: String) -> void:
	if not C.ITEMS.has(key):return
	if not key in p.inventory:p.inventory.append(key)
	else:p.gold+=maxi(1,int(C.ITEMS[key].value)/2)

func _npc(key: String) -> Dictionary:
	for npc: Dictionary in C.NPCS:
		if npc.id==key:return npc
	return {}

static func _distance(a: Variant,b: Variant) -> float:
	var aa := C.vector(a)
	var bb := C.vector(b)
	return Vector2(aa.x-bb.x,aa.z-bb.z).length()

func _emit(type: String, text: String, actor: int=0, target: String="", position: Vector3=Vector3.ZERO, value: Variant=0) -> void:
	_event_number+=1
	events.append({"id":_event_number,"type":type,"text":text,"actor":actor,"target":target,"pos":C.array(position),"value":value})
	if events.size()>128:events.pop_front()

static func _no(message: String) -> Dictionary:return {"ok":false,"message":message}
static func _yes(message: String) -> Dictionary:return {"ok":true,"message":message}

func snapshot() -> Dictionary:
	return state.duplicate(true)

func profile(id: int) -> Dictionary:
	if not state.players.has(str(id)):return {}
	var p: Dictionary=state.players[str(id)]
	var result: Dictionary={"version":SAVE_VERSION}
	for key: String in ["name","level","xp","gold","attributes","inventory","equipment","quests","potions"]:
		var value: Variant=p[key]
		result[key]=value.duplicate(true) if value is Dictionary or value is Array else value
	return result
