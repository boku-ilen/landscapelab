shader_type particles;

#define DISTRIBUTION_RESOLUTION 16

uniform float rows = 300;
uniform float spacing = 1.0;

uniform sampler2D heightmap: repeat_disable;
uniform sampler2D splatmap: repeat_disable, filter_nearest;

uniform float splatmap_size_meters;

uniform sampler2D distribution_map : hint_default_black, repeat_enable;
uniform float dist_scale = 5000.0;
uniform float id_to_row[255]; // Rows are floats of integers between 0 and 255, divided by 255.0

uniform float amplitude = 1.0;
uniform vec2 heightmap_size = vec2(300.0, 300.0);

uniform float row_spacing = 1.0;

uniform vec2 uv_offset;

uniform sampler2D noisemap;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float get_height(vec2 pos) {
	pos += 0.5 * heightmap_size;
	pos /= heightmap_size;
	
	return texture(heightmap, pos).r;
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
	
	// apply our height
	pos.y = get_height(pos.xz - uv_offset);
	
	// rotate our transform
	TRANSFORM[0][0] = cos(rand(round((pos.xz) * 10.0) * 0.03) * 3.0);
	TRANSFORM[0][2] = -sin(rand(round((pos.xz) * 10.0) * 0.04) * 3.0);
	TRANSFORM[2][0] = sin(rand(round((pos.xz) * 10.0) * 0.05) * 3.0);
	TRANSFORM[2][2] = cos(rand(round((pos.xz) * 10.0) * 0.06) * 3.0);
	
	// update our transform to place
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y;
	TRANSFORM[3][2] = pos.z;
	
	// Read from splatmap based on world position
	vec2 splatmap_uv = pos.xz + 0.5 * splatmap_size_meters - uv_offset;
	splatmap_uv /= splatmap_size_meters;
	
	int splatmap_value = int(round(texture(splatmap, splatmap_uv).r * 255.0));
	
	// The row in the spritesheets which corresponds to this splatmap ID
	float row = id_to_row[splatmap_value];
	
	ACTIVE = !(abs(row + 1.0) < 0.0001);
	
	// Using the row, we can get the ID (the column) of the plant which should be here
	ivec2 dist_pos = ivec2(int(pos.x * dist_scale) % DISTRIBUTION_RESOLUTION,
			int(pos.z * dist_scale) % DISTRIBUTION_RESOLUTION);
	
	vec2 dist_value = texelFetch(distribution_map, ivec2(0, int(row) * 16) + dist_pos, 0).rg;
	float dist_id = dist_value.r;
	
	float size_scale = dist_value.g;
	
	CUSTOM.r = size_scale; // To be multiplied by the maximum size before use!
	CUSTOM.g = dist_id; // To be multiplied by 255.0 before use!
	CUSTOM.b = row; // To be multiplied by 255.0 before use!
}