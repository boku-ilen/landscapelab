shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D heightmap;
uniform sampler2D tex : hint_albedo;
uniform sampler2D splat;

uniform sampler2D vegetation_tex1 : hint_albedo;

uniform vec3 curv_middle = vec3(0.0, 0.0, 0.0);

// Global parameters - will need to be the same in all shaders:
uniform float height_range = 1500;

uniform float subdiv;
uniform float size;
uniform float size_without_skirt;
uniform float tex_factor = 0.5; // 0.5 means one Godot meter will have half the texture

uniform float RADIUS = 6371000; // average earth radius in meters

// Get the value by which vertex at given point must be lowered to simulate the earth's curvature 
float get_curve_offset(float distance_squared) {
	return sqrt(RADIUS * RADIUS + distance_squared) - RADIUS;
}

// Shrinks and centers UV coordinates to compensate for the skirt around the edges
vec2 get_relative_pos(vec2 raw_pos) {
	float offset_for_subdiv = ((size_without_skirt/(subdiv+1.0))/size_without_skirt);
	float factor = (size / size_without_skirt);
	
	vec2 pos = raw_pos * factor;

	pos.x -= offset_for_subdiv;
	pos.y -= offset_for_subdiv;
	
	pos.x = clamp(pos.x, 0.005, 0.995);
	pos.y = clamp(pos.y, 0.005, 0.995);
	
	return pos;
}

// Gets the absolute height at a given pos without taking the skirt into account
float get_height_no_falloff(vec2 pos) {
	return texture(heightmap, get_relative_pos(pos)).g * height_range;
}

// Gets the required height of the vertex, including the skirt around the edges (the outermost vertices are set to y=0 to allow seamless transitions between tiles)
float get_height(vec2 pos) {
	float falloff = 1.0/(10000.0);
	
	if (pos.x > 1.0 - falloff || pos.y > 1.0 - falloff || pos.x < falloff || pos.y < falloff) {
		return 0.0;
	}
	
	return get_height_no_falloff(pos);
}

void vertex() {
	// Apply the height of the heightmap at this pixel
	VERTEX.y = get_height(UV);
	
	// Apply the curvature based on the position of the current camera
	vec3 world_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float dist_to_middle = pow(world_pos.x, 2.0) + pow(world_pos.y, 2.0) + pow(world_pos.z, 2.0);
	
	VERTEX.y -= get_curve_offset(dist_to_middle);
	
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor. Note: This might be dependent on the picture resolution! The current value works for my test images.
	float e = 1.0/20.0;

	NORMAL = normalize(vec3(-get_height_no_falloff(UV + vec2(e, 0.0)) + get_height_no_falloff(UV - vec2(e, 0.0)), 10.0 , -get_height_no_falloff(UV + vec2(0.0, e)) + get_height_no_falloff(UV - vec2(0.0, e))));
}

void fragment(){
	vec3 color;
	
	if (int(texture(splat, get_relative_pos(UV)).r * 255.0) == 1) {
		color = texture(vegetation_tex1, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
	} else {
		color = texture(tex, get_relative_pos(UV)).rgb;
	}
	
	ALBEDO = color;
}