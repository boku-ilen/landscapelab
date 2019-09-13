shader_type particles;

uniform float rows = 20;
uniform float spacing = 0.1;
uniform float vertical_offset = 0;

uniform sampler2D heightmap;
uniform sampler2D noisemap;

uniform int id;
uniform sampler2D splatmap;

uniform float scale;

uniform vec3 curv_middle = vec3(0.0, 0.0, 0.0);
uniform vec3 tile_pos;

// Global parameters - will need to be the same in all shaders:
uniform float height_range = 500;

uniform float subdiv;
uniform float size;
uniform float size_without_skirt;

uniform float RADIUS = 6371000; // average earth radius in meters

// Shrinks and centers UV coordinates to compensate for the skirt around the edges
vec2 get_relative_pos(vec2 raw_pos) {
	float offset_for_subdiv = ((size_without_skirt/(subdiv+1.0))/size_without_skirt);
	float factor = (size / size_without_skirt);
	
	vec2 pos = raw_pos * factor;

	pos.x -= offset_for_subdiv;
	pos.y -= offset_for_subdiv;
	
	pos.x = clamp(pos.x, 0.005, 0.995);
	pos.y = clamp(pos.y, 0.005, 0.995);
	
	return pos;
}

// Gets the absolute height at a given pos without taking the skirt into account
float get_height_no_falloff(vec2 pos) {
	int r_int = int(texture(heightmap, get_relative_pos(pos)).r * 255.0);
	int g_int = int(texture(heightmap, get_relative_pos(pos)).g * 255.0);
	int b_int = int(texture(heightmap, get_relative_pos(pos)).b * 255.0);
	
	float r_conv = float(r_int) * 65536.0;
	float g_conv = float(g_int) * 256.0;
	float b_conv = float(b_int);
	
	return (r_conv + g_conv + b_conv) / 100.0;
}

// Gets the required height of the vertex, including the skirt around the edges (the outermost vertices are set to y=0 to allow seamless transitions between tiles)
float get_height(vec2 pos) {
	float falloff = 1.0/(10000.0);
	
	if (pos.x > 1.0 - falloff || pos.y > 1.0 - falloff || pos.x < falloff || pos.y < falloff) {
		return 0.0;
	}
	
	// Interpolation
	vec2 scaled_pos = pos * subdiv;
	vec2 scaled_pos_clamped = vec2(floor(scaled_pos.x), floor(scaled_pos.y));
	vec2 pos_clamped = scaled_pos_clamped / subdiv;
	
	vec2 factor = scaled_pos - scaled_pos_clamped;
	
	// Interestingly, for the grass, we need to 'reverse' the position, that's why we subtract from vec2(1.0)
	float height1 = get_height_no_falloff(vec2(1.0) - (pos_clamped + vec2(0, 0) * (1.0 / subdiv)));
	float height2 = get_height_no_falloff(vec2(1.0) - (pos_clamped + vec2(1, 0) * (1.0 / subdiv)));
	float height3 = get_height_no_falloff(vec2(1.0) - (pos_clamped + vec2(0, 1) * (1.0 / subdiv)));
	float height4 = get_height_no_falloff(vec2(1.0) - (pos_clamped + vec2(1, 1) * (1.0 / subdiv)));
	
	return mix(mix(height1, height2, factor.x), mix(height3, height4, factor.x), factor.y); 
}

vec2 get_uv_position(vec2 global_pos) {
	vec2 size_vec = vec2(size_without_skirt, size_without_skirt);
	
	vec2 upper_left = tile_pos.xz - size_vec / 2.0;
	
	vec2 pos_from_upper_left = global_pos - upper_left;
	vec2 pos_scaled = pos_from_upper_left / size_vec;
	
	return pos_scaled;
}

void vertex ()
{
	// Get the world position of this particle
	vec3 pos = vec3(0.0, 0.0, 0.0);
	pos.z = float(INDEX);
	pos.x = mod(pos.z, rows);
	pos.z = (pos.z - pos.x) / rows;
	
	// Center
	pos.x -= rows * 0.5;
	pos.z -= rows * 0.5;
	
	// Apply spacing
	pos *= spacing;
	
	// Transform by the position of this particular particle
	pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], spacing) + 0.5;
	pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], spacing) + 0.5;
	
	// Check the splatmap for whether we need to do draw something and exit if not
	int splat_id_at_pos = int(texture(splatmap, get_uv_position(pos.xz)).r * 255.0);
	
	if (!(splat_id_at_pos == id)) {
		ACTIVE = false;
		return;
	}
	
	// Apply noise to prevent visible repetitive patterns
	// The multiplicator 0.0123 is chosen to get a good variety of pixels from the noise map - a clean
	//  value like 0.01 might overlap with a setting such as '0.1 plants per m²', causing patterns again
	vec3 noise = texture(noisemap, pos.xz * 0.0123).rgb;

	// Apply random offset
	pos.x += (0.5 - noise.x) * spacing * 2.0;
	pos.z += (0.5 - noise.y) * spacing * 2.0;
	
	// Apply the height from the heightmap, plus the vertical offset (used for making sure it doesn't float at low LODs)
	pos.y += get_height((pos.xz / size) * -1.0 + vec2(0.5)) + vertical_offset;
	
	// Initialize the TRANSFORM matrix with the identity (needs to be done since otherwise, the previous
	//  TRANSFORM is calculated on each frame)
	TRANSFORM = mat4(1.0);
	
	// Apply the scale of this vegetation layer
	// This is done here because it's easier than procedurally generating and assigning meshes in the CPU
	TRANSFORM[0][0] = scale;
	TRANSFORM[1][1] = scale;
	TRANSFORM[2][2] = scale;
	
	// Apply the position
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y;
	TRANSFORM[3][2] = pos.z;
	
	// Apply random rotation
	mat4 rot = mat4(	vec4(cos(noise.x * 7.0), 0.0, sin(noise.x * 7.0), 0.0),
						vec4(0.0, 1.0, 0.0, 0.0),
						vec4(-sin(noise.x * 7.0), 0.0, cos(noise.x * 7.0), 0.0),
						vec4(0.0, 0.0, 0.0, 1.0));
	
	TRANSFORM *= rot;
}
