uniform float albedo_node_rand_hue_branch : hint_range(0.0, 1.0) = 0.08;
uniform float albedo_node_rand_hue_leaf : hint_range(0.0, 1.0) = 0.1;
uniform float albedo_node_rand_chroma_branch : hint_range(0.0, 1.0) = 0.01;
uniform float albedo_node_rand_chroma_leaf : hint_range(0.0, 1.0) = 0.005;
uniform float albedo_node_rand_luma_branch : hint_range(0.0, 1.0) = 0.02;
uniform float albedo_node_rand_luma_leaf : hint_range(0.0, 1.0) = 0.01;

varying flat vec3 hue_mix_from;
varying flat vec3 hue_mix_to;

vec3 get_hue_mix_from_values(vec3 position) {
	return vec3(
		sin(position.x * 2.0 * PI * 71.33) * PI * albedo_node_rand_hue_branch,
		sin(position.y * 132.935) * albedo_node_rand_chroma_branch,
		sin(position.z * 387.247) * albedo_node_rand_luma_branch
	);
}

vec3 get_hue_mix_to_values(vec3 position) {
	return vec3(
		sin(position.x * 2.0 * PI * 62.691) * PI * albedo_node_rand_hue_leaf,
		sin(position.y * 538.217) * albedo_node_rand_chroma_leaf,
		sin(position.z * 239.871) * albedo_node_rand_luma_leaf
	);
}