shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D heightmap;
uniform sampler2D tex : hint_albedo;
uniform sampler2D normalmap : hint_normal;
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

vec3 get_normal(vec2 normal_uv_pos) {
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor.
	float texture_size = float(textureSize(heightmap, 0).x);
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
	VERTEX.y = get_height(UV);
	
	// Calculate the engine position of this vertex
	v_obj_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz / size;
	
	// Calculate the engine position of the camera
	world_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Apply the curvature based on the position of the current camera
	float dist_to_middle = pow(world_pos.x, 2.0) + pow(world_pos.y, 2.0) + pow(world_pos.z, 2.0);
	VERTEX.y -= get_curve_offset(dist_to_middle);
	
	int splat_id = int(texture(splat, get_relative_pos_with_blending(UV, distance(v_obj_pos, world_pos))).r * 255.0);
	
	if (splat_id == water_splat_id) {
		VERTEX.y -= 2.0;
	}
	
	if (fake_forests &&
		(splat_id == 91
		|| splat_id == 93)) {
		VERTEX.y += forest_height;
	}
}

// Adapted from https://stackoverflow.com/questions/9234724/how-to-change-hue-of-a-texture-with-glsl
const vec3  kRGBToYPrime = vec3 (0.299, 0.587, 0.114);
const vec3  kRGBToI      = vec3 (0.596, -0.275, -0.321);
const vec3  kRGBToQ      = vec3 (0.212, -0.523, 0.311);

const vec3  kYIQToR   = vec3 (1.0, 0.956, 0.621);
const vec3  kYIQToG   = vec3 (1.0, -0.272, -0.647);
const vec3  kYIQToB   = vec3 (1.0, -1.107, 1.704);

vec3 RGBtoHCY(vec3 color) {
    // Convert to YIQ
    float   YPrime  = dot (color, kRGBToYPrime);
    float   I      = dot (color, kRGBToI);
    float   Q      = dot (color, kRGBToQ);

    // Calculate the hue and chroma
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);
	
	return vec3(hue, chroma, YPrime);
}

vec3 HCYtoRGB(vec3 hcy) {
	// Convert back to YIQ
    float Q = hcy.y * sin (hcy.x);
    float I = hcy.y * cos (hcy.x);

    // Convert back to RGB
    vec3 yIQ = vec3 (hcy.z, I, Q);
	vec3 color;
    color.r = dot (yIQ, kYIQToR);
    color.g = dot (yIQ, kYIQToG);
    color.b = dot (yIQ, kYIQToB);
	
	return color;
}

void fragment(){
	// Material parameters
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
	
	int splat_id = int(texture(splat, get_relative_pos_with_blending(UV, distance(v_obj_pos, world_pos))).r * 255.0);
	
	vec3 total_color;
	vec3 normal = texture(normalmap, get_relative_pos(UV)).rgb;
	
	if (clay_rendering) { // Early exit?
		// For clay rendering, simply display the land-use splatmap.
		total_color = vec3(float(splat_id) / 255.0);
	} else {
		// Early exit due to overlay texture?
		bool done = false;

		if (has_overlay) {
			vec4 overlay = texture(overlay_texture, get_relative_pos(UV));

			if (overlay.a > 0.5) {
				total_color = overlay.rgb;
				normal = get_normal(UV);
				done = true;
			}
		}

		if (!done) {
			vec3 base_color = texture(tex, get_relative_pos(UV)).rgb;
			vec3 detail_color = vec3(0.0);
			vec3 current_normal = vec3(0.0);

			float dist = distance(v_obj_pos, world_pos);
			float detail_factor = 1.0;

			// Starting at a certain distance, we blend a larger version of the texture
			//  to the normal one. This reduces tiling and increases detail.
			float larger_texture_factor = clamp(pow(dist / 50.0, 2.0), 0.0, 1.0);

			vec3 detail_color_near;
			vec3 current_normal_near;

			vec3 detail_color_far;
			vec3 current_normal_far;

			float uv_large_scale = 0.2;

			// If the player is too far away, don't do all the detail calculation
			if (detail_factor > 0.0) {
				if (splat_id == vegetation_id1) {
					detail_color_near = texture(vegetation_tex1, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
					current_normal_near = texture(vegetation_normal1, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;

					detail_color_far = texture(vegetation_tex1, UV * uv_large_scale * size * tex_factor - vec2(floor(UV.x * uv_large_scale * size * tex_factor), floor(UV.y * uv_large_scale * size * tex_factor))).rgb;
					current_normal_far = texture(vegetation_normal1, UV * uv_large_scale * size * tex_factor - vec2(floor(UV.x * uv_large_scale * size * tex_factor), floor(UV.y * uv_large_scale * size * tex_factor))).rgb;
				} else if (splat_id == vegetation_id2) {
					detail_color_near = texture(vegetation_tex2, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;
					current_normal_near = texture(vegetation_normal2, UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor))).rgb;

					detail_color_far = texture(vegetation_tex2, UV * uv_large_scale * size * tex_factor - vec2(floor(UV.x * uv_large_scale * size * tex_factor), floor(UV.y * uv_large_scale * size * tex_factor))).rgb;
					current_normal_far = texture(vegetation_normal2, UV * uv_large_scale * size * tex_factor - vec2(floor(UV.x * uv_large_scale * size * tex_factor), floor(UV.y * uv_large_scale * size * tex_factor))).rgb;
				}
			}

			vec3 raw_detail_color = mix(detail_color_near, detail_color_far, larger_texture_factor);
			vec3 raw_current_normal = mix(current_normal_near, current_normal_far, larger_texture_factor);

			vec3 base_hcy = RGBtoHCY(base_color);
			vec3 detail_hcy = RGBtoHCY(raw_detail_color);

			float hue_difference = abs(base_hcy.x - detail_hcy.x);

			// Adapt the detail texture hue and chroma to the orthophoto
			// TODO: Would be neat if we could only adapt the hue slightly, but that
			//  can get us to completely different colors inbetween
			detail_hcy.x = base_hcy.x;
			detail_hcy.y = mix(detail_hcy.y, base_hcy.y, 0.5);

			detail_color = HCYtoRGB(detail_hcy);

			if (blend_only_similar_colors) {
				// If the hue difference is too large, don't use the detail texture at all.
				// Otherwise, the amount of the detail texture depends on the difference.
				if (hue_difference > 2.8) {
					detail_factor = 0.0;
				} else {
					detail_factor = (1.0 - hue_difference / 2.8);
				}
			}

			// Detail factor gets higher when player is close
			float dist_factor = clamp(dist / detail_start_dist, 0.0, 1.0);  // 0.0 if very close, 1.0 if very far
			detail_factor = clamp(detail_factor * (2.0 - dist_factor), 0.0, 1.0);

			// If there was a detail texture here, mix it with the base color
			// Otherwise, just use the base color
			// TODO: we could check for this earlier, but I don't think it
			// makes a difference in shaders, it might actually cause bugs...
			if (raw_detail_color != vec3(0.0)) {
				total_color = mix(base_color, detail_color, detail_factor);
			} else {
				total_color = base_color;
			}
		}
	}

	NORMALMAP = normal;
	// To test the normals: total_color = NORMALMAP;
	// To test the land-use map: total_color = vec3(float(splat_id) / 255.0);
	
	ALBEDO = total_color;
}