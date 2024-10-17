// DARKEN_GRADIENT_FROM_UVS:
// 	Can be used for e.g. darkening Albedo or AO by multiplying in this black-to-white gradient. Default values:
// 	uv_axis = UV.y
// 	darken_strength = 1.0 (if < 1, increases the blackest point -> gradient doesn't start with 0.0 black, but 0.x grey.
// 	grad_length_in_uvs = 1.0
// 	grad_offset_in_uvs = 0.0
float generate_darken_gradient(float uv_axis, float darken_strength, float grad_length_in_uvs, float grad_offset_in_uvs) {
	float gradient = (1.0 - uv_axis - grad_offset_in_uvs) * (1.0 / grad_length_in_uvs);

// More finetuning possible via grad_bias, but more expensive:
// float darken_gradient_from_uvs(float uv_axis, float darken_strength, float grad_length_in_uvs, float grad_offset_in_uvs, float grad_bias) {
	//float gradient = pow((1.0 - uv_axis - grad_offset_in_uvs) * (1.0 / grad_length_in_uvs), grad_bias);

	return clamp((1.0 - ((1.0 - clamp(gradient, 0.0, 1.0)) * darken_strength)), 0.0, 1.0); // All this oneminus and clamping is required, so the gradient behaves as expected.
}