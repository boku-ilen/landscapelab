uniform mat4 start;
uniform mat4 end;

vec3 get_interpolated_vertex(vec3 vertex, float mix_factor) {
	return mix(start * vec4(vertex, 1.0), end * vec4(vertex * vec3(1.0, 1.0, 0.0), 1.0), mix_factor).xyz;
}

vec3 get_interpolated_normal(vec3 normal, float mix_factor) {
	return mix(start * vec4(normal, 0.0), end * vec4(normal, 0.0), mix_factor).xyz;
}
