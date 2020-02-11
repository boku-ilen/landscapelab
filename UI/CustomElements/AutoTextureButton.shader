shader_type canvas_item;

uniform vec3 color;
uniform float rotation_radians;

vec2 rotateUV(vec2 uv, vec2 pivot, float rotation)
{
	mat2 rotation_matrix = mat2(vec2(cos(rotation), -sin(rotation)),
							    vec2(sin(rotation), cos(rotation)));
	
	uv -= pivot;
	uv = uv * rotation_matrix;
	uv += pivot;
	
	return uv;
}

void fragment() {
	vec4 original_color = texture(TEXTURE, rotateUV(UV, vec2(0.5), -rotation_radians));
	COLOR = vec4(color, original_color.a);
}