shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 andere = vec3((UV.x - 0.5) * PI * 2.0, 0.5, 0.5);
	
	float begin = -PI;
	float end = 0.0;
	
	if (andere.x > begin && andere.x < end) {
		float factor = andere.x - begin;
		factor /= end - begin;
		factor -= 0.5;
		factor *= PI;
		
		andere.x += cos(factor);
	}
	
	ALBEDO = vec3(HCYtoRGB(andere));
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
