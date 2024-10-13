// Lowest - Surface/Mesh
shader_type spatial;

uniform float multiplier = 1.0;

void fragment() {
	// Called for every pixel the material is visible on.
		ALBEDO = multiplier * vec3(1.0, 1.0, 0.0);
}