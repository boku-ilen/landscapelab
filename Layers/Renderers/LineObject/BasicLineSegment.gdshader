shader_type spatial;


#include "res://Layers/Renderers/LineObject/LineObject.gdshaderinc"

uniform sampler2D albedo: source_color;
uniform sampler2D normal: hint_normal;
uniform sampler2D roughness: hint_default_white;
uniform sampler2D metallic: hint_default_black;

varying vec3 world_uv;


void vertex() {
	// Bend the road segment to the desired start and end positions
	NORMAL = get_interpolated_normal(VERTEX, NORMAL);
	VERTEX = get_interpolated_vertex(VERTEX);

	world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
	NORMAL_MAP = texture(normal, UV).rgb;
	ROUGHNESS = texture(roughness, UV).r;
	METALLIC = texture(metallic, UV).r;
}