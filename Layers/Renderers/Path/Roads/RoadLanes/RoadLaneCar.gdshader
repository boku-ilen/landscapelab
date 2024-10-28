shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

// Custom variables
uniform bool draw_outer_lines = true;
uniform float outerline_width = 0.25;
uniform float outerline_offset = 0.1;

uniform float innerline_width = 0.15;
uniform float innerline_gap = 6.0;
uniform float innerline_length = 3.0;
uniform int lanes = 2;

uniform float banquet_width;
uniform vec3 lid_color: source_color;

uniform bool render_lid = true;

float map_to_range(float value, float old_from, float old_to, float new_from, float new_to){
	return new_from + ((new_to - new_from) / (old_to - old_from)) * (value - old_from);
}

void vertex() {
	if ((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16))) {
		VERTEX += NORMAL * banquet_width;
	}
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

void fragment() {
	if (render_lid && ((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		ALBEDO = lid_color;
	} else {
		vec2 damage_uv = WORLD_UV.xz * 0.3;
		vec2 wear_uv = WORLD_UV.xz * 0.05;

		float wear_noise = texture(wear_factor, wear_uv).r;

		float damage_opacity_sample = texture(damage_opacity, damage_uv).r;
		damage_opacity_sample *= float(wear_noise > 0.8);

		vec3 color = mix(
			texture(road_texture, WORLD_UV.xz).rgb,
			texture(damage_texture, WORLD_UV.xz).rgb,
			wear_noise);

		color *= 1.0 - damage_opacity_sample;
		color += texture(damage_overlay, damage_uv).rgb * damage_opacity_sample;
		// Map UV to the upper face of the polygon
		vec2 uv = UV * 8.0  * width;

		float marking_multiplier = 1.0;

		// Outer lines
		if (draw_outer_lines) {
			if ((uv.y > outerline_offset && uv.y < outerline_offset + outerline_width) ||
				(uv.y > width - (outerline_offset + outerline_width) && uv.y < width - outerline_offset))
			{
				marking_multiplier *= 2.0;
			}
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
				float remainder = fract(UV.x / (innerline_length + innerline_gap));
				if (remainder > innerline_gap / (innerline_length + innerline_gap))
				{
					marking_multiplier *= 2.0;
				}

			}
		}

		color *= mix(1.0, marking_multiplier, 1.0 - damage_opacity_sample);

		// TODO: expose as brightness factor to alter type of asphalt
		color *= 1.2;

		ALBEDO = min(color, vec3(1.0,1.0, 1.0));
	}
}
