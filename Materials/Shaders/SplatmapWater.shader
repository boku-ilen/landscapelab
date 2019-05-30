shader_type spatial;
render_mode depth_draw_opaque;

// Parameters to be passed in GDscript:
uniform sampler2D splatmap;
uniform int water_id;

uniform sampler2D water_normal : hint_normal;
uniform sampler2D small_noise;
uniform sampler2D heightmap;

// Other variables:
uniform vec3 color = vec3(0.0, 0.05, 0.05); // Shade of blue/green for the water - can be modified based on data in the future
uniform float transparency = 0.8; // Base transparency - alpha 1 means this transparency is used

uniform float time_scale = 0.2; // Bigger number means faster waves (m/sec)
uniform float uv_scale = 20.0; // Bigger number means smaller waves
uniform float uv_strength = 3.0; // Bigger number means higher waves

uniform float beer_factor = 0.5;
uniform float reflection_factor = 0.3;

varying float height;

// Global parameters - will need to be the same in all shaders:
uniform float height_range = 500;

uniform float subdiv;
uniform float size;
uniform float size_without_skirt;

uniform float RADIUS = 6371000; // average earth radius in meters

// Get the value by which vertex at given point must be lowered to simulate the earth's curvature 
float get_curve_offset(float distance_squared) {
	return sqrt(RADIUS * RADIUS + distance_squared) - RADIUS;
}

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
	
	return get_height_no_falloff(pos);
}

void vertex() {
	// Apply the height of the heightmap at this pixel
	VERTEX.y = get_height_no_falloff(UV) - 8.0; // TODO: Getting the height like this isn't very precise!

	// Apply the curvature based on the position of the current camera
	vec3 world_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float dist_to_middle = pow(world_pos.x, 2.0) + pow(world_pos.y, 2.0) + pow(world_pos.z, 2.0);
	
	VERTEX.y -= get_curve_offset(dist_to_middle);
}

void fragment () {
	float water_check_lenience = 0.03; // Used to get slightly more water than the splatmap is telling us to make sure it reaches the shores
	
	if (!(int(texture(splatmap, UV).r * 255.0) == water_id)
		&& !(int(texture(splatmap, UV + vec2(water_check_lenience, water_check_lenience)).r * 255.0) == water_id)
		&& !(int(texture(splatmap, UV - vec2(water_check_lenience, water_check_lenience)).r * 255.0) == water_id)
		&& !(int(texture(splatmap, UV + vec2(water_check_lenience, -water_check_lenience)).r * 255.0) == water_id)
		&& !(int(texture(splatmap, UV + vec2(-water_check_lenience, water_check_lenience)).r * 255.0) == water_id)) {
		ALPHA = 0.0;
		ALPHA_SCISSOR = 0.1;
		return;
	}
	ALPHA = transparency;

//	// sample our depth buffer
//	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
//
//	// unproject depth
//	depth = depth * 2.0 - 1.0;
//	float z = -PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
//	float delta = -(z - VERTEX.z); // z is negative.
//
//	// beers law
//	float att = exp(-delta * beer_factor);
//	ALPHA = clamp(1.0 - att, 0.0, 1.0);

	// Apply a shade of blue to the material
	ALBEDO = color *  transparency;

	// Apply the normal map texture, constantly offset it based on time to create a wave effect
	float scale = size / uv_scale;
	float time = time_scale;

	vec2 uv1 = UV * scale + vec2(-TIME * time, 1.0);
	vec2 uv_small1 = UV * scale * 5.0 + vec2(-TIME * time/2.0, 1.0);
	vec3 part1 = texture(small_noise, uv_small1).rgb * 0.3 + texture(water_normal, uv1).rgb;

	vec2 uv2 = UV * scale + vec2(TIME * time, 0.5);
	vec2 uv_small2 = UV * scale * 5.0 + vec2(TIME * time/2.0, 0.5);
	vec3 part2 = texture(small_noise, uv_small2).rgb + texture(water_normal, uv2).rgb;

	NORMALMAP = (part1 + part2) * uv_strength;
	NORMALMAP_DEPTH = 0.8;

	// Material params
	METALLIC = 0.7;
	ROUGHNESS = 0.12;

	// Add a refraction effect
	vec3 ref_normal = normalize( mix(NORMAL,TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL * NORMALMAP.z,NORMALMAP_DEPTH) );
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * 0.02;
	EMISSION += textureLod(SCREEN_TEXTURE,ref_ofs,ROUGHNESS * 10.0).rgb * (1.0 - ALPHA);
	ALBEDO *= ALPHA;
	ALPHA = 1.0;
}