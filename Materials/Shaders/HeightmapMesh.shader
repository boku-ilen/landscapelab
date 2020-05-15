shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D heightmap;
uniform sampler2D tex : hint_albedo;
uniform sampler2D normalmap : hint_normal;
uniform sampler2D splat;
uniform int water_splat_id;

uniform float detail_start_dist;

uniform float tex_factor = 0.2; // 0.5 means one Godot meter will have half the texture
uniform float texture_blending_amount = 25.0; // 1.0 means the transition between two textures will be maximally 1m wide
                                              // (Also depends greatly on the random_offset_vectors texture used!)
uniform float random_offset_vectors_scale = 2.5; // 2.0 means the random offset vectors texture will repeat every 2m
uniform sampler2D random_offset_vectors : hint_normal;

uniform sampler2D detail_albedo_sheet : hint_albedo;
uniform sampler2D detail_normal_sheet : hint_normal;
uniform sampler2D detail_depth_sheet : hint_black;
uniform sampler2D id_to_row;
uniform bool is_detailed = false;

uniform sampler2D overlay_texture;
uniform bool has_overlay;

uniform float depth_scale = 0.8;
uniform int depth_min_layers = 4;
uniform int depth_max_layers = 16;

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
uniform bool simple_rendering = false;

// Get the value by which vertex at given point must be lowered to simulate the earth's curvature 
float get_curve_offset(float distance_squared) {
	// Necessary to be 100% safe, but when using the earth's radius, it'll never happen:
	if (distance_squared > RADIUS * RADIUS) { return 100000.0; }
	return RADIUS - sqrt(RADIUS * RADIUS - distance_squared);
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
	return texture(heightmap, get_relative_pos(pos)).r * 1.45;
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
	
//	// Experiment: If there is an overlay texture here, smooth the terrain out
//	if (has_overlay) {
//		vec4 overlay = texture(overlay_texture, get_relative_pos(UV));
//
//		if (overlay.a > 0.5) {
//			// TODO: The value that makes sense here is related to the resolutin of the overlay texture, maybe we should pass it
//			float e = 2.0 / 128.0;
//			VERTEX.y = (get_height(UV + vec2(e, 0)) + get_height(UV + vec2(-e, 0)) + get_height(UV + vec2(0, e)) + get_height(UV + vec2(0, -e))) / 4.0;
//		}
//	}
	
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
	vec3 normal = texture(normalmap, get_relative_pos(UV)).rgb * 2.0 - vec3(1.0, 1.0, 1.0);

	if (false) { // Early exit?
		// For clay rendering, simply display the land-use splatmap.
		total_color = vec3(float(splat_id) / 255.0);
	} else {
		// Early exit due to overlay texture?
		bool done = false;

//		if (has_overlay) {
//			vec4 overlay = texture(overlay_texture, get_relative_pos(UV));
//
//			if (overlay.a > 0.5) {
//				total_color = overlay.rgb;
//				normal = get_normal(UV);
//				done = true;
//			}
//		}

		if (!done) {
			vec3 base_color = texture(tex, get_relative_pos(UV)).rgb;
			vec3 detail_color = vec3(0.0);
			vec3 current_normal = vec3(0.0);

			float dist = distance(v_obj_pos, world_pos);
			float detail_factor = 1.0;

			// Starting at a certain distance, we blend a larger version of the texture
			//  to the normal one. This reduces tiling and increases detail.
			float larger_texture_factor = clamp(pow(dist / 50.0, 2.0), 0.0, 1.0);

			float uv_large_scale = 0.2;

			// If the player is too far away, don't do all the detail calculation
			if (is_detailed && detail_factor > 0.0) {
				vec2 near_uv = UV * size * tex_factor - vec2(floor(UV.x * size * tex_factor), floor(UV.y * size * tex_factor));
				vec2 far_uv = UV * uv_large_scale * size * tex_factor - vec2(floor(UV.x * uv_large_scale * size * tex_factor), floor(UV.y * uv_large_scale * size * tex_factor));

				// Calculate the UV offset in the spritesheet
				float row = texelFetch(id_to_row, ivec2(splat_id, 0), 0).r * 255.0;
				vec2 uv_scale = vec2(1.0, 1.0/8.0);
				vec2 uv_offset = vec2(0.0, row / 8.0);

				vec3 view_dir = normalize(normalize(-VERTEX)*mat3(TANGENT,-BINORMAL,NORMAL));
				float num_layers = mix(float(depth_max_layers),float(depth_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
				float layer_depth = 1.0 / num_layers;
				float current_layer_depth = 0.0;
				vec2 P = view_dir.xy * depth_scale;
				vec2 delta = P / num_layers;
				vec2  ofs = near_uv;

				float depth = 1.0 - textureLod(detail_depth_sheet, ofs * uv_scale + uv_offset,0.0).r;
				float current_depth = 0.0;

				while(current_depth < depth) {
					ofs -= delta;
					depth = 1.0 - textureLod(detail_depth_sheet, ofs * uv_scale + uv_offset,0.0).r;
					current_depth += layer_depth;
				}

				vec2 prev_ofs = ofs + delta;
				float after_depth  = depth - current_depth;
				float before_depth = 1.0 - textureLod(detail_depth_sheet, prev_ofs * uv_scale + uv_offset, 0.0).r - current_depth + layer_depth;
				float weight = after_depth / (after_depth - before_depth);
				ofs = mix(ofs,prev_ofs,weight);
				near_uv=ofs;
				
				vec2 uv = near_uv * uv_scale + uv_offset;
				
				// Fix for UV going to a different texture in the spritesheet
				if (uv.y < row / 8.0) {
					uv.y += 1.0 / 8.0;
				} else if (uv.y > (row + 1.0) / 8.0) {
					uv.y -= 1.0 / 8.0;
				}

				// Sample textures
				detail_color = texture(detail_albedo_sheet, uv).rgb;
				current_normal = texture(detail_normal_sheet, uv).rgb;

				vec3 raw_current_normal = current_normal* 2.0 - vec3(1.0, 1.0, 1.0);

				// Blend the normals
				// Adapted from https://math.stackexchange.com/questions/35005/rotate-vector-relative-to-xz-plane-to-be-relative-to-a-new-plane-defined-by-give/35053
				vec3 z = vec3(0.0, 0.0, 1.0);
				vec3 tangent = cross(normal, vec3(1.0, 0.0, 0.0));

				vec3 a = cross(tangent, z);
				vec3 b = cross(tangent, normal);

				mat3 A = mat3(z, tangent, a);
				mat3 B = mat3(normal, tangent, b);

				// TODO: According to the stackexchange post linked above, transpose(A)
				//  should be usable instead of inverse(A) here. However, it is not true
				//  for us that z and tangent are always normal. Why?
				mat3 R = B * inverse(A);

				normal = R * raw_current_normal;
			}
			
			if (simple_rendering) {
				total_color = detail_color;
			} else if (clay_rendering) {
				total_color = base_color;
			} else {
				vec3 raw_detail_color = detail_color;
				
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
	}

	// We previously put the normal into a range of -1, 1 for proper calculations.
	// We revert this here because NORMALMAP expects raw values from the texture.
	NORMALMAP = (normal + vec3(1.0, 1.0, 1.0)) * 0.5;
	NORMALMAP_DEPTH = 10.0;

	// To test the normals: total_color = NORMALMAP;
	// To test the land-use map: total_color = vec3(float(splat_id) / 255.0);

	ALBEDO = total_color;
}