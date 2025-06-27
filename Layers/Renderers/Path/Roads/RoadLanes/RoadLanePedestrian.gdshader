shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

uniform vec3 lid_color;

varying float global_height;


void vertex() {
	global_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	
	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 17))) == int(pow(2, 17)))) {
		VERTEX += (UV.x - 0.5) * 5.0;
	}
	
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

vec3 srgb_to_linear(vec3 color) {
	return mix(
		pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)),
		color.rgb * (1.0 / 12.92),
		lessThan(color.rgb, vec3(0.04045))
	);
}
vec3 encode (float v) {
	vec3 r = vec3(
		fract(v),
		mod(floor(v), 255.0) / 255.0,
		floor(mod(v, 255.0 * 255.0) / 255.0) / 255.0
	);
	return srgb_to_linear(r);
}

void fragment() {
	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		ALBEDO = lid_color;
		ALPHA = 1.0;
	
	} else if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 17))) == int(pow(2, 17)))) {
		vec3 encoded = encode(global_height);
		ALBEDO = encoded.rgb;
	}else {
		vec3 color = texture(road_texture, WORLD_UV.xz).rgb;

		// Map UV to the upper face of the polygon
		vec2 uv = UV * 8.0 * width;

		ALBEDO = min(color, vec3(1.0,1.0, 1.0));
		ALPHA = 1.0;
	}
}
