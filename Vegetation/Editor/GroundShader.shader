shader_type spatial;

uniform sampler2D albedo_tex: hint_albedo;
uniform sampler2D normal_tex: hint_normal;
uniform sampler2D ambient_tex;
uniform sampler2D specular_tex;
uniform sampler2D roughness_tex;
uniform sampler2D ao_tex;

uniform float size_m;
uniform float texture_size_m;

uniform float normal_scale;

// Increase or decrease texture values in the range 0..1
uniform bool is_roughness_increase;
uniform float roughness_scale = 0.0;

uniform bool is_specular_increase;
uniform float specular_scale = 0.0;

uniform bool is_ao_increase;
uniform float ao_scale = 0.0;

void fragment() {
	vec2 scaled_uv = UV * size_m / texture_size_m;
	
	// Base color
	ALBEDO = texture(albedo_tex, scaled_uv).rgb;
	
	// Normals
	NORMALMAP = texture(normal_tex, scaled_uv).xyz;
	NORMALMAP_DEPTH = normal_scale;
	
	// Roughness and specularity
	SPECULAR = float(is_specular_increase) * specular_scale
			+ texture(specular_tex, scaled_uv).r * (1.0 - specular_scale);
	
	ROUGHNESS = float(is_roughness_increase) * roughness_scale
			+ texture(roughness_tex, scaled_uv).r * (1.0 - roughness_scale);
	METALLIC = 0.0;
	
	// Ambient Occlusion
	AO = float(is_ao_increase) * ao_scale
			+ texture(ao_tex, scaled_uv).r * (1.0 - ao_scale);
}
