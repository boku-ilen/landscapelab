shader_type spatial;

#include "res://Layers/Renderers/LineObject/LineObject.gdshaderinc"
#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

uniform vec3 lid_color_edge: source_color;
uniform vec3 lid_color_outer_edge: source_color;
uniform vec3 lid_color_center: source_color;
uniform vec3 lid_color_track: source_color;

uniform float banquet_width = 0.0;

varying float global_height;
varying vec3 untransformed_vertex;


float get_edge_falloff(vec2 uv, float flat_center_fraction) {
	float edge_falloff = 1.0 - abs(uv.y * 8.0 - 0.5) * 2.0;
	edge_falloff = min(edge_falloff * (1.0 / (1.0 - max(flat_center_fraction, 0.01))), 1.0);
	return edge_falloff;
}


void vertex() {
	untransformed_vertex = VERTEX;

	// Scale by width
	VERTEX.x += sign(VERTEX.x) * width / 2.0;

	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		VERTEX.x += sign(VERTEX.x) * 2.5;
	} else if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 17))) == int(pow(2, 17)))) {
		VERTEX.x += sign(VERTEX.x) * 2.7;
	}

	// Bend the road segment to the desired start and end positions
	NORMAL = get_interpolated_normal(VERTEX, NORMAL);
	VERTEX = get_interpolated_vertex(VERTEX);

	global_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y - 0.15;

	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

void fragment() {
	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		DEPTH = FRAGCOORD.z;
		float zero_to_one_from_center = abs(untransformed_vertex.x) * 2.0;
		if (zero_to_one_from_center < 0.08) {
			ALBEDO = lid_color_center;
		} else if (zero_to_one_from_center > 0.9) {
			ALBEDO = lid_color_outer_edge;
		} else if (zero_to_one_from_center > 0.75) {
			ALBEDO = lid_color_edge;
		} else {
			ALBEDO = lid_color_track;
		}
	} else if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 17))) == int(pow(2, 17)))) {
		float edge_falloff = 1.0 - (abs(untransformed_vertex.x) * 3.0);
		DEPTH = edge_falloff;

		float height_here = global_height;
		height_here -= sin(min(edge_falloff + 0.25, 1.0) * PI) * 0.3;

		// Encode the overlay height and the falloff parameter into the RGB channels of this
		//  16 bit float RGB viewport texture
		ALBEDO = vec3(floor(height_here / 10.0), fract(height_here / 10.0), clamp(edge_falloff * 2.0, 0.0, 1.0));
	}
}
