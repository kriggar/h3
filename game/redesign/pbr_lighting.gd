class_name PBRLighting
extends RefCounted
## Shared, immutable reflection radiance for original PBR assets.
## Callers retain their own backdrop, ambient light, key lights and exposure.
## Never change the returned Sky/material: it is shared across separate worlds.

const VERSION: String = "neutral-overcast-reflections-v1"
const TOP: Color = Color("89929b")
const HORIZON: Color = Color("b0afa6")
const GROUND: Color = Color("44433c")
const GROUND_HORIZON: Color = Color("7b7769")
const ENERGY: float = 0.65
const SKY_SHADER: String = """shader_type sky;
// No TIME, POSITION or LIGHT inputs. A town key light cannot rewrite a card's
// shared radiance map, and hidden previews do not need individual sky renders.
uniform vec4 top_color : source_color;
uniform vec4 horizon_color : source_color;
uniform vec4 ground_color : source_color;
uniform vec4 ground_horizon_color : source_color;
uniform float radiance_energy = 0.65;
void sky() {
    float elevation = clamp(EYEDIR.y, -1.0, 1.0);
    if (elevation >= 0.0) {
        COLOR = mix(horizon_color.rgb, top_color.rgb, pow(elevation, 0.15)) * radiance_energy;
    } else {
        COLOR = mix(ground_horizon_color.rgb, ground_color.rgb, pow(-elevation, 0.02)) * radiance_energy;
    }
}
"""

static var _reflection_sky: Sky

static func reflection_sky() -> Sky:
	# Retain one resource for the process. Repeated inventory/card replacement
	# must not allocate and destroy unrendered procedural skies; that lifetime
	# exposed leaked Compatibility textures in the tested engine previously.
	if _reflection_sky == null:
		var shader: Shader = Shader.new()
		shader.code = SKY_SHADER
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("top_color", TOP)
		material.set_shader_parameter("horizon_color", HORIZON)
		material.set_shader_parameter("ground_color", GROUND)
		material.set_shader_parameter("ground_horizon_color", GROUND_HORIZON)
		material.set_shader_parameter("radiance_energy", ENERGY)
		_reflection_sky = Sky.new()
		_reflection_sky.radiance_size = Sky.RADIANCE_SIZE_128
		_reflection_sky.process_mode = Sky.PROCESS_MODE_QUALITY
		_reflection_sky.sky_material = material
	return _reflection_sky

static func apply_reflections(environment: Environment) -> void:
	if environment == null:
		return
	environment.sky = reflection_sky()
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

static func descriptor() -> Dictionary:
	return {
		"version": VERSION, "kind": "static_neutral_gradient_sky",
		"radianceSize": 128, "processMode": "quality", "energy": ENERGY,
		"topSrgb": TOP.to_html(false), "horizonSrgb": HORIZON.to_html(false),
		"groundSrgb": GROUND.to_html(false), "groundHorizonSrgb": GROUND_HORIZON.to_html(false),
		"shaderSha256": SKY_SHADER.sha256_text(), "sceneLightDependent": false
	}
