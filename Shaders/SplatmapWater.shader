shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D water_map;
uniform sampler2D water_normal;
uniform sampler2D small_noise;

// Other variables:
uniform vec3 color = vec3(0.0, 0.05, 0.05); // Shade of blue/green for the water - can be modified based on data in the future
uniform float transparency = 0.3; // Base transparency - alpha 1 means this transparency is used

uniform float time_scale = 0.07; // Bigger number means faster waves
uniform float uv_scale = 10.0; // Bigger number means larger waves

uniform float beer_factor = 0.5;
uniform float reflection_factor = 0.3;

varying float height;

void vertex () {
	// Apply height to the vertex depending on the blue value in splatmap
	height = texture(water_map, UV).b;
	VERTEX.y = height;
}

void fragment () {
	// Amount of water at this pixel - alpha value of 0 means no water
    float water_at_location = texture(water_map, UV).a;
	ALPHA = transparency * water_at_location;
	
	// sample our depth buffer
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;

	// unproject depth
	depth = depth * 2.0 - 1.0;
	float z = -PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	float delta = -(z - VERTEX.z); // z is negative.
	
	// beers law
	float att = exp(-delta * beer_factor);
	ALPHA = clamp(1.0 - att, 0.0, 1.0);
	
	// Apply a shade of blue to the material
	ALBEDO = color *  transparency * water_at_location;
	
	// Apply the normal map texture, constantly offset it based on time to create a wave effect
	vec2 uv1 = UV * uv_scale + vec2(-TIME * time_scale, 1);
	vec2 uv_small1 = UV * uv_scale * 5.0 + vec2(-TIME * time_scale/2.0, 1);
	vec3 part1 = texture(small_noise, uv_small1).rgb * 0.3 + texture(water_normal, uv1).rgb;
	
	vec2 uv2 = UV * uv_scale + vec2(TIME * time_scale, 0.5);
	vec2 uv_small2 = UV * uv_scale * 5.0 + vec2(TIME * time_scale/2.0, 0.5);
	vec3 part2 = texture(small_noise, uv_small2).rgb + texture(water_normal, uv2).rgb;
	
	NORMALMAP = normalize(part1 + part2); // This multiplier changes depending on textures and device...
	NORMALMAP_DEPTH = 0.4;
	
	// Material params
	METALLIC = 0.7;
	ROUGHNESS = 0.12;
	
	// Add a refraction effect
	vec3 ref_normal = normalize( mix(NORMAL,TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL * NORMALMAP.z,NORMALMAP_DEPTH) );
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * 0.02;
	EMISSION += textureLod(SCREEN_TEXTURE,ref_ofs,ROUGHNESS * 10.0).rgb * (1.0 - ALPHA);
	ALBEDO *= ALPHA;
	ALPHA = 1.0;
	
	// Add reflection
//	vec2 uv = SCREEN_UV;
//  float y = (CAMERA_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).y * height - uv.y;
//
//  ALBEDO += vec4(texture(SCREEN_TEXTURE, vec2(uv.x, y))).xyz * reflection_factor; 
}