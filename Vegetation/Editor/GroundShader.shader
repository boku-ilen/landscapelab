shader_type spatial;

uniform sampler2D albedo_tex: hint_albedo;
uniform sampler2D normal_tex: hint_normal;
uniform sampler2D ambient_tex;
uniform sampler2D specular_tex;
uniform sampler2D ao_tex;

uniform float size_m;
uniform float texture_size_m;

void fragment() {
	vec2 scaled_uv = UV * size_m / texture_size_m;
	
	// Base color
	ALBEDO = texture(albedo_tex, scaled_uv).rgb;
	
	// Normals
	NORMALMAP = texture(normal_tex, scaled_uv).xyz;
	NORMALMAP_DEPTH = 3.0;
	
	// Roughness -- we need to invert it since we get a specular map
	SPECULAR = texture(specular_tex, scaled_uv).r;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
	
	// Ambient Occlusion
	AO = texture(ao_tex, scaled_uv).r;
}
