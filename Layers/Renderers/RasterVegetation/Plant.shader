shader_type spatial;
render_mode cull_disabled;

uniform sampler2D texture_map : hint_albedo;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D specular_map : hint_black;

uniform sampler2D distribution_map : hint_black;
uniform sampler2D id_to_row;

uniform sampler2D splatmap;

uniform float amplitude = 0.1;
uniform vec2 speed = vec2(2.0, 1.5);
uniform vec2 scale = vec2(0.1, 0.2);

uniform vec2 heightmap_size = vec2(300.0, 300.0);
uniform vec2 offset;

uniform float dist_scale = 5000.0;

uniform float max_distance;

varying vec3 worldpos;
varying vec3 camera_pos;

varying flat float splat_id;
varying flat float row;
varying flat float dist_id;

void vertex() {
	worldpos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	camera_pos = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	
	// Move the upper vertices around for a wind wave effect
	if (VERTEX.y > 0.3) {
		VERTEX.x += amplitude * sin(worldpos.x * scale.x * 0.75 + TIME * speed.x) * cos(worldpos.z * scale.x + TIME * speed.x * 0.25);
		VERTEX.z += amplitude * sin(worldpos.x * scale.y + TIME * speed.y * 0.35) * cos(worldpos.z * scale.y * 0.80 + TIME * speed.y);
	}
	
	vec2 pos = worldpos.xz;
	pos += offset;
	
	pos -= 0.5 * heightmap_size;
	pos /= heightmap_size;
	
	pos += vec2(1.0, 1.0);
	
	// Splatmap ID at this position
	splat_id = texture(splatmap, pos).r * 255.0;
	
	// The row in the spritesheets which corresponds to this splatmap ID
	row = texelFetch(id_to_row, ivec2(int(round(splat_id)), 0), 0).r * 255.0;
	
	// Using the row, we can get the ID (the column) of the plant which should be here
	ivec2 dist_pos = ivec2(int(worldpos.x * dist_scale) % 16, int(worldpos.z * dist_scale) % 16);
	
	vec2 dist_value = texelFetch(distribution_map, ivec2(0, int(row) * 16) + dist_pos, 0).rg;
	dist_id = dist_value.r * 255.0;
	
	float size_scale = dist_value.g;
	VERTEX *= size_scale;
}

void fragment() {
	// If the row value is 255, this means that no data is available for this
	// land-use ID in this shader, so discard this pixel.
	if (abs(row - 255.0) < 0.1) {
		discard;
	}

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

	float blend_start_distance = max_distance - max_distance / 4.0;
	float dist = length(camera_pos - worldpos);

	float dist_alpha = (max_distance - dist) / (max_distance - blend_start_distance);

	if (dist_alpha - thresholdMatrix[y_index * 4 + x_index] < 0.0) {
		discard;
	}

	// Get the color from the right sprite in the spritesheet
	ivec2 sheet_size = textureSize(texture_map, 0);
	ivec2 cols_rows = sheet_size / 1024;

	vec2 scaled_uv = UV / (vec2(sheet_size) / 1024.0);

	vec2 uv_offset = vec2(dist_id / float(cols_rows.x), row / float(cols_rows.y));

	vec4 color = texture(texture_map, scaled_uv + uv_offset);

	ALBEDO = color.rgb;
	if (color.a < 0.7) {
		discard;
	}

	NORMALMAP = texture(normal_map, UV).rgb;

	METALLIC = 0.0;
	SPECULAR = texture(specular_map, UV).r;
	ROUGHNESS = 1.0 - SPECULAR;
	TRANSMISSION = vec3(0.2, 0.2, 0.2);
}