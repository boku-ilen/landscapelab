shader_type canvas_item;
uniform vec3 color: source_color;

void fragment() {
	vec4 sample = texture(TEXTURE, UV);
	COLOR = vec4(color.rgb, sample.r);
}
