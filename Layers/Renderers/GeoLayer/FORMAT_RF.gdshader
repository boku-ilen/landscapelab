shader_type canvas_item;

uniform sampler2D tex: repeat_disable;
uniform float[16] values;
uniform vec3[16] colors;
uniform float alpha = 1.0;
uniform float NODATA = 0.0;


float invLerp(float start, float end, float value){
	return (value - start) / (end - start);
}

// GPU optimized binary search
// https://blog.demofox.org/2017/06/20/simd-gpu-friendly-branchless-binary-search/
int findInterval(float val) {
    int ret = int(values[8] <= val) * 8;
    ret += int(values[ret + 4] <= val) * 4;
    ret += int(values[ret + 2] <= val) * 2;
    ret += int(values[ret + 1] <= val);
    return ret;
}

void fragment() {
	// Obtain data for the current pixel
	float current_val = texture(tex, UV).r;

	// GLSL detects NaN by comparing to itself
	if (current_val == NODATA || current_val != current_val) {
		discard;
	}

	// Find between which values the current value lies
	int interval = findInterval(current_val);
	vec3 min_col = colors[interval];
	vec3 max_col = colors[interval + 1];
	float min_val = values[interval];
	float max_val = values[interval + 1];

	// Transform between 0 and 1
	current_val = invLerp(min_val, max_val, current_val);

	// Interpolate the color between the start- and endcolor
	vec3 data_color = mix(min_col, max_col, current_val);

	COLOR.rgb = data_color;
	COLOR.a = alpha;
}
