shader_type canvas_item;
uniform vec3 color;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 sample = texture(TEXTURE, UV);
	COLOR = vec4(color.rgb, sample.r);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
