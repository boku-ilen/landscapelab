// ============================================================
// TRIPLANAR MODE DEFINES
// ============================================================

#define TRIP_PROJECTION_HARD 0
#define TRIP_PROJECTION_BLENDED 1
#define TRIP_PROJECTION_MODE TRIP_PROJECTION_BLENDED // CHOOSE PROJECTION MODE

#define TRIP_SHADE_CHEAP 0
#define TRIP_SHADE_EXPENSIVE 1
#define TRIP_SHADE_MODE TRIP_SHADE_EXPENSIVE // CHOOSE SHADING MODE

// WARNING: Meshes MUST NOT use negative scale, this is not considered!


// ============================================================
// UNIFORMS + VARYING DECLARATION
// ============================================================

//// GENERAL PARAMETERS
group_uniforms general_parameters;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;
uniform int debug_mode = 0; // Debug-view different things if >0
uniform float triplanar_blend_sharpness : hint_range(1, 150.0, 0.001) = 50.0; // ONLY USED FOR BLENDED MODE!
group_uniforms;

//// BASE LAYER
group_uniforms layer_base;
uniform vec4 base_albedo_tint : source_color = vec4(1.0); // Multiplied on top of _albedo_tex
uniform sampler2D base_albedo_tex : hint_default_white;
uniform sampler2D base_normal_tex : hint_normal;
uniform sampler2D base_mrao_tex : hint_default_white;// R=Metal G=Rough B=AO
uniform float base_uv_tiling : hint_range(0.01, 10.0) = 1.0; // Tiling = UV Tiling
group_uniforms;

//// DIRT LAYER
group_uniforms layer_dirt;
uniform sampler2D dirt_albedo_tex : hint_default_white; // Depending on whether "Cheap" or "Expensive" Shade Mode, this is either mixed with Base Layer, or multiplied on top of it (both methods using Dirtmask_Tex)
uniform vec4 dirt_albedo_tint : source_color = vec4(1.0); // Multiplied on top of _albedo_tex
uniform sampler2D dirt_normal_tex : hint_normal;
uniform sampler2D dirt_mrao_tex : hint_default_white; // R=Metal G=Rough B=AO
uniform float dirt_uv_tiling : hint_range(0.01, 20.0) = 4.0; // Tiling = UV Tiling
group_uniforms;

//// DIRTMASK = Mask for Blending between pure Base layer, and Base Layer * Dirt Layer
group_uniforms dirtmask;
uniform sampler2D dirtmask_tex : hint_default_black; // Grayscale
uniform float dirtmask_amount : hint_range(0.0, 1.0) = 1.0; // Additionally reduces effect of Dirt Layer
uniform float dirtmask_uv_tiling : hint_range(0.01, 20.0) = 2.0;
group_uniforms;

//// VARYINGS
varying vec3 trip_v_triplanar_pos;
varying vec3 trip_v_local_normal; // Used for determining dominant axis of Vertex -> which Projection Axis to use
varying vec3 trip_v_blend_weight_mask; // Only required for TRIP_PROJECTION_BLENDED


// ============================================================
// FUNC DEFINITIONS
// ============================================================


// CALC IN VERTEX SHADER ===========================================
// NOTE: Unfortunately, func in shaderinclude can NOT get from builtin VERTEX, NORMAL and MODEL_MATRIX directly, that's why those need to be passed in!
// Also it can NOT assign to varying variables or built-in vertex outputs like TANGENT / BINORMAL directly.
// That's why it just outputs the results, and varyings / built-in vertex outputs need to be assigned directly inside vertex() in the Main Shader's vertex()!
// ============================================================
void trip_calc_vertex_data(
	vec3 in_builtin_VERTEX,
	vec3 in_builtin_NORMAL,
	mat4 in_builtin_MODEL_MATRIX,
	out vec3 out_v_triplanar_pos,
	out vec3 out_v_local_normal,
	out vec3 out_v_blend_weight_mask,
	out vec3 out_tangent,
	out vec3 out_binormal
	)
	{
	out_v_local_normal = in_builtin_NORMAL;
	vec3 normal = in_builtin_NORMAL; // Maybe not required?

	// --- World position of the vertex
	vec3 vertex_wp = (in_builtin_MODEL_MATRIX * vec4(in_builtin_VERTEX, 1.0)).xyz;

	// --- Rotation-only basis from MODEL_MATRIX (strip scale)
	vec3 ax = normalize(in_builtin_MODEL_MATRIX[0].xyz);
	vec3 ay = normalize(in_builtin_MODEL_MATRIX[1].xyz);
	vec3 az = normalize(in_builtin_MODEL_MATRIX[2].xyz);

	// world -> object-axes (inverse rotation via transpose)
	mat3 world_to_obj_axes = transpose(mat3(ax, ay, az));

	// World anchored coordinates expressed in object axes
	// => seamless UVs across meshes with identical rotation
	out_v_triplanar_pos = world_to_obj_axes * vertex_wp;
	out_v_triplanar_pos *= vec3(1.0, -1.0, 1.0);

#if TRIP_PROJECTION_MODE == TRIP_PROJECTION_HARD
	out_v_blend_weight_mask = vec3(0.0);

#elif TRIP_PROJECTION_MODE == TRIP_PROJECTION_BLENDED
	out_v_blend_weight_mask = pow(abs(normal), vec3(triplanar_blend_sharpness));
	out_v_blend_weight_mask /= dot(out_v_blend_weight_mask, vec3(1.0));

#endif

	//// Synthetic TANGENT / BINORMAL basis
	//// Current practical fix for wrong NormalMap light direction on some projection sides.
	//// It must be assigned to TANGENT / BINORMAL directly inside vertex() in the Main Shader.
	out_tangent = normalize(vec3(
									abs(normal.y) + abs(normal.z),
									0.0,
									-abs(normal.x)
								));

	out_binormal = normalize(vec3(
									0.0,
									abs(normal.x) + abs(normal.z),
									-abs(normal.y)
								));
}


// FRAGMENT SHARED PREPARE ====================================
// If TRIP_PROJECTION_HARD: Calculate dominant_axis_mask (pure R or G or B), fallback values for blend_weight_mask.
// If TRIP_PROJECTION_BLENDED: Calculate blend_weight_mask, fallback values for dominant_axis_mask.
//
// Sends out-parameters "out_triplanar_pos_" for the 3 Layers, because each has different UV Tiling.
//
// NOTE:
// This function reads the varyings directly, which must be previously calculated by "trip_calc_vertex_data" and updated correctly in void vertex() in Main Shader:
// - trip_v_local_normal
// - trip_v_triplanar_pos
// - trip_v_blend_weight_mask
// ============================================================
void trip_fragment_prepare_shared(
	out vec3 out_dominant_axis_mask,
	out vec3 out_projection_axis_flip,
	out vec3 out_blend_weight_mask,
	out vec3 out_triplanar_pos_layer_base,
	out vec3 out_triplanar_pos_layer_dirt,
	out vec3 out_triplanar_pos_layer_dirtmask
	)
	{
	vec3 local_normal = normalize(trip_v_local_normal);

	// sign of local normal (+1 / -1) per axis
	vec3 axis_sign = vec3(
		mix(-1.0, 1.0, step(0.0, local_normal.x)),
		mix(-1.0, 1.0, step(0.0, local_normal.y)),
		mix(-1.0, 1.0, step(0.0, local_normal.z))
	);

	// Flip U on negative-facing projections to remove mirroring
	out_projection_axis_flip = vec3(
		(axis_sign.x < 0.0) ? 1.0 : -1.0,
		(axis_sign.y < 0.0) ? -1.0 : 1.0,
		(axis_sign.z < 0.0) ? -1.0 : 1.0
	);

#if TRIP_PROJECTION_MODE == TRIP_PROJECTION_HARD
	// -------------------------
	// DOMINANT AXIS (PER-PIXEL, HARD / ONE-HOT)
	// -------------------------
	vec3 abs_local_normal = abs(local_normal);

	// one-hot winner (avoids ties turning on multiple axes)
	float x_wins = step(abs_local_normal.y, abs_local_normal.x) * step(abs_local_normal.z, abs_local_normal.x);
	float y_wins = step(abs_local_normal.x, abs_local_normal.y) * step(abs_local_normal.z, abs_local_normal.y);
	float z_wins = 1.0 - max(x_wins, y_wins);
	out_dominant_axis_mask = vec3(x_wins, y_wins, z_wins);

	out_blend_weight_mask = vec3(0.0);

#elif TRIP_PROJECTION_MODE == TRIP_PROJECTION_BLENDED
	out_dominant_axis_mask = vec3(0.0);
	out_blend_weight_mask = trip_v_blend_weight_mask;

#endif

	out_triplanar_pos_layer_base = trip_v_triplanar_pos * base_uv_tiling;
	out_triplanar_pos_layer_dirt = trip_v_triplanar_pos * dirt_uv_tiling;
	out_triplanar_pos_layer_dirtmask = trip_v_triplanar_pos * dirtmask_uv_tiling;
}


// BASE LAYER SAMPLING - PROJECTION HARD ======================
//
// NOTE:
// This function reads the Base Layer uniforms directly:
// - base_albedo_tint, base_albedo_tex, base_normal_tex, base_mrao_tex
//
// It expects that func "trip_fragment_prepare_shared" has already done this:
// - in_triplanar_pos_layer_base to already be scaled by base_uv_tiling
// - in_dominant_axis_mask to already be prepared
// - in_projection_axis_flip to already be prepared
//
// It writes the sampled Base Layer channels into these 3 out variables:
// - out_base_albedo_texsampled, out_base_normal_texsampled, out_base_mrao_texsampled
// ============================================================
void trip_sample_base_layer_hard(
	vec3 in_triplanar_pos_layer_base,
	vec3 in_dominant_axis_mask,
	vec3 in_projection_axis_flip,
	out vec3 out_base_albedo_texsampled,
	out vec3 out_base_normal_texsampled,
	out vec3 out_base_mrao_texsampled
	)
	{
	// Multiply using these potentially inverted flip vars
	vec2 uv_xaxis = vec2(in_triplanar_pos_layer_base.z * in_projection_axis_flip.x, in_triplanar_pos_layer_base.y);
	vec2 uv_yaxis = vec2(in_triplanar_pos_layer_base.x * in_projection_axis_flip.y, in_triplanar_pos_layer_base.z);
	vec2 uv_zaxis = vec2(in_triplanar_pos_layer_base.x * in_projection_axis_flip.z, in_triplanar_pos_layer_base.y);

	vec2 proj_uv = uv_xaxis * in_dominant_axis_mask.x
	             + uv_yaxis * in_dominant_axis_mask.y
	             + uv_zaxis * in_dominant_axis_mask.z;

	out_base_albedo_texsampled = texture(base_albedo_tex, proj_uv).rgb * base_albedo_tint.rgb;
	out_base_normal_texsampled = texture(base_normal_tex, proj_uv).rgb;
	out_base_mrao_texsampled   = texture(base_mrao_tex, proj_uv).rgb;
}


// BASE LAYER SAMPLING - PROJECTION BLENDED ===================
//
// NOTE:
// This function reads the Base Layer uniforms directly:
// - base_albedo_tint, base_albedo_tex, base_normal_tex, base_mrao_tex
//
// It expects that func "trip_fragment_prepare_shared" has already done this:
// - in_triplanar_pos_layer_base to already be scaled by base_uv_tiling
// - in_blend_weight_mask to already be prepared
// - in_projection_axis_flip to already be prepared
//
// It writes the sampled Base Layer channels into these 3 out variables:
// - out_base_albedo_texsampled, out_base_normal_texsampled, out_base_mrao_texsampled
// ============================================================
void trip_sample_base_layer_blended(
	vec3 in_triplanar_pos_layer_base,
	vec3 in_blend_weight_mask,
	vec3 in_projection_axis_flip,
	out vec3 out_base_albedo_texsampled,
	out vec3 out_base_normal_texsampled,
	out vec3 out_base_mrao_texsampled
	)
	{
	vec2 uv_xaxis = vec2(in_triplanar_pos_layer_base.z * in_projection_axis_flip.x, in_triplanar_pos_layer_base.y); // X -> zy
	vec2 uv_yaxis = vec2(in_triplanar_pos_layer_base.x * in_projection_axis_flip.y, in_triplanar_pos_layer_base.z); // Y -> xz
	vec2 uv_zaxis = vec2(in_triplanar_pos_layer_base.x * in_projection_axis_flip.z, in_triplanar_pos_layer_base.y); // Z -> xy

	out_base_albedo_texsampled =
		texture(base_albedo_tex, uv_zaxis).rgb * in_blend_weight_mask.z +
		texture(base_albedo_tex, uv_yaxis).rgb * in_blend_weight_mask.y +
		texture(base_albedo_tex, uv_xaxis).rgb * in_blend_weight_mask.x;
	out_base_albedo_texsampled *= base_albedo_tint.rgb;

	out_base_normal_texsampled =
		texture(base_normal_tex, uv_zaxis).rgb * in_blend_weight_mask.z +
		texture(base_normal_tex, uv_yaxis).rgb * in_blend_weight_mask.y +
		texture(base_normal_tex, uv_xaxis).rgb * in_blend_weight_mask.x;

	out_base_mrao_texsampled =
		texture(base_mrao_tex, uv_zaxis).rgb * in_blend_weight_mask.z +
		texture(base_mrao_tex, uv_yaxis).rgb * in_blend_weight_mask.y +
		texture(base_mrao_tex, uv_xaxis).rgb * in_blend_weight_mask.x;
}


// DIRT LAYER SAMPLING - PROJECTION HARD ======================
//
// NOTE:
// This function reads the Dirt Layer uniforms directly:
// dirt_albedo_tint, dirt_albedo_tex, dirt_normal_tex, dirt_mrao_tex (but normal and mrao are only sampled if TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE!)
//
// It expects that func "trip_fragment_prepare_shared" has already done this:
// - in_triplanar_pos_layer_dirt to already be scaled by dirt_uv_tiling
// - in_dominant_axis_mask to already be prepared
// - in_projection_axis_flip to already be prepared
//
// It writes these out variables:
// - out_dirt_albedo_texsampled
// - out_dirt_normal_texsampled (sampled only if TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE, otherwise receives fallback value)
// - out_dirt_mrao_texsampled (sampled only if TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE, otherwise receives fallback value)
// ============================================================

void trip_sample_dirt_layer_hard(
	vec3 in_triplanar_pos_layer_dirt,
	vec3 in_dominant_axis_mask,
	vec3 in_projection_axis_flip,
	out vec3 out_dirt_albedo_texsampled,
	out vec3 out_dirt_normal_texsampled,
	out vec3 out_dirt_mrao_texsampled
	)
	{
	// Multiply using these potentially inverted flip vars
	vec2 uv_xaxis = vec2(in_triplanar_pos_layer_dirt.z * in_projection_axis_flip.x, in_triplanar_pos_layer_dirt.y);
	vec2 uv_yaxis = vec2(in_triplanar_pos_layer_dirt.x * in_projection_axis_flip.y, in_triplanar_pos_layer_dirt.z);
	vec2 uv_zaxis = vec2(in_triplanar_pos_layer_dirt.x * in_projection_axis_flip.z, in_triplanar_pos_layer_dirt.y);

	vec2 proj_uv = uv_xaxis * in_dominant_axis_mask.x
	             + uv_yaxis * in_dominant_axis_mask.y
	             + uv_zaxis * in_dominant_axis_mask.z;

	out_dirt_albedo_texsampled = texture(dirt_albedo_tex, proj_uv).rgb * dirt_albedo_tint.rgb;

#if TRIP_SHADE_MODE == TRIP_SHADE_CHEAP
	out_dirt_normal_texsampled = vec3(0.5, 0.5, 1.0);
	out_dirt_mrao_texsampled   = vec3(0.0, 1.0, 1.0);

#elif TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE
	out_dirt_normal_texsampled = texture(dirt_normal_tex, proj_uv).rgb;
	out_dirt_mrao_texsampled   = texture(dirt_mrao_tex, proj_uv).rgb;

#endif
}


// DIRT LAYER SAMPLING - PROJECTION BLENDED ===================
//
// NOTE:
// This function reads the Dirt Layer uniforms directly:
// dirt_albedo_tint, dirt_albedo_tex, dirt_normal_tex, dirt_mrao_tex (but normal and mrao are only sampled if TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE!)
//
// It expects that func "trip_fragment_prepare_shared" has already done this:
// - in_triplanar_pos_layer_dirt to already be scaled by dirt_uv_tiling
// - in_blend_weight_mask to already be prepared
// - in_projection_axis_flip to already be prepared
//
// It writes these out variables:
// - out_dirt_albedo_texsampled
// - out_dirt_normal_texsampled (sampled only if TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE, otherwise receives fallback value)
// - out_dirt_mrao_texsampled (sampled only if TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE, otherwise receives fallback value)
// ============================================================
void trip_sample_dirt_layer_blended(
	vec3 in_triplanar_pos_layer_dirt,
	vec3 in_blend_weight_mask,
	vec3 in_projection_axis_flip,
	out vec3 out_dirt_albedo_texsampled,
	out vec3 out_dirt_normal_texsampled,
	out vec3 out_dirt_mrao_texsampled
	)
	{
	vec2 uv_xaxis = vec2(in_triplanar_pos_layer_dirt.z * in_projection_axis_flip.x, in_triplanar_pos_layer_dirt.y); // X -> zy
	vec2 uv_yaxis = vec2(in_triplanar_pos_layer_dirt.x * in_projection_axis_flip.y, in_triplanar_pos_layer_dirt.z); // Y -> xz
	vec2 uv_zaxis = vec2(in_triplanar_pos_layer_dirt.x * in_projection_axis_flip.z, in_triplanar_pos_layer_dirt.y); // Z -> xy

	out_dirt_albedo_texsampled =
		texture(dirt_albedo_tex, uv_zaxis).rgb * in_blend_weight_mask.z +
		texture(dirt_albedo_tex, uv_yaxis).rgb * in_blend_weight_mask.y +
		texture(dirt_albedo_tex, uv_xaxis).rgb * in_blend_weight_mask.x;
	out_dirt_albedo_texsampled *= dirt_albedo_tint.rgb;

#if TRIP_SHADE_MODE == TRIP_SHADE_CHEAP
	out_dirt_normal_texsampled = vec3(0.5, 0.5, 1.0);
	out_dirt_mrao_texsampled   = vec3(0.0, 1.0, 1.0);

#elif TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE
	out_dirt_normal_texsampled =
		texture(dirt_normal_tex, uv_zaxis).rgb * in_blend_weight_mask.z +
		texture(dirt_normal_tex, uv_yaxis).rgb * in_blend_weight_mask.y +
		texture(dirt_normal_tex, uv_xaxis).rgb * in_blend_weight_mask.x;

	out_dirt_mrao_texsampled =
		texture(dirt_mrao_tex, uv_zaxis).rgb * in_blend_weight_mask.z +
		texture(dirt_mrao_tex, uv_yaxis).rgb * in_blend_weight_mask.y +
		texture(dirt_mrao_tex, uv_xaxis).rgb * in_blend_weight_mask.x;

#endif
}

// DIRTMASK SAMPLING - PROJECTION HARD ========================
//
// NOTE:
// This function reads the Dirtmask uniform directly:
// - dirtmask_tex
//
// It expects that func "trip_fragment_prepare_shared" has already done this:
// - in_triplanar_pos_layer_dirtmask to already be scaled by dirtmask_uv_tiling
// - in_dominant_axis_mask to already be prepared
// - in_projection_axis_flip to already be prepared
//
// This function does not use out variables.
// It returns the sampled dirtmask value directly as float.
// ============================================================
float trip_sample_dirtmask_hard(
	vec3 in_triplanar_pos_layer_dirtmask,
	vec3 in_dominant_axis_mask,
	vec3 in_projection_axis_flip
	)
	{
	// Multiply using these potentially inverted flip vars
	vec2 uv_xaxis = vec2(in_triplanar_pos_layer_dirtmask.z * in_projection_axis_flip.x, in_triplanar_pos_layer_dirtmask.y);
	vec2 uv_yaxis = vec2(in_triplanar_pos_layer_dirtmask.x * in_projection_axis_flip.y, in_triplanar_pos_layer_dirtmask.z);
	vec2 uv_zaxis = vec2(in_triplanar_pos_layer_dirtmask.x * in_projection_axis_flip.z, in_triplanar_pos_layer_dirtmask.y);

	vec2 proj_uv = uv_xaxis * in_dominant_axis_mask.x
	             + uv_yaxis * in_dominant_axis_mask.y
	             + uv_zaxis * in_dominant_axis_mask.z;

	return texture(dirtmask_tex, proj_uv).r;
}


// DIRTMASK SAMPLING - PROJECTION BLENDED =====================
//
// NOTE:
// This function reads the Dirtmask uniform directly:
// dirtmask_tex
//
// It expects that func "trip_fragment_prepare_shared" has already done this:
// - in_triplanar_pos_layer_dirtmask to already be scaled by dirtmask_uv_tiling
// - in_blend_weight_mask to already be prepared
// - in_projection_axis_flip to already be prepared
//
// This function does not use out variables.
// It returns the sampled dirtmask value directly as float.
// ============================================================
float trip_sample_dirtmask_blended(
	vec3 in_triplanar_pos_layer_dirtmask,
	vec3 in_blend_weight_mask,
	vec3 in_projection_axis_flip
	)
	{
	vec2 uv_xaxis = vec2(in_triplanar_pos_layer_dirtmask.z * in_projection_axis_flip.x, in_triplanar_pos_layer_dirtmask.y); // X -> zy
	vec2 uv_yaxis = vec2(in_triplanar_pos_layer_dirtmask.x * in_projection_axis_flip.y, in_triplanar_pos_layer_dirtmask.z); // Y -> xz
	vec2 uv_zaxis = vec2(in_triplanar_pos_layer_dirtmask.x * in_projection_axis_flip.z, in_triplanar_pos_layer_dirtmask.y); // Z -> xy

	return
		texture(dirtmask_tex, uv_zaxis).r * in_blend_weight_mask.z +
		texture(dirtmask_tex, uv_yaxis).r * in_blend_weight_mask.y +
		texture(dirtmask_tex, uv_xaxis).r * in_blend_weight_mask.x;
}

// BLEND NORMALS WHITEOUT =====================================
// Sub-Func for blending 2 Base + Dirt Layer Normals
// ============================================================
vec3 blend_normals_whiteout(vec3 in_base_normal, vec3 in_dirt_normal) {
	vec3 base_n = normalize(in_base_normal);
	vec3 dirt_n = normalize(in_dirt_normal);

	return normalize(vec3(
		base_n.xy + dirt_n.xy,
		base_n.z * dirt_n.z
	));
}

// BLEND NORMALMAPS WHITEOUT MASKED============================
// Main Func for blending 2 Base + Dirt Layer Normal Maps
// ============================================================
vec3 blend_normalmaps_whiteout_masked(
	vec3 in_base_normal_encoded,
	vec3 in_dirt_normal_encoded,
	float in_mask_texsampled,
	float in_mask_amount
	)
	{
	float mask = clamp(in_mask_texsampled * in_mask_amount, 0.0, 1.0);

	// Decode
	vec3 base_n = in_base_normal_encoded * 2.0 - 1.0;
	vec3 dirt_n = in_dirt_normal_encoded * 2.0 - 1.0;

	// Scale dirt detail strength
	dirt_n = normalize(dirt_n);
	vec2 dirt_xy = dirt_n.xy * mask;
	float dirt_z = sqrt(max(1.0 - dot(dirt_xy, dirt_xy), 0.0));
	vec3 dirt_n_scaled = normalize(vec3(dirt_xy, dirt_z));

	// Whiteout overlay
	vec3 final_n = blend_normals_whiteout(base_n, dirt_n_scaled);

	// Encode again for Return
	return final_n * 0.5 + 0.5;
}


// RESOLVE SURFACE ===========================================
// Main function to be used in void fragment() of Main Shader - writes final surface channels back into out variables.
// They need to be stored in Main Shader and then set there.
//
// NOTE:
// This function reads the included uniforms directly.
// It internally switches depending on:
// - TRIP_PROJECTION_MODE
// - TRIP_SHADE_MODE
// - debug_mode
//
// It expects that vertex() has already assigned these varyings correctly:
// - trip_v_triplanar_pos
// - trip_v_local_normal
// - trip_v_blend_weight_mask
//
// It writes the final surface channels into these 5 out variables:
// - out_final_albedo, out_final_normal, out_final_metallic, out_final_roughness, out_final_ao
// ============================================================
void trip_resolve_surface(
	out vec3 out_final_albedo,
	out vec3 out_final_normal,
	out float out_final_metallic,
	out float out_final_roughness,
	out float out_final_ao
	)
	{
	// SHARED PREPARE -------------------------------------------
	vec3 dominant_axis_mask;
	vec3 projection_axis_flip;
	vec3 blend_weight_mask;
	vec3 triplanar_pos_layer_base;
	vec3 triplanar_pos_layer_dirt;
	vec3 triplanar_pos_layer_dirtmask;

	// Calculates + Stores out-parameters triplanar_pos_layer_base, triplanar_pos_layer_dirt and triplanar_pos_layer_dirtmask for later - not via return!
	trip_fragment_prepare_shared(
		dominant_axis_mask,
		projection_axis_flip,
		blend_weight_mask,
		triplanar_pos_layer_base,
		triplanar_pos_layer_dirt,
		triplanar_pos_layer_dirtmask
	);

	// SAMPLE RESULT VARIABLE DECLARATIONS -----------------------
	vec3 base_albedo_texsampled;
	vec3 base_normal_texsampled;
	vec3 base_mrao_texsampled;
	vec3 dirt_albedo_texsampled;
	vec3 dirt_normal_texsampled;
	vec3 dirt_mrao_texsampled;
	float dirtmask_texsampled;


	// PROJECTION-DEPENDENT SAMPLING ----------------------------

#if TRIP_PROJECTION_MODE == TRIP_PROJECTION_HARD
	//// BASE LAYER TEX SAMPLING
	trip_sample_base_layer_hard(
		triplanar_pos_layer_base,
		dominant_axis_mask,
		projection_axis_flip,
		base_albedo_texsampled,
		base_normal_texsampled,
		base_mrao_texsampled
	);

	//// DIRT LAYER TEX SAMPLING
	trip_sample_dirt_layer_hard(
		triplanar_pos_layer_dirt,
		dominant_axis_mask,
		projection_axis_flip,
		dirt_albedo_texsampled,
		dirt_normal_texsampled,
		dirt_mrao_texsampled
	);

	//// DIRTMASK TEX SAMPLING
	dirtmask_texsampled = trip_sample_dirtmask_hard(
		triplanar_pos_layer_dirtmask,
		dominant_axis_mask,
		projection_axis_flip
	);

#elif TRIP_PROJECTION_MODE == TRIP_PROJECTION_BLENDED
	//// BASE LAYER TEX SAMPLING
	trip_sample_base_layer_blended(
		triplanar_pos_layer_base,
		blend_weight_mask,
		projection_axis_flip,
		base_albedo_texsampled,
		base_normal_texsampled,
		base_mrao_texsampled
	);

	//// DIRT LAYER TEX SAMPLING
	trip_sample_dirt_layer_blended(
		triplanar_pos_layer_dirt,
		blend_weight_mask,
		projection_axis_flip,
		dirt_albedo_texsampled,
		dirt_normal_texsampled,
		dirt_mrao_texsampled
	);

	//// DIRTMASK TEX SAMPLING
	dirtmask_texsampled = trip_sample_dirtmask_blended(
		triplanar_pos_layer_dirtmask,
		blend_weight_mask,
		projection_axis_flip
	);
#endif


	// CALCULATE "final_" CHANNELS FOR USE IN OUTPUT ------------

	if (debug_mode == 0) {
		float dirtmask_factor = dirtmask_texsampled * dirtmask_amount;

#if TRIP_SHADE_MODE == TRIP_SHADE_CHEAP
		out_final_albedo    = mix(base_albedo_texsampled, dirt_albedo_texsampled, dirtmask_factor); // ---- Variant 1: Dirt replaces Base
		//out_final_albedo  = mix(base_albedo_texsampled, dirt_albedo_texsampled * base_albedo_texsampled, dirtmask_factor); // ---- Variant 2: Dirt multiplies on top of Base
		out_final_normal    = base_normal_texsampled; // Cheap method: Dirt Layer does not affect Normal/MRAO
		out_final_metallic  = base_mrao_texsampled.r;
		out_final_roughness = base_mrao_texsampled.g;
		out_final_ao        = base_mrao_texsampled.b;

#elif TRIP_SHADE_MODE == TRIP_SHADE_EXPENSIVE
		out_final_albedo    = mix(base_albedo_texsampled, dirt_albedo_texsampled, dirtmask_factor);
		out_final_normal    = blend_normalmaps_whiteout_masked(base_normal_texsampled, dirt_normal_texsampled, dirtmask_texsampled, dirtmask_amount);
		out_final_metallic  = mix(base_mrao_texsampled.r, dirt_mrao_texsampled.r, dirtmask_factor);
		out_final_roughness = mix(base_mrao_texsampled.g, dirt_mrao_texsampled.g, dirtmask_factor);
		out_final_ao        = mix(base_mrao_texsampled.b, dirt_mrao_texsampled.b, dirtmask_factor);
#endif

	} else if (debug_mode == 1) {
#if TRIP_PROJECTION_MODE == TRIP_PROJECTION_HARD
		out_final_albedo = dominant_axis_mask;
#elif TRIP_PROJECTION_MODE == TRIP_PROJECTION_BLENDED
		out_final_albedo = blend_weight_mask;
#endif
		out_final_normal    = vec3(0.5, 0.5, 1.0);
		out_final_metallic  = 0.0;
		out_final_roughness = 1.0;
		out_final_ao        = 1.0;
	} else if (debug_mode == 2) {
		out_final_albedo    = vec3(dirtmask_texsampled);
		out_final_normal    = vec3(0.5, 0.5, 1.0);
		out_final_metallic  = 0.0;
		out_final_roughness = 1.0;
		out_final_ao        = 1.0;
	} else {
		out_final_albedo    = vec3(1.0, 0.0, 1.0);
		out_final_normal    = vec3(0.5, 0.5, 1.0);
		out_final_metallic  = 0.0;
		out_final_roughness = 1.0;
		out_final_ao        = 1.0;
	}
}
