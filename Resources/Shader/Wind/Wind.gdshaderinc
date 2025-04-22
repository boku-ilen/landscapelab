uniform sampler2D wind_map: hint_default_black;
uniform vec2 wind_speed = vec2(12.0, 12.0);
uniform float wind_factor = 1.0;

vec3 get_vertex_offset(vec3 vertex, mat4 model_matrix, float time) {
	vec3 vertex_offset = vec3(0.0);

	float distance_from_zero = length(vertex);
	distance_from_zero = pow(distance_from_zero, 2.0);
	float distance_from_center = 0.2 + length(vertex.xz) * 0.8;
	distance_from_center = pow(distance_from_center, 3.0) * 4.0;

	float wind_amount = texture(wind_map, (model_matrix * vec4(vertex, 1.0)).xz / 512.0 - time * wind_speed / 2500.0).r;
	vec2 wind_offset_vector = (inverse(model_matrix) * vec4(wind_speed.x, 0.0, wind_speed.y, 0.0)).xz * 0.2 * wind_amount * distance_from_zero * distance_from_center * wind_factor;

	vertex_offset.xz += wind_offset_vector;
	vertex_offset.y -= length(wind_offset_vector) * 0.5;

	vertex_offset *= sqrt(length(model_matrix[0]));

	return vertex_offset;
}