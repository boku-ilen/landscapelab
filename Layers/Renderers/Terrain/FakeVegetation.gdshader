shader_type spatial;

#define DISTRIBUTION_RESOLUTION 64

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

global uniform vec3 HCY_SHIFT;

uniform sampler2D heightmap: repeat_disable;
uniform float height_scale = 1.0;

uniform sampler2D landuse: repeat_disable, filter_nearest;
uniform sampler2D landuse_overlay: repeat_disable, filter_nearest;
uniform bool use_landuse_overlay = true;

uniform sampler2D uv_offset: filter_linear;
uniform sampler2D uv_normals;
uniform sampler2D plant: source_color;

uniform sampler2D world_space_normal_map: hint_normal, repeat_enable;
uniform float world_space_normal_scale = 0.007;

uniform sampler2D high_frequency_noise: repeat_enable;

uniform sampler2D[96] distribution_array: repeat_enable, filter_nearest;
uniform sampler2D row_ids;
uniform sampler2D[100] texture_map : source_color, repeat_disable;

uniform float size;

varying vec3 camera_pos;
varying vec3 worldpos;


// Adapted from https://www.shadertoy.com/view/mds3R4
vec4 fractal_texture(sampler2D tex, vec2 uv, float depth) {
	uv.xy *= 2.0;

	float clamped_depth = max(depth, 10.0);

    //Find the pixel level of detail
	float LOD = log(clamped_depth);
    //Round LOD down
	float LOD_floor = floor(LOD);
    //Compute the fract part for interpolating
	float LOD_fract = LOD - LOD_floor;

    //Compute scaled uvs
	vec2 uv1 = uv.xy / exp(LOD_floor - 1.0);
	vec2 uv2 = uv.xy / exp(LOD_floor + 0.0);
	vec2 uv3 = uv.xy / exp(LOD_floor + 1.0);

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
	return clamp(height, -1000.0, 50000.0);
}

float get_landuse(vec2 uv) {
	vec4 lu_sample = texture(landuse_overlay, uv);
	float overlay = use_landuse_overlay ? round(lu_sample.r * 255.0) + round(lu_sample.g * 255.0 * 255.0) : 0.0;

	return overlay > 0.0 ? overlay : texture(landuse, uv).r;
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

void vertex() {
	camera_pos = CAMERA_POSITION_WORLD;

	// Hide transition with a "skirt": outermost row of vertices is moved down to create a wall that fills holes
	if (UV.x < -0.1 || UV.x > 1.1 || UV.y < -0.1 || UV.y > 1.1) {
		VERTEX.y = -1000.0;
	} else {
		VERTEX.y = get_height(UV);
	}

	int splatmap_value = int(round(get_landuse(UV)));
	int distribution_id = int(round(texelFetch(row_ids, ivec2(splatmap_value, 0), 0).r * 255.0));
	vec3 dist_value = texture(distribution_array[distribution_id - 1], (worldpos.xz) / float(DISTRIBUTION_RESOLUTION)).rgb;

	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	VERTEX.y += max(0.1, (dist_value.g * 255.0 + dist_value.b) * float(distribution_id > 0) * 0.75);
}

void fragment() {
	int distribution_id = 0;
	vec3 dist_value;

	float highest_height = 0.0;

	for (float x_off = -2.0; x_off <= 2.0; x_off += 2.0) {
		for (float y_off = -2.0; y_off <= 2.0; y_off += 2.0) {
			vec2 offset = vec2(x_off, y_off) / size;
			int splatmap_value = int(round(get_landuse(UV + offset)));
			int distribution_id_here = int(round(texelFetch(row_ids, ivec2(splatmap_value, 0), 0).r * 255.0));
			vec3 dist_value_here = texture(distribution_array[distribution_id_here - 1], (worldpos.xz) / float(DISTRIBUTION_RESOLUTION)).rgb;

			float height_here = max(0.2, (dist_value_here.g * 255.0 + dist_value_here.b) * float(distribution_id_here > 0));

			if (distribution_id_here != 0 && height_here > highest_height) {
				distribution_id = distribution_id_here;
				dist_value = dist_value_here;
				highest_height = height_here;
			}
		}
	}

	float dist_id = dist_value.r * 255.0;
	float active = float(distribution_id != 0);

	dist_id = clamp(dist_id, 0.0, 99.0); // To ensure we don't read invalid data

	if (active < 0.5) discard;

	float depth = (1.0 - FRAGCOORD.z) / FRAGCOORD.w;

	vec2 uv = texture(uv_offset, UV * 30.0).rg;

	vec4 plant_sample = texture(texture_map[int(round(dist_id))], uv, depth * 0.002);

	BACKLIGHT = vec3(1.0, 1.0, 0.5) * min(plant_sample.g * 2.0, 1.0) * 0.5;

	// Hue shift to make plant appear e.g. dryer
	vec3 hcy = RGBtoHCY(plant_sample.rgb);

	//float begin = mix(-0.6, -PI, min(HCY_SHIFT.r * 2.0, 1.0));
	//float end = -0.6;
//
	//if (hcy.x > begin && hcy.x < end) {
		//// `factor` is the position of hcy.x within the range of begin to end, scaled to -PI/2 to +PI/2.
		//// This way, by getting the cosine of the factor, we get a smooth curve from 0..1..0.
		//float factor = hcy.x - begin;
		//factor /= end - begin;
		//factor -= 0.5;
		//factor *= PI;
//
		//float addition = cos(factor) * (end - begin) / 2.0;
		//hcy.x += addition;
		//hcy.y += addition * 0.01;
	//}
//
	float random_hue_shift = (0.9 - texture(world_space_normal_map, worldpos.xz / 512.0).z) * 1.6;
	hcy.r += random_hue_shift;
	hcy.g *= HCY_SHIFT.g * (random_hue_shift + 1.0);
	hcy.b *= HCY_SHIFT.b * (random_hue_shift + 1.0);
	
	ALBEDO = HCYtoRGB(hcy);
	
	// At steeper angles, the vegetation tends to look darker since we see through more plants and
	//  therefore see more of the self-shadowing
	float view_angle = max(dot((INV_VIEW_MATRIX  * vec4(NORMAL, 0.0)).xyz, CAMERA_DIRECTION_WORLD), 0.0);
	ALBEDO *= mix(0.85, 1.0, view_angle);
	
	ALPHA = clamp(plant_sample.a * mix(4.0, 1.5, dot(VIEW, NORMAL)), 0.75, 0.99);
	ALPHA *= smoothstep(90.0, 110.0, length((camera_pos - worldpos)));
	ALPHA_HASH_SCALE = 1.0;
	NORMAL = (VIEW_MATRIX * vec4(get_normal(UV), 0.0)).xyz;

	vec3 normal = texture(uv_normals, UV * 10.0).rgb;
	vec3 world_normal = texture(world_space_normal_map, worldpos.xz * world_space_normal_scale).xyz;
	vec3 high_frequency_normal = texture(high_frequency_noise, worldpos.xz * world_space_normal_scale * 2.0).xyz;
	NORMAL_MAP = normalize(world_normal + high_frequency_normal * 2.0);//mix(world_normal, high_frequency_normal, 0.5);
	NORMAL_MAP_DEPTH = 0.5;

	METALLIC = 0.0;

	// hue of -1.6 is approximately the middle of green.
	// we want the roughness to go from small (when green) to large (when not green)
	float greenness = clamp(pow(abs(hcy.r + 1.6) * 4.0, 4.0), 0.0, 1.0);

	ROUGHNESS = mix(0.65, 0.95, greenness);
	SPECULAR = 0.15;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
