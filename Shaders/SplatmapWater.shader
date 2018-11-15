shader_type spatial;

// Parameters to be passed in GDscript:
uniform sampler2D water_map;
uniform sampler2D water_normal;
uniform vec3 curv_middle = vec3(0.0, 0.0, 0.0); // This should be current position of the camera

// Global parameters - will need to be the same in all shaders:
uniform float curv_factor = 0.2;
uniform float height_scale = 1;

// Other variables:
uniform vec3 color = vec3(0, 0.4, 0.6); // Nice shade of blue for the water
uniform float transparency = 0.6; // Base transparency - alpha 1 means this transparency is used
uniform float normal_scale = 10; // Bigger number means higher waves

uniform float time_scale = 0.05; // Bigger number means faster waves
uniform float uv_scale = 10; // Bigger number means larger waves

void vertex () {
	// Apply height to the vertex depending on the blue value in splatmap
	float height = texture(water_map, UV).b * height_scale;
	VERTEX.y = height;
	
	// Apply the curvature based on the distance from the current point to the origin point
	// Note: This can and should probably use the location of the camera instead of a passed parameter like curv_middle (CAMERA_MATRIX might be relevant here!)
	vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist_to_middle = distance(world_pos, curv_middle) * curv_factor;
	
	VERTEX.y -= dist_to_middle;
}

void fragment () {
	// Amount of water at this pixel - alpha value of 0 means no water
    float water_at_location = texture(water_map, UV).a;
	ALPHA = transparency * water_at_location;
	
	// Apply a shade of blue to the material
	ALBEDO = color;
	
	// Apply the normal map texture, constantly offset it based on time to create a wave effect
	vec3 normalmap = texture(water_normal, UV * uv_scale + vec2(TIME * time_scale, 1)).xyz * normal_scale - vec3(1.0,1.0,1.0);
	vec3 normal = normalize(TANGENT * normalmap.y + BINORMAL * normalmap.x + NORMAL * normalmap.z);
	NORMAL = normal;
	
	// Material params
	METALLIC = 0.5;
	ROUGHNESS = 0.2;
	
	// Add a refraction effect
	vec3 ref_normal = normalize( mix(NORMAL,TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL * NORMALMAP.z,NORMALMAP_DEPTH) );
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * water_at_location * 0.1;
	EMISSION += textureLod(SCREEN_TEXTURE,ref_ofs,ROUGHNESS * 8.0).rgb * (1.0 - ALPHA);

}