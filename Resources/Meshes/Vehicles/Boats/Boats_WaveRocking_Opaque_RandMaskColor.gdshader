shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

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

// Wave Rocking Motion
uniform float rotation_damping = 1.0;
uniform float velocity_damping = 0.5;
uniform float wave_timer_min = 5.0;
uniform float wave_timer_max = 8.0;
uniform float wave_height  = 0.5;
uniform float wind_speed = 110.0;
uniform float time_offset = 0.0;
uniform float rand_seed = 1.0;
uniform vec3 wind_direction = vec3(1.0, 0.0, 0.0);

float rand(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

float rand_range(float x, float min_val, float max_val) {
    return mix(min_val, max_val, rand(x));
}

float smooth_noise(float t, float seed) {
    float t0 = floor(t);
    float t1 = t0 + 1.0;
    float fade = smoothstep(0.0, 1.0, fract(t));
    float r0 = rand_range(t0 + seed, wind_speed / 4.0, wind_speed / 2.0);
    float r1 = rand_range(t1 + seed, wind_speed / 4.0, wind_speed / 2.0);
    return mix(r0, r1, fade);
}

float hash_2dpos_to_float(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 78.233);
    return fract(p.x * p.y);
}

void vertex() {
	float time = TIME + time_offset;

    // Determine duration of one gust cycle per instance
    float wave_duration = mix(wave_timer_min, wave_timer_max, rand(rand_seed + 0.123));
    float t_wave = time / wave_duration;

    // Smoothed gust strength (wind strength over time)
    float gust_strength = smooth_noise(t_wave, rand_seed + 42.0);

    // Use vertex position to offset wave phase
    float local_phase = 
        VERTEX.y * (2.0 + rand(VERTEX.y)) +
        VERTEX.x * (2.5 + rand(VERTEX.x)) +
        VERTEX.z * (3.0 + rand(VERTEX.z));

    // Compute wind-influenced waving
    float wave = sin(local_phase + time * velocity_damping);
    float displacement = wave * gust_strength * 0.001;

    // Normalize wind direction to avoid scaling artifacts
    vec3 wind_dir = normalize(wind_direction);

    // Offset the vertex along wind direction
    VERTEX += wind_dir * displacement;
    VERTEX.y += sin(TIME) * 0.05;

}

void fragment() {
	vec2 base_uv = UV;
	vec3 mask = texture(mask_tex, base_uv).rgb;
	vec3 color2[4] = {color2_a, color2_b, color2_c, color2_d};
	vec3 color3[4] = {color3_a, color3_b, color3_c, color3_d};
	vec3 random_color1 = mix(color1_mixstart, color1_mixend, hash_2dpos_to_float(NODE_POSITION_WORLD.xz));
	vec3 random_color2 = color2[int(hash_2dpos_to_float(NODE_POSITION_WORLD.xz*1.33)*4.0)];
	vec3 random_color3 = color3[int(hash_2dpos_to_float(NODE_POSITION_WORLD.xz*0.82)*4.0)];
	
	
	// Creates a multipliable map, where pixels who have no mask value, remain white
	vec3 masked_resulting_colors = vec3(1.0);
	masked_resulting_colors = mix(masked_resulting_colors, random_color1, mask.r);
	masked_resulting_colors = mix(masked_resulting_colors, random_color2, mask.g);
	masked_resulting_colors = mix(masked_resulting_colors, random_color3, mask.b);
	

	vec3 albedo = texture(albedo_tex, base_uv).rgb;
	ALBEDO = albedo * albedo_multiply * masked_resulting_colors;
	//ALBEDO = masked_resulting_colors;
	
	SPECULAR = specular;
	
	vec3 metal_rough_ao = texture(metal_rough_ao_tex, base_uv).rgb;
	METALLIC = metal_rough_ao.r;
	ROUGHNESS = metal_rough_ao.g * roughness_multiply;
	AO = clamp(pow(metal_rough_ao.b, ao_gamma), 0.0, 1.0);
	AO_LIGHT_AFFECT = ao_light_affect;
	
	NORMAL_MAP = texture(normal_tex, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}
