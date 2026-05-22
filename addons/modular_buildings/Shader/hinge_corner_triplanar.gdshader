shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://Shader/Triplanar_WorldPosButObjAxis.gdshaderinc"

instance uniform float bend; // Input coming from hinge-corner.gd

//group_uniforms general_parameters;
//uniform vec3 offset_pos_for_bend = vec3(0.0);
//group_uniforms;

void vertex() {

	// Keep originals for later re-use
	vec3 original_vertex = VERTEX;
	vec3 original_normal = NORMAL;

	// CORNER BENDING CALCULATIONS IN VERTEX SHADER
	//
	float angle = bend * sign(original_vertex.x + original_vertex.z);
	if (abs(original_vertex.x + original_vertex.z) < 0.1) angle = 0.0;

	mat3 rotation = mat3(
		vec3(cos(angle), 0.0, -sin(angle)),
		vec3(0.0, 1.0, 0.0),
		vec3(sin(angle), 0.0, cos(angle))
	);

	vec3 bent_vertex = rotation * original_vertex;
	vec3 bent_normal = rotation * original_normal;

	// TRIPLANAR PRE-CALCULATIONS IN VERTEX SHADER
	// Keep original_normal for now, if you want to preserve your current projection behaviour.
	vec3 tmp_out_v_triplanar_pos;
	vec3 tmp_out_v_local_normal;
	vec3 tmp_out_v_blend_weight_mask;
	vec3 tmp_out_tangent;
	vec3 tmp_out_binormal;

	trip_calc_vertex_data(
		original_vertex,       // using bent_vertex makes it worse
		original_normal,   // keep current projection convention for now
		MODEL_MATRIX,
		tmp_out_v_triplanar_pos,
		tmp_out_v_local_normal,
		tmp_out_v_blend_weight_mask,
		tmp_out_tangent,
		tmp_out_binormal
	);

	// Update newly calculated varyings
	trip_v_triplanar_pos = tmp_out_v_triplanar_pos;
	//trip_v_triplanar_pos = tmp_out_v_triplanar_pos + offset_pos_for_bend; // Only used for testing with offset
	trip_v_local_normal = tmp_out_v_local_normal;
	trip_v_blend_weight_mask = tmp_out_v_blend_weight_mask;

	// Set final bent geometry
	VERTEX = bent_vertex;
	NORMAL = bent_normal;
	TANGENT = rotation * tmp_out_tangent;
	BINORMAL = rotation * tmp_out_binormal;
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
