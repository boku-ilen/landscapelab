/** == 0 creates neutral NormalMap values, == 1 creates Normal information from Albedo,  */
uniform float create_normal : hint_range(0.0, 1.0) = 1.0;

/** Distance that Normal effect is generated along. Keep very small. TODO: Influenced by Texture Size?? */
uniform float offset_normal_from_albedo : hint_range(0, 1) = 0.0025;

/** Influence of RGBA channels of the Albedo Map. Default == 1.0, only A == lower. Maybe change this value on a per material basis before calling the function. */
uniform vec4 albedo_channel_influence_for_normalgen = vec4(1.0, 1.0, 1.0, 0.6);

vec3 generate_normal_from_albedo(sampler2D albedo_sampler2d, vec2 uv) {
// TRY TO SET DEFAULT for option arg INFLUENCE vec3 generate_normal_from_albedo(sampler2D albedo_sampler2d, vec2 uv, vec4 albedo_channel_influence = (1.0, 1.0, 1.0, 0.6)) {
	// Create 3 differently UV-offset Texture2Ds
	vec4 texture2d_uv_unchanged = texture(albedo_sampler2d, uv);
	vec4 texture2d_uv_offsetu = texture(albedo_sampler2d, (uv + vec2(offset_normal_from_albedo, 0.0)));
	vec4 texture2d_uv_offsetv = texture(albedo_sampler2d, (uv + vec2(0.0, offset_normal_from_albedo)));
	
	// DotProducts of differently offset UVs
	float normal_dotprod_uv_unchanged = dot(texture2d_uv_unchanged, albedo_channel_influence_for_normalgen);
	float normal_dotprod_uv_offsetu = dot(texture2d_uv_offsetu, albedo_channel_influence_for_normalgen);
	float normal_dotprod_uv_offsetv = dot(texture2d_uv_offsetv, albedo_channel_influence_for_normalgen);
	
	// Create new Vectors by subtracting the DotProducts from the original Tex
	vec3 normal_result_dotprod_offsetu = vec3(1.0, 0.0, (normal_dotprod_uv_offsetu - normal_dotprod_uv_unchanged));
	vec3 normal_result_dotprod_offsetv = vec3(0.0, 1.0, (normal_dotprod_uv_offsetv - normal_dotprod_uv_unchanged));

	// Normalized CrossProd of the 2 offset DotProduct Vectors 
	vec3 normal_result_crossprod = normalize((cross(normal_result_dotprod_offsetu, normal_result_dotprod_offsetv)));

	// MultiplyAdd - Invert G channel and remap Normalmap from -1 .. +1 range to expected 0 .. 1 range
	// (Z/Blue Value seems to be ignored anyway, probably reconstructed from the other 2)
	vec3 corrected_normal_map = fma(normal_result_crossprod, vec3(0.5, -0.5, 0.5), vec3(0.5, 0.5, 0.5));

	// Switch output Normal between None and Generated From Albedo
	return mix(vec3(0.5, 0.5, 1.0), corrected_normal_map, float(create_normal));
}