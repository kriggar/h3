extends SceneTree
const Realm=preload("res://game/online/realm.gd")
const C=preload("res://game/online/catalog.gd")
var checks := 0
var failures: Array[String]=[]

func _init() -> void:
	call_deferred("_run")

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures.append(message)
		push_error("FAIL: "+message)

func near(a: float,b: float,tolerance: float=0.01) -> bool:return absf(a-b)<=tolerance

func step(realm: RefCounted,seconds: float) -> void:
	for unused: int in range(int(ceil(seconds*60.0))):realm.step(1.0/60.0)

func place(p: Dictionary,x: float,z: float) -> void:
	p.pos=C.array(C.ground_position(x,z))

func fresh() -> RefCounted:
	var realm: RefCounted=Realm.new()
	realm.add_player(1,"Mara")
	return realm

func _run() -> void:
	_identity_and_profiles()
	_movement()
	_combat_commitment()
	_quest_and_loot()
	_guard_and_respawn()
	_boss_and_shared_credit()
	_chat()
	var report := {"suite":"authoritative_realm","checks":checks,"passed":failures.is_empty(),"failures":failures}
	print(JSON.stringify(report))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			var file := FileAccess.open(arg.trim_prefix("--report="),FileAccess.WRITE)
			if file!=null:file.store_string(JSON.stringify(report,"\t"))
	quit(0 if failures.is_empty() else 1)

func _identity_and_profiles() -> void:
	var realm := fresh()
	var p: Dictionary=realm.state.players["1"]
	check(p.name=="Mara","Valid player name retained")
	check(realm.add_player(1,"Intruder").is_empty(),"Duplicate player IDs rejected")
	check(realm.add_player(-1,"Invalid").is_empty(),"Negative peer ID rejected")
	check(Realm.clean_name("<img>\n  ")=="img","Name sanitization removes control and markup characters")
	for id: int in range(2,5):check(not realm.add_player(id,"Traveller").is_empty(),"Four players supported")
	check(realm.add_player(5,"Overflow").is_empty(),"Fifth player rejected")
	check(near(float(p.max_hp),180.0),"Base health derives from attributes and coat")
	var snap: Dictionary=realm.snapshot()
	snap.players["1"].gold=9999
	check(int(p.gold)==18,"Snapshot does not alias authority")
	var profile: Dictionary=realm.profile(1)
	profile.attributes.might=999
	check(p.attributes.might==5,"Profile extraction does not alias authority")
	var malicious := {"level":99999,"xp":INF,"gold":-8,"hp":999999,"attributes":{"might":999999,"vitality":999999,"spirit":NAN},"inventory":["admin_sword",{},"moon_blade","moon_blade"],"equipment":{"weapon":"admin_sword","chest":"moon_blade"},"quests":{"crown":{"state":"complete","progress":100}},"potions":-8,"pos":[999999,0,999999]}
	realm.remove_player(4)
	var q: Dictionary=realm.add_player(4,"Reload",malicious)
	check(q.level==20,"Loaded level bounded")
	check(q.gold==0 and q.potions==0,"Loaded money and consumables bounded")
	check(q.attributes.might+q.attributes.vitality+q.attributes.spirit<=15+38,"Loaded attribute points cannot exceed earned budget")
	check(not "admin_sword" in q.inventory and q.inventory.count("moon_blade")==1,"Invalid and duplicate inventory entries removed")
	check(q.equipment.weapon=="travel_blade" and q.equipment.chest=="travel_coat","Wrong slot/unowned saved equipment rejected")
	check(q.quests.is_empty(),"Broken saved quest prerequisite chain rejected")
	check(C.vector(q.pos).distance_to(C.SPAWN)<0.1,"Saved teleport positions ignored")
	check(q.hp==q.max_hp and q.max_hp<1000,"Saved health cannot override derived stats")
	check(not realm.act(999,{"type":"ability","id":"strike"}).ok,"Unknown peer cannot act")

func _movement() -> void:
	var realm := fresh()
	var p: Dictionary=realm.state.players["1"]
	var start := C.vector(p.pos)
	for unused: int in range(60):
		realm.input_player(1,{"move":[1.0,1.0],"yaw":0.4,"jump":false})
		realm.step(1.0/60.0)
	check(near(Vector2(C.vector(p.pos).x-start.x,C.vector(p.pos).z-start.z).length(),Realm.RUN_SPEED,0.02),"Diagonal movement normalized to run speed")
	var before := C.vector(p.pos)
	step(realm,2.0)
	check(C.vector(p.pos).distance_to(before)<1.6,"Lost input stops movement within timeout")
	before=C.vector(p.pos)
	realm.input_player(1,{"move":[NAN,0.0],"yaw":0.0})
	realm.input_player(1,{"move":[100000.0,0.0],"yaw":0.0})
	realm.input_player(1,{"move":[0.0,1.0],"yaw":INF})
	step(realm,0.5)
	check(C.vector(p.pos).is_finite() and C.vector(p.pos).distance_to(before)<0.01,"Non-finite and forged oversized input cannot move player")
	place(p,-22.0,17.0)
	for unused: int in range(180):
		realm.input_player(1,{"move":[1.0,0.0],"yaw":PI/2,"jump":false})
		realm.step(1.0/60.0)
	check(float(p.pos[0])<=-19.40 and float(p.pos[0])>=-19.6,"Server collision stops at watchhall wall")
	check(not C.blocked(C.vector(p.pos)),"Collision does not leave actor inside a building")
	place(p,102.4,80.0)
	for unused: int in range(60):
		realm.input_player(1,{"move":[1.0,0.0],"yaw":PI/2,"jump":false})
		realm.step(1.0/60.0)
	check(float(p.pos[0])<=102.59,"World boundary prevents leaving authored terrain")
	place(p,0.0,28.0)
	realm.input_player(1,{"move":[0.0,0.0],"yaw":PI,"jump":true})
	realm.step(1.0/60.0)
	check(not p.grounded and float(p.pos[1])>0.0,"Jump is simulated by server")
	step(realm,1.5)
	check(p.grounded and near(float(p.pos[1]),C.ground_y(0.0,28.0)),"Jump returns precisely to terrain")
	var tick: int=realm.state.tick
	realm.step(NAN)
	realm.step(-1)
	check(realm.state.tick==tick,"Invalid simulation deltas ignored")

func _combat_commitment() -> void:
	var realm := fresh()
	var p: Dictionary=realm.state.players["1"]
	var enemy: Dictionary=realm.state.enemies.fang_1
	var energy: float=p.energy
	check(not realm.act(1,{"type":"ability","id":"strike","target":"fang_1"}).ok,"Out of range attack rejected")
	check(p.energy==energy and p.cooldowns.is_empty(),"Failed attack spends no resource or cooldown")
	check(not realm.act(1,{"type":"ability","id":"nonexistent"}).ok,"Unknown ability rejected")
	check(not realm.act(1,{"type":"ability","id":"strike","target":{}}).ok,"Non-string target rejected")
	place(p,-4.0,-10.0)
	var hp: float=enemy.hp
	check(realm.act(1,{"type":"ability","id":"strike","target":"fang_1"}).ok,"Valid melee strike accepted")
	check(not realm.act(1,{"type":"ability","id":"strike","target":"fang_1"}).ok,"Repeated ability cannot bypass action commitment")
	step(realm,0.4)
	check(enemy.hp==hp,"Damage waits for authored contact phase")
	step(realm,0.15)
	check(near(hp-float(enemy.hp),33.0),"One authoritative strike applies one derived damage amount")
	var after: float=enemy.hp
	step(realm,0.8)
	check(enemy.hp==after,"Animation recovery cannot apply damage again")
	check(not realm.act(1,{"type":"ability","id":"strike","target":"fang_1"}).ok,"Cooldown remains independent of visual recovery")
	step(realm,0.2)
	check(realm.act(1,{"type":"ability","id":"strike","target":"fang_1"}).ok,"Cooldown expires normally")
	step(realm,1.5)
	var r: Dictionary=realm.act(1,{"type":"ability","id":"strike","target":"fang_1"})
	check(r.ok,"Third finishing blow accepted")
	step(realm,0.6)
	check(enemy.dead and enemy.hp==0.0,"Enemy death is authoritative")
	check(p.xp==26,"Kill awards XP once")
	check(realm.state.drops.size()==1,"Kill creates one owner-bound spoils pile")
	var xp: int=p.xp
	check(not realm.act(1,{"type":"ability","id":"strike","target":"fang_1"}).ok,"Cannot attack dead enemy for more rewards")
	step(realm,2.0)
	check(p.xp==xp and realm.state.drops.size()==1,"Dead enemy produces no repeat awards")
	var drop: Dictionary=realm.state.drops.values()[0]
	realm.add_player(2,"Guest")
	realm.state.players["2"].pos=p.pos.duplicate()
	check(not realm.act(2,{"type":"loot","id":drop.id}).ok,"Other player cannot steal personal loot")
	var gold: int=p.gold
	check(realm.act(1,{"type":"loot","id":drop.id}).ok,"Owner can claim nearby loot")
	check(p.gold==gold+5,"Claim adds exact gold reward")
	check(not realm.act(1,{"type":"loot","id":drop.id}).ok and p.gold==gold+5,"Repeated loot request cannot duplicate rewards")
	step(realm,46.0)
	check(not realm.state.enemies.fang_1.dead,"Enemies respawn for repeatable shared-world play")
	check(p.xp==xp,"Respawn itself awards no XP")

func _quest_and_loot() -> void:
	var realm := fresh()
	var p: Dictionary=realm.state.players["1"]
	check(not realm.act(1,{"type":"quest","id":"road"}).ok,"Quest cannot be remotely accepted")
	place(p,-4.5,18.0)
	check(not realm.act(1,{"type":"quest","id":"crown"}).ok,"Quest prerequisites enforced")
	check(realm.act(1,{"type":"quest","id":"road"}).ok,"Road quest accepts at steward")
	check(not realm.act(1,{"type":"quest","id":"road"}).ok,"Unfinished quest cannot grant reward")
	for key: String in ["fang_1","fang_2","fang_3"]:
		var e: Dictionary=realm.state.enemies[key]
		place(p,float(e.pos[0]),float(e.pos[2])+1.8)
		for unused: int in range(3):
			realm.act(1,{"type":"ability","id":"strike","target":key})
			step(realm,1.5)
		check(e.dead,"Quest target killed through real action timeline: "+key)
	check(p.quests.road.progress==3,"Three kills complete objective exactly")
	place(p,-4.5,18.0)
	check(realm.act(1,{"type":"quest","id":"road"}).ok,"Completed road quest pays at steward")
	check(p.quests.road.state=="complete" and "watch_blade" in p.inventory,"Turn-in commits completion and equipment")
	check(p.level==2 and p.points==2,"Quest chain advances level with spendable attributes")
	var gold: int=p.gold
	check(not realm.act(1,{"type":"quest","id":"road"}).ok and p.gold==gold,"Quest reward replay rejected")
	step(realm,7.0)
	var power: float=p.power
	check(realm.act(1,{"type":"equip","id":"watch_blade"}).ok and float(p.power)>power,"Owned equipment changes derived combat power")
	check(not realm.act(1,{"type":"equip","id":"moon_blade"}).ok,"Unowned gear cannot be equipped")
	var old_might: int=p.attributes.might
	check(realm.act(1,{"type":"attribute","id":"might"}).ok and p.attributes.might==old_might+1 and p.points==1,"Attribute purchase spends one earned point")
	check(not realm.act(1,{"type":"attribute","id":"admin"}).ok,"Unknown attribute cannot be allocated")
	check(realm.act(1,{"type":"quest","id":"lantern"}).ok,"Second chapter unlocks after first turn-in")
	for key: String in ["bloom_1","bloom_2","bloom_3"]:
		p.pos=realm.state.gathers[key].pos.duplicate()
		check(realm.act(1,{"type":"gather","id":key}).ok,"Gather node contributes objective: "+key)
		check(not realm.act(1,{"type":"gather","id":key}).ok,"Gather claim replay rejected: "+key)
	check(p.quests.lantern.progress==3,"Three distinct gathering claims recorded")
	place(p,-4.5,18.0)
	check(realm.act(1,{"type":"quest","id":"lantern"}).ok,"Gathering quest pays on return")
	check(p.level==3 and p.points==3 and "rowan_ring" in p.inventory,"Second chapter grants level and ring")
	check(realm.act(1,{"type":"quest","id":"crown"}).ok,"Final chapter becomes available")
	check(not realm.act(1,{"type":"buy","id":"potion"}).ok,"Merchant purchase requires physical proximity")
	place(p,9.0,25.0)
	step(realm,7.0)
	var potions: int=p.potions
	gold=p.gold
	check(realm.act(1,{"type":"buy","id":"potion"}).ok and p.potions==potions+1 and p.gold==gold-8,"Merchant transaction spends money and awards consumable atomically")
	check(not realm.act(1,{"type":"buy","id":"moon_blade"}).ok,"Cannot buy items outside merchant stock")
	var saved: Dictionary=realm.profile(1)
	var restored: RefCounted=Realm.new()
	var q: Dictionary=restored.add_player(1,"Mara",JSON.parse_string(JSON.stringify(saved)))
	check(q.level==p.level and q.xp==p.xp and q.gold==p.gold and q.potions==p.potions,"JSON profile roundtrip preserves progression")
	check(q.attributes==p.attributes and q.inventory==p.inventory and q.equipment==p.equipment and q.quests==p.quests,"JSON profile preserves allocations, ownership, equipment, quest progress")
	check(q.cooldowns.is_empty() and not q.dead and C.vector(q.pos).distance_to(C.SPAWN)<0.1,"Reconnect enters safe town without stale combat state")

func _guard_and_respawn() -> void:
	var realm := fresh()
	var p: Dictionary=realm.state.players["1"]
	check(not realm.act(1,{"type":"ability","id":"potion"}).ok and p.potions==3,"Full-health potion cannot be wasted")
	p.hp=50.0
	check(realm.act(1,{"type":"ability","id":"potion"}).ok and p.potions==2 and p.hp==115.0,"Potion restores actual bounded health")
	step(realm,0.5)
	check(realm.act(1,{"type":"ability","id":"ward"}).ok,"Ward starts valid cast")
	check(p.ward==0.0,"Ward waits for cast impact")
	step(realm,0.6)
	check(p.ward>4.9 and p.hp>145.0,"Ward commitment restores health and starts protection")
	step(realm,6.0)
	check(p.ward==0.0,"Ward expires on server clock")
	place(p,-4.0,-10.7)
	step(realm,0.1)
	var e: Dictionary=realm.state.enemies.fang_1
	check(e.action=="windup" and e.attack_radius>0.0,"Enemy telegraph exposes exact server danger region")
	realm.input_player(1,{"move":[0.0,1.0],"yaw":0.0,"jump":false})
	var hp: float=p.hp
	check(realm.act(1,{"type":"ability","id":"roll"}).ok,"Roll starts from current movement direction")
	step(realm,0.9)
	check(p.hp==hp,"Repositioning out of telegraph avoids the blow")
	place(p,-4.0,-10.7)
	p.hp=1.0
	step(realm,4.0)
	check(p.dead and p.action=="death","Lethal enemy hit enters authoritative death state")
	check(not realm.act(1,{"type":"quest","id":"road"}).ok,"Dead actors cannot act")
	step(realm,3.0)
	check(realm.act(1,{"type":"respawn"}).ok,"Defeated player can return to town")
	check(not p.dead and p.hp==p.max_hp and C.vector(p.pos).distance_to(C.SPAWN)<0.1,"Respawn resets health and location safely")
	var energy: float=p.energy
	p.energy=0.0
	check(not realm.act(1,{"type":"ability","id":"cleave"}).ok,"Insufficient resolve rejects ability")
	p.energy=energy
	for unused: int in range(200):realm._emit("test","bounded")
	check(realm.events.size()==128,"Outgoing event queue is bounded")

func _boss_and_shared_credit() -> void:
	var realm: RefCounted=Realm.new()
	var advanced := {"level":3,"xp":0,"attributes":{"might":7,"vitality":6,"spirit":6},"inventory":["travel_blade","travel_coat","watch_blade","rowan_ring"],"equipment":{"weapon":"watch_blade","chest":"travel_coat","ring":"rowan_ring"},"quests":{"road":{"state":"complete","progress":3},"lantern":{"state":"complete","progress":3}}}
	var a: Dictionary=realm.add_player(1,"Mara",advanced)
	var b: Dictionary=realm.add_player(2,"Ally",advanced)
	var gone: Dictionary=realm.add_player(3,"Departing",advanced)
	for p: Dictionary in [a,b,gone]:
		place(p,-4.5,18.0)
		check(realm.act(int(p.id),{"type":"quest","id":"crown"}).ok,"Final quest accepts for eligible contributor")
	place(a,-1.0,-67.5)
	place(b,1.0,-67.5)
	place(gone,0.0,28.0)
	step(realm,0.1)
	var boss: Dictionary=realm.state.enemies.king
	check(boss.action=="windup","Named elite starts a visible windup")
	var locked: Array=boss.attack_point.duplicate()
	var hp_a: float=a.hp
	var hp_b: float=b.hp
	place(a,8.0,-67.5)
	step(realm,0.7)
	check(boss.attack_point==locked,"Boss windup keeps the telegraphed impact point when its target moves")
	step(realm,0.9)
	check(a.hp==hp_a and b.hp<hp_b,"Telegraphed strike damages actors still in the region and misses those who left")
	place(a,-1.0,-67.5)
	place(gone,0.0,-67.5)
	check(realm.act(3,{"type":"ability","id":"strike","target":"king"}).ok,"Third player can contribute before leaving")
	step(realm,0.6)
	check(float(boss.hp)<float(boss.max_hp),"Departing contribution was an actual committed hit")
	var departed_xp: int=gone.xp
	realm.remove_player(3)
	for unused: int in range(12):
		if boss.dead:break
		realm.act(1,{"type":"ability","id":"strike","target":"king"})
		realm.act(2,{"type":"ability","id":"strike","target":"king"})
		step(realm,1.5)
	check(boss.dead and not a.dead and not b.dead,"Two appropriately equipped adventurers can defeat the elite through normal abilities")
	check(a.xp==115 and b.xp==115,"Both living nearby contributors receive one kill award")
	check(a.quests.crown.progress==1 and b.quests.crown.progress==1,"Both contributors receive final quest kill credit")
	check(gone.xp==departed_xp,"Disconnected contributor receives no future phantom reward")
	check(realm.state.drops.size()==2,"Boss creates one personal loot claim for each eligible contributor")
	for drop: Dictionary in realm.state.drops.values().duplicate():
		var owner: int=drop.owner
		var p: Dictionary=realm.state.players[str(owner)]
		p.pos=drop.pos.duplicate()
		check(realm.act(owner,{"type":"loot","id":drop.id}).ok,"Each contributor can claim their own boss spoils")
		check("kings_signet" in p.inventory,"Boss spoils grant guaranteed rare ring")
	place(a,-4.5,18.0)
	check(realm.act(1,{"type":"quest","id":"crown"}).ok,"Final quest turns in at captain")
	check(a.quests.crown.state=="complete" and "moon_blade" in a.inventory,"Final turn-in grants sword and commits campaign completion")
	check(a.level==4 and a.points==2,"Final reward crosses level threshold and grants points")
	var final_gold: int=a.gold
	check(not realm.act(1,{"type":"quest","id":"crown"}).ok and a.gold==final_gold,"Final quest cannot be claimed repeatedly")
	var reloaded: RefCounted=Realm.new()
	var restored: Dictionary=reloaded.add_player(1,"Mara",JSON.parse_string(JSON.stringify(realm.profile(1))))
	check(restored.quests==a.quests and restored.inventory==a.inventory and restored.level==a.level and restored.gold==a.gold,"Entire three-chapter campaign and boss loot survive JSON profile reload")

func _chat() -> void:
	var realm := fresh()
	check(not realm.act(1,{"type":"chat","text":{}}).ok,"Chat requires plain text")
	check(not realm.act(1,{"type":"chat","text":"x".repeat(161)}).ok,"Chat length bounded before broadcast")
	check(not realm.act(1,{"type":"chat","text":"\n\r\t"}).ok,"Control-only chat rejected")
	check(realm.act(1,{"type":"chat","text":"Hello\nrealm\u202e"}).ok,"Valid chat accepted with control characters stripped")
	var event: Dictionary=realm.events[-1]
	check(event.type=="chat" and event.text=="Mara: Hellorealm","Chat records validated identity and strips controls")
	check(realm.act(1,{"type":"chat","text":"A second message"}).ok,"Two brief chat messages permitted")
	check(not realm.act(1,{"type":"chat","text":"Spam"}).ok,"Third chat message in one second rate-limited")
	step(realm,1.1)
	check(realm.act(1,{"type":"chat","text":"The next message"}).ok,"Chat rate budget replenishes on server clock")
