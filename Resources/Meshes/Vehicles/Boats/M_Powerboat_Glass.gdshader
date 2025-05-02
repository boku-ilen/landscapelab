// NOTE: Shader automatically converted from Godot Engine 4.4.beta3's StandardMaterial3D.

shader_type spatial;
render_mode world_vertex_coords, blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_g, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);

uniform float rim : hint_range(0.0, 1.0, 0.01);
uniform float rim_tint : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_rim : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform float clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float clearcoat_roughness : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_clearcoat : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform sampler2D texture_ambient_occlusion : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

float hash_2dpos_to_float(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Wave Rocking Motion
uniform float wave_height = 10.5;
uniform float wave_frequency = 1.5;
uniform float wave_speed = 1.0;
uniform vec2 wave_direction = vec2(1.0, 0.3);
uniform float tilt_strength = 0.025;

float get_wave(vec3 world_pos, float time) {
	vec2 dir = normalize(wave_direction);
	float phase = dot(world_pos.xz, dir);
	return sin(phase * wave_frequency + time * wave_speed);
}

float get_slope(vec3 world_pos, float time, vec2 axis_offset) {
	vec2 dir = normalize(wave_direction);
	float delta = 0.1;

	vec3 pos1 = world_pos;
	pos1.xz += dir * delta;
	vec3 pos2 = world_pos;
	pos2.xz -= dir * delta;

	float wave1 = get_wave(pos1, time);
	float wave2 = get_wave(pos2, time);

	return (wave1 - wave2) / (2.0 * delta);
}

void vertex() {
	float time_offset = hash_2dpos_to_float(NODE_POSITION_WORLD.xz);
	float time = TIME + time_offset;

	// Dynamically determine center (fallback)
	vec3 local_center = NODE_POSITION_WORLD;

	vec3 world_center = (MODEL_MATRIX * vec4(local_center, 1.0)).xyz;
	float wave_val = get_wave(world_center, time);
	float height_offset = wave_val * wave_height;

	// Estimate slope for tilt
	float slope_x = get_slope(world_center, time, vec2(1.0, 0.0));
	float slope_z = get_slope(world_center, time, vec2(0.0, 1.0));

	vec3 local_pos = VERTEX - local_center;

	// Tilt angles from slope
	float angle_x = -slope_z * tilt_strength;
	float angle_z = slope_x * tilt_strength;

	mat3 rot_x = mat3(
		vec3(1.0,        0.0,         0.0),
		vec3(0.0, cos(angle_x), -sin(angle_x)),
		vec3(0.0, sin(angle_x),  cos(angle_x))
	);

	mat3 rot_z = mat3(
		vec3( cos(angle_z), -sin(angle_z), 0.0),
		vec3( sin(angle_z),  cos(angle_z), 0.0),
		vec3(        0.0,          0.0, 1.0)
	);

	local_pos = rot_z * rot_x * local_pos;

	VERTEX = local_pos + local_center;
	VERTEX.y += sin(time) * height_offset;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(0.0, 1.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Normal Map: Enabled
	NORMAL_MAP = texture(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	ALPHA *= albedo.a * albedo_tex.a;

	// Rim: Enabled
	vec2 rim_tex = texture(texture_rim, base_uv).xy;
	RIM = rim * rim_tex.x;
	RIM_TINT = rim_tint * rim_tex.y;

	// Clearcoat: Enabled
	vec2 clearcoat_tex = texture(texture_clearcoat, base_uv).xy;
	CLEARCOAT = clearcoat * clearcoat_tex.x;
	CLEARCOAT_ROUGHNESS = clearcoat_roughness * clearcoat_tex.y;

	// Ambient Occlusion: Enabled
	AO = dot(texture(texture_ambient_occlusion, base_uv), ao_texture_channel);
	AO_LIGHT_AFFECT = ao_light_affect;
}
