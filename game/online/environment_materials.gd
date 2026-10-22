extends RefCounted
## Photo-referenced colour surfaces. Tiling and roughness are authored choices,
## not measurements recovered from a single photograph. No fabricated normal,
## height, ambient-occlusion or roughness maps are attached to these textures.
const FILTER = preload("res://game/online/avatar.gd")
const TERRAIN_SHADER = preload("res://game/online/terrain_blend.gdshader")
const BASE := "res://assets/online/terrain/"
const SURFACES := {
	"packed_dirt":{"file":"packed_dirt_albedo.png","tile_metres":1.8,"role":"Packed soil in road centres and the village square"},
	"cracked_stone":{"file":"cracked_stone_albedo.png","tile_metres":1.2,"role":"Weathered mineral faces on old ruins, waystones and rubble"},
	"meadow":{"file":"meadow_albedo.png","tile_metres":1.1,"role":"Clover and dry grass on verges and village ground"},
	"pebble_gravel":{"file":"pebble_gravel_albedo.png","tile_metres":0.75,"role":"Small aggregate along village footpaths"}
}
static var _textures: Dictionary = {}
static var _terrain: ShaderMaterial
static var _stone: StandardMaterial3D

static func texture(surface: String) -> Texture2D:
	if _textures.has(surface):return _textures[surface]
	var path := BASE+str(SURFACES[surface].file)
	var source := load(path) as Texture2D
	if source==null:
		push_error("Required photographic environment texture is missing: "+path)
		return null
	_textures[surface]=FILTER._filtered(source)
	return _textures[surface]

static func terrain() -> ShaderMaterial:
	if _terrain!=null:return _terrain
	_terrain=ShaderMaterial.new()
	_terrain.resource_name="BlackbriarPhotoGround"
	_terrain.shader=TERRAIN_SHADER
	for surface: String in ["packed_dirt","meadow","pebble_gravel"]:
		_terrain.set_shader_parameter(surface+"_tex",texture(surface))
		_terrain.set_shader_parameter(surface+"_tile_metres",float(SURFACES[surface].tile_metres))
	_terrain.set_shader_parameter("forest_tex",FILTER._filtered(load("res://assets/models/materials/forrest_ground_01/albedo.jpg")))
	return _terrain

static func weathered_stone() -> StandardMaterial3D:
	if _stone!=null:return _stone
	_stone=StandardMaterial3D.new()
	_stone.resource_name="PhotoReferencedWeatheredMineral"
	_stone.albedo_texture=texture("cracked_stone")
	_stone.albedo_color=Color("c7c7bf")
	_stone.roughness=0.96
	_stone.metallic=0.0
	_stone.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_stone.texture_repeat=true
	_stone.uv1_triplanar=true
	_stone.uv1_world_triplanar=true
	_stone.uv1_triplanar_sharpness=6.0
	_stone.uv1_scale=Vector3.ONE/float(SURFACES.cracked_stone.tile_metres)
	return _stone
