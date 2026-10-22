extends RefCounted
## The source paintings stay intact; reviewed regions become native AtlasTextures.

const ROOT: String = "res://assets/ui/manuscript/"
const BUILDING_ATLAS: String = ROOT+"buildings.png"
const BUILDING_ATLAS_SHA256: String = "f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be"
const ABILITY_ROOT: String = "res://assets/ui/abilities/"
const BUILDINGS: Array[String] = ["granary","barracks","market","smithy","shrine","palisade","wharf","water_gate"]
const SYMBOLS: Array[String] = ["gold","wood","ore","food","sword","oaths","realm","expedition","rest","watch","ward","roots","hood","coat","boots","jewellery"]
const EQUIPMENT: Array[String] = ["head","chest","hands","legs","feet","cloak","main_hand","off_hand","amulet","ring","rune_cinder","rune_stone","rune_gale","gem_amber","cleave","ember"]
static var _cache: Dictionary = {}

static func region(path: String, rect: Rect2) -> Texture2D:
	var key: String = path+str(rect)
	if not _cache.has(key):
		var texture: AtlasTexture = AtlasTexture.new()
		texture.atlas = load(path)
		texture.region = rect
		texture.filter_clip = true
		_cache[key] = texture
	return _cache[key]

static func cell(file: String, index: int, columns: int, rows: int) -> Texture2D:
	var path: String = ROOT+file+".png"
	var source: Texture2D = load(path)
	var step: Vector2 = source.get_size()/Vector2(columns,rows)
	# The atlas dimensions need not be multiples of the grid. Use proportional
	# boundaries, not integer crops, so the last row and column remain complete.
	return region(path,Rect2(Vector2(index%columns,index/columns)*step,step))

static func building(id: String) -> Texture2D:
	# The original painting is the visual brief. Blender models must be rebuilt
	# to match it; neither a model render nor a hover viewport replaces this art.
	var index: int = BUILDINGS.find(id)
	return null if index < 0 else cell("buildings",index,4,2)

static func ability(id: String) -> Texture2D:
	if id not in ["cleave", "ward", "ember", "roots"]:
		return null
	var path: String = ABILITY_ROOT+id+".png"
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]

static func symbol(id: String) -> Texture2D:
	return cell("symbols",maxi(0,SYMBOLS.find(id)),4,4)

static func equipment(slot: String) -> Texture2D:
	var key: String = "ring" if slot.begins_with("ring") else slot
	return cell("equipment",maxi(0,EQUIPMENT.find(key)),4,4)

static func item(data: Dictionary) -> Texture2D:
	var id: String = str(data.get("itemId",""))
	if id.begins_with("rune_") or id.begins_with("gem_"):
		return equipment(id)
	return equipment(str(data.get("slot","main_hand")))

static func portrait() -> Texture2D:
	# Only this hands-free source region passed anatomy review.
	return region("res://assets/generated/manuscript-portraits.png",Rect2(738,700,342,234))

static func crest() -> Texture2D:
	return region(ROOT+"folio.png",Rect2(657,0,220,224))
