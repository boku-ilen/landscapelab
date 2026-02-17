shader_type spatial;

uniform float height = 0.0;

uniform float fade_towards_front = 0.5;
uniform float fade_towards_side = 0.5;


//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
	float edge_falloff = 1.0 - abs(UV.x - 0.5) * 2.0;
	edge_falloff = min(edge_falloff * (1.0 + fade_towards_side), 1.0);

	float front_falloff = min(UV.y * (1.0 + fade_towards_front), 1.0);

	ALBEDO = vec3(floor(height / 10.0), fract(height / 10.0), front_falloff * edge_falloff);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
