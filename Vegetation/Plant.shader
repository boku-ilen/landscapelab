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

varying float splat_id;
varying float row;
varying float dist_id;

void vertex() {
	vec3 worldpos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Move the upper vertices around for a wind wave effect
	if (VERTEX.y > 0.3) {
		VERTEX.x += amplitude * sin(worldpos.x * scale.x * 0.75 + TIME * speed.x) * cos(worldpos.z * scale.x + TIME * speed.x * 0.25);
		VERTEX.z += amplitude * sin(worldpos.x * scale.y + TIME * speed.y * 0.35) * cos(worldpos.z * scale.y * 0.80 + TIME * speed.y);
	}
	
	// TODO: Pass the offset to the world origin and add it here
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
	ivec2 dist_pos = ivec2(int(pos.x * 1000.0) % 16, int(pos.y * 1000.0) % 16);
	dist_id = texelFetch(distribution_map, ivec2(0, int(row) * 16) + dist_pos, 0).r * 255.0;
}

void fragment() {
	if (abs(row - 255.0) < 0.1) {
		discard;
	}
	
	ivec2 sheet_size = textureSize(texture_map, 0);
	
	vec2 scaled_uv = UV / (vec2(sheet_size) / 1024.0);
	
	vec2 uv_offset = vec2(dist_id / 7.0, row / 8.0);
	
	vec4 color = texture(texture_map, scaled_uv + uv_offset);
	
	ALBEDO = color.rgb;
	if (color.a < 0.3) {
		discard;
	}
	
	NORMALMAP = texture(normal_map, UV).rgb;
	
	METALLIC = 0.0;
	SPECULAR = texture(specular_map, UV).r;
	ROUGHNESS = 1.0 - SPECULAR;
	TRANSMISSION = vec3(0.2, 0.2, 0.2);
}