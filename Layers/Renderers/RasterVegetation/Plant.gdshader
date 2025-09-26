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

varying float lod_world_distance;
varying float world_distance;

global uniform vec3 VEGETATION_CENTER;

uniform bool is_billboard = true;

void vertex() {
	dist_id = clamp(INSTANCE_CUSTOM.r * 255.0, 0.0, 99.0);

	vec3 camera_pos = VEGETATION_CENTER + vec3(0.0, 1.0, 0.0) * INV_VIEW_MATRIX[3].xyz;
	vec3 worldpos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	lod_world_distance = length(camera_pos - worldpos);
	world_distance = length(CAMERA_POSITION_WORLD - worldpos);

	vec3 mesh_normal = NORMAL;

	float angle = INSTANCE_CUSTOM.a;
	vec2 stripe_position = worldpos.xz / 256.0;
	mat2 rotation = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
	stripe_position = rotation * stripe_position;

	random_hue_shift = (0.9 - texture(world_space_normal_map, worldpos.xz / 512.0).z) * 1.2;
	stripe_sample = 0.1 + texture(stripe_noise, stripe_position).r * 0.9;

	// Read plant size
	float size = (INSTANCE_CUSTOM.g * 255.0 + INSTANCE_CUSTOM.b);

	// Safeguard against potential erroneous values
	size = max(size, 0.1);

	// Scale size by hue-shift
	size  *= (1.0 + random_hue_shift * 2.0);

	// FIXME: scale this and the vec3(0.0, 4.0, 0.0) to look good and match the LOD plane
	vec3 n_up = normalize(COLOR.xyz + vec3(0.0, 0.0, 0.0));
	vec3 n_forward = cross(vec3(1.0, 0.0, 0.0), n_up);
	vec3 n_right = cross(n_up, n_forward);

	mat3 basis = mat3(n_right, n_up, n_forward);

	// Rotate the bottom vertices to match the terrain, but not the top vertices to make plants
	// grow straight up
	if (VERTEX.y < 0.2) {
		VERTEX = basis * VERTEX;

		// As another safeguard against floating plants at steep angles, make them grow a bit further
		// into the ground if the angle is steep (i.e. the y component of the normal vector is small)
		VERTEX.y -= mix(0.0, 0.2, smoothstep(1.0, 0.8, n_up.y));
	}

	// TODO: Keep the normal of non-billboard meshes?
	vec3 texture_normal = (texture(world_space_normal_map, worldpos.xz * world_space_normal_scale).xyz - vec3(0.5, 0.5, 0.0)).xzy * vec3(2.0, 1.0, 2.0);
	NORMAL = basis * normalize(texture_normal + vec3(0.0, 4.0, 0.0));

	// Also make normals follow a "half-dome" around the mesh to get some front- and back-lighting
	NORMAL = normalize(VERTEX + NORMAL * mix(0.3, 1.0, smoothstep(5.0, 50.0, length(INV_VIEW_MATRIX[3].xyz - worldpos))));

	// Account for the texture's aspect ratio
	ivec2 texture_size = textureSize(texture_map[int(round(dist_id))], 0);

	// We want to multiply the texture_size.y by 2 if this is not a billboard, since that means we're using a shrub with 2 textures next to each other.
	// We also use a larger multiplicator for billboards
	VERTEX += mesh_normal * (float(texture_size.x) / float(texture_size.y * (1 + int(!is_billboard))) - 1.0) * (0.3 + (0.2 * float(is_billboard)));

	// Also make non-billboards less spread-out if the texture is thin
	VERTEX.xz += VERTEX.xz * (float(texture_size.x) / float(texture_size.y * 2) - 1.0) * 0.7 * float(!is_billboard);

	// Scale by the size
	VERTEX *= size;

	float wind_amount = texture(wind_map, worldpos.xz / 512.0 - TIME * speed / 2500.0).r;
	vec2 wind_offset_vector = (inverse(MODEL_MATRIX) * vec4(speed.x, 0.0, speed.y, 0.0)).xz * wind_amount * 0.04;

	// Move the upper vertices around for a wind wave effect
	float inv_y = 1.0 - UV.y;

	// Bring the wind offset into a good scale based on the height along the plant, the plant size,
	// and the wind speed (the offset increases more slowly than the speed)
	wind_offset_vector *= inv_y;
	wind_offset_vector *= min(size, 1.0);
	wind_offset_vector *= inversesqrt(length(speed));
	wind_offset_vector *= 4.0;

	wind_strength = length(wind_offset_vector);

	VERTEX.xz += wind_offset_vector;
	VERTEX.y -= length(wind_offset_vector) * 0.5;

	// Update the world position again with the scaled Vertex (otherwise the distance fade-out is off)
	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// See https://github.com/godotengine/godot/issues/42411
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	int texture_index = clamp(int(round(dist_id)), 0, 99);

	vec4 color = texture(texture_map[texture_index], UV);

	ALPHA = color.a;

	// Use more pixels at a distance to increase perceived density and thickness
	ALPHA_SCISSOR_THRESHOLD = mix(0.4, 0.15, smoothstep(1.0, 30.0, world_distance));

	// Fade out towards impostor LOD
	ALPHA_SCISSOR_THRESHOLD += smoothstep(max_distance - 20.0, max_distance, lod_world_distance);

	// Vary the transmission based on how bright and/or green the plant is here
	// (This is to approximate a higher transmission for leaves)
	BACKLIGHT = vec3(1.0, 1.0, 0.5) * min(color.g * 2.0, 1.0) * 0.5;

	// Hue shift to make plant appear e.g. dryer
	vec3 hcy = RGBtoHCY(color.rgb);

	hcy.r += HCY_SHIFT.r + random_hue_shift;
	hcy.g *= HCY_SHIFT.g * (random_hue_shift + 1.0) * 0.8 * stripe_sample;
	hcy.b *= HCY_SHIFT.b * (random_hue_shift + 1.0) * 0.8 * stripe_sample;

	ALBEDO = HCYtoRGB(hcy);

	// Other material parameters
	AO_LIGHT_AFFECT = 0.7;
	AO = max(generate_darken_gradient(UV.y, 0.6, 0.6, 0.0) - wind_strength * 0.5, 0.0);
	NORMAL_MAP = generate_normal_from_albedo(texture_map[texture_index], UV, vec4(1.0, 0.7, 0.5, 0.2), 0.03, 1.0);
	NORMAL_MAP_DEPTH = 3.0;
	METALLIC = 0.0;

	// hue of -1.6 is approximately the middle of green.
	// we want the roughness to go from small (when green) to large (when not green)
	float greenness = clamp(pow(abs(hcy.r + 1.6) * 4.0, 4.0), 0.0, 1.0);

	ROUGHNESS = mix(0.65, 0.95, greenness);
	SPECULAR = mix(0.05, 0.2, AO);
}
