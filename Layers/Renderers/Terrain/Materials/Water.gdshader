shader_type spatial;
render_mode blend_mix, specular_phong;

// Adapted from https://godotshaders.com/shader/stylized-water-shader/


// LandscapeLab-specific uniforms
uniform sampler2D heightmap;
uniform sampler2D landuse;
uniform sampler2D offset_noise;

uniform float size;

varying vec3 world_pos;

uniform float speed : hint_range(-1,1) = 0.01;

//colors
uniform sampler2D noise1; // add Godot noise here
uniform sampler2D noise2; // add Godot noise here
uniform sampler2D normalmap : hint_normal; // add Godot noise here, enable as_normalmap
uniform sampler2D normalmap2 : hint_normal; // add Godot noise here, enable as_normalmap
uniform vec4 color : hint_color;
uniform vec4 color_ground : hint_color;

//foam
uniform float near = 0.1;
uniform float far = 100.0;

//waves
uniform vec2 wave_strengh = vec2(0.5, 0.25);
uniform vec2 wave_frequency = vec2(12.0, 12.0);
uniform vec2 time_factor = vec2(1.0, 2.0);



float rim(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}


float waves(vec2 pos, float time){
	return (wave_strengh.y * sin(pos.y * wave_frequency.y + time * time_factor.y)) + (wave_strengh.x * sin(pos.x * wave_frequency.x + time * time_factor.x));
}


void vertex(){
	VERTEX.y = texture(heightmap, UV).r;
	world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment(){
	// Check landuse for whether we need to do rendering here
	vec2 random_landuse_offset = (texture(offset_noise, world_pos.xz * 0.006).rg - 0.5) * (50.0 / size);
	int splat_id = int(round(texture(landuse, UV + random_landuse_offset).r * 255.0));
	
	// TODO: Expose these parameters
	if (splat_id < 60 || splat_id > 66) {
		discard;
	}

	vec2 scaled_uv = world_pos.xz * 0.002;

	float time = TIME * speed;
	vec3 n1 = texture(noise1, scaled_uv + time).rgb;
	vec3 n2 = texture(noise2, scaled_uv - time * 0.2).rgb;
	
	vec2 scaled_uv_movement = scaled_uv * 4.0;
	scaled_uv_movement += TIME * speed * 4.0;
	
	vec2 scaled_uv_movement2 = scaled_uv * 7.0 - TIME * speed * 4.0;
	
	float sum = (n1.r + n2.r) - 1.0;
	
	
	float z_depth = rim(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = rim(FRAGCOORD.z);
	float diff = z_depth - z_pos;
	
	float fin = sum * 15.0;
	
	ALBEDO = fin * color_ground.rgb + color.rgb;
	
	vec3 normal_1 = texture(normalmap, scaled_uv_movement).rgb;
	vec3 normal_2 = texture(normalmap, scaled_uv_movement2).rgb;
	
	NORMALMAP = mix(normal_1, normal_2, 0.4);
	ROUGHNESS = 0.05;
	SPECULAR = 0.5;
	METALLIC = 0.2;
	NORMALMAP_DEPTH = 1.25;
}