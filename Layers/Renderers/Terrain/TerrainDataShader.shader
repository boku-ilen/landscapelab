shader_type spatial;

// Basic data shading
uniform sampler2D tex: hint_albedo;
uniform sampler2D heightmap;
uniform float height_scale = 1.0;

uniform vec4 min_color : hint_color;
uniform vec4 max_color : hint_color;
uniform float min_value;
uniform float max_value;
uniform float alpha;

// Surface heights
uniform bool has_surface_heights = false;
uniform float surface_heights_start_distance = 800.0;
uniform sampler2D surface_heightmap;

uniform float size;
varying vec3 world_pos;
varying float world_distance;

float get_height(vec2 uv) {
	return texture(heightmap, uv).r * height_scale;
}

vec3 get_normal(vec2 normal_uv_pos) {
	// To calculate the normal vector, height values on the left/right/top/bottom of the current pixel are compared.
	// e is the offset factor.
	float e = 1.0 / 100.0; // TODO: Take resolution as a uniform var and use that here
	
	// Sobel filter for getting the normal at this position
	float bottom_left = get_height(normal_uv_pos + vec2(-e, -e));
	float bottom_center = get_height(normal_uv_pos + vec2(0, -e));
	float bottom_right = get_height(normal_uv_pos + vec2(e, -e));
	
	float center_left = get_height(normal_uv_pos + vec2(-e, 0));
	float center_center = get_height(normal_uv_pos + vec2(0, 0));
	float center_right = get_height(normal_uv_pos + vec2(e, 0));
	
	float top_left = get_height(normal_uv_pos + vec2(-e, e));
	float top_center = get_height(normal_uv_pos + vec2(0, e));
	float top_right = get_height(normal_uv_pos + vec2(e, e));
	
	vec3 long_normal;
	
	long_normal.x = -(bottom_right - bottom_left + 2.0 * (center_right - center_left) + top_right - top_left) / (size * e);
	long_normal.z = -(top_left - bottom_left + 2.0 * (top_center - bottom_center) + top_right - bottom_right) / (size * e);
	long_normal.y = size * e * 1.0; // scaling by <1.0 makes the normals more drastic

	return normalize(long_normal);
}

void vertex() {
	world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_distance = length(world_pos.xz);
	
	VERTEX.y = get_height(UV);
	NORMAL = get_normal(UV);
	
	if (has_surface_heights) {
		float surface_height_factor = float(world_distance > surface_heights_start_distance);
		VERTEX.y += texture(surface_heightmap, UV).r * height_scale * surface_height_factor;
	}
}

float invLerp(float start, float end, float value){
	return (value - start) / (end - start);
}

void fragment() {
	// Obtain data for the current pixel
	float data_value = texture(tex, UV).r;
	// Transform between 0 and 1
	data_value = invLerp(min_value, max_value, data_value);
	// Interpolate the color between the start- and endcolor
	vec4 data_color = mix(min_color, max_color, data_value);
	
	ALPHA = alpha;
	ALBEDO = data_color.rgb;
}