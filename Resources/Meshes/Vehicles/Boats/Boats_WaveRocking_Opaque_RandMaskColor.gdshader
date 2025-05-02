shader_type spatial;
render_mode world_vertex_coords, blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Shading

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 albedo_multiply : source_color = vec3(1.0);

uniform sampler2D mask_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 color1_mixstart : source_color = vec3(0.4, 0.0, 0.0);
uniform vec3 color1_mixend : source_color = vec3(1.0, 0.0, 0.0);
uniform vec3 color2_a : source_color = vec3(0.0, 0.4, 0.0);
uniform vec3 color2_b : source_color = vec3(0.0, 0.6, 0.0);
uniform vec3 color2_c : source_color = vec3(0.0, 0.8, 0.0);
uniform vec3 color2_d : source_color = vec3(0.0, 1.0, 0.0);
uniform vec3 color3_a : source_color = vec3(0.0, 0.0, 0.4);
uniform vec3 color3_b : source_color = vec3(0.0, 0.0, 0.6);
uniform vec3 color3_c : source_color = vec3(0.0, 0.0, 0.8);
uniform vec3 color3_d : source_color = vec3(0.0, 0.0, 1.0);

uniform sampler2D metal_rough_ao_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float roughness_multiply : hint_range(0.0, 1.0) = 1.0;
uniform float ao_gamma : hint_range(0.0, 10.0)= 1.0;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01) = 0.5;

uniform sampler2D normal_tex : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;

float hash_2dpos_to_float(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.545);
}

// Wave Rocking Motion
uniform float wave_height = 0.015;
uniform float wave_frequency = 1.5;
uniform float wave_speed = 1.0;
uniform vec2 wave_direction = vec2(1.0, 0.3);
uniform float tilt_strength = 0.025;

varying flat vec3 local_center;

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
	local_center = NODE_POSITION_WORLD;

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
	vec3 mask = texture(mask_tex, base_uv).rgb;
	vec3 color2[4] = {color2_a, color2_b, color2_c, color2_d};
	vec3 color3[4] = {color3_a, color3_b, color3_c, color3_d};
	vec3 random_color1 = mix(color1_mixstart, color1_mixend, fract(hash_2dpos_to_float(local_center.xz - local_center.yx)));
	vec3 random_color2 = color2[int(hash_2dpos_to_float(local_center.xz) * 1000.0) % 4];
	vec3 random_color3 = color3[int(hash_2dpos_to_float(local_center.xz - local_center.zy) * 1000.0) % 4];

	// Creates a multipliable map, where pixels who have no mask value, remain white
	vec3 masked_resulting_colors = vec3(1.0);
	masked_resulting_colors = mix(masked_resulting_colors, random_color1, mask.r);
	masked_resulting_colors = mix(masked_resulting_colors, random_color2, mask.g);
	masked_resulting_colors = mix(masked_resulting_colors, random_color3, mask.b);

	vec3 albedo = texture(albedo_tex, base_uv).rgb;
	ALBEDO = albedo * albedo_multiply * masked_resulting_colors;
	//ALBEDO = vec3(fract(local_center.z));

	SPECULAR = specular;

	vec3 metal_rough_ao = texture(metal_rough_ao_tex, base_uv).rgb;
	METALLIC = metal_rough_ao.r;
	ROUGHNESS = metal_rough_ao.g * roughness_multiply;
	AO = clamp(pow(metal_rough_ao.b, ao_gamma), 0.0, 1.0);
	AO_LIGHT_AFFECT = ao_light_affect;

	NORMAL_MAP = texture(normal_tex, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}
