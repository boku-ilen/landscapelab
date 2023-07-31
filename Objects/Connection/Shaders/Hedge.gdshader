shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tex: source_color;


void vertex() {
	vec2 uv_before = UV;
	if(UV.y <= 0.125) {
		UV.y = UV.y * 8.0;
	}
	else if(UV.y >= 0.25 && UV.y <= 0.375) {
		UV.y = UV.y * -8.0;
	}
	else if(UV.y <= 0.5) {
		UV.y = UV.y / 100.0;
	}
	if(NORMAL.y >= 0.8) {
		VERTEX.y -= 1.5;
		UV = uv_before;
	}
}


void fragment() {
	vec3 color = texture(tex, UV).rgb;
	// Map UV to the upper face of the polygon
	
	ALBEDO = min(color, vec3(1.0, 1.0, 1.0));
	ALPHA = texture(tex, UV).a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
}
