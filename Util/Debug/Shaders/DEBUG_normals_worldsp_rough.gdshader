// DEBUG Shader. Assign this to a quad in front of the camera!
// Renders either Roughness or Normals (Mesh Normals + potential Normal Maps) in WorldSpace, instead of ScreenSpace (Default).
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_front;

uniform sampler2D normal_rough_buffer : hint_normal_roughness_texture, repeat_disable, filter_nearest; // Buffer contains ViewSpace Normals + Roughness
//uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest; // Can be used to mask values coming from a skybox
uniform float show_roughness : hint_range(0.0, 1.0, 1.0); // 0: Show WorldSpace Normals, 1: Show Roughness

void vertex() {
  POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	//float skybox_mask = ceil(textureLod(depth_texture, SCREEN_UV, 0.0).r); // Could be used as a multiplied mask at the ALBEDO output
	float roughness_buffer = texture(normal_rough_buffer, SCREEN_UV).a;
	
	vec3 normal_buffer_remap = fma(texture(normal_rough_buffer, SCREEN_UV).rgb, vec3(2.0), vec3(-1.0)); // Remap from 0..1 range to -1..1
	vec3 world_normal = fma(mat3(INV_VIEW_MATRIX) * normal_buffer_remap , vec3(0.5), vec3(0.5));// Multiply Screenspace Normals by InvViewMatrix to get WorldSpace, remap to 0..1 range
	
	vec3 output = mix(world_normal, vec3(roughness_buffer), show_roughness); // To output either WS Normals or Roughness, NOT an inbetween...
	ALBEDO = pow(output, vec3(2.2)); // Remove auto-applied Gamma (from outputting Albedo) for correct values.
}