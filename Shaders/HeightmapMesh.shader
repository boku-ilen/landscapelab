shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D heightmap;
uniform sampler2D tex;
uniform vec3 curv_middle = vec3(0.0, 0.0, 0.0);

// Global parameters - will need to be the same in all shaders:
uniform float curv_factor = 0;
uniform float height_range = 600;

uniform float subdiv;
uniform float size;
uniform float size_without_skirt;

vec2 get_relative_pos(vec2 raw_pos) {
	float offset_for_subdiv = ((size_without_skirt/(subdiv+1.0))/size_without_skirt);// + 0.01;
	float factor = (size / size_without_skirt);
	
	vec2 pos = raw_pos * factor;// * 0.99; //* (size_without_skirt/size);

	pos.x -= offset_for_subdiv;// * 0.93;
	pos.y -= offset_for_subdiv;// * 0.93;
	
	pos.x = clamp(pos.x, 0.005, 0.995);
	pos.y = clamp(pos.y, 0.005, 0.995);
	
	return pos;
}

float get_height(vec2 pos) {
	float falloff = 1.0/(10000.0);
	
	if (pos.x > 1.0 - falloff || pos.y > 1.0 - falloff || pos.x < falloff || pos.y < falloff) {
		return 0.0;
	}
	return texture(heightmap, get_relative_pos(pos)).g * height_range;
}

void vertex() {
	// Apply the height of the heightmap at this pixel
	VERTEX.y = get_height(UV);
	
	// Apply the curvature based on the distance from the current point to the origin point
	// Note: This can and should probably use the location of the camera instead of a passed parameter like curv_middle (CAMERA_MATRIX might be relevant here!)
	vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist_to_middle = distance(world_pos, curv_middle) * curv_factor;
	
	VERTEX.y -= dist_to_middle;
	
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor. Note: This might be dependent on the picture resolution! The current value works for my test images.
	float e = 1.0 / 50.0;

	NORMAL = normalize(vec3(-get_height(UV - vec2(e, 0)) + get_height(UV + vec2(e, 0)), 2.0 , -get_height(UV - vec2(0, e)) + get_height(UV + vec2(0, e))));
}

void fragment(){
	// TODO: These values work perfectly for 4 subdivisions - figure out why!
	ALBEDO = texture(tex, get_relative_pos(UV)).rgb;
}