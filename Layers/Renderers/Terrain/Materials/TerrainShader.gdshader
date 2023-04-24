shader_type spatial;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

// Basic Terrain
uniform sampler2D orthophoto: source_color, repeat_disable;
uniform sampler2D heightmap: repeat_disable;
uniform sampler2D normalmap: hint_normal, repeat_disable;
uniform float height_scale = 1.0;
uniform bool has_hole = false;

// Surface heights
uniform bool has_surface_heights = false;
uniform float surface_heights_start_distance = 800.0;
uniform sampler2D surface_heightmap: repeat_disable;

// Land use-based detail textures
uniform sampler2D landuse: repeat_disable, filter_nearest;
uniform bool has_landuse = false;

uniform sampler2D offset_noise;

uniform bool uses_detail_textures = false;
uniform sampler2DArray albedo_tex: source_color;
uniform sampler2DArray normal_tex: hint_normal;
uniform sampler2DArray ambient_tex;
uniform sampler2DArray specular_tex;
uniform sampler2DArray roughness_tex;
uniform sampler2DArray ao_tex;

// See Vegetation.get_metadata_texture for details
uniform sampler2D metadata;

uniform bool uses_distance_textures = false;
uniform float distance_tex_switch_distance = 20.0;
uniform float fade_transition_space = 8.0;
uniform float ortho_switch_distance = 150.0;
uniform float ortho_transition_space = 20.0;
uniform sampler2DArray distance_tex: source_color;
uniform sampler2DArray distance_normals: hint_normal;

uniform float normal_scale = 1.0;
uniform float ortho_saturation = 1.2;
uniform float ortho_blue_shift_factor = 0.9;

uniform float size;

varying vec3 camera_pos;
varying vec3 world_pos;
varying float world_distance;
varying float camera_distance;

// Workaround for a bug in `texelFetch` - use this instead!
// More info at https://github.com/godotengine/godot/issues/31732
vec4 texelGet ( sampler2D tg_tex, ivec2 tg_coord, int tg_lod ) {
	vec2 tg_texel = 1.0 / vec2(textureSize(tg_tex, 0));
	vec2 tg_getpos = (vec2(tg_coord) * tg_texel) + (tg_texel * 0.5);
	return texture(tg_tex, tg_getpos, float(tg_lod));
}

float get_height(vec2 uv) {
	float height = texture(heightmap, uv).r * height_scale;
	// Clamp to prevent weird behavior with extreme nodata values
	// TODO: Might have to be generalized further to be more robust
	return clamp(height, -1000.0, 50000.0);
}

vec3 get_normal(vec2 normal_uv_pos) {
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor.
	float e = 1.0 / 100.0; // TODO: Take resolution as a uniform var and use that here
	
	// Sobel filter for getting the normal at this position
	float bottom_left = get_height(normal_uv_pos + vec2(-e, -e));
	float bottom_center = get_height(normal_uv_pos + vec2(0, -e));
	float bottom_right = get_height(normal_uv_pos + vec2(e, -e));
	
	float center_left = get_height(normal_uv_pos + vec2(-e, 0));
	float center_center = get_height(normal_uv_pos + vec2(0, 0));
	float center_right = get_height(normal_uv_pos + vec2(e, 0));
	
	float top_left = get_height(normal_uv_pos + vec2(-e, e));
	float top_center = get_height(normal_uv_pos + vec2(0, e));
	float top_right = get_height(normal_uv_pos + vec2(e, e));
	
	vec3 long_normal;
	
	long_normal.x = -(bottom_right - bottom_left + 2.0 * (center_right - center_left) + top_right - top_left) / (size * e);
	long_normal.z = -(top_left - bottom_left + 2.0 * (top_center - bottom_center) + top_right - bottom_right) / (size * e);
	long_normal.y = size * e * 0.1; // scaling by <1.0 makes the normals more drastic

	return normalize(long_normal);
}

void vertex() {
	// Hide transition with a "skirt": outermost row of vertices is moved down to create a wall that fills holes
	if (UV.x < 0.0 || UV.x > 1.0 || UV.y < 0.0 || UV.y > 1.0) {
		VERTEX.y = -1000.0;
	} else {
		VERTEX.y = get_height(UV);
	}
	
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_distance = length(world_pos.xz);
	
	camera_pos = INV_VIEW_MATRIX[3].xyz;
	camera_distance = length(world_pos - camera_pos);
	
//	if (has_surface_heights) {
//		float surface_height_factor = float(world_distance > surface_heights_start_distance);
//		float texture_read = texture(surface_heightmap, UV).r;
//		if (texture_read < 80.0) {
//			// Nodata may be encoded as infinity
//			VERTEX.y += texture_read * height_scale * surface_height_factor;
//		}
//	}
}

// Decrase or increase the color saturation
// Adapted from http://www.alienryderflex.com/saturation.html
vec3 saturate_color(vec3 color, float change) {
	float P = sqrt(color.r * color.r * 0.299
			+ color.g * color.g * 0.587
			+ color.b * color.b * 0.114);
	
	return vec3(P, P, P) + (color - vec3(P, P, P)) * change;
}

vec3 shift_blue(vec3 color, float change) {
	color.b *= change;
	return color;
}


vec3 get_ortho_color(vec2 uv) {
	vec3 blue_shifted_sample = shift_blue(texture(orthophoto, uv).rgb, ortho_blue_shift_factor);
	return saturate_color(blue_shifted_sample, ortho_saturation);
}


vec3 get_distance_color(vec3 uv, vec3 ortho_color) {
	vec3 detail_color = texture(distance_tex, uv).rgb;
	
	vec3 base_hcy = RGBtoHCY(ortho_color);
	vec3 detail_hcy = RGBtoHCY(detail_color);

	float hue_difference = abs(base_hcy.x - detail_hcy.x);

	// Adapt the detail texture hue and chroma to the orthophoto
	// TODO: Would be neat if we could only adapt the hue slightly, but that
	//  can get us to completely different colors inbetween
	detail_hcy.x = base_hcy.x;
	detail_hcy.y = mix(detail_hcy.y, base_hcy.y, 0.5);

	return HCYtoRGB(detail_hcy);
}


void fragment() {
	NORMAL = (VIEW_MATRIX * vec4(get_normal(UV), 0.0)).xyz;
	
	vec2 random_landuse_offset = (texture(offset_noise, world_pos.xz * 0.006).rg - 0.5) * (50.0 / size);
	int splat_id = int(round(texture(landuse, UV + random_landuse_offset).r * 255.0));
	
	// Check for water
	// TODO: Expose these parameters
	if (splat_id >= 60 && splat_id <= 66) {
		discard;
	}
	
	// Add some more noise for all non-water land-uses
	vec2 random_fine_landuse_offset = (texture(offset_noise, world_pos.xz * 0.8).gb - 0.5) * (7.0 / size);
	random_fine_landuse_offset += (texture(offset_noise, world_pos.xz * 0.55).rb - 0.5) * (6.0 / size);
	
	splat_id = int(round(texture(landuse, UV + random_landuse_offset + random_fine_landuse_offset).r * 255.0));
	
	vec3 metadata_value = texelGet(metadata, ivec2(splat_id, 0), 0).rgb;
	
	float plant_row = metadata_value.r * 255.0;
	float ground_texture_scale = float(uses_detail_textures) * metadata_value.g * 128.0; // FIXME: Move scale to uniform
	float fade_texture_scale = float(uses_distance_textures) * metadata_value.b * 128.0;
	
	vec3 ortho_color = get_ortho_color(UV);
	
	// Calculate the near factor: 0.0 when only the distance texture should be applied,
	// 1.0 when only the close ground texture should be used
	float near_factor = 0.0;
	
	if (camera_distance < distance_tex_switch_distance - fade_transition_space) {
		near_factor = 1.0;
	} else if (camera_distance < distance_tex_switch_distance + fade_transition_space) {
		near_factor = camera_distance - (distance_tex_switch_distance - fade_transition_space);
		near_factor /= fade_transition_space * 2.0;
	} else {
		near_factor = 0.0;
	}
	
	// Apply textures
	if (has_landuse && (ground_texture_scale > 0.0 || fade_texture_scale > 0.0)) {
		// We have special near textures here
		if (near_factor >= 1.0) {
			if (ground_texture_scale > 0.0) {
				vec3 scaled_uv = vec3(UV * size / ground_texture_scale, plant_row);
				
				ALBEDO = texture(albedo_tex, scaled_uv).rgb;
				NORMAL_MAP = texture(normal_tex, scaled_uv).rgb;
				NORMAL_MAP_DEPTH = 3.0;// * (1.0 - camera_distance / (distance_tex_switch_distance - fade_transition_space));
	//			AO = texture(ambient_tex, scaled_uv).r;
	//			SPECULAR = texture(specular_tex, scaled_uv).r;
	//			ROUGHNESS = texture(roughness_tex, scaled_uv).r;
			} else {
				ALBEDO = ortho_color;
			}
		} else if (near_factor <= 0.0) {
			// Apply the distance tex or ortho
			if (fade_texture_scale <= 0.0 || camera_distance > ortho_switch_distance + ortho_transition_space) {
				// If none is available or the camera is far away, use orthophoto
				ALBEDO = ortho_color;
			} else { 
				vec3 scaled_far_uv = vec3(UV * size / fade_texture_scale, plant_row);
				vec3 distance_sample = get_distance_color(scaled_far_uv, ortho_color);
				
				if (camera_distance < ortho_switch_distance - ortho_transition_space) {
					// Fade texture only
					ALBEDO = distance_sample;
					// TODO: Something like this could bend the normals towards the camera, which
					//  makes the lighting look more as if plants were rising up. However, the effect
					//  is a bit strange while turning the camera because the ground color changes,
					//  and the abrupt transition from the adapted color to the raw orthophoto is jarring.
					// NORMAL = normalize(NORMAL + vec3(0.0, 0.0, 2.0));
					NORMAL_MAP = texture(distance_normals, scaled_far_uv).xyz;
					NORMAL_MAP_DEPTH = 3.0;
				} else {
					// Mix
					float fade_factor = camera_distance - (ortho_switch_distance - ortho_transition_space);
					fade_factor /= ortho_transition_space * 2.0;
					
					ALBEDO = mix(distance_sample, ortho_color, fade_factor);
					NORMAL_MAP = texture(distance_normals, scaled_far_uv).xyz;
					NORMAL_MAP_DEPTH = 3.0;
				}
			}
		} else {
			// Blend between close tex and distance tex
			vec3 scaled_near_uv = vec3(UV * size / ground_texture_scale, plant_row);
			vec3 scaled_far_uv = vec3(UV * size / fade_texture_scale, plant_row);
			
			// Select the detail sample depending on whether it is available
			vec3 detail_sample;
			if (ground_texture_scale > 0.0) {
				detail_sample = texture(albedo_tex, scaled_near_uv).rgb;
			} else {
				detail_sample = ortho_color;
			}
			
			// Select the distance sample depending on whether a fade texture is available (ortho otherwise)
			vec3 distance_sample;
			if (fade_texture_scale > 0.0) {
				distance_sample = get_distance_color(scaled_far_uv, ortho_color);
			} else {
				distance_sample = ortho_color;
			}
			
			ALBEDO = mix(detail_sample, distance_sample, near_factor);
			NORMAL_MAP = texture(distance_normals, scaled_far_uv).xyz;
			NORMAL_MAP_DEPTH = 3.0;
		}
	} else {
		// No near texture is available, so just apply the ortho
		// TOOD: Restructure to also handle the case of a fade texture being available, but no near texture
		ALBEDO = ortho_color;
	}
	
	METALLIC = 0.0;
	ROUGHNESS = 0.95;
}