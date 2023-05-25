shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

// Custom variables
uniform sampler2D curbside_texture: source_color;
uniform bool has_curbside_left = false;
uniform bool has_curbside_right = false;
uniform float curbside_width = 0.1;



void vertex() {
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

void fragment() {
	vec3 color = texture(road_texture, WORLD_UV.xz).rgb;
	
	// Map UV to the upper face of the polygon
	vec2 uv = UV * 8.0 * width;
	
	if (has_curbside_left)
	{
		if (uv.y > 0.0 && uv.y < curbside_width)
		{
			color = texture(curbside_texture, vec2(uv.x, uv.y * width) * 0.5).rgb;
		}
		else if(uv.y > width * 4.0 - curbside_width / height && uv.y < width * 4.0)
		{
			color = texture(curbside_texture, vec2(uv.x, uv.y * height - width) * 0.5).rgb;
		}
		
	}
	
	if (has_curbside_right)
	{
		if (uv.y > width - 0.1 && uv.y < width)
		{
			color = texture(curbside_texture, vec2(uv.x, uv.y * width - width) * 0.5).rgb;
		}
		else if (uv.y > width && uv.y < width + 0.4)
		{
			color = texture(curbside_texture, vec2(uv.x, uv.y * height) * 0.5).rgb;
		}
		
	}
	
	
	ALBEDO = min(color, vec3(1.0,1.0, 1.0));
}
