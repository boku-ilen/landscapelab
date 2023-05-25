shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

// Custom variables
uniform float outerline_width = 0.25;
uniform float outerline_offset = 0.1;

uniform float innerline_width = 0.12;
uniform float innerline_gap = 6.0;
uniform float innerline_length = 3.0;
uniform int lanes = 2;


float map_to_range(float value, float old_from, float old_to, float new_from, float new_to){
	return new_from + ((new_to - new_from) / (old_to - old_from)) * (value - old_from);
}

void vertex() {
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

void fragment() {
	vec3 color = texture(road_texture, WORLD_UV.xz).rgb;
	// Map UV to the upper face of the polygon
	vec2 uv = UV * 8.0  * width;
	
	// Outer lines
	if ((uv.y > outerline_offset && uv.y < outerline_offset + outerline_width) ||
		(uv.y > width - (outerline_offset + outerline_width) && uv.y < width - outerline_offset))
	{
		color *= 5.0;
	}
	
	// Map UV to inner part of road (between outerlines)
	uv.y = map_to_range(uv.y, outerline_offset + outerline_width, width - outerline_offset - outerline_width, 0.0, 1.0);
	float scale = 1.0 / (width - (outerline_offset + outerline_width) * 2.0);
	float half_width = innerline_width / 2.0 * scale;
	// Check each line
	for (int i = 1; i < lanes; ++i)
	{
		float pos = 1.0 * (float(i) / float(lanes));
		if (uv.y > pos - half_width && uv.y < pos + half_width)
		{
			float remainder = mod(uv.x, innerline_length + innerline_gap);
			if (remainder > innerline_length)
			{
				color *= 5.0;
			}
			
		}
	}
	
	ALBEDO = min(color, vec3(1.0,1.0, 1.0));
}
