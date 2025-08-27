uniform mat4 start;
uniform mat4 end;

uniform float mesh_length = 1.0;

vec3 get_interpolated_vertex(vec3 vertex) {
	return mix(start * vec4(vertex * vec3(1.0, 1.0, 0.0), 1.0), end * vec4(vertex * vec3(1.0, 1.0, 0.0), 1.0), -vertex.z / mesh_length).xyz;
}

vec3 get_interpolated_normal(vec3 vertex, vec3 normal) {
	return mix(start * vec4(normal, 0.0), end * vec4(normal, 0.0), -vertex.z / mesh_length).xyz;
}
