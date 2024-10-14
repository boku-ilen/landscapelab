shader_type spatial;
render_mode depth_draw_opaque;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

global uniform vec3 HCY_SHIFT;

// Brigthness, Saturation and Contrast for terrain
global uniform vec3 HCY_TERRAIN_SHIFT;

// Basic Terrain
uniform sampler2D orthophoto: source_color, repeat_disable;
uniform sampler2D heightmap: repeat_disable;
uniform float height_scale = 1.0;

// Land use-based detail textures
uniform sampler2D landuse: repeat_disable, filter_nearest;

uniform bool use_landuse_overlay = false;
uniform sampler2D landuse_overlay: repeat_disable, filter_nearest, hint_default_black;

uniform float detail_only_range = 50.0;
uniform float detail_ortho_blend_range = 700.0;

uniform float size;

varying vec3 world_pos;

//uniform bool has_terraforming_texture;
//uniform sampler2D terraforming_texture: repeat_disable, filter_nearest;
//uniform sampler2D terraforming_weights: repeat_disable, filter_nearest;

uniform sampler2DArray ground_textures: source_color;
uniform sampler2DArray ground_normals: hint_normal;
uniform sampler2DArray ground_displacement: hint_default_black;

uniform bool make_hole = true;
uniform sampler2D detail_noise;
uniform float[10] detail_noise_lid_weights;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Adapted from https://www.shadertoy.com/view/mds3R4
vec4 fractal_texture_array(sampler2DArray tex, vec3 uv, float depth) {
	uv.xy *= 2.0;

	float clamped_depth = max(depth, 10.0);

    //Find the pixel level of detail
	float LOD = log(clamped_depth);
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

    // Blend samples together
	// Blend fully towards tex1 at close distances in order to have a clear detail view
	return mix(tex1, mix(tex0, tex2, clamp(LOD_fract, 0.0, 1.0)), min(depth / 20.0, 0.5));
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
	//float center_center = get_height(normal_uv_pos + vec2(0, 0));
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

float get_landuse(vec2 uv) {
	vec4 lu_sample = texture(landuse_overlay, uv);
	float overlay = use_landuse_overlay ? round(lu_sample.r * 255.0) + round(lu_sample.g * 255.0 * 255.0) : 0.0;

	return overlay > 0.0 ? overlay : texture(landuse, uv).r;
}

void vertex() {
	// Hide transition with a "skirt": outermost row of vertices is moved down to create a wall that fills holes
	if (UV.x < -0.1 || UV.x > 1.1 || UV.y < -0.1 || UV.y > 1.1) {
		VERTEX.y = -1000.0;
	} else {
		VERTEX.y = get_height(UV);
	}

	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 camera_to_world = world_pos - INV_VIEW_MATRIX[3].xyz;
	float camera_distance = length(camera_to_world);

	float max_distance = max(abs(camera_to_world.x), abs(camera_to_world.z));
	if (make_hole && max_distance < 47.0) {
		VERTEX.y -= 10.0;
	}

	if (!make_hole) {
		// This is the detail mesh
		float splat_id = get_landuse(UV);
		int texture_index = int(splat_id / 1000.0) - 1;

		vec2 scaled_near_uv = world_pos.xz;

		//float normal_y = fractal_texture_array(ground_displacement, vec3(scaled_near_uv, float(texture_index)), camera_distance).b;

		// Attempt to scale this normal to about +- 0.025
		//normal_y = (normal_y - 0.95) * 0.5;

		float offset = fractal_texture_array(ground_displacement, vec3(scaled_near_uv, float(texture_index)), camera_distance).r - 0.75;
		offset += texture(detail_noise, scaled_near_uv / 40.0).r - 0.75;
		offset *= detail_noise_lid_weights[texture_index];

		offset *= float(texture_index >= 0 && texture_index <= 10);

		// Make transition more seamless by lerping between 1.0 in the center and 0.0 on the border
		float center_distance_factor = (0.5 - min(abs(UV.x - 0.5), abs(UV.y - 0.5))) * 2.0;

		VERTEX.y += offset * center_distance_factor;
	}

//	if (has_surface_heights) {
//		float surface_height_factor = float(world_distance > surface_heights_start_distance);
//		float texture_read = texture(surface_heightmap, UV).r;
//		if (texture_read < 80.0) {
//			// Nodata may be encoded as infinity
//			VERTEX.y += texture_read * height_scale * surface_height_factor;
//		}
//	}
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

	base_hcy.g *= HCY_SHIFT.g * HCY_TERRAIN_SHIFT.g;
	base_hcy.b *= HCY_SHIFT.b * HCY_TERRAIN_SHIFT.b;

	detail_hcy.r += HCY_SHIFT.r;
	detail_hcy.g *= HCY_SHIFT.g;
	detail_hcy.b *= HCY_SHIFT.b;

	// Adapt the detail texture hue and chroma to the orthophoto
	detail_hcy.y = mix(detail_hcy.y, base_hcy.y, shift_scale);
	detail_hcy.z = mix(detail_hcy.z, base_hcy.z, shift_scale);

	// Return RGB result
	return HCYtoRGB(detail_hcy);
}

void fragment() {
	float depth = (1.0 - FRAGCOORD.z) / FRAGCOORD.w;

	NORMAL = (VIEW_MATRIX * vec4(get_normal(UV), 0.0)).xyz;

	vec3 detail_color = vec3(0.0);
	vec2 scaled_near_uv = world_pos.xz;

	float count = 0.0;

	vec2 noise = vec2(
		rand(SCREEN_UV),
		rand(SCREEN_UV + vec2(0.123, 0.123))
	);

	// Get detail texture sample, but blur the position to get nice transitions
	for (float x_off = -0.5; x_off <= 0.5; x_off += 0.5) {
		for (float y_off = -0.5; y_off <= 0.5; y_off += 0.5) {
			vec2 offset_vector = vec2(x_off, y_off);
			offset_vector += (noise - vec2(0.5)) * 0.5;
			offset_vector /= size;

			float splat_id = get_landuse(UV + offset_vector);

			int texture_index = int(splat_id / 1000.0) - 1;

			detail_color += fractal_texture_array(ground_textures, vec3(scaled_near_uv, float(texture_index)), depth).rgb;
			count++;
		}
	}

	detail_color /= count;

	float dist_scale = clamp((depth - detail_only_range) / detail_ortho_blend_range, 0.0, 1.0);

	float splat_id = get_landuse(UV);

	if (int(splat_id / 1000.0) != 6) {
		vec3 ortho_color = texture(orthophoto, UV).rgb;
		ALBEDO = hue_shift(detail_color, ortho_color, dist_scale);
	} else {
		// If we have water here, use only the detail color - the color can be very off otherwise
		ALBEDO = detail_color;
	}

	// Normal
	int texture_index = int(splat_id / 1000.0) - 1;

	NORMAL_MAP = fractal_texture_array(ground_normals, vec3(scaled_near_uv, float(texture_index)), depth).rgb;

	METALLIC = 0.0;
	ROUGHNESS = 0.95;
	NORMAL_MAP_DEPTH = 1.0;
}