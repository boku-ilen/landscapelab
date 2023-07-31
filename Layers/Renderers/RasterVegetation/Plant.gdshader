shader_type spatial;
render_mode cull_disabled;

uniform sampler2D test_texture  : source_color, repeat_disable;




uniform sampler2DArray texture_map : source_color, repeat_disable;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D specular_map : hint_default_black;

uniform int sprite_size = 2048;

uniform float amplitude = 0.1;
uniform vec2 speed = vec2(0.5, 0.4);
uniform vec2 scale = vec2(0.06, 0.11);

uniform vec2 heightmap_size = vec2(300.0, 300.0);
uniform vec2 offset;

uniform float max_distance;
uniform bool camera_facing;
uniform bool billboard_enabled = false;

uniform float fake_shadow_height = 1.2;
uniform float fake_shadow_min_multiplier = 0.25;

varying vec3 worldpos;
varying vec3 camera_pos;

varying float size;
varying float row;
varying float dist_id;


// Workaround for a bug in `texelFetch` - use this instead!
// More info at https://github.com/godotengine/godot/issues/31732
vec4 texelGet ( sampler2D tg_tex, ivec2 tg_coord, int tg_lod ) {
	vec2 tg_texel = 1.0 / vec2(textureSize(tg_tex, 0));
	vec2 tg_getpos = (vec2(tg_coord) * tg_texel) + (tg_texel * 0.5);
	return texture(tg_tex, tg_getpos, float(tg_lod));
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void vertex() {
	camera_pos = INV_VIEW_MATRIX[3].xyz;

	worldpos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	vec2 pos = worldpos.xz;

	// Add some noise to the land-use position to get better fading
	pos += vec2(rand(pos) - 0.5, rand(pos + vec2(0.01, 0.01)) - 0.5) * 4.0;

	pos += offset;

	pos += 0.5 * heightmap_size;
	pos /= heightmap_size;

	// Move the upper vertices around for a wind wave effect
	if (VERTEX.y > 0.3) {
		VERTEX.x += amplitude * sin(worldpos.x * scale.x * 0.75 + TIME * speed.x) * cos(worldpos.z * scale.x + TIME * speed.x * 0.25);
		VERTEX.z += amplitude * sin(worldpos.x * scale.y + TIME * speed.y * 0.35) * cos(worldpos.z * scale.y * 0.80 + TIME * speed.y);
	}

	// Scale by the size
	size = INSTANCE_CUSTOM.r * 40.0;
	VERTEX *= size;

	// Update the world position again with the scaled Vertex (otherwise the distance fade-out is off)
	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Billboarding
	if (camera_facing && billboard_enabled) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],MODEL_MATRIX[1],
				vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz,MODEL_MATRIX[1].xyz)), 0.0),MODEL_MATRIX[3]);
	}

	dist_id = INSTANCE_CUSTOM.g * 255.0;
	row = INSTANCE_CUSTOM.b * 255.0;
}

void fragment() {
	// Make the plant transparent if it's between 3/4 and 4/4 of the possible
	//  distance from the camera, to prevent a harsh cutoff from full vegetation
	//  to no vegetation.
	// Checkerboard transparency is used to prevent issues with depth sorting.
	// The matrix was adapted from:
	// https://digitalrune.github.io/DigitalRune-Documentation/html/fa431d48-b457-4c70-a590-d44b0840ab1e.htm
	float thresholdMatrix[16] = {
		1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
		13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
		4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
		16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
	};

	int x_index = int(SCREEN_UV.x * VIEWPORT_SIZE.x) % 4;
	int y_index = int(SCREEN_UV.y * VIEWPORT_SIZE.y) % 4;

	float blend_start_distance = max_distance - max_distance / 8.0;
	float dist = length(camera_pos.xz - worldpos.xz);

	float dist_alpha = (max_distance - dist) / (max_distance - blend_start_distance);

	if (dist_alpha - thresholdMatrix[y_index * 4 + x_index] < 0.0) {
		discard;
	}

	// Get the color from the right sprite in the spritesheet
	ivec2 sheet_size = textureSize(texture_map, 0).xy;
	ivec2 cols_rows = sheet_size / sprite_size;

	vec2 scaled_uv = UV / (vec2(sheet_size) / float(sprite_size));
	vec2 uv_offset = vec2(0.0, row / float(cols_rows.y));

	vec4 color = textureLod(texture_map, vec3(scaled_uv + uv_offset, dist_id), length(camera_pos - worldpos) * 0.135 * (1.0 / size));
//	vec4 color = texture(test_texture, UV);

	// Alpha Scissoring
	if (color.a < 0.3) {
		discard;
	}
	
//	ALPHA_HASH_SCALE = 2.0;
	
	// Vary the transmission based on how bright and/or green the plant is here
	// (This is to approximate a higher transmission for leaves)
	BACKLIGHT = vec3(1.0) * min(color.g * 2.0, 1.0);
	
	// Make the plant darker at the bottom to simulate some shadowing
	float size_scaled_uv = (1.0 - UV.y) * size; // ranges from 0 (bottom) to size (top)
	color.rgb *= min(max(size_scaled_uv, fake_shadow_min_multiplier), fake_shadow_height) / fake_shadow_height;

	ALBEDO = color.rgb;
	
	NORMAL_MAP = texture(normal_map, UV).xyz;
	
	vec3 diff = (mat3(INV_VIEW_MATRIX) * VIEW) * (mat3(INV_VIEW_MATRIX) * NORMAL);
	float diff_dot = 1.0 - abs(dot(diff, diff));
	
//	if (min(1.0, 5.0 - diff_dot * 5.0) - thresholdMatrix[y_index * 4 + x_index] < 0.0) {
//		discard;
//	}
	//ALPHA = min(1.0, 5.0 - diff_dot * 5.0);
	
	// Other material parameters
	RIM = 1.0;
	METALLIC = 0.0;
	ROUGHNESS = 1.0 - color.g * 1.0;
}