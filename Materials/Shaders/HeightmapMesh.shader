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
uniform float tex_factor = 0.5; // 0.5 means one Godot meter will have half the texture
uniform float texture_blending_amount = 25.0; // 1.0 means the transition between two textures will be maximally 1m wide
                                              // (Also depends greatly on the random_offset_vectors texture used!)
uniform float random_offset_vectors_scale = 2.5; // 2.0 means the random offset vectors texture will repeat every 2m

uniform sampler2D random_offset_vectors : hint_normal;

uniform sampler2D overlay_texture;
uniform bool has_overlay;

uniform bool fake_forests;
uniform float forest_height;

uniform bool blend_only_similar_colors = false;
varying vec3 world_pos;
varying vec3 v_obj_pos;

// Global parameters - will need to be the same in all shaders:
uniform float subdiv;
uniform float size;
uniform float size_without_skirt;

uniform float RADIUS = 6371000; // average earth radius in meters

uniform bool clay_rendering = false;

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
	
	pos.x = clamp(pos.x, 0.0005, 0.9995);
	pos.y = clamp(pos.y, 0.0005, 0.9995);
	
	return pos;
}

vec2 get_relative_pos_with_blending(vec2 raw_pos) {
	// Add a random offset to the relative pos, so that a different color could be chosen if one is nearby
	// Subtract 0.5, 0.5 and multiply by 2 to level out vectors around 0 (between -1 and 1), not around 0.5 (between 0 and 1)
	// Otherwise we get an offset since random vectors always tend towards a certain direction
	vec2 random_offset = (texture(random_offset_vectors, raw_pos * (size / random_offset_vectors_scale)).rg - vec2(0.5, 0.5)) * 2.0;
	
	return get_relative_pos(raw_pos + random_offset * (texture_blending_amount / size));
}

// Gets the absolute height at a given pos without taking the skirt into account
float get_height_no_falloff(vec2 pos) {
	return texture(heightmap, get_relative_pos(pos)).r;
}

// Gets the required height of the vertex, including the skirt around the edges (the outermost vertices are set to y=0 to allow seamless transitions between tiles)
float get_height(vec2 pos) {
	float falloff = 1.0/(100000.0);
	
	if (pos.x > 1.0 - falloff || pos.y > 1.0 - falloff || pos.x < falloff || pos.y < falloff) {
		return 0.0;
	}
	
	return get_height_no_falloff(pos);
}

void vertex() {
	// Apply the height of the heightmap at this pixel
	VERTEX.y = get_height(UV);
	
	if (int(texture(splat, get_relative_pos(UV)).r) == water_splat_id) {
		VERTEX.y -= 2.0;
	}
	
	if (fake_forests &&
		(int(texture(splat, get_relative_pos(UV)).r) == 91
		|| int(texture(splat, get_relative_pos(UV)).r) == 93)) {
		VERTEX.y += forest_height;
	}
	
	// Calculate the engine position of this vertex
	v_obj_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz / size;
	
	// Calculate the engine position of the camera
	world_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Apply the curvature based on the position of the current camera
	float dist_to_middle = pow(world_pos.x, 2.0) + pow(world_pos.y, 2.0) + pow(world_pos.z, 2.0);
	VERTEX.y -= get_curve_offset(dist_to_middle);
}

void fragment(){
	// Material parameters
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
	
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
		if (int(texture(splat, get_relative_pos_with_blending(UV)).r) == vegetation_id1) {
			detail_color = texture(vegetation_tex1, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
			current_normal = texture(vegetation_normal1, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
		} else if (int(texture(splat, get_relative_pos_with_blending(UV)).r) == vegetation_id2) {
			detail_color = texture(vegetation_tex2, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
			current_normal = texture(vegetation_normal2, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
		}
	}
	
	if (blend_only_similar_colors) {
		detail_factor *= max(0.0, (1.0 - length(detail_color - base_color)));
	}

	if (detail_color != vec3(0.0)) {
		total_color = mix(base_color, detail_color, detail_factor);
	} else {
		total_color = base_color;
	}
	
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor.
	// TODO: The calculation of e is not correct, we should not need the ' * (9783.93962 / size)' part.
	//  I believe we need it due to our heightmap images being low res with doubled pixels at small scales.
	float texture_size = float(textureSize(heightmap, 0).x);
	float e = ((size / size_without_skirt) / texture_size);
	
	vec2 normal_uv_pos = UV;
	
	// Sobel filter for getting the normal at this position
	float bottom_left = get_height_no_falloff(normal_uv_pos + vec2(-e, -e));
	float bottom_center = get_height_no_falloff(normal_uv_pos + vec2(0, -e));
	float bottom_right = get_height_no_falloff(normal_uv_pos + vec2(e, -e));
	
	float center_left = get_height_no_falloff(normal_uv_pos + vec2(-e, 0));
	float center_center = get_height_no_falloff(normal_uv_pos + vec2(0, 0));
	float center_right = get_height_no_falloff(normal_uv_pos + vec2(e, 0));
	
	float top_left = get_height_no_falloff(normal_uv_pos + vec2(-e, e));
	float top_center = get_height_no_falloff(normal_uv_pos + vec2(0, e));
	float top_right = get_height_no_falloff(normal_uv_pos + vec2(e, e));
	
	vec3 long_normal;
	
	long_normal.x = -(bottom_right - bottom_left + 2.0 * (center_right - center_left) + top_right - top_left) / (size_without_skirt / texture_size);
	long_normal.y = (top_left - bottom_left + 2.0 * (top_center - bottom_center) + top_right - bottom_right) / (size_without_skirt / texture_size);
	long_normal.z = 1.0;

	vec3 normal = normalize(long_normal);
	
	NORMALMAP = normal;
	// To test the normals: total_color = NORMALMAP;
	
	vec4 overlay = texture(overlay_texture, get_relative_pos(UV));
	
	// If the overlay texture has data at this pixel, it is used instead of the normal color
	if (has_overlay && overlay.a > 0.5) {
		total_color = overlay.rgb;
	}
	
	if (clay_rendering) {
		ALBEDO = vec3(0.6 + (get_height(get_relative_pos(UV)) - 1000.0) * (1.0/1500.0));
	} else {
		ALBEDO = total_color;
	}
}