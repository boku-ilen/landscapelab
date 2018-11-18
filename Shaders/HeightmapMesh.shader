shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D heightmap;
uniform sampler2D tex;
uniform vec3 curv_middle = vec3(0.0, 0.0, 0.0);

// Global parameters - will need to be the same in all shaders:
uniform float curv_factor = 0.01;
uniform float height_range = 15;

float get_height(vec2 pos) {
	return texture(heightmap, pos).g * height_range;
}

void vertex() {
	// Apply the height of the heightmap at this pixel
	VERTEX.y = get_height(UV);
	
	// Apply the curvature based on the distance from the current point to the origin point
	// Note: This can and should probably use the location of the camera instead of a passed parameter like curv_middle (CAMERA_MATRIX might be relevant here!)
	vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist_to_middle = distance(world_pos, curv_middle) * curv_factor;
	
	VERTEX.y -= dist_to_middle;
	
	// Calculate normal
	float e = 0.002;

	NORMAL = normalize(vec3(get_height(UV - vec2(e, 0)) - get_height(UV + vec2(e, 0)), 2.0 , get_height(UV - vec2(0, e)) - get_height(UV + vec2(0, e))));
}

void fragment(){
	// Just apply the texture
	ALBEDO = texture(tex, UV).rgb;
}