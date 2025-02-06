shader_type canvas_item;

uniform sampler2D tex: repeat_disable;
uniform vec3 NODATA;

void fragment() {
	// Obtain data for the current pixel
	vec4 current_val = texture(tex, UV).rgba;
	if(current_val.rgb == NODATA)
		discard;
	COLOR.rgba = current_val.rgba;
}
