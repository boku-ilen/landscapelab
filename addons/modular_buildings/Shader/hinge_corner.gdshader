// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

instance uniform float bend;

uniform vec4 albedo : source_color;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_g, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D normal_texture : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	// Corner Bending
	//float angle = bend * sign(VERTEX.x + VERTEX.z);
	// angle is halved since both sides are each rotated by this value
	// and PI/4.0 is subtracted to match the look_at direction 
	float angle = INSTANCE_CUSTOM.x * sign(VERTEX.x + VERTEX.z) * 0.5 - PI/4.0;
	
	// correction for the right angle initial state
	angle -= PI/4.0 * sign(VERTEX.x + VERTEX.z);

	if (abs(VERTEX.x + VERTEX.z) < 0.1) angle = -PI/4.0;

	// (column-major notation) y-rotation matrix
	mat3 rotation = mat3(
		vec3(cos(angle), 0.0, -sin(angle)),
		vec3(0.0, 1.0, 0.0),
		vec3(sin(angle), 0.0, cos(angle))
	);


	VERTEX = rotation * VERTEX;
	NORMAL = rotation * NORMAL;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(albedo_texture, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(metallic_texture, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(0.0, 1.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Normal Map: Enabled
	NORMAL_MAP = texture(normal_texture, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}
