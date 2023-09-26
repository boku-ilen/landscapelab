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

uniform bool has_terraforming_texture;
uniform sampler2D terraforming_texture: repeat_disable, filter_nearest;
uniform sampler2D terraforming_weights: repeat_disable, filter_nearest;

uniform float texture_thresholds[14];
uniform sampler2DArray ground_textures: source_color;
uniform sampler2DArray ground_normals;

// From https://www.shadertoy.com/view/mds3R4
vec4 fractal_texture(sampler2D tex, vec2 uv, float depth) {
    //Find the pixel level of detail
	float LOD = log(depth);
    //Round LOD down
	float LOD_floor = floor(LOD);
    //Compute the fract part for interpolating
	float LOD_fract = LOD - LOD_floor;
	
    //Compute scaled uvs
	vec2 uv1 = uv / exp(LOD_floor - 1.0);
	vec2 uv2 = uv / exp(LOD_floor + 0.0);
	vec2 uv3 = uv / exp(LOD_floor + 1.0);
	
    //Sample at 3 scales
	vec4 tex0 = texture(tex, uv1);
	vec4 tex1 = texture(tex, uv2);
	vec4 tex2 = texture(tex, uv3);
    
    //Blend samples together
	return (tex1 + mix(tex0, tex2, LOD_fract)) * 0.5;
}

vec4 fractal_texture_array(sampler2DArray tex, vec3 uv, float depth) {
    //Find the pixel level of detail
	float LOD = log(depth);
    //Round LOD down
	float LOD_floor = floor(LOD);
    //Compute the fract part for interpolating
	float LOD_fract = LOD - LOD_floor;
	
    //Compute scaled uvs
	vec3 uv1 = vec3(uv.xy / exp(LOD_floor - 1.0), uv.z);
	vec3 uv2 = vec3(uv.xy / exp(LOD_floor + 0.0), uv.z);
	vec3 uv3 = vec3(uv.xy / exp(LOD_floor + 1.0), uv.z);
	
    //Sample at 3 scales
	vec4 tex0 = texture(tex, uv1);
	vec4 tex1 = texture(tex, uv2);
	vec4 tex2 = texture(tex, uv3);
    
    //Blend samples together
	return (tex1 + mix(tex0, tex2, LOD_fract)) * 0.5;
}

// Workaround for a bug in `texelFetch` - use this instead!
// More info at https://github.com/godotengine/godot/issues/31732
vec4 texelGet ( sampler2D tg_tex, ivec2 tg_coord, int tg_lod ) {
	vec2 tg_texel = 1.0 / vec2(textureSize(tg_tex, 0));
	vec2 tg_getpos = (vec2(tg_coord) * tg_texel) + (tg_texel * 0.5);
	return texture(tg_tex, tg_getpos, float(tg_lod));
}

float get_height(vec2 uv) {
	float height = texture(heightmap, uv).r * height_scale;
//	float correction = texture(terraforming_texture, uv).r;
//	float weight = texture(terraforming_weights, uv).r * float(has_terraforming_texture);
//	height = mix(height, correction, weight);
	
	// Clamp to prevent weird behavior with extreme nodata values
	// TODO: Might have to be generalized further to be more robust
	return clamp(height, -1000.0, 50000.0);
}

vec3 get_normal(vec2 normal_uv_pos) {
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor.
	float e = 10.0 / size;
	
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


// Takes two colors: one coming from a detailed texture, one from a more basic one.
// Returns a color with the hue coming from the detailed texture and chroma and luminance blended
//  between the detailed and the base color based on shift_scale.
// Used for mixing orthophoto and detail textures: by using the hue from the detail textures, we get
//  good colors and a nice transition, while we still get some large structures from the orthophoto
//  at distances by using its chroma and luminance.
vec3 hue_shift(vec3 detail, vec3 base, float shift_scale) {
	// Convert to Hue-Chroma-Luminance color space
	vec3 base_hcy = RGBtoHCY(base);
	vec3 detail_hcy = RGBtoHCY(detail);

	// Adapt the detail texture hue and chroma to the orthophoto
	detail_hcy.y = mix(detail_hcy.y, base_hcy.y, shift_scale);
	detail_hcy.z = mix(detail_hcy.z, base_hcy.z, shift_scale);
	
	// Return RGB result
	return HCYtoRGB(detail_hcy);
}

void fragment() {
	float depth = FRAGCOORD.z / FRAGCOORD.w;
	
	NORMAL = (VIEW_MATRIX * vec4(get_normal(UV), 0.0)).xyz;
	
	vec3 ortho_color = get_ortho_color(UV);
	
	vec3 detail_color = vec3(0.0);
	vec2 scaled_near_uv = vec2(UV * size / 2.0);
	
	float count = 0.0;
	
	// Get detail texture sample, but blur the position to get nice transitions
	for (float x_off = -1.0; x_off <= 1.0; x_off += 0.5) {
		for (float y_off = -1.0; y_off <= 1.0; y_off += 0.5) {
			vec2 offset_vector = vec2(x_off / size, y_off / size);
			float splat_id = texture(landuse, UV + offset_vector).r;
			
			int texture_index = 0;
			
			for (int i = 0; i < 16; i++) {
				if (splat_id < texture_thresholds[i]) {
					texture_index = i;
					break;
				}
			}
			
			detail_color += fractal_texture_array(ground_textures, vec3(scaled_near_uv, float(texture_index)), depth).rgb;
			count++;
		}
	}
	
	detail_color /= count;
	
	float dist_scale = min(depth / 300.0, 1.0);
	
	float splat_id = texture(landuse, UV).r;
	
	if (splat_id < 250.0 || splat_id > 261.0) {
		ALBEDO = hue_shift(detail_color, ortho_color, dist_scale);
	} else {
		// If we have water here, use only the detail color - the color can be very off otherwise
		ALBEDO = detail_color;
	}
	
	// Normal
	int texture_index = 0;
	
	for (int i = 0; i < 16; i++) {
		if (splat_id < texture_thresholds[i]) {
			texture_index = i;
			break;
		}
	}
	
	NORMAL_MAP = fractal_texture_array(ground_normals, vec3(scaled_near_uv, float(texture_index)), depth).rgb;
	
	METALLIC = 0.0;
	ROUGHNESS = 0.95;
	NORMAL_MAP_DEPTH = 1.0;
}