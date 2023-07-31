shader_type canvas_item;

uniform vec3 color;
uniform float rotation_radians;
uniform float color_length_modulate_threshold = 1.5;

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
	
	// If the original color here is relatively dark, and the new color isn't black, change it to the new color.
	// The color is not changed if the new color is black because that can mess up color gradients.
	if (length(original_color) < color_length_modulate_threshold
		&& color != vec3(0.0, 0.0, 0.0)) {
		COLOR = vec4(color, original_color.a);
	} else {
		COLOR = original_color;
	}
}