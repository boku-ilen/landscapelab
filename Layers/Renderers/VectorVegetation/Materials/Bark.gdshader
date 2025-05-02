shader_type spatial;

#include "res://Resources/Shader/Wind/Wind.gdshaderinc"

uniform float roughness : hint_range(0,1);
uniform float specular;
uniform float metallic;

uniform sampler2D spritesheet_albedo: source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D spritesheet_normal: hint_normal, filter_linear_mipmap, repeat_disable;

varying flat float spritesheet_index;

void vertex() {
	VERTEX += get_vertex_offset(VERTEX, MODEL_MATRIX, TIME);

	spritesheet_index = INSTANCE_CUSTOM.r;
}

void fragment() {
	vec2 base_uv = UV;

	base_uv.x -= floor(base_uv.x);
	base_uv.y -= floor(base_uv.y);

	base_uv.y /= 3.0;
	base_uv.y += spritesheet_index / 3.0;

	vec4 albedo_tex = texture(spritesheet_albedo, base_uv);

	ALBEDO = albedo_tex.rgb;
	NORMAL_MAP = texture(spritesheet_normal, base_uv).rgb;

	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
