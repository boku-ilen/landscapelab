shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D height;
uniform float height_multiplicator;
uniform sampler2D tex : hint_albedo;
uniform vec4 startcolor : hint_color;
uniform vec4 endcolor : hint_color;
uniform sampler2D normalmap : hint_normal;

// Clipping logic
uniform bool should_clip;
uniform vec3 table_pos;
varying vec3 global_pixel_pos;
uniform float table_radius;

// Value shader
varying vec3 color_at_pixel;

uniform float random_offset_vectors_scale = 2.5; // 2.0 means the random offset vectors texture will repeat every 2m

uniform sampler2D random_offset_vectors : hint_normal;

uniform sampler2D overlay_texture;
uniform bool has_overlay;

uniform float depth_scale = 0.07;
uniform int depth_min_layers = 4;
uniform int depth_max_layers = 16;

uniform bool blend_only_similar_colors = true;
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

vec2 get_relative_pos_with_blending(vec2 raw_pos, float dist) {
	// Add a random offset to the relative pos, so that a different color could be chosen if one is nearby
	// Subtract 0.5, 0.5 and multiply by 2 to level out vectors around 0 (between -1 and 1), not around 0.5 (between 0 and 1)
	// Otherwise we get an offset since random vectors always tend towards a certain direction
	vec2 random_offset = (texture(random_offset_vectors, raw_pos * size_without_skirt * 0.1).rg - vec2(0.5, 0.5)) * 2.0;
	
	return get_relative_pos(raw_pos + random_offset * (1000.0 / size_without_skirt) * (dist / 1000.0));
}

// Gets the absolute height at a given pos without taking the skirt into account
float get_height_no_falloff(vec2 pos) {
	return texture(height, get_relative_pos(pos)).r;
}

// Gets the required height of the vertex, including the skirt around the edges (the outermost vertices are set to y=0 to allow seamless transitions between tiles)
float get_height(vec2 pos) {
	float falloff = 1.0/(100000.0);
	
	if (pos.x > 1.0 - falloff || pos.y > 1.0 - falloff || pos.x < falloff || pos.y < falloff) {
		return 0.0;
	}
	
	return get_height_no_falloff(pos);
}

vec3 get_normal(vec2 normal_uv_pos) {
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor.
	float texture_size = float(textureSize(height, 0).x);
	float e = ((size / size_without_skirt) / texture_size);
	
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

	return normalize(long_normal);
}

void vertex() {
		// Apply the height of the heightmap at this pixel
	VERTEX.y = get_height(UV) * height_multiplicator;
	
	// Vertex engine pos ..?
	global_pixel_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Calculate the engine position of this vertex
	v_obj_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz / size;
	
	// Calculate the engine position of the camera
	world_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Apply the curvature based on the position of the current camera
	float dist_to_middle = pow(world_pos.x, 2.0) + pow(world_pos.y, 2.0) + pow(world_pos.z, 2.0);
	VERTEX.y -= get_curve_offset(dist_to_middle);
}

float invLerp(float start, float end, float value){
  return (value - start) / (end - start);
}

void fragment(){
	if (should_clip) {
		vec2 delta_pos = vec2(table_pos.x, table_pos.z) - vec2(global_pixel_pos.x, global_pixel_pos.z);
		float delta_height = table_pos.y - global_pixel_pos.y;
		
		if (length(delta_pos) > table_radius || delta_height > 0.0) {
			discard;
		}
	}
	
	float data_value = texture(tex, UV).r;
	data_value = invLerp(210, 278, data_value);
	vec4 data_color = mix(startcolor, endcolor, data_value);
	
	ALPHA = 1.0;
	ALBEDO = data_color.rgb;
}