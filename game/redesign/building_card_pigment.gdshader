shader_type canvas_item;
render_mode unshaded;

// Presentation only: no UV displacement, silhouette expansion or hue remap.
uniform float pigment_steps = 16.0;
uniform float ink_strength : hint_range(0.0,0.4) = 0.12;
uniform float pigment_strength : hint_range(0.0,0.5) = 0.16;
uniform float grain_strength : hint_range(0.0,0.03) = 0.006;

float luminance(vec3 color) { return dot(color,vec3(0.2126,0.7152,0.0722)); }

void fragment() {
	vec4 source = texture(TEXTURE,UV);
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	vec4 left = texture(TEXTURE,UV-vec2(pixel.x,0.0));
	vec4 right = texture(TEXTURE,UV+vec2(pixel.x,0.0));
	vec4 up = texture(TEXTURE,UV-vec2(0.0,pixel.y));
	vec4 down = texture(TEXTURE,UV+vec2(0.0,pixel.y));
	float light = luminance(source.rgb);
	float edge = clamp(abs(luminance(left.rgb)-luminance(right.rgb))+abs(luminance(up.rgb)-luminance(down.rgb)),0.0,1.0);
	float inner_edge = 1.0-min(min(left.a,right.a),min(up.a,down.a));
	float quantized = floor(light*pigment_steps+0.5)/pigment_steps;
	float pigment = mix(light,quantized,pigment_strength)/max(light,0.001);
	vec2 cell = floor(UV/pixel);
	float grain = fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453)-0.5;
	vec3 color = source.rgb*pigment*(1.0-ink_strength*max(edge,inner_edge));
	color *= 1.0+grain*grain_strength;
	COLOR = vec4(clamp(color,vec3(0.0),vec3(1.0)),source.a);
}
