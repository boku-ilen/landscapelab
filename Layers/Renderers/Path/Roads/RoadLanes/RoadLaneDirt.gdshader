shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

uniform vec3 lid_color;
uniform vec3 lid_color_center;
uniform float banquet_width = 0.0;

varying float global_height;


void vertex() {
	global_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;

	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		VERTEX += NORMAL * banquet_width;
	} else if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 17))) == int(pow(2, 17)))) {
		VERTEX += NORMAL * (banquet_width + 4.0);
	}

	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

void fragment() {
	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		if (abs(UV.y * 8.0 - 0.5) > 0.05) {
			ALBEDO = lid_color;
		} else {
			ALBEDO = lid_color_center;
		}

		ALPHA = 1.0;
	} else if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 17))) == int(pow(2, 17)))) {
		// We want to fully use the overlay height at and beside the street and then blend into the
		//  heightmap height. This edge_falloff value is the factor for this blending.
		float edge_falloff = 1.0 - abs(UV.y * 8.0 - 0.5) * 2.0;
		edge_falloff = min(edge_falloff * 2.0, 1.0);

		float height_here = global_height - 0.9;
		if (abs(UV.y * 8.0 - 0.5) > 0.05) {
			height_here -= 0.2;
		}

		// Encode the overlay height and the falloff parameter into the RGB channels of this
		//  16 bit float RGB viewport texture
		ALBEDO = vec3(floor(height_here / 10.0), fract(height_here / 10.0), edge_falloff);
	}
}
