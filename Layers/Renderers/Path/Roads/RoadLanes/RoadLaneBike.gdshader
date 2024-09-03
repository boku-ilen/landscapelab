shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

// Custom variables
uniform float outerline_width = 0.25;
uniform float outerline_offset = 0.1;


void vertex() {
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}


void fragment() {
	vec3 color = texture(road_texture, WORLD_UV.xz).rgb;
	// Map UV to the upper face of the polygon
	vec2 uv = UV * 8.0 * width;

	// Outer lines
	if ((uv.y > outerline_offset && uv.y < outerline_offset + outerline_width) ||
		(uv.y > width - (outerline_offset + outerline_width) && uv.y < width - outerline_offset))
	{
		color *= 5.0;
	}

	ALBEDO = min(color, vec3(1.0,1.0, 1.0));
}
