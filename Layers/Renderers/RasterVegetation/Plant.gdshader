shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// Used in combination with Fragmentshader's "ALPHA_ANTIALIASING_EDGE" & "ALPHA_TEXTURE_COORDINATE" for nicer Foliage, but currently costs too much
//render_mode cull_disabled, depth_draw_opaque, alpha_to_coverage_and_one;
//

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"
#include "res://Util/Shading/generate_gradients_from_uvs.gdshaderinc"
#include "res://Util/Shading/generate_normal_from_albedo.gdshaderinc"

global uniform vec3 HCY_SHIFT;

uniform sampler2D[100] texture_map : source_color, repeat_disable;

uniform sampler2D world_space_normal_map: hint_normal, repeat_enable;
uniform sampler2D wind_map;
uniform float world_space_normal_scale = 0.007;

uniform float amplitude = 0.1;
uniform vec2 speed = vec2(0.5, 0.4);
uniform vec2 scale = vec2(0.06, 0.11);

uniform float max_distance;

varying float dist_id;
varying float random_hue_shift;
varying float wind_strength;

uniform bool is_billboard = true;

void vertex() {
	dist_id = INSTANCE_CUSTOM.r * 255.0;

	vec3 camera_pos = INV_VIEW_MATRIX[3].xyz;
	vec3 worldpos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	float world_distance = length(camera_pos - worldpos);

	vec3 mesh_normal = NORMAL;

	random_hue_shift = (0.9 - texture(world_space_normal_map, worldpos.xz / 512.0).z) * 1.6;

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

	float size = INSTANCE_CUSTOM.g * 255.0 + INSTANCE_CUSTOM.b;

	// Scale by the size
	VERTEX *= size;

	float wind_amount = texture(wind_map, worldpos.xz / 512.0 - TIME * speed / 2500.0).r;
	vec2 wind_offset_vector = (inverse(MODEL_MATRIX) * vec4(speed.x, 0.0, speed.y, 0.0)).xz * wind_amount * 0.04;

	wind_strength = length(wind_offset_vector);

	// Move the upper vertices around for a wind wave effect
	if (UV.y < 0.3) {

		VERTEX.xz += wind_offset_vector * min(size, 1.0);
		//NORMAL -= vec3(wind_offset_vector.x, 0.0, wind_offset_vector.y) * 0.8;

		float speed_length = length(speed);
		VERTEX.x += 0.002 * sin(worldpos.x * scale.x * 0.75 + TIME * speed_length) * cos(worldpos.z * scale.x + TIME * speed_length * 0.25);
		VERTEX.z += 0.002 * sin(worldpos.x * scale.y + TIME * speed_length * 0.35) * cos(worldpos.z * scale.y * 0.80 + TIME * speed_length);

		// Also bend them away from the camera to make it look better from above
		//VERTEX.xz += (inverse(MODELVIEW_MATRIX) * vec4(0.0, 0.5, 0.0, 0.0)).xz * VERTEX.y;
	}

	// Update the world position again with the scaled Vertex (otherwise the distance fade-out is off)
	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Move vertices down when they are far away - makes the plants "grow out" as they fade in,
	//  which produces a nice fade-in result since it avoids sampling the lower parts of plants
	//  that are usually darker
	float dist = length(camera_pos.xz - worldpos.xz);
	float dist_alpha = smoothstep(max_distance - 20.0, max_distance + 20.0, dist);

	VERTEX.y -= dist_alpha;
}

void fragment() {
	// See https://github.com/godotengine/godot/issues/42411
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	vec4 color = texture(texture_map[int(round(dist_id))], UV);

	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.2;

	// Vary the transmission based on how bright and/or green the plant is here
	// (This is to approximate a higher transmission for leaves)
	BACKLIGHT = vec3(1.0, 1.0, 0.5) * min(color.g * 2.0, 1.0) * 0.5;

	// Hue shift to make plant appear e.g. dryer
	vec3 hcy = RGBtoHCY(color.rgb);

	float begin = mix(-0.6, -PI, min(HCY_SHIFT.r * 2.0, 1.0));
	float end = -0.6;

	if (hcy.x > begin && hcy.x < end) {
		// `factor` is the position of hcy.x within the range of begin to end, scaled to -PI/2 to +PI/2.
		// This way, by getting the cosine of the factor, we get a smooth curve from 0..1..0.
		float factor = hcy.x - begin;
		factor /= end - begin;
		factor -= 0.5;
		factor *= PI;

		float addition = cos(factor) * (end - begin) / 2.0;
		hcy.x += addition;
		hcy.y += addition * 0.01;
	}

	hcy.r += random_hue_shift;
	hcy.g *= HCY_SHIFT.g * (random_hue_shift + 1.0);
	hcy.b *= HCY_SHIFT.b * (random_hue_shift + 1.0);

	ALBEDO = HCYtoRGB(hcy);

	// Other material parameters
	//RIM = 0.4;
	AO_LIGHT_AFFECT = 0.9;
	AO = max(generate_darken_gradient(UV.y, 1.0, 0.6, 0.0) - wind_strength * 0.5, 0.0);
	NORMAL_MAP = generate_normal_from_albedo(texture_map[int(round(dist_id))], UV, vec4(0.7, 0.7, 0.7, 0.8), 0.05, 1.0);
	NORMAL_MAP_DEPTH = 1.0;
	METALLIC = 0.0;

	// hue of -1.6 is approximately the middle of green.
	// we want the roughness to go from small (when green) to large (when not green)
	float greenness = clamp(pow(abs(hcy.r + 1.6) * 4.0, 4.0), 0.0, 1.0);

	ROUGHNESS = mix(0.65, 0.95, greenness);
	SPECULAR = mix(0.05, 0.17, AO);

	//ALBEDO = mix(ALBEDO,
		//vec3(mix(0.25, 0.85, pow(abs(hcy.r + 1.7), 2.0))),
		//step(0.0, sin(TIME * 2.0)));
}
