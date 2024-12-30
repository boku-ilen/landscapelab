shader_type canvas_item;

uniform sampler2D tex: repeat_disable;
uniform float min_val;
uniform float max_val;
uniform vec3 max_col = vec3(1.0, 1.0, 1.0);
uniform vec3 min_col = vec3(0.0, 0.0, 0.0);
uniform float alpha = 1.0;


float invLerp(float start, float end, float value){
	return (value - start) / (end - start);
}

void fragment() {
	// Obtain data for the current pixel
	float current_val = texture(tex, UV).r;
	// Transform between 0 and 1
	current_val = invLerp(min_val, max_val, current_val);
	// Interpolate the color between the start- and endcolor
	vec3 data_color = mix(min_col, max_col, current_val);

	COLOR = vec4(data_color, alpha);
}
