shader_type spatial;
//render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

// Custom variables
uniform float rail_width = 0.35;
uniform float rail_width_bottom = 0.6;
uniform float rail_offset = 0.717;

uniform sampler2D railway_texture: source_color;

uniform sampler2D railway_normals: hint_normal;
uniform sampler2D gravel_normals: hint_normal;

uniform sampler2D railway_metal;


void vertex() {
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}


void fragment() {
	vec3 color;
	// Map UV to the upper face of the polygon
	vec2 uv = UV * vec2(1.0, 8.0);

	vec4 railway_albedo = texture(railway_texture, uv);
	vec4 gravel_albedo = texture(road_texture, WORLD_UV.xz);

	float rail_factor = 1.0 - min(1.0 - railway_albedo.a + float(uv.y > 1.0), 1.0);

	ALBEDO = railway_albedo.rgb * rail_factor + gravel_albedo.rgb * (1.0 - rail_factor);
	NORMAL_MAP = texture(railway_normals, uv).xyz * rail_factor + texture(gravel_normals, WORLD_UV.xz).xyz * (1.0 - rail_factor);
	METALLIC = texture(railway_metal, uv).x * rail_factor;
	ROUGHNESS = 1.0 - METALLIC;
}
