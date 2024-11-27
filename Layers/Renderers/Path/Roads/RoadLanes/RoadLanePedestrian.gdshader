shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

uniform vec3 lid_color;


void vertex() {
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

void fragment() {
	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		ALBEDO = lid_color;
		ALPHA = 1.0;
	} else {
		vec3 color = texture(road_texture, WORLD_UV.xz).rgb;

		// Map UV to the upper face of the polygon
		vec2 uv = UV * 8.0 * width;

		ALBEDO = min(color, vec3(1.0,1.0, 1.0));
		ALPHA = 1.0;
	}
}
