shader_type particles;

#define DISTRIBUTION_RESOLUTION 64

uniform float rows = 300;
uniform float spacing = 1.0;

uniform sampler2D heightmap: repeat_disable;
uniform sampler2D splatmap: repeat_disable, filter_nearest;
uniform sampler2D splatmap_overlay: repeat_disable, filter_nearest, hint_default_black;
uniform sampler2D height_overlay: repeat_disable, filter_linear, hint_default_black;

uniform float splatmap_size_meters;

uniform sampler2D[96] distribution_array: repeat_enable, filter_nearest;
uniform sampler2D row_ids;
uniform sampler2D[100] texture_map : source_color, repeat_disable;

uniform float amplitude = 1.0;
uniform vec2 heightmap_size = vec2(300.0, 300.0);

uniform float row_spacing = 1.0;

uniform vec2 uv_offset;

uniform vec3 view_direction;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float get_height(vec2 uv, bool local_use_height_overlay) {
	// R: Integer part of the overlay height (divided by 10)
	// G: Fractional part of the overlay height (divided by 10)
	// B: Mixing factor from overlay height (1.0) to heightmap height (0.0)
	vec4 overlay_height_sample = texture(height_overlay, uv);

	// Height directly from the heightmap
	float heightmap_height = texture(heightmap, uv).r;

	// Interpolating from a valid value to an invalid value presents us with faulty results,
	//  since the result will seem valid (> 0.0), but actually be far lower than anything sensible.
	// 	Therefore, we check all 4 values surrounding the sample position and don't use the overlay
	//  height if any of them is invalid.
	vec4 near_values = textureGather(height_overlay, uv);
	bool is_surrounded_by_valid = (near_values.x > 0.0 && near_values.y > 0.0
			&& near_values.z > 0.0 && near_values.w > 0.0);

	if (is_surrounded_by_valid && local_use_height_overlay && overlay_height_sample.b > 0.01) {
		// Blend between heightmap height and overlay height by the blue channel of the overlay height
		return mix(heightmap_height, (overlay_height_sample.r + overlay_height_sample.g) * 10.0, overlay_height_sample.b);
	}

	// Clamp to prevent weird behavior with extreme nodata values
	// TODO: Might have to be generalized further to be more robust
	return clamp(heightmap_height, -1000.0, 50000.0);
}

void process() {
	// obtain our position based on which particle we're rendering
	vec3 pos = vec3(0.0, 0.0, 0.0);
	pos.z = float(INDEX);
	pos.x = mod(pos.z, rows);
	pos.z = (pos.z - pos.x) / rows;

	// center this
	pos.x -= rows * 0.5;
	pos.z -= rows * 0.5;

	// and now apply our spacing
	pos *= spacing;

	// Add single-dimension spacing for some crops
	pos.x *= row_spacing;

	// now center on our particle location but within our spacing
	pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], spacing);
	pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], spacing);

	// now add some noise based on our _world_ position
	pos.x += rand(round((pos.xz) * 10.0) * 0.01) * spacing;
	pos.z += rand(round((pos.xz) * 10.0) * 0.02) * spacing;

	// rotate our transform
	float angle = rand(round((pos.xz) * 10.0) * 0.03) * 3.0;
	TRANSFORM[0][0] = cos(angle);
	TRANSFORM[0][2] = -sin(angle);
	TRANSFORM[2][0] = sin(angle);
	TRANSFORM[2][2] = cos(angle);

	// Read from splatmap based on world position
	vec2 splatmap_uv = pos.xz + 0.5 * splatmap_size_meters - uv_offset;
	splatmap_uv /= splatmap_size_meters;

	float e = 2.0 / splatmap_size_meters;

	float height_here = get_height(splatmap_uv, true);
	float height_right = get_height(splatmap_uv  + vec2(e, 0.0), true);
	float height_above = get_height(splatmap_uv + vec2(0.0, -e), true);

	// Save terrain normal into COLOR to use as an up vector later
	mat3 inv_rot = mat3(1.0);
	inv_rot[0][0] = cos(-angle);
	inv_rot[0][2] = -sin(-angle);
	inv_rot[2][0] = sin(-angle);
	inv_rot[2][2] = cos(-angle);
	
	// Write the normal vector of the terrain here into the vertex color.
	// That way we can use it as the NORMAL in the plant shader later.
	COLOR.xyz = inv_rot * normalize(cross(vec3(0.1, height_right - height_here, 0.0), vec3(0.0, height_above - height_here, -0.1)));

	// Depending on the normal steepness, we move the plant down a bit to prevent (half-)flying plants
	height_here -= (1.0 - COLOR.y) * 0.1;

	// apply our height
	pos.y = height_here;

	// update our transform to place
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y;
	TRANSFORM[3][2] = pos.z;

	int overlay_value = int(round(texture(splatmap_overlay, splatmap_uv).r * 255.0) + round(texture(splatmap_overlay, splatmap_uv).g * 255.0 * 255.0));
	int splatmap_value = overlay_value > 0 ? overlay_value : int(round(texture(splatmap, splatmap_uv).r));
	splatmap_value = clamp(splatmap_value, 0, 10999);

	int distribution_id = int(round(texelFetch(row_ids, ivec2(splatmap_value, 0), 0).r * 255.0));

	ACTIVE = !(distribution_id == 0) &&
			(splatmap_uv.x > 0.0 && splatmap_uv.x < 1.0 &&
			 splatmap_uv.y > 0.0 && splatmap_uv.y < 1.0);

	// Note that the pos.xz is already offset by a random normal vector here, so it does not really matter what exactly we do with it since it's already random
	vec3 dist_value = texture(distribution_array[distribution_id - 1], (pos.xz / spacing) / float(DISTRIBUTION_RESOLUTION)).rgb;

	float plant_id = dist_value.r;
	float size_scale_whole = dist_value.g;
	float size_scale_comma = dist_value.b;

	CUSTOM.r = plant_id; // To be multiplied by 255.0 before use!
	CUSTOM.g = size_scale_whole; // To be multiplied by 255.0 before use!
	CUSTOM.b = size_scale_comma; // No multiplication required
	CUSTOM.a = mod(float(splatmap_value) / 10.0, PI * 2.0);
}