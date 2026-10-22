shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D packed_dirt_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D meadow_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D pebble_gravel_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D forest_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float packed_dirt_tile_metres = 1.8;
uniform float meadow_tile_metres = 1.1;
uniform float pebble_gravel_tile_metres = 0.75;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float broad_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), f.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = world_position.xz;
	float irregularity = broad_noise(p * 0.24) - 0.5;
	float centreline = sin(p.y * 0.055) * 1.6;
	float road_distance = abs(p.x - centreline);
	float road = 1.0 - smoothstep(2.1, 4.8, road_distance + irregularity * 1.1);
	float town_distance = length(p - vec2(0.0, 26.0));
	float square = 1.0 - smoothstep(4.0, 9.5, town_distance + irregularity * 1.0);
	float soil_area = max(road, square);

	// Small gravel occupies the village's cross paths; its edges soften into
	// packed soil and meadow instead of forming a painted rectangular strip.
	float town_cross = (1.0 - smoothstep(0.85, 2.0, abs(p.y - 26.0) + irregularity * 0.6))
		* (1.0 - smoothstep(16.0, 22.0, abs(p.x)));
	float hall_walk = (1.0 - smoothstep(0.65, 1.7, abs(p.y - 22.0) + irregularity * 0.5))
		* (1.0 - smoothstep(5.5, 9.0, abs(p.x + 12.0)));
	float market = 1.0 - smoothstep(1.1, 2.8, length(p - vec2(9.0, 25.0)) + irregularity * 0.7);
	float gravel_area = max(town_cross, max(hall_walk, market));
	soil_area = max(soil_area, gravel_area);

	// Preserve darker woodland litter farther from the meadow verges.
	float verge = max(1.0 - smoothstep(8.0, 24.0, road_distance),
		1.0 - smoothstep(22.0, 49.0, town_distance));
	vec3 meadow = texture(meadow_tex, p / meadow_tile_metres).rgb;
	vec3 dirt = texture(packed_dirt_tex, p / packed_dirt_tile_metres).rgb;
	vec3 gravel = texture(pebble_gravel_tex, p / pebble_gravel_tile_metres).rgb;
	vec3 leaves = texture(forest_tex, p * 0.21).rgb;
	float litter_grey = dot(leaves, vec3(0.299, 0.587, 0.114));
	vec3 forest = mix(vec3(litter_grey), leaves, 0.22) * vec3(0.37, 0.44, 0.31);
	vec3 living_ground = mix(forest, meadow * 0.88, verge);
	vec3 travelled_ground = mix(dirt * vec3(0.85, 0.82, 0.75), gravel * 0.82, gravel_area);
	float broad_variation = mix(0.92, 1.04, broad_noise(p * 0.055 + vec2(11.7, 3.1)));
	ALBEDO = mix(living_ground, travelled_ground, clamp(soil_area, 0.0, 1.0)) * broad_variation;
	// These scalar values are art direction, not scanned material properties.
	ROUGHNESS = mix(0.98, 0.93, soil_area);
	METALLIC = 0.0;
}
