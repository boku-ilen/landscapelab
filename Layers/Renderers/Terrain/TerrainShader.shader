shader_type spatial;

// Basic Terrain
uniform sampler2D orthophoto: hint_albedo;
uniform sampler2D heightmap;
uniform float height_scale = 1.0;

// Surface heights
uniform bool has_surface_heights = false;
uniform float surface_heights_start_distance = 800.0;
uniform sampler2D surface_heightmap;

// Land use-based detail textures
uniform sampler2D landuse;
uniform bool has_landuse = false;

uniform sampler2DArray albedo_tex: hint_albedo;
uniform sampler2DArray normal_tex: hint_normal;
uniform sampler2DArray ambient_tex;
uniform sampler2DArray specular_tex;
uniform sampler2DArray roughness_tex;
uniform sampler2DArray ao_tex;

// See Vegetation.get_metadata_texture for details
uniform sampler2D metadata;

uniform float distance_tex_switch_distance = 20.0;
uniform float transition_space = 8.0;
uniform sampler2DArray distance_tex: hint_albedo;
uniform sampler2DArray distance_normals: hint_normal;

uniform float normal_scale = 1.0;
uniform float ortho_saturation = 1.5;
uniform float ortho_blue_shift_factor = 0.9;

uniform float size;

varying vec3 camera_pos;
varying vec3 world_pos;
varying float world_distance;
varying float camera_distance;

float get_height(vec2 uv) {
	return texture(heightmap, uv).r * height_scale;
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
	long_normal.y = size * e * 1.0; // scaling by <1.0 makes the normals more drastic

	return normalize(long_normal);
}

void vertex() {
	VERTEX.y = get_height(UV);
	NORMAL = get_normal(UV);
	
	world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_distance = length(world_pos.xz);
	
	camera_pos = CAMERA_MATRIX[3].xyz;
	camera_distance = length(world_pos - camera_pos);
	
	if (has_surface_heights) {
		float surface_height_factor = float(world_distance > surface_heights_start_distance);
		VERTEX.y += texture(surface_heightmap, UV).r * height_scale * surface_height_factor;
	}
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

// Workaround for a bug in `texelFetch` - use this instead!
// More info at https://github.com/godotengine/godot/issues/31732
vec4 texelGet ( sampler2D tg_tex, ivec2 tg_coord, int tg_lod ) {
	vec2 tg_texel = 1.0 / vec2(textureSize(tg_tex, 0));
	vec2 tg_getpos = (vec2(tg_coord) * tg_texel) + (tg_texel * 0.5);
	return texture(tg_tex, tg_getpos, float(tg_lod));
}


vec3 get_ortho_color(vec2 uv) {
	vec3 blue_shifted_sample = shift_blue(texture(orthophoto, uv).rgb, ortho_blue_shift_factor);
	return saturate_color(blue_shifted_sample, ortho_saturation);
}



void fragment() {
	int splat_id = int(round(texture(landuse, UV).r * 255.0));
	
	vec3 metadata_value = texelGet(metadata, ivec2(splat_id, 0), 0).rgb;
	
	float plant_row = metadata_value.r * 255.0;
	float ground_texture_scale = metadata_value.g * 128.0; // FIXME: Move scale to uniform
	float fade_texture_scale = metadata_value.b * 128.0;
	
	// Calculate the near factor: 0.0 when only the distance texture should be applied,
	// 1.0 when only the close ground texture should be used
	float near_factor = 0.0;
	
	if (camera_distance < distance_tex_switch_distance - transition_space) {
		near_factor = 1.0;
	} else if (camera_distance < distance_tex_switch_distance + transition_space) {
		near_factor = camera_distance - (distance_tex_switch_distance - transition_space);
		near_factor /= transition_space * 2.0;
	} else {
		near_factor = 0.0;
	}
	
	// Apply textures
	if (ground_texture_scale > 0.0 && has_landuse) {
		// We have special near textures here
		if (near_factor >= 1.0) {
			vec3 scaled_uv = vec3(UV * size / ground_texture_scale, plant_row);
		
			ALBEDO = texture(albedo_tex, scaled_uv).rgb;
			// TODO: Angle normals by previous vertex NORMAL so that the shading isn't overwritten (need to use TANGENT)
			NORMALMAP = texture(normal_tex, scaled_uv).rgb;
			NORMALMAP_DEPTH = 2.5;
			AO = texture(ambient_tex, scaled_uv).r;
			SPECULAR = texture(specular_tex, scaled_uv).r;
			ROUGHNESS = texture(roughness_tex, scaled_uv).r;
		} else if (near_factor <= 0.0) {
			// Apply the distance tex only
			if (fade_texture_scale > 0.0) {
				vec3 scaled_far_uv = vec3(UV * size / fade_texture_scale, plant_row);
				ALBEDO = texture(distance_tex, scaled_far_uv).rgb;
			} else {
				// If none is available, just use the orthophoto
				ALBEDO = get_ortho_color(UV);
			}
		} else {
			// Blend between close tex and distance tex
			vec3 scaled_near_uv = vec3(UV * size / ground_texture_scale, plant_row);
			vec3 scaled_far_uv = vec3(UV * size / fade_texture_scale, plant_row);
			
			// Select the distance sample depending on whether a fade texture is available (ortho otherwise)
			vec3 second_sample;
			vec3 second_sample_normals;
			if (fade_texture_scale > 0.0) {
				second_sample = texture(distance_tex, scaled_far_uv).rgb;
				second_sample_normals = texture(distance_normals, scaled_far_uv).rgb;
			} else {
				second_sample = get_ortho_color(UV);
			}
			
			ALBEDO = mix(texture(albedo_tex, scaled_near_uv).rgb, second_sample, near_factor);
		}
	} else {
		// No near texture is available, so just apply the ortho
		// TOOD: Restructure to also handle the case of a fade texture being available, but no near texture
		ALBEDO = get_ortho_color(UV);
	}
}