shader_type spatial;
render_mode unshaded;
uniform vec3 color;
uniform sampler2D raster;

void fragment() {
	ALBEDO = color.rgb;
	ALPHA_SCISSOR_THRESHOLD = 1.0;
	ALPHA = texture(raster, UV).r;
}