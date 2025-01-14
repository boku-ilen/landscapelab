/** Explanation & Default Input values:
Input "uvs" == which mesh UV channel to use, default is "UV".
Input "albedo_channel_influences" drives how strongly each Color/Alpha channel is influencing the result in vec4 Format. Default usually RGB = 0.5-1.0, Alpha = 0.5-1.0. Higher values create stronger NormalMap!
Input "offset_normal_calc_dist" determines how far the Normal calculations are offset, should be a small value, e.g. Default = 0.02 - 0.1.
Input "mix_generated_normal" determines how strong the generated Normal is. 0 == Neutral NormalMap without Generated, 1 == use only Generated. >1 increases NormalMap Depth.
*/

vec3 generate_normal_from_albedo(sampler2D albedo_sampler2d, vec2 uvs, vec4 albedo_channel_influences, float offset_normal_calc_dist, float mix_generated_normal) {
	// Recalculate offset distance depending on albedo's TextureSize
	/** In Future also should account for scaling - which for Vegetation Particles unfortunately doesn't exist as Transform, but as parameter... */
	vec2 sizecorrected_offset = (250.0 * offset_normal_calc_dist) / vec2(textureSize(albedo_sampler2d, 0));

	// Create 4 differently UV-offset Texture2Ds
	vec4 texture2d_uv_offsetuminus = texture(albedo_sampler2d, (uvs - vec2(sizecorrected_offset.x, 0.0)));
	vec4 texture2d_uv_offsetuplus = texture(albedo_sampler2d, (uvs + vec2(sizecorrected_offset.x, 0.0)));
	vec4 texture2d_uv_offsetvminus = texture(albedo_sampler2d, (uvs - vec2(0.0, sizecorrected_offset.y)));
	vec4 texture2d_uv_offsetvplus = texture(albedo_sampler2d, (uvs + vec2(0.0, sizecorrected_offset.y)));

	// DotProducts of differently offset UVs
	float normal_dotprod_uv_offsetuminus = dot(texture2d_uv_offsetuminus, albedo_channel_influences);
	float normal_dotprod_uv_offsetuplus = dot(texture2d_uv_offsetuplus, albedo_channel_influences);
	float normal_dotprod_uv_offsetvminus = dot(texture2d_uv_offsetvminus, albedo_channel_influences);
	float normal_dotprod_uv_offsetvplus = dot(texture2d_uv_offsetvplus, albedo_channel_influences);
	// Create new Vectors by calculating DotProducts differences along U and V
	vec3 normal_result_dotprod_offsetu = vec3(1.0, 0.0, (normal_dotprod_uv_offsetuplus - normal_dotprod_uv_offsetuminus));
	vec3 normal_result_dotprod_offsetv = vec3(0.0, 1.0, (normal_dotprod_uv_offsetvplus - normal_dotprod_uv_offsetvminus));
	// Normalized CrossProd of the 2 offset DotProduct Vectors
	vec3 normal_result_crossprod = normalize((cross(normal_result_dotprod_offsetu, normal_result_dotprod_offsetv)));

	// FusedMultiplyAdd - Invert G channel and remap Normalmap from -1 .. +1 range to expected 0 .. 1 range
	// (Z/Blue Value seems to be ignored anyway, probably reconstructed from the other 2)
	vec3 corrected_normal_map = fma(normal_result_crossprod, vec3(0.5, -0.5, 0.5), vec3(0.5, 0.5, 0.5));

	// Mix output Normal between Neutral and Generated From Albedo, just for quick testing.
	return mix(vec3(0.5, 0.5, 1.0), corrected_normal_map, float(mix_generated_normal));
}