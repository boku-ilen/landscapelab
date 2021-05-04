shader_type spatial;

uniform sampler2D albedo_tex: hint_albedo;
uniform sampler2D normal_tex: hint_normal;
uniform sampler2D ambient_tex;
uniform sampler2D specular_tex;
uniform sampler2D roughness_tex;
uniform sampler2D ao_tex;

uniform float size_m;
uniform float texture_size_m;

uniform float normal_scale = 1.0;

// Increase or decrease texture values in the range 0..1
uniform bool is_roughness_increase;
uniform float roughness_scale = 0.0;

uniform bool is_specular_increase;
uniform float specular_scale = 0.0;

uniform bool is_ao_increase;
uniform float ao_scale = 0.0;

uniform bool has_distance_tex = false;
uniform sampler2D distance_tex: hint_albedo;
uniform sampler2D distance_normals: hint_normal;
uniform float distance_tex_start;
uniform float distance_texture_size_m;

varying vec3 camera_pos;
varying vec3 world_pos;

void vertex() {
	camera_pos = CAMERA_MATRIX[3].xyz;
	world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float close_factor() {
	// Returns 1.0 if has_distance_tex is false or if the camera is closer than distance_tex_start.
	// Returns 0.0 otherwise.
	return (1.0 - float(has_distance_tex))
		+ float(has_distance_tex) * float(distance(camera_pos, world_pos) <= distance_tex_start);
}

float far_factor() {
	// Returns 1.0 if has_distance_tex is true and the camera is further than distance_tex_start.
	// Returns 0.0 otherwise.
	return float(has_distance_tex) * float(distance(camera_pos, world_pos) > distance_tex_start);
}

void fragment() {
	vec2 scaled_uv = UV * size_m / texture_size_m;
	vec2 fade_scaled_uv = UV * size_m / distance_texture_size_m;

	// Base color
	ALBEDO = texture(albedo_tex, scaled_uv).rgb * close_factor()
			+ texture(distance_tex, fade_scaled_uv).rgb * far_factor();
	
	// Normals
	NORMALMAP = texture(normal_tex, scaled_uv).rgb * close_factor()
			+ texture(distance_normals, fade_scaled_uv).rgb * far_factor();
	NORMALMAP_DEPTH = normal_scale;
	
	// Roughness and specularity
	SPECULAR = (float(is_specular_increase) * specular_scale
			+ texture(specular_tex, scaled_uv).r * (1.0 - specular_scale)) * close_factor()
			+ 0.5 * far_factor();
	
	ROUGHNESS = (float(is_roughness_increase) * roughness_scale
			+ texture(roughness_tex, scaled_uv).r * (1.0 - roughness_scale)) * close_factor()
			+ 0.9 * far_factor();
	METALLIC = 0.0;
	
	// Ambient Occlusion
	AO = (float(is_ao_increase) * ao_scale
			+ texture(ao_tex, scaled_uv).r * (1.0 - ao_scale)) * close_factor()
			+ 0.0 * far_factor();
}
