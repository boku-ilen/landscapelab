shader_type canvas_item;

uniform sampler2D tex: repeat_disable;
uniform sampler2D gradient: repeat_disable;
uniform float min_val;
uniform float max_val;
uniform float alpha = 1.0;
uniform float NODATA = 0.0;


float invLerp(float start, float end, float value){
	return (value - start) / (end - start);
}

void fragment() {
	// Obtain data for the current pixel
	float current_val = texture(tex, UV).r;

	// GLSL detects NaN by comparing to itself
	if (current_val == NODATA || current_val != current_val)
		discard;
	
	// Transform between 0 and 1
	current_val = invLerp(min_val, max_val, current_val);
	
	// Read from the gradient
	vec4 data_color = texture(gradient, vec2(current_val, current_val));
	COLOR.rgb = data_color.rgb;
	COLOR.a = data_color.a * alpha;
}
