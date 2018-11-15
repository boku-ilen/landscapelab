shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D heightmap;
uniform sampler2D tex;
uniform vec3 curv_middle = vec3(0.0, 0.0, 0.0);

// Global parameters - will need to be the same in all shaders:
uniform float curv_factor = 0.2;
uniform float height_range = 15;

void vertex() {
	// Apply the height of the heightmap at this pixel
	float h = texture(heightmap, UV).g * height_range;
	VERTEX.y = h;
	
	// Apply the curvature based on the distance from the current point to the origin point
	// Note: This can and should probably use the location of the camera instead of a passed parameter like curv_middle (CAMERA_MATRIX might be relevant here!)
	vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist_to_middle = distance(world_pos, curv_middle) * curv_factor;
	
	VERTEX.y -= dist_to_middle;
}

void fragment(){
	// Just apply the texture
	ALBEDO = texture(tex, UV).rgb;
}