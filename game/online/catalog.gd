extends RefCounted
## Shared, explicit design data. Art never decides stats or server authority.

const VERSION := "0.4.0-third-person"
const ZONE := "The Blackbriar March"
const TOWN := "Thornwatch"
const PORT := 24572
const MAX_PLAYERS := 4
const WORLD_LIMIT := 103.0
const SPAWN := Vector3(0.0, 0.0, 28.0)
const HERO_MODEL := "res://assets/models/mara/mara.glb"
const HERO_SHA256 := "8ada77b97e748814283fbf3f6efe960026674c0bf4ed04776610515c70fac94d"

const ABILITIES := {
	"strike": {"name":"Swordfall", "key":"1", "icon":0, "cost":7.0, "cooldown":1.45, "duration":1.1, "impact":0.48, "range":3.0, "damage":26.0, "description":"A deliberate sword strike. Close within 3 metres of your target.", "clip":"attack"},
	"cleave": {"name":"Mooncleave", "key":"2", "icon":1, "cost":25.0, "cooldown":7.0, "duration":1.2, "impact":0.5, "range":3.8, "damage":43.0, "description":"Sweep your blade through nearby foes in a forward arc. Costs 25 resolve.", "clip":"attack"},
	"ward": {"name":"Iron Vow", "key":"3", "icon":2, "cost":30.0, "cooldown":18.0, "duration":1.4, "impact":0.55, "range":0.0, "damage":0.0, "description":"Recover 35 health and halve incoming damage for 5 seconds. Costs 30 resolve.", "clip":"cast_start"},
	"roll": {"name":"Wayfarer's Step", "key":"4", "icon":3, "cost":18.0, "cooldown":5.0, "duration":0.85, "impact":0.0, "range":0.0, "damage":0.0, "description":"Roll in your movement direction. Evade incoming blows for the first half-second.", "clip":"dodge"},
	"potion": {"name":"Rowan Draught", "key":"5", "icon":4, "cost":0.0, "cooldown":15.0, "duration":0.35, "impact":0.0, "range":0.0, "damage":0.0, "description":"Drink a carried draught to restore 65 health. Refill at Thornwatch's provisioner.", "clip":"idle"}
}
const ITEMS := {
	"travel_blade":{"name":"Wayfarer's Blade", "slot":"weapon", "rarity":"Common", "power":3, "armor":0, "vitality":0, "value":6, "icon":5, "description":"A dependable blade for uncertain roads."},
	"watch_blade":{"name":"Thornwatch Steel", "slot":"weapon", "rarity":"Uncommon", "power":8, "armor":0, "vitality":0, "value":24, "icon":5, "description":"A balanced sword awarded to a proven watcher."},
	"moon_blade":{"name":"Fang of the Hollow King", "slot":"weapon", "rarity":"Rare", "power":14, "armor":0, "vitality":2, "value":70, "icon":5, "description":"The pale edge remembers the fall of a cursed lord."},
	"travel_coat":{"name":"Wayfarer's Coat", "slot":"chest", "rarity":"Common", "power":0, "armor":3, "vitality":1, "value":8, "icon":6, "description":"Wool, linen, and weathered leather."},
	"watch_coat":{"name":"Blackbriar Hauberk", "slot":"chest", "rarity":"Uncommon", "power":0, "armor":7, "vitality":3, "value":38, "icon":6, "description":"Reinforced travel gear. Equipment bonuses are shown in the character sheet."},
	"rowan_ring":{"name":"Rowan Signet", "slot":"ring", "rarity":"Uncommon", "power":2, "armor":1, "vitality":2, "value":32, "icon":7, "description":"A small ward carved into dark silver."},
	"kings_signet":{"name":"Hollow King's Signet", "slot":"ring", "rarity":"Rare", "power":5, "armor":2, "vitality":5, "value":90, "icon":7, "description":"Proof that the woods can be made to yield."}
}
const NPCS := [
	{"id":"steward", "name":"Captain Elric", "title":"Warden of Thornwatch", "pos":[-4.5,0.0,18.0], "role":"quests"},
	{"id":"merchant", "name":"Mira Rowan", "title":"Provisioner", "pos":[9.0,0.0,25.0], "role":"merchant"},
	{"id":"keeper", "name":"Yseld", "title":"Keeper of the Old Road", "pos":[-12.0,0.0,28.0], "role":"lore"}
]
const QUESTS := {
	"road":{"name":"The Road of Teeth", "description":"Duskfangs have followed the old road to our gates. Break their pack before another traveller disappears.", "objective":"Defeat 3 duskfangs", "goal":3, "kind":"kill", "target":"duskfang", "requires":"", "xp":85, "gold":20, "item":"watch_blade"},
	"lantern":{"name":"A Light Against the Briar", "description":"The old ward-lanterns are failing. Bring back three emberblooms from the eastern wood, and we can rekindle them.", "objective":"Gather 3 emberblooms", "goal":3, "kind":"gather", "target":"emberbloom", "requires":"road", "xp":100, "gold":25, "item":"rowan_ring"},
	"crown":{"name":"The Hollow King's Due", "description":"The varcolac at the ruined watchtower was once our protector. End his curse, and return with proof that the March has a future.", "objective":"Defeat the Hollow King", "goal":1, "kind":"kill", "target":"hollow_king", "requires":"lantern", "xp":180, "gold":65, "item":"moon_blade"}
}
const ENEMY_TYPES := {
	"duskfang":{"name":"Duskfang", "level":1, "hp":85.0, "damage":12.0, "speed":2.9, "xp":26, "gold":5, "aggro":9.0, "reach":2.0, "windup":0.8, "cooldown":2.2, "leash":16.0},
	"briarborn":{"name":"Briarbound", "level":2, "hp":125.0, "damage":17.0, "speed":2.1, "xp":40, "gold":8, "aggro":9.0, "reach":2.5, "windup":1.1, "cooldown":2.8, "leash":17.0},
	"hollow_king":{"name":"The Hollow King", "level":4, "hp":440.0, "damage":32.0, "speed":2.6, "xp":115, "gold":25, "aggro":12.0, "reach":4.3, "windup":1.45, "cooldown":3.5, "leash":19.0}
}
const ENEMIES := [
	{"id":"fang_1", "kind":"duskfang", "pos":[-4.0,0.0,-12.0]},
	{"id":"fang_2", "kind":"duskfang", "pos":[7.0,0.0,-21.0]},
	{"id":"fang_3", "kind":"duskfang", "pos":[-9.0,0.0,-28.0]},
	{"id":"fang_4", "kind":"duskfang", "pos":[15.0,0.0,-37.0]},
	{"id":"briar_1", "kind":"briarborn", "pos":[30.0,0.0,-28.0]},
	{"id":"briar_2", "kind":"briarborn", "pos":[-29.0,0.0,-40.0]},
	{"id":"king", "kind":"hollow_king", "pos":[0.0,0.0,-70.0]}
]
const GATHERS := [
	{"id":"bloom_1", "pos":[23.0,0.0,-16.0]},
	{"id":"bloom_2", "pos":[34.0,0.0,-23.0]},
	{"id":"bloom_3", "pos":[25.0,0.0,-38.0]},
	{"id":"bloom_4", "pos":[40.0,0.0,-33.0]}
]
## Axis-aligned building footprints are shared with server movement collision.
const BUILDINGS := [
	{"id":"watchhall", "pos":[-14.0,0.0,17.0], "size":[10.0,8.0], "height":6.5, "kind":"hall"},
	{"id":"inn", "pos":[15.0,0.0,19.0], "size":[9.0,9.0], "height":5.0, "kind":"inn"},
	{"id":"cottage_a", "pos":[-18.0,0.0,34.0], "size":[8.0,7.0], "height":4.0, "kind":"house"},
	{"id":"cottage_b", "pos":[18.0,0.0,37.0], "size":[9.0,7.0], "height":4.8, "kind":"house"},
	{"id":"smithy", "pos":[-3.0,0.0,47.0], "size":[9.0,7.0], "height":3.6, "kind":"smithy"},
	{"id":"tower_west", "pos":[-9.0,0.0,3.0], "size":[5.5,5.5], "height":10.0, "kind":"tower"},
	{"id":"tower_east", "pos":[9.0,0.0,3.0], "size":[5.5,5.5], "height":10.0, "kind":"tower"},
	{"id":"ruin_west", "pos":[-12.0,0.0,-73.0], "size":[6.0,6.0], "height":8.0, "kind":"ruin"},
	{"id":"ruin_east", "pos":[12.0,0.0,-73.0], "size":[5.0,5.0], "height":5.0, "kind":"ruin"}
]

## Solid props are authored once, used both by server movement and camera bodies.
## The ground-level market footprint includes its table legs and awning posts.
const PROP_BLOCKERS := [
	{"id":"market_stall", "kind":"box", "pos":[9.0,0.0,28.0], "size":[3.3,2.8,1.6]},
	{"id":"gate_post_west", "kind":"box", "pos":[-5.0,0.0,3.0], "size":[0.3,5.2,0.34]},
	{"id":"gate_post_east", "kind":"box", "pos":[5.0,0.0,3.0], "size":[0.3,5.2,0.34]},
	{"id":"town_sign", "kind":"circle", "pos":[5.3,0.0,13.0], "radius":0.15, "height":2.5},
	{"id":"lamp_west", "kind":"circle", "pos":[-8.0,0.0,31.0], "radius":0.14, "height":2.9},
	{"id":"lamp_east", "kind":"circle", "pos":[7.0,0.0,31.0], "radius":0.14, "height":2.9},
	{"id":"waystone_south", "kind":"box", "pos":[-4.0,0.0,-7.0], "size":[0.75,1.55,0.3]},
	{"id":"waystone_middle", "kind":"box", "pos":[5.0,0.0,-39.0], "size":[0.75,1.55,0.3]},
	{"id":"waystone_north", "kind":"box", "pos":[-6.0,0.0,-54.0], "size":[0.75,1.55,0.3]}
]
static var _woodland: Dictionary = {}
static var _solid_props: Array = []
static var _solid_grid: Dictionary = {}

static func vector(value: Variant) -> Vector3:
	if value is Vector3:return value
	if value is Array and value.size()>=3:return Vector3(float(value[0]),float(value[1]),float(value[2]))
	return Vector3.ZERO

static func array(v: Vector3) -> Array:
	return [v.x,v.y,v.z]

static func ground_y(x: float, z: float) -> float:
	var town_blend := smoothstep(8.0,28.0,Vector2(x,z-25.0).length())
	var rolling := sin(x*0.051)*cos(z*0.047)*1.45 + sin(z*0.035)*0.75
	var banks := smoothstep(32.0,94.0,absf(x))*8.5
	return rolling*town_blend+banks

static func ground_position(x: float, z: float) -> Vector3:
	return Vector3(x,ground_y(x,z),z)

static func blocked(p: Vector3, radius: float=0.42) -> bool:
	if absf(p.x)>WORLD_LIMIT-radius or absf(p.z)>WORLD_LIMIT-radius:return true
	if _building_blocked(p,radius):return true
	_ensure_solids()
	var cell := Vector2i(floori(p.x/8.0),floori(p.z/8.0))
	for dz: int in range(-1,2):
		for dx: int in range(-1,2):
			for prop: Dictionary in _solid_grid.get(cell+Vector2i(dx,dz),[]):
				var center := vector(prop.pos)
				if str(prop.kind)=="box":
					if absf(p.x-center.x)<float(prop.size[0])*0.5+radius and absf(p.z-center.z)<float(prop.size[2])*0.5+radius:return true
				elif Vector2(p.x-center.x,p.z-center.z).length_squared()<pow(float(prop.radius)+radius,2):return true
	return false

static func _building_blocked(p: Vector3, radius: float) -> bool:
	for building: Dictionary in BUILDINGS:
		var b := vector(building.pos)
		if absf(p.x-b.x)<float(building.size[0])*0.5+radius and absf(p.z-b.z)<float(building.size[1])*0.5+radius:return true
	return false

static func _reserved(x: float, z: float, radius: float=2.5) -> bool:
	if _building_blocked(Vector3(x,0,z),radius):return true
	for group: Array in [NPCS,GATHERS,ENEMIES]:
		for point: Dictionary in group:
			if Vector2(x-float(point.pos[0]),z-float(point.pos[2])).length()<radius:return true
	return Vector2(x-SPAWN.x,z-SPAWN.z).length()<3.0

static func woodland_layout() -> Dictionary:
	if not _woodland.is_empty():return _woodland
	var rng := RandomNumberGenerator.new()
	rng.seed=729023
	var trees: Array=[]
	var rocks: Array=[]
	for i: int in range(210):
		var x := rng.randf_range(-124,124)
		var z := rng.randf_range(-137,105)
		if absf(x)<9.0 or (absf(x)<31 and z>-1 and z<60) or (absf(x)<19 and z<-57 and z>-87):continue
		if _reserved(x,z,3.0):continue
		var pine := i%4!=0
		var height := rng.randf_range(7.0,14.0) if pine else rng.randf_range(6.0,10.0)
		trees.append({"id":"tree_%d"%trees.size(),"pos":[x,0,z],"height":height,"pine":pine,"yaw":rng.randf()*TAU,"radius":height*0.023})
	for i: int in range(14):
		for side: int in [-1,1]:
			var z := -7.0-float(i)*4.5+rng.randf_range(-1,1)
			var x := float(side)*rng.randf_range(13.0,19.0)
			var height := rng.randf_range(10.0,16.0)
			var yaw := rng.randf()*TAU
			if _reserved(x,z,3.0):continue
			trees.append({"id":"tree_%d"%trees.size(),"pos":[x,0,z],"height":height,"pine":true,"yaw":yaw,"radius":height*0.023})
	for i: int in range(17):
		var side := -1.0 if i%2==0 else 1.0
		var x := side*rng.randf_range(7.0,10.5)
		var z := -8.0-float(i)*3.6
		var size := [rng.randf_range(0.8,1.6),rng.randf_range(0.4,0.9),rng.randf_range(0.7,1.3)]
		var yaw := rng.randf()*TAU
		if _reserved(x,z,2.2):continue
		rocks.append({"id":"rock_%d"%i,"pos":[x,0,z],"size":size,"yaw":yaw,"variant":i,"radius":maxf(float(size[0]),float(size[2]))*0.48})
	for i: int in range(32):
		var x := -77.0+float(i)*5.0+rng.randf_range(-1.8,1.8)
		var z := rng.randf_range(-122.0,-108.0)
		var height := rng.randf_range(11.0,17.0)
		trees.append({"id":"tree_%d"%trees.size(),"pos":[x,0,z],"height":height,"pine":true,"yaw":rng.randf()*TAU,"radius":height*0.023})
	_woodland={"trees":trees,"rocks":rocks}
	return _woodland

static func solid_props() -> Array:
	_ensure_solids()
	return _solid_props

static func _ensure_solids() -> void:
	if not _solid_props.is_empty():return
	_solid_props=PROP_BLOCKERS.duplicate(true)
	for i: int in range(8):
		var angle := float(i)/8*TAU
		_solid_props.append({"id":"obelisk_%d"%i,"kind":"circle","pos":[sin(angle)*7.0,0.0,-76.0+cos(angle)*7.0],"radius":0.43,"height":1.65})
	for building: Dictionary in BUILDINGS:
		if building.kind!="ruin":continue
		for i: int in range(5):
			_solid_props.append({"id":str(building.id)+"_rubble_%d"%i,"kind":"circle","pos":[float(building.pos[0])+(float(i)-2)*0.85,0,float(building.pos[2])+float(building.size[1])*0.5+0.4],"radius":0.48,"height":0.65})
	var layout := woodland_layout()
	for tree: Dictionary in layout.trees:
		_solid_props.append({"id":tree.id,"kind":"circle","pos":tree.pos,"radius":tree.radius,"height":float(tree.height)*0.7})
	for rock: Dictionary in layout.rocks:
		_solid_props.append({"id":rock.id,"kind":"circle","pos":rock.pos,"radius":rock.radius,"height":float(rock.size[1])})
	for prop: Dictionary in _solid_props:
		var position := vector(prop.pos)
		var cell := Vector2i(floori(position.x/8.0),floori(position.z/8.0))
		if not _solid_grid.has(cell):_solid_grid[cell]=[]
		_solid_grid[cell].append(prop)

static func move_slide(from: Vector3, displacement: Vector3, radius: float=0.42) -> Vector3:
	var result := from
	var steps := maxi(1,int(ceil(displacement.length()/0.3)))
	var step := displacement/float(steps)
	for unused: int in range(steps):
		var x := result+Vector3(step.x,0,0)
		if not blocked(x,radius):result.x=x.x
		var z := result+Vector3(0,0,step.z)
		if not blocked(z,radius):result.z=z.z
	result.y=ground_y(result.x,result.z)
	return result

static func rarity_color(rarity: String) -> Color:
	match rarity:
		"Uncommon":return Color("83b991")
		"Rare":return Color("78b7ec")
		"Legendary":return Color("e4ac58")
	return Color("d5d0bd")
