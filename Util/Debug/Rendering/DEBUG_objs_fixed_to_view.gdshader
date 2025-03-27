// DEBUG Shader. Render helper objects fixed to camera to compare their Normals with world objects.

shader_type spatial;
render_mode unshaded, skip_vertex_transform;

uniform vec3 position_in_view = vec3(0.0, 0.0, 2.0); // Allows offsetting multiple objects differently via unique Materials.
varying vec3 vertex_pos; // Just for albedo testrendering

void vertex() {
	vertex_pos = VERTEX; // Just for albedo testrendering
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz - position_in_view * vec3(-1.0, -1.0, 1.0); // Transform to ViewSpace
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz); // Needs to be manually calculated -> skip vertex transform
}

void fragment() {
	ALBEDO = clamp(pow(vertex_pos*5.0, vec3(2.2)), 0.0, 1.0); // Just for debugging the debugging
}