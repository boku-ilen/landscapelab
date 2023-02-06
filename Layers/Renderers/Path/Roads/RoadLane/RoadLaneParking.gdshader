shader_type spatial;

// RoadLane variables. REQUIRED
uniform float width = 5.0;
uniform float height = 0.2;
uniform sampler2D road_texture: source_color;
uniform float world_uv_scaling = 0.35;
varying vec3 WORLD_UV;

// Custom variables


void vertex() {
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}


void fragment() {
	vec3 color = texture(road_texture, WORLD_UV.xz).rgb;
	// Map UV to the upper face of the polygon
	vec2 uv = UV * 8.0 * width;
	
	color += vec3(0.0,0.0, 0.5);
	
	ALBEDO = min(color, vec3(1.0,1.0, 1.0));
}
