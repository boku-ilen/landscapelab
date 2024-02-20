shader_type particles;

#define DISTRIBUTION_RESOLUTION 16

uniform float rows = 300;
uniform float spacing = 1.0;

uniform sampler2D heightmap: repeat_disable;
uniform sampler2D splatmap: repeat_disable, filter_nearest;
uniform sampler2D splatmap_overlay: repeat_disable, filter_nearest;

uniform float splatmap_size_meters;

uniform sampler2D[64] distribution_array: repeat_enable, filter_nearest;
uniform sampler2D row_ids;

uniform float amplitude = 1.0;
uniform vec2 heightmap_size = vec2(300.0, 300.0);

uniform float row_spacing = 1.0;

uniform vec2 uv_offset;

uniform vec3 view_direction;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
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
	
//	// WIP: decrease density further away
//	pos *= pos * 0.1 * sign(pos);
// or:
//	if (length(pos) > 20.0) {
//		if (rand(round(pos.xz) * 10.0) < 0.5) {
//			pos *= pos;
//		}
//	}
	
	// now center on our particle location but within our spacing
	pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], spacing);
	pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], spacing);
	
	// now add some noise based on our _world_ position
	pos.x += rand(round((pos.xz) * 10.0) * 0.01) * spacing;
	pos.z += rand(round((pos.xz) * 10.0) * 0.02) * spacing;
	
	// The particle only needs to be active if it's in front of the camera
	// Do this before applying world-space position and height - easier to calculate in local space
	bool is_in_front_of_camera = dot(normalize(view_direction.xz), normalize(pos.xz)) > 0.7;
	
	// rotate our transform
	TRANSFORM[0][0] = cos(rand(round((pos.xz) * 10.0) * 0.03) * 3.0);
	TRANSFORM[0][2] = -sin(rand(round((pos.xz) * 10.0) * 0.03) * 3.0);
	TRANSFORM[2][0] = sin(rand(round((pos.xz) * 10.0) * 0.03) * 3.0);
	TRANSFORM[2][2] = cos(rand(round((pos.xz) * 10.0) * 0.03) * 3.0);
	
	// Read from splatmap based on world position
	vec2 splatmap_uv = pos.xz + 0.5 * splatmap_size_meters - uv_offset;
	splatmap_uv /= splatmap_size_meters;
	
	// apply our height
	pos.y = texture(heightmap, splatmap_uv).r;
	
	// update our transform to place
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y;
	TRANSFORM[3][2] = pos.z;
	
	int overlay_value = int(round(texture(splatmap_overlay, splatmap_uv).r * 255.0) + round(texture(splatmap_overlay, splatmap_uv).g * 255.0 * 255.0));
	int splatmap_value = overlay_value > 0 ? overlay_value : int(round(texture(splatmap, splatmap_uv).r));
	
	int distribution_id = int(round(texelFetch(row_ids, ivec2(splatmap_value, 0), 0).r * 255.0));
	
	ACTIVE = !(distribution_id == 0) &&
			(splatmap_uv.x > 0.0 && splatmap_uv.x < 1.0 &&
			 splatmap_uv.y > 0.0 && splatmap_uv.y < 1.0);// && is_in_front_of_camera;
	
	vec2 dist_value = texture(distribution_array[distribution_id - 1], pos.xz / spacing).rg;
	
	float plant_id = dist_value.r;
	float size_scale = dist_value.g;
	
	CUSTOM.r = size_scale; // To be multiplied by the maximum size before use!
	CUSTOM.g = plant_id; // To be multiplied by 255.0 before use!
	//CUSTOM.b = dist / 255.0; // To be multiplied by 255.0 before use!
}