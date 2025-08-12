shader_type spatial;
render_mode depth_draw_opaque;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

global uniform vec3 HCY_SHIFT;

// Brigthness, Saturation and Contrast for terrain
global uniform vec3 HCY_TERRAIN_SHIFT;

// Basic Terrain
uniform sampler2D heightmap: repeat_disable, filter_linear;
uniform float height_scale = 1.0;

// Land use-based detail textures
uniform sampler2D landuse: repeat_disable, filter_nearest;

uniform bool use_landuse_overlay = false;
uniform sampler2D landuse_overlay: repeat_disable, filter_nearest, hint_default_black;

uniform bool use_height_overlay = false;
uniform sampler2D height_overlay: repeat_disable, filter_linear, hint_default_transparent;

uniform float detail_only_range = 50.0;
uniform float detail_ortho_blend_range = 700.0;

uniform float size;

varying vec3 world_pos;

uniform sampler2DArray ground_textures: source_color;
uniform sampler2DArray ground_normals: hint_normal;
uniform sampler2DArray ground_displacement: hint_default_black;
uniform sampler2DArray ground_roughness: hint_default_black;

uniform bool make_hole = true;
uniform float hole_size = 47.0;
uniform sampler2D detail_noise;
uniform sampler2D detail_noise_normals: hint_normal;
uniform float[10] detail_noise_lid_weights;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Adapted from https://www.shadertoy.com/view/mds3R4
vec4 fractal_texture_array(sampler2DArray tex, vec3 uv, float depth) {
	uv.xy *= 3.0;

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

float get_height(vec2 uv, bool local_use_height_overlay) {
	// R: Integer part of the overlay height (divided by 10)
	// G: Fractional part of the overlay height (divided by 10)
	// B: Mixing factor from overlay height (1.0) to heightmap height (0.0)
	vec4 overlay_height_sample = texture(height_overlay, uv) * height_scale;
	
	// Height directly from the heightmap
	float heightmap_height = texture(heightmap, uv).r * height_scale;
	
	// Interpolating from a valid value to an invalid value presents us with faulty results,
	//  since the result will seem valid (> 0.0), but actually be far lower than anything sensible.
	// 	Therefore, we check all 4 values surrounding the sample position and don't use the overlay
	//  height if any of them is invalid.
	vec4 near_values = textureGather(height_overlay, uv);
	bool is_surrounded_by_valid = (near_values.x > 0.0 && near_values.y > 0.0
			&& near_values.z > 0.0 && near_values.w > 0.0);
	
	if (is_surrounded_by_valid && local_use_height_overlay && use_height_overlay && overlay_height_sample.b > 0.01) {
		// Blend between heightmap height and overlay height by the blue channel of the overlay height
		return mix(heightmap_height, (overlay_height_sample.r + overlay_height_sample.g) * 10.0, overlay_height_sample.b);
	}

	// Clamp to prevent weird behavior with extreme nodata values
	// TODO: Might have to be generalized further to be more robust
	return clamp(heightmap_height, -1000.0, 50000.0);
}

vec3 get_normal(vec2 normal_uv_pos) {
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor.
	float e = 1.0 / size;

	// Sobel filter for getting the normal at this position
	float bottom_left = get_height(normal_uv_pos + vec2(-e, -e), true);
	float bottom_center = get_height(normal_uv_pos + vec2(0, -e), true);
	float bottom_right = get_height(normal_uv_pos + vec2(e, -e), true);

	float center_left = get_height(normal_uv_pos + vec2(-e, 0), true);
	//float center_center = get_height(normal_uv_pos + vec2(0, 0));
	float center_right = get_height(normal_uv_pos + vec2(e, 0), true);

	float top_left = get_height(normal_uv_pos + vec2(-e, e), true);
	float top_center = get_height(normal_uv_pos + vec2(0, e), true);
	float top_right = get_height(normal_uv_pos + vec2(e, e), true);

	vec3 long_normal;

	long_normal.x = -(bottom_right - bottom_left + 2.0 * (center_right - center_left) + top_right - top_left) / (size * e);
	long_normal.z = -(top_left - bottom_left + 2.0 * (top_center - bottom_center) + top_right - bottom_right) / (size * e);
	long_normal.y = size * e; // scaling by <1.0 makes the normals more drastic

	return normalize(long_normal);
}

float get_landuse(vec2 uv) {
	vec4 lu_sample = texture(landuse_overlay, uv);
	float overlay = use_landuse_overlay ? round(lu_sample.r * 255.0) + round(lu_sample.g * 255.0 * 255.0) : 0.0;

	return overlay > 0.0 ? overlay : texture(landuse, uv).r;
}

vec3 blend_normals(vec3 n1, vec3 n2)
{
    vec3 t = n1.xyz*vec3( 2,  2, 2) + vec3(-1, -1,  0);
    vec3 u = n2.xyz*vec3(-2, -2, 2) + vec3( 1,  1, -1);
    vec3 r = t*dot(t, u) - u*t.z;
    return normalize(r) * 0.5 + 0.5;
}

void vertex() {
	// Hide transition with a "skirt": outermost row of vertices is moved down to create a wall that fills holes
	if (UV.x < -0.1 || UV.x > 1.1 || UV.y < -0.1 || UV.y > 1.1) {
		VERTEX.y = -1000.0;
	} else {
		VERTEX.y = get_height(UV, true);
	}

	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 camera_to_world = world_pos - INV_VIEW_MATRIX[3].xyz;
	float camera_distance = length(camera_to_world);

	float max_distance = max(abs(camera_to_world.x), abs(camera_to_world.z));
	if (make_hole && max_distance < hole_size) {
		VERTEX.y -= hole_size / 5.0;
	}

	NORMAL = get_normal(UV);

	if (!make_hole) {
		// This is the detail mesh
		float splat_id = get_landuse(UV);
		int texture_index = int(splat_id / 1000.0) - 1;

		vec2 scaled_near_uv = world_pos.xz;

		float average_weight = 0.0;
		float count = 0.0;
		float offset = 0.0;

		// Get detail texture sample, but blur the position to get nice transitions
		for (float x_off = -0.5; x_off <= 0.5; x_off += 0.5) {
			for (float y_off = -0.5; y_off <= 0.5; y_off += 0.5) {
				vec2 offset_vector = vec2(x_off, y_off);
				offset_vector /= size;

				float local_splat_id = get_landuse(UV + offset_vector);
				int local_texture_index = int(local_splat_id / 1000.0) - 1;

				float weight_here = detail_noise_lid_weights[local_texture_index];
				weight_here *= float(local_texture_index >= 0 && local_texture_index <= 10);

				average_weight += weight_here;

				offset += (fractal_texture_array(ground_displacement, vec3(scaled_near_uv, float(local_texture_index)), camera_distance).r - 0.6) * weight_here;
				count++;
			}
		}

		average_weight /= count;
		offset /= count;

		offset += (texture(detail_noise, scaled_near_uv / 40.0).r - 0.5) * average_weight;

		offset *= float(texture_index >= 0 && texture_index <= 10);

		// Make transition more seamless by lerping between 1.0 in the center and 0.0 on the border
		float center_distance_factor = (0.5 - min(abs(UV.x - 0.5), abs(UV.y - 0.5))) * 2.0;

		VERTEX.y += offset * center_distance_factor;
	}
}

void fragment() {
	float depth = (1.0 - FRAGCOORD.z) / FRAGCOORD.w;
	vec3 normal_sample = get_normal(UV);
	NORMAL = (VIEW_MATRIX * vec4(normal_sample, 0.0)).xyz;// normalize(NORMAL + (VIEW_MATRIX * vec4(get_normal(UV), 0.0)).xyz);

	vec3 detail_color = vec3(0.0);
	vec3 detail_normal = vec3(0.0);

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
			detail_normal += fractal_texture_array(ground_normals, vec3(scaled_near_uv, float(texture_index)), depth).rgb;

			count++;
		}
	}

	detail_color /= count;
	detail_normal /= count;

	float splat_id = get_landuse(UV);
	int texture_index = int(splat_id / 1000.0) - 1;

	ALBEDO = detail_color;

	vec3 semi_detail_normal = texture(detail_noise_normals, scaled_near_uv / 40.0).rgb;

	NORMAL_MAP = mix(
		blend_normals(semi_detail_normal, detail_normal),
		detail_normal,
		max(1.0 - detail_noise_lid_weights[texture_index] * 2.0, 0.0));
	METALLIC = 0.0;
	ROUGHNESS = fractal_texture_array(ground_roughness, vec3(scaled_near_uv, float(texture_index)), depth).r;
	SPECULAR = 0.2;
	NORMAL_MAP_DEPTH = 1.5;
}