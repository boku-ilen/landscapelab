shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// Used in combination with Fragmentshader's "ALPHA_ANTIALIASING_EDGE" & "ALPHA_TEXTURE_COORDINATE" for nicer Foliage, but currently costs too much
//render_mode cull_disabled, depth_draw_opaque, alpha_to_coverage_and_one;
//

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"
#include "res://Util/Shading/generate_gradients_from_uvs.gdshaderinc"
#include "res://Util/Shading/generate_normal_from_albedo.gdshaderinc"

global uniform vec3 HCY_SHIFT;

uniform sampler2D[100] texture_map : source_color, repeat_disable, filter_linear_mipmap_anisotropic;

uniform sampler2D world_space_normal_map: hint_normal, repeat_enable;
uniform sampler2D wind_map;
uniform float world_space_normal_scale = 0.007;

uniform sampler2D stripe_noise: filter_linear;

uniform float amplitude = 0.1;
uniform vec2 speed = vec2(0.5, 0.4);
uniform vec2 scale = vec2(0.06, 0.11);

uniform float max_distance;

varying flat float dist_id;
varying float random_hue_shift;
varying float stripe_sample;
varying float wind_strength;

global uniform vec3 VEGETATION_CENTER;

uniform bool is_billboard = true;

void vertex() {
	dist_id = clamp(INSTANCE_CUSTOM.r * 255.0, 0.0, 99.0);

	vec3 camera_pos = VEGETATION_CENTER + vec3(0.0, 1.0, 0.0) * INV_VIEW_MATRIX[3].xyz;
	vec3 worldpos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	float world_distance = length(camera_pos - worldpos);

	vec3 mesh_normal = NORMAL;

	float angle = INSTANCE_CUSTOM.a;
	vec2 stripe_position = worldpos.xz / 256.0;
	mat2 rotation = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
	stripe_position = rotation * stripe_position;

	random_hue_shift = (0.9 - texture(world_space_normal_map, worldpos.xz / 512.0).z) * 1.2;
	stripe_sample = 0.1 + texture(stripe_noise, stripe_position).r * 0.9;

	// FIXME: scale this and the vec3(0.0, 4.0, 0.0) to look good and match the LOD plane
	vec3 n_up = normalize(COLOR.xyz + vec3(0.0, 1.0, 0.0));
	vec3 n_forward = cross(vec3(1.0, 0.0, 0.0), n_up);
	vec3 n_right = cross(n_up, n_forward);

	mat3 basis = mat3(n_right, n_up, n_forward);

	// TODO: Keep the normal of non-billboard meshes?
	vec3 texture_normal = (texture(world_space_normal_map, worldpos.xz * world_space_normal_scale).xyz - vec3(0.5, 0.5, 0.5)).xzy * 2.0;
	NORMAL = basis * normalize(texture_normal + vec3(0.0, 4.0, 0.0));

	// Also make normals follow a "half-dome" around the mesh to get some front- and back-lighting
	NORMAL = mix(NORMAL, basis * normalize(VERTEX), smoothstep(40.0, 10.0, world_distance) * 0.8); // Scale by distance for smooth transition to LOD

	// Account for the texture's aspect ratio
	if (is_billboard) {
		ivec2 texture_size = textureSize(texture_map[int(round(dist_id))], 0);
		VERTEX += mesh_normal * (float(texture_size.x) / float(texture_size.y) - 1.0) * 0.5;
	}

	// Read plant size
	float size = (INSTANCE_CUSTOM.g * 255.0 + INSTANCE_CUSTOM.b);

	// Safeguard against potential erroneous values
	size = max(size, 0.1);

	// Scale size by hue-shift
	size  *= (1.0 + random_hue_shift * 2.0);

	//if (stripe_sample < 0.6)
	//size *= stripe_sample;

	// Scale by the size
	VERTEX *= size;

	float wind_amount = texture(wind_map, worldpos.xz / 512.0 - TIME * speed / 2500.0).r;
	vec2 wind_offset_vector = (inverse(MODEL_MATRIX) * vec4(speed.x, 0.0, speed.y, 0.0)).xz * wind_amount * 0.04;

	wind_strength = length(wind_offset_vector);

	// Move the upper vertices around for a wind wave effect
	float inv_y = 1.0 - UV.y;

	VERTEX.xz += inv_y * wind_offset_vector * min(size, 1.0);
	//NORMAL -= vec3(wind_offset_vector.x, 0.0, wind_offset_vector.y) * 0.8;

	float speed_length = length(speed);
	VERTEX.x += inv_y * 0.002 * sin(worldpos.x * scale.x * 0.75 + TIME * speed_length) * cos(worldpos.z * scale.x + TIME * speed_length * 0.25);
	VERTEX.z += inv_y * 0.002 * sin(worldpos.x * scale.y + TIME * speed_length * 0.35) * cos(worldpos.z * scale.y * 0.80 + TIME * speed_length);

	// Update the world position again with the scaled Vertex (otherwise the distance fade-out is off)
	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Move vertices down when they are far away - makes the plants "grow out" as they fade in,
	//  which produces a nice fade-in result since it avoids sampling the lower parts of plants
	//  that are usually darker
	float dist_alpha = smoothstep(max_distance - 5.0, max_distance + 5.0, world_distance);

	VERTEX.y -= dist_alpha * size;
}

void fragment() {
	// See https://github.com/godotengine/godot/issues/42411
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	int texture_index = clamp(int(round(dist_id)), 0, 99);

	vec4 color = texture(texture_map[texture_index], UV);

	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.2;

	// Vary the transmission based on how bright and/or green the plant is here
	// (This is to approximate a higher transmission for leaves)
	BACKLIGHT = vec3(1.0, 1.0, 0.5) * min(color.g * 2.0, 1.0) * 0.5;

	// Hue shift to make plant appear e.g. dryer
	vec3 hcy = RGBtoHCY(color.rgb);
//
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

	hcy.r += HCY_SHIFT.r + random_hue_shift;
	hcy.g *= HCY_SHIFT.g * (random_hue_shift + 1.0) * 0.8 * stripe_sample;
	hcy.b *= HCY_SHIFT.b * (random_hue_shift + 1.0) * 0.8 * stripe_sample;

	ALBEDO = HCYtoRGB(hcy);

	// Other material parameters
	//RIM = 0.4;
	AO_LIGHT_AFFECT = 0.9;
	AO = max(generate_darken_gradient(UV.y, 0.6, 0.6, 0.0) - wind_strength * 0.5, 0.0);
	NORMAL_MAP = generate_normal_from_albedo(texture_map[texture_index], UV, vec4(0.7, 0.7, 0.7, 0.8), 0.05, 1.0);
	NORMAL_MAP_DEPTH = 1.5;
	METALLIC = 0.0;

	// hue of -1.6 is approximately the middle of green.
	// we want the roughness to go from small (when green) to large (when not green)
	float greenness = clamp(pow(abs(hcy.r + 1.6) * 4.0, 4.0), 0.0, 1.0);

	ROUGHNESS = mix(0.65, 0.95, greenness);
	SPECULAR = mix(0.05, 0.2, AO);

	//ALBEDO = mix(ALBEDO,
		//vec3(mix(0.25, 0.85, pow(abs(hcy.r + 1.7), 2.0))),
		//step(0.0, sin(TIME * 2.0)));
}
