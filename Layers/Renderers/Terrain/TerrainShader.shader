shader_type spatial;

uniform sampler2D tex: hint_albedo;
uniform sampler2D heights;
uniform float height_scale = 1.0;

void vertex() {
	VERTEX.y = texture(heights, UV).r * height_scale;
}

void fragment() {
	ALBEDO = texture(tex, UV).rgb;
}