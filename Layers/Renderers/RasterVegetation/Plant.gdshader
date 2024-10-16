shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"
#include "res://Util/Shading/generate_gradients_from_uvs.gdshaderinc"

global uniform vec3 HCY_SHIFT;

uniform sampler2D[100] texture_map : source_color, repeat_disable;

uniform sampler2D world_space_normal_map: hint_normal, repeat_enable;
uniform float world_space_normal_scale = 0.007;

uniform float amplitude = 0.1;
uniform vec2 speed = vec2(0.5, 0.4);
uniform vec2 scale = vec2(0.06, 0.11);

uniform float max_distance;

varying vec3 worldpos;
varying vec3 camera_pos;

varying float dist_id;
varying float random_hue_shift;

uniform bool is_billboard = true;

void vertex() {
	dist_id = INSTANCE_CUSTOM.r * 255.0;

	camera_pos = INV_VIEW_MATRIX[3].xyz;
	worldpos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	vec3 mesh_normal = NORMAL;

	random_hue_shift = (0.9 - texture(world_space_normal_map, worldpos.xz / 512.0).z) * 1.6;


	// TODO: Keep the normal of non-billboard meshes?
	NORMAL = mix(COLOR.xyz, (texture(world_space_normal_map, worldpos.xz * world_space_normal_scale).xyz - vec3(0.5, 0.5, 0.5)).xzy * 2.0, 0.5);

	// Also make normals follow a "half-dome" around the mesh to get some front- and back-lighting
	NORMAL = normalize(mix(NORMAL, VERTEX, 0.8));

	// Account for the texture's aspect ratio
	if (is_billboard) {
		ivec2 texture_size = textureSize(texture_map[int(round(dist_id))], 0);
		VERTEX += mesh_normal * (float(texture_size.x) / float(texture_size.y) - 1.0) * 0.5;
	}

	// Move the upper vertices around for a wind wave effect
	if (VERTEX.y > 0.3) {
		VERTEX.x += amplitude * sin(worldpos.x * scale.x * 0.75 + TIME * speed.x) * cos(worldpos.z * scale.x + TIME * speed.x * 0.25);
		VERTEX.z += amplitude * sin(worldpos.x * scale.y + TIME * speed.y * 0.35) * cos(worldpos.z * scale.y * 0.80 + TIME * speed.y);

		// Also bend them away from the camera to make it look better from above
		//VERTEX.xz += (inverse(MODELVIEW_MATRIX) * vec4(0.0, 0.5, 0.0, 0.0)).xz * VERTEX.y;
	}

	// Scale by the size
	VERTEX *= INSTANCE_CUSTOM.g * 255.0 + INSTANCE_CUSTOM.b;

	// Update the world position again with the scaled Vertex (otherwise the distance fade-out is off)
	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// See https://github.com/godotengine/godot/issues/42411
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	float blend_start_distance = max_distance - max_distance / 4.0;
	float dist = length(camera_pos.xz - worldpos.xz);

	float dist_alpha = clamp((dist -  blend_start_distance) / (max_distance - blend_start_distance), 0.0, 1.0);

	vec4 color = texture(texture_map[int(round(dist_id))], UV);

	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.7 + dist_alpha * 0.3;

	// Vary the transmission based on how bright and/or green the plant is here
	// (This is to approximate a higher transmission for leaves)
	BACKLIGHT = vec3(1.0, 1.0, 0.5) * min(color.g * 2.0, 1.0) * 0.5;

	// Make the plant darker at the bottom to simulate some shadowing
//	float size_scaled_uv = (1.0 - UV.y) * size; // ranges from 0 (bottom) to size (top)
//	color.rgb *= min(max(size_scaled_uv, fake_shadow_min_multiplier), fake_shadow_height) / fake_shadow_height;

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

	ALBEDO = HCYtoRGB(hcy) * generate_darken_gradient(UV.y, 0.35, 0.66, 0.0); // Gradient is wrong here, in future should be in AO (but currently not doing much)
	//ALBEDO = HCYtoRGB(hcy);

	//NORMAL_MAP = texture(normal_map, UV).xyz;

	// Other material parameters
	//RIM = 0.4;
	//AO = generate_darken_gradient(UV.y, 1.0, 0.6, 0.0); // Currently not doing much, because Rough + Spec are wrong. In future, use Gradient here instead of Albedo!
	METALLIC = 0.0;
	ROUGHNESS = 1.0;// - color.g * 0.5;
	SPECULAR = 0.1;
}