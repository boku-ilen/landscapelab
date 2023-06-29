shader_type spatial;
//render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

// Custom variables
uniform float rail_width = 0.35;
uniform float rail_width_bottom = 0.6;
uniform float rail_offset = 0.717;

uniform sampler2D metal_texture;
uniform sampler2D concrete_texture;


void vertex() {
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}


void fragment() {
	vec3 color;
	// Map UV to the upper face of the polygon
	vec2 uv = UV * 8.0 * width;
	
	float wood_pos = fract(uv.x * 0.15);
	
	float left_rail_uv = uv.y - rail_offset;
	float right_rail_uv = uv.y + rail_offset;
	
	if ((left_rail_uv > width / 2.0 - rail_width / width && left_rail_uv < width / 2.0 + rail_width / width)
			|| (right_rail_uv > width / 2.0 - rail_width / width && right_rail_uv < width / 2.0 + rail_width / width)) {
		color = texture(metal_texture, WORLD_UV.xz * 10.0).rgb;
		METALLIC = 1.0;
		ROUGHNESS = 0.1;
	} else if ((left_rail_uv > width / 2.0 - rail_width_bottom / width && left_rail_uv < width / 2.0 + rail_width_bottom / width)
			|| (right_rail_uv > width / 2.0 - rail_width_bottom / width && right_rail_uv < width / 2.0 + rail_width_bottom / width)) {
		color = texture(metal_texture, WORLD_UV.xz * 10.0).rgb * 0.7;
		METALLIC = 1.0;
		ROUGHNESS = 0.1;
	} else if (wood_pos > 0.7 && wood_pos < 1.0
			&& uv.y + 1.5 > width / 2.0 && uv.y - 1.5 < width / 2.0) {
		color = texture(concrete_texture, WORLD_UV.xz * 1.0).rgb;
		METALLIC = 0.0;
		ROUGHNESS = 0.7;
	} else {
		color = texture(road_texture, WORLD_UV.xz).rgb;
		ROUGHNESS = 0.9;
		METALLIC = 0.0;
	}
	
	ALBEDO = min(color, vec3(1.0,1.0, 1.0));
}
