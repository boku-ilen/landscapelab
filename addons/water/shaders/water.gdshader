shader_type spatial;

// Adapted from https://www.youtube.com/watch?v=wkRFtEgy2Qg
// With waves from https://github.com/godot-extended-libraries/godot-realistic-water

#include "res://addons/water/lib/funcs/normals.gdshaderinc"
#include "res://addons/water/lib/funcs/colour.gdshaderinc"

// LandscapeLab-specific uniforms
uniform sampler2D heightmap: repeat_disable, filter_nearest;
uniform sampler2D surface_heightmap: repeat_disable, filter_nearest;
uniform sampler2D landuse: repeat_disable, filter_nearest;

uniform float size;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture,repeat_disable;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture,repeat_disable;
uniform vec3 surface_color:source_color;
uniform vec3 depth_color:source_color;
uniform float opacity:hint_range(0.0, 1.0)=0.5;
uniform sampler2D _foam:repeat_enable;
uniform sampler2D normal_map:hint_normal,repeat_enable;
uniform float normal_scale:hint_range(-16.0, 16.0)=1.0;
uniform float beer_factor:hint_range(0.0, 10.0)=3.0;
uniform float _roughness:hint_range(0.0, 1.0)=0.0;
uniform float _refraction:hint_range(0.00, 0.20);
uniform float _uv_scale:hint_range(0.0, 3.0)=0.02;
uniform float _foam_strength: hint_range(0.0, 1.0);
uniform float _foam_size: hint_range(0.0, 100.0);
uniform float dullness: hint_range(0.0, 1.0);

// Waves
uniform vec4	wave_a			 = vec4(1.0, 1.0, 0.35, 2.3); 	// xy = Direction, z = Steepness, w = Length
uniform	vec4	wave_b			 = vec4(0.2, 0.6, 0.30, 2.55);	// xy = Direction, z = Steepness, w = Length
uniform	vec4	wave_c			 = vec4(0.5, 1.3, 0.5, 1.5); 	// xy = Direction, z = Steepness, w = Length

uniform float wind_speed = 30.0;

varying flat int should_render;
varying vec3 world_pos;
varying float vertex_height;


float depth_proximity(float dist, vec3 vertex, sampler2D depthtex, vec2 screenuv,mat4 invproj){
	float depth_tex = textureLod(depthtex, screenuv, 0.0).r;
	vec4 depth_world_pos = invproj * vec4(screenuv * 2.0 - 1.0, depth_tex, 1.0);
	depth_world_pos.xyz /= depth_world_pos.w;
	return clamp(1.0 - smoothstep(depth_world_pos.z + dist, depth_world_pos.z, vertex.z), 0.0, 1.0);
}
float get_depth_linear(sampler2D depthtex, vec2 screenuv, mat4 invproj){
	float depth_tex = textureLod(depthtex,screenuv,0.0).r;
  	vec3 ndc = vec3(screenuv * 2.0 - 1.0, depth_tex);
	vec4 depth_world_pos = invproj * vec4(ndc, 1.0);
	depth_world_pos.xyz /= depth_world_pos.w;
	return depth_world_pos.z;
}
float depth_proximity_z(float dist, float z, float base_z){
	return clamp(1.0 - smoothstep(z + dist, z, base_z), 0.0, 1.0);
}

float fresnel(float power,vec3 normal,vec3 view){
	return pow(1.0 - clamp(dot(normal,view), 0.0, 1.0), power);
}
// Function taken from stackoverflow : https://stackoverflow.com/a/51137756
float linearize(float depth, float z_near, float z_far) {
	return z_near * z_far / (z_far + depth * (z_near - z_far));
}

vec4 wave(vec4 parameter, vec2 position, float time, inout vec3 tangent, inout vec3 binormal, float scale)
{
	time *= wind_speed / 100.0 + 0.5;

	float	wave_steepness	 = parameter.z * wind_speed * 0.03;
	float	wave_length		 = parameter.w * max(wind_speed, 40.0) * 0.05;

	float	k	 = 2.0 * 3.14159265359 / wave_length;
	float 	c	 = sqrt(9.8 / k);
	vec2	d	 = normalize(parameter.xy);
	float 	f	 = k * (dot(d, position) - c * time);
	float 	a	 = wave_steepness / k;

	tangent		+= normalize(vec3(1.0-d.x * d.x * (wave_steepness * sin(f)), d.x * (wave_steepness * cos(f)), -d.x * d.y * (wave_steepness * sin(f)))) * scale;
	binormal	+= normalize(vec3(-d.x * d.y * (wave_steepness * sin(f)), d.y * (wave_steepness * cos(f)), 1.0-d.y * d.y * (wave_steepness * sin(f)))) * scale;

	return vec4(d.x * (a * cos(f)), a * sin(f) * 0.5, d.y * (a * cos(f)), 0.0) * scale;
}


void vertex() {
	// Hide transition with a "skirt": outermost row of vertices is moved down to create a wall that fills holes
	if (UV.x < -0.1 || UV.x > 1.1 || UV.y < -0.1 || UV.y > 1.1) {
		VERTEX.y = -1000.0;
	} else {
		VERTEX.y = texture(surface_heightmap, UV).r;
	}

	bool has_water = false;

	for (int x = -3; x <= 3; x += 3) {
		for (int y = -3; y <= 3; y += 3) {
			if (floor(texture(landuse, UV + vec2(float(x), float(y)) / size).r / 1000.0) == 6.0) {
				has_water = true;
			}
		}
	}

	if (!has_water) {
		VERTEX.y -= 10.0;
	}

	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 camera_pos = INV_VIEW_MATRIX[3].xyz;
	vec3 camera_to_world = world_pos - camera_pos;

	// Waves
	vec3 tang = vec3(1.0, 0.0, 0.0);
	vec3 bin = vec3(0.0, 0.0, 1.0);

	vec4 vertex = vec4(VERTEX, 1.0);

	// Fade out waves further from the camera (further the larger the waves are) in order to prevent
	// 	artifacts and repetitive patterns
	float distance_factor = wind_speed * 4.0;
	float camera_distance_factor = max(distance_factor - length(camera_to_world), 0.0) / distance_factor;

	vec4 wave_sample = wave(wave_a, world_pos.xz, TIME, tang, bin, camera_distance_factor)
			+ wave(wave_b, world_pos.xz, TIME, tang, bin, camera_distance_factor)
			+ wave(wave_c, world_pos.xz, TIME, tang, bin, camera_distance_factor);

	vertex += wave_sample;
	vertex_height = wave_sample.y;

	TANGENT = tang;
	BINORMAL = bin;
	NORMAL = normalize(cross(bin, tang));
	VERTEX = vertex.xyz;

}

void fragment() {
	float time = TIME;// + sin(TIME * 3.0) * 0.1;

	vec2 uv_scale = world_pos.xz * _uv_scale;
 	vec3 n = texture(normal_map,uv_scale+time * 0.02).rgb;
	vec3 n2 = texture(normal_map,uv_scale-time * 0.03).rgb;
	vec3 n3 = texture(normal_map,uv_scale*0.3 +vec2(time * 0.01,time * -0.02)).rgb;

	// Calculate z_near and z_far (required for the linearize function)
	float z_near = abs(PROJECTION_MATRIX[3][2] / PROJECTION_MATRIX[2][2]);
	float z_far = abs((PROJECTION_MATRIX[3][2] * z_near) / (PROJECTION_MATRIX[3][2] + z_near));

	// Get the depth difference between the object we want to overdraw and the other objects
	float screen_depth = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	float fragment_depth = FRAGCOORD.z;

	float l_screen_depth = linearize(screen_depth, z_near, z_far);
	float l_fragment_depth = linearize(fragment_depth, z_near, z_far);
	float l_depth_delta = l_fragment_depth - l_screen_depth;

	float _depth_linear = l_depth_delta;

	float d = depth_proximity_z(-40.0, l_screen_depth, l_fragment_depth);
	float d2 = depth_proximity_z(-15.0, l_screen_depth, l_fragment_depth);

	d2 = 1.0-pow(d2,0.07);
	d = exp(-d * beer_factor);

	//ALPHA = clamp(opacity+1.0-d-d2,0.0,1.0);
	vec3 n_out = mix(n3,mix(n,n2, 0.5), 0.5);
	NORMAL_MAP = n_out;
	NORMAL_MAP_DEPTH = normal_scale;

	vec2 n_distortion = n_out.xy - vec2(0.5, 0.5); //(mat3(TANGENT,BINORMAL,NORMAL) * n_out).rg * 2.0 - 1.0;
	vec3 color_out = mix(depth_color, surface_color,d);

	vec3 _screen = texture(SCREEN_TEXTURE,SCREEN_UV).rgb;
	// TODO: blur effect could be added like +n_distortion*_refraction*(1.0-d), but it's hard not to affect nearby objects above the water

	_screen = mix(_screen, color_out, clamp(1.0 - d + (dullness * 0.3), 0.0, 1.0));

	float depthfoam = depth_proximity_z(-abs(n_distortion.r+n_distortion.g) * _foam_size , l_screen_depth, l_fragment_depth);
	depthfoam = pow(depthfoam,_foam_strength);
	depthfoam += pow(max(vertex_height, 0.0), 1.0) * 2.0;  // Foam on the top of large waves
	vec3 foam = vec3(1.0 - depthfoam);// * texture(_foam,uv_scale * 1.0 + n_distortion).rgb;

	ALBEDO = mix(foam,soft_light(_screen,color_out),depthfoam);
	ALBEDO = clamp(ALBEDO, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
	ROUGHNESS = _roughness;
	SPECULAR = 0.25;
//	ALBEDO = soft_light(_screen,color_out);

}
