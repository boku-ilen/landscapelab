shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://addons/modular_buildings/Shader/Triplanar_WorldPosButObjAxis.gdshaderinc"

// VERTEX =====================================================
// NOTE:
// Feed these built-in shader variables into "trip_calc_vertex_data" (because they can NOT be accessed inside):
// - VERTEX
// - NORMAL
// - MODEL_MATRIX
// The helper func "trip_calc_vertex_data" also can NOT assign to varyings itself!
// So it out-parameters these calculated varyings, they need to be stored during vertex():
// - trip_v_triplanar_pos
// - trip_v_local_normal
// - trip_v_blend_weight_mask
// ============================================================
void vertex() {
	vec3 tmp_out_v_triplanar_pos;
	vec3 tmp_out_v_local_normal;
	vec3 tmp_out_v_blend_weight_mask;
	vec3 tmp_out_tangent;
	vec3 tmp_out_binormal;

	trip_calc_vertex_data(
		VERTEX,
		NORMAL,
		MODEL_MATRIX,
		tmp_out_v_triplanar_pos,
		tmp_out_v_local_normal,
		tmp_out_v_blend_weight_mask,
		tmp_out_tangent,
		tmp_out_binormal
	);
	// Update newly calculated varyings
	trip_v_triplanar_pos = tmp_out_v_triplanar_pos;
	trip_v_local_normal = tmp_out_v_local_normal;
	trip_v_blend_weight_mask = tmp_out_v_blend_weight_mask;
	
	// Set modified Tangent/Binormal, otherwise Normal Map lighting direction is wrong from some axis...
	TANGENT = tmp_out_tangent;
	BINORMAL = tmp_out_binormal;
}


// FRAGMENT ===================================================
// NOTE:
// "trip_resolve_surface" calculates (using the previously updated varyings) and writes the final surface channels into 5 out params:
// - final_albedo, final_normal, final_metallic, final_roughness, final_ao
//
// These are then assigned to the real shader outputs:
// - ALBEDO, NORMAL_MAP, METALLIC, ROUGHNESS, AO
//
// SPECULAR and NORMAL_MAP_DEPTH are assigned from the Uniforms in the Shaderinclude directly (require no manipulation).
// ============================================================
void fragment() {
	vec3 final_albedo;
	vec3 final_normal;
	float final_metallic;
	float final_roughness;
	float final_ao;

	trip_resolve_surface(
		final_albedo,
		final_normal,
		final_metallic,
		final_roughness,
		final_ao
	);

	ALBEDO           = final_albedo;
	NORMAL_MAP       = final_normal;
	METALLIC         = final_metallic;
	ROUGHNESS        = final_roughness;
	AO               = final_ao;
	SPECULAR         = specular;
	NORMAL_MAP_DEPTH = normal_scale;
}