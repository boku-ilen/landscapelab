shader_type spatial;

uniform sampler2D heightmap;
uniform sampler2D landuse;


void vertex() {
	// Check landuse for whether we need to do rendering here
	// Set VERTEX.y based on heightmap
}


void fragment() {
	// Water rendering
	ALBEDO = vec3(UV, 0.0); // Placeholder
}