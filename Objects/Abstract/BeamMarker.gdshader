shader_type spatial;
render_mode unshaded;

instance uniform vec3 color: source_color = vec3(0.0, 1.0, 0.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = color;
	ALPHA = 1.0 - dot(NORMAL, VIEW);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
