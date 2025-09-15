shader_type spatial;
render_mode unshaded;

uniform vec4 color: source_color;

void fragment() {
	ALBEDO = color.rgb;
}
