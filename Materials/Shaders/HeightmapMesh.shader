shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D heightmap;
uniform sampler2D tex : hint_albedo;
uniform sampler2D splat;
uniform int water_splat_id;

uniform float detail_start_dist;

uniform sampler2D vegetation_tex1 : hint_albedo;
uniform sampler2D vegetation_normal1 : hint_normal;
uniform int vegetation_id1;
uniform sampler2D vegetation_tex2 : hint_albedo;
uniform sampler2D vegetation_normal2 : hint_normal;
uniform int vegetation_id2;
uniform sampler2D vegetation_tex3 : hint_albedo;
uniform sampler2D vegetation_normal3 : hint_normal;
uniform int vegetation_id3;
uniform sampler2D vegetation_tex4 : hint_albedo;
uniform sampler2D vegetation_normal4 : hint_normal;
uniform int vegetation_id4;
uniform float tex_factor = 1.0; // 0.5 means one Godot meter will have half the texture

uniform bool blend_only_similar_colors = false;

varying vec3 normal;
varying vec3 world_pos;
varying vec3 v_obj_pos;

// Global parameters - will need to be the same in all shaders:
uniform float subdiv;
uniform float size;
uniform float size_without_skirt;

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
	int r_int = int(texture(heightmap, get_relative_pos(pos)).r * 255.0);
	int g_int = int(texture(heightmap, get_relative_pos(pos)).g * 255.0);
	int b_int = int(texture(heightmap, get_relative_pos(pos)).b * 255.0);
	
	float r_conv = float(r_int) * 65536.0;
	float g_conv = float(g_int) * 256.0;
	float b_conv = float(b_int);
	
	return (r_conv + g_conv + b_conv) / 100.0;
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
	
	if (int(texture(splat, get_relative_pos(UV)).r * 255.0) == water_splat_id) {
		VERTEX.y -= 50.0; // TODO: This will become deprecated once water is precalculated into the heightmap!
	}
	
	// Calculate the engine position of this vertex
	v_obj_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz / size;
	
	// Calculate the engine position of the camera
	world_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Apply the curvature based on the position of the current camera
	float dist_to_middle = pow(world_pos.x, 2.0) + pow(world_pos.y, 2.0) + pow(world_pos.z, 2.0);
	VERTEX.y -= get_curve_offset(dist_to_middle);
	
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor. (Not quite sure about those values yet, but they work nicely!)
	float e = 1.0/(size/50.0);

	normal = normalize(vec3(-get_height_no_falloff(UV + vec2(e, 0.0)) + get_height_no_falloff(UV - vec2(e, 0.0)), 10.0 , -get_height_no_falloff(UV + vec2(0.0, e)) + get_height_no_falloff(UV - vec2(0.0, e))));
}

void fragment(){
	vec3 base_color = texture(tex, get_relative_pos(UV)).rgb;
	vec3 detail_color = vec3(0.0);
	vec3 total_color;
	vec3 current_normal = vec3(0.0);
	
	// Calculate the factor by which the detail texture should be shown
	// The factor is between 0 and 1: 0 when the camera is more than detail_start_dist away; 1 when the camera is right here.
	float detail_factor = distance(v_obj_pos, world_pos);
	detail_factor = clamp(1.0 - (detail_factor / detail_start_dist), 0.0, 1.0);
	
	// If the player is too far away, don't do all the detail calculation
	if (detail_factor > 0.0) {
		if (int(texture(splat, get_relative_pos(UV)).r * 255.0) == vegetation_id1) {
			detail_color = texture(vegetation_tex1, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
			current_normal = texture(vegetation_normal1, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
		} else if (int(texture(splat, get_relative_pos(UV)).r * 255.0) == vegetation_id2) {
			detail_color = texture(vegetation_tex2, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
			current_normal = texture(vegetation_normal2, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
		} else if (int(texture(splat, get_relative_pos(UV)).r * 255.0) == vegetation_id3) {
			detail_color = texture(vegetation_tex3, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
			current_normal = texture(vegetation_normal3, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
		} else if (int(texture(splat, get_relative_pos(UV)).r * 255.0) == vegetation_id4) {
			detail_color = texture(vegetation_tex4, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
			current_normal = texture(vegetation_normal4, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
		}
	}
	
	if (blend_only_similar_colors) {
		detail_factor *= max(0.0, (1.0 - length(detail_color - base_color)));
	}

	if (detail_color != vec3(0.0)) {
		total_color = detail_color * detail_factor + base_color * (1.0 - detail_factor);
		NORMALMAP += detail_factor * (current_normal * vec3(2.0, 2.0, 1.0) - vec3(1.0, 1.0, 0.0));
	} else {
		total_color = base_color;
	}
	
	ALBEDO = total_color;
	NORMAL = (INV_CAMERA_MATRIX * vec4(normalize(normal), 0.0)).xyz;
}