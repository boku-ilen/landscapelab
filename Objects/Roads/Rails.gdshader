shader_type spatial;


#include "res://Layers/Renderers/LineObject/LineObject.gdshaderinc"

uniform sampler2D albedo: source_color;
uniform sampler2D normal: hint_normal;
uniform sampler2D roughness: hint_default_white;
uniform sampler2D metallic: hint_default_black;

varying vec3 world_uv;
varying vec3 untransformed_vertex;
varying vec3 transformed_vertex;
varying float segment_length;


void vertex() {
	untransformed_vertex = VERTEX;
	
	VERTEX.x *= 2.4;
	
	// Bend the road segment to the desired start and end positions
	NORMAL = get_interpolated_normal(VERTEX, NORMAL);
	VERTEX = get_interpolated_vertex(VERTEX);
	
	transformed_vertex = VERTEX;

	world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	segment_length = length((end * vec4(0.0, 0.0, 0.0, 1.0)).xyz - (start * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
}

void fragment() {
	vec2 uv = vec2((untransformed_vertex.x + 1.0) * 0.5, untransformed_vertex.z * segment_length * 0.2);
	
	ALBEDO = texture(albedo, uv).rgb;
	NORMAL_MAP = texture(normal, uv).rgb;
	ROUGHNESS = texture(roughness, uv).r;
	METALLIC = texture(metallic, uv).r;
}