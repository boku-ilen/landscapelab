// NOTE: Shader automatically converted from Godot Engine 4.2.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_front,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform float wing_length = 1.0;
uniform float flap_speed = 0.8;


uniform float time_scale = 15.0;
uniform float side_to_side = 0.005;
uniform float pivot = 0.05;
uniform float wave = 0.05;
uniform float twist = 1.5;

uniform float mask_black = .2;
uniform float mask_white = .2;

float rand_from_seed(in uint seed) {
  int k;
  int s = int(seed);
  if (s == 0)
    s = 305420679;
  k = s / 127773;
  s = 16807 * (s - k * 127773) - 2836 * k;
  if (s < 0)
    s += 2147483647;
  seed = uint(s);
  return float(seed % uint(65536)) / 65535.0;
}

uint hash(uint x) {
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = (x >> uint(16)) ^ x;
  return x;
}


void vertex() {
	float intensity = clamp(max(0.1, cos(TIME * 0.5 + INSTANCE_CUSTOM.x * PI)) + INSTANCE_CUSTOM.y, 0.0, 1.0);

	float time = TIME * time_scale * flap_speed;
	//VERTEX.y += cos(time) * side_to_side * 1.0;

	float body = (VERTEX.z + 1.0) / 2.0; //for a fish centered at (0, 0) with a length of 2


	float pivot_angle = cos(time) * 0.5 * pivot * intensity;
	mat2 rotation_matrix = mat2(vec2(cos(pivot_angle), -sin(pivot_angle)), vec2(sin(pivot_angle), cos(pivot_angle)));
	VERTEX.yz = rotation_matrix * VERTEX.yz;

	VERTEX.y += cos(time + body) * wave * intensity * wing_length;

	//twist is a uniform float
	float twist_angle = cos(time) * 0.3 * twist * (VERTEX.x / wing_length) * float(distance(0, VERTEX.x / wing_length) > 0.2) * 1.5 * intensity;
	twist_angle += cos(time - PI / 2.0) * 0.5 * twist * (VERTEX.x / wing_length) * float(distance(0, VERTEX.x / wing_length) > 0.4) * 0.5 * intensity;
	mat2 twist_matrix = mat2(vec2(cos(twist_angle), -sin(twist_angle)), vec2(sin(twist_angle), cos(twist_angle)));
	VERTEX.xy = twist_matrix * VERTEX.xy;
}


void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	NORMAL_MAP = texture(texture_normal,base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}
