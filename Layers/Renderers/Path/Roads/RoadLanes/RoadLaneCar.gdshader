shader_type spatial;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

// Custom variables
uniform bool draw_outer_lines = true;
uniform float outerline_width = 0.25;
uniform float outerline_offset = 0.1;

uniform float innerline_width = 0.15;
uniform float innerline_gap = 6.0;
uniform float innerline_length = 3.0;
uniform int lanes = 2;

uniform float banquet_width = 1.0;
uniform vec3 lid_color: source_color;

uniform bool render_lid = true;

varying float global_height;
varying float vertex_x;

float map_to_range(float value, float old_from, float old_to, float new_from, float new_to){
	return new_from + ((new_to - new_from) / (old_to - old_from)) * (value - old_from);
}

void vertex() {
	global_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	vertex_x = VERTEX.x;

	if (render_lid && ((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		VERTEX += NORMAL * banquet_width;
	} else if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 17))) == int(pow(2, 17)))) {
		VERTEX += NORMAL * 8.0;
		global_height -= 0.15;
	}

	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;

	NORMAL = mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.25);
}

void fragment() {
	vec2 uv = UV * 8.0 * width;

	if (render_lid && ((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		ALBEDO = lid_color;
	} else if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 17))) == int(pow(2, 17)))) {
		// We want to fully use the overlay height at and beside the street and then blend into the
		//  heightmap height. This edge_falloff value is the factor for this blending.
		float edge_falloff = 1.0 - abs(UV.y * 8.0 - 0.5) * 2.0;
		edge_falloff = min(edge_falloff * 3.0, 1.0);

		// Encode the overlay height and the falloff parameter into the RGB channels of this
		//  16 bit float RGB viewport texture
		ALBEDO = vec3(floor(global_height / 10.0), fract(global_height / 10.0), edge_falloff);
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

		float marking_multiplier = 1.0;

		// Outer lines
		if (draw_outer_lines) {
			if ((uv.y > outerline_offset && uv.y < outerline_offset + outerline_width) ||
				(uv.y > width - (outerline_offset + outerline_width) && uv.y < width - outerline_offset))
			{
				marking_multiplier *= 3.0;
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
					marking_multiplier *= 3.0;
				}

			}
		}

		color *= mix(1.0, marking_multiplier, 1.0 - damage_opacity_sample);

		ALBEDO = min(color, vec3(1.0,1.0, 1.0));
		NORMAL_MAP = mix(
			texture(road_normals, WORLD_UV.xz).rgb,
			texture(damage_normals, WORLD_UV.xz).rgb,
			wear_noise
		);
		NORMAL_MAP = mix(
			NORMAL_MAP,
			texture(damage_overlay_normals, damage_uv).rgb,
			damage_opacity_sample
		);
		NORMAL_MAP_DEPTH = (1.0 + wear_noise) * 3.0;
	}
}
