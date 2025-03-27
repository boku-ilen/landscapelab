// Copyright © 2021 Kasper Arnklit Frandsen - MIT License
// See `LICENSE.md` included in the source distribution for details.
shader_type spatial;
// CHANGED from author
// enabled culling cause we could not use it as a plane
render_mode depth_draw_always, specular_schlick_ggx;

// CHANGED from author
// Removed unecessary descriptions

// Main
uniform sampler2D depth: hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen: hint_screen_texture, filter_linear_mipmap;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;
uniform sampler2D normal_bump_texture : hint_normal;
uniform vec3 uv_scale = vec3(1.0, 1.0, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.2;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.25;

// Albedo
// CHANGED from author
// made the mat4 into two color hints for easier modifications
uniform vec4 _albedo_color_near: source_color;
uniform vec4 _albedo_color_far: source_color;
uniform float albedo_depth : hint_range(0.0, 200.0) = 10.0;
uniform float albedo_depth_curve = 0.25;

// Transparency
uniform float transparency_clarity : hint_range(0.0, 200.0) = 10.0;
uniform float transparency_depth_curve = 0.25;
uniform float transparency_refraction : hint_range(-1.0, 1.0) = 0.05;

// Flow
uniform float flow_speed : hint_range(0.0, 10.0) = 1.0;
uniform float flow_base : hint_range(0.0, 8.0) = 0.0;
uniform float flow_steepness : hint_range(0.0, 8.0) = 2.0;
uniform float flow_distance : hint_range(0.0, 8.0) = 1.0;
uniform float flow_pressure : hint_range(0.0, 8.0) = 1.0;
uniform float flow_max : hint_range(0.0, 8.0) = 4.0;

// Internal uniforms - DO NOT CUSTOMIZE THESE
uniform float i_lod0_distance : hint_range(5.0, 200.0) = 50.0;
uniform sampler2D i_texture_foam_noise : hint_default_white;
// CHANGED from author
// removed dist and flowmap
uniform int i_uv2_sides = 2;


vec3 FlowUVW(vec2 uv_in, vec2 flowVector, vec2 jump, vec3 tiling, float time, bool flowB) {
	float phaseOffset = flowB ? 0.5 : 0.0;
	float progress = fract(time + phaseOffset);
	vec3 uvw;
	uvw.xy = uv_in - flowVector * (progress - 0.5);
	uvw.xy *= tiling.xy;
	uvw.xy += phaseOffset;
	uvw.xy += (time - progress) * jump;
	uvw.z = 1.0 - abs(1.0 - 2.0 * progress);
	return uvw;
}

// ease implementation copied from math_funcs.cpp in source
float ease(float p_x, float p_c) {
	if (p_x < 0.0) {
		p_x = 0.0;
	} else if (p_x > 1.0) {
		p_x = 1.0;
	}
	if (p_c > 0.0) {
		if (p_c < 1.0) {
			return 1.0 - pow(1.0 - p_x, 1.0 / p_c);
		} else {
			return pow(p_x, p_c);
		}
	} else if (p_c < 0.0) {
		//inout ease

		if (p_x < 0.5) {
			return pow(p_x * 2.0, -p_c) * 0.5;
		} else {
			return (1.0 - pow(1.0 - (p_x - 0.5) * 2.0, -p_c)) * 0.5 + 0.5;
		}
	} else {
		return 0.0; // no ease (raw)
	}
}

float lin2srgb(float lin) {
	return pow(lin, 2.2);
}

mat4 gradient_lin2srgb(mat4 lin_mat) {
	mat4 srgb_mat = mat4(
		vec4(lin2srgb(lin_mat[0].x), lin2srgb(lin_mat[0].y), lin2srgb(lin_mat[0].z), lin2srgb(lin_mat[0].w)),
		vec4(lin2srgb(lin_mat[1].x), lin2srgb(lin_mat[1].y), lin2srgb(lin_mat[1].z), lin2srgb(lin_mat[1].w)),
		vec4(0.0),
		vec4(0.0)
	);
	return srgb_mat;
}

// CHANGED from author
// removed flowmap and distmap
void fragment() {
	// Sample the UV2 textures. To avoid issues with the UV2 seams, margins
	// are left on the textures, so the UV2 needs to be rescaled to cut off
	// the margins.
	vec2 custom_UV = (UV2 + 1.0 / float(i_uv2_sides)) * (float(i_uv2_sides) / float(i_uv2_sides + 2));

	vec2 flow;
	float distance_map;
	float pressure_map;
	float foam_mask;

	flow = vec2(0.5, 0.572);
	distance_map = 0.5;
	pressure_map = 0.5;
	foam_mask = 0.0;

	flow = (flow - 0.5) * 2.0; // unpack the flow vectors
	flow *= (0.6 - abs(UV.y - 0.5)) * 5.0;
	float temp = flow.x;
	flow.x = -flow.y;
	flow.y = temp;

	// Calculate the steepness map
	vec3 flow_viewspace = flow.x * TANGENT + flow.y * BINORMAL;
	vec3 up_viewspace = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	float steepness_map = max(0.0, dot(flow_viewspace, up_viewspace)) * 4.0;

	float flow_force = min(flow_base + steepness_map * flow_steepness + distance_map * flow_distance + pressure_map * flow_pressure, flow_max);
	flow *= flow_force;

	vec2 jump1 = vec2(0.24, 0.2083333);
	vec2 jump2 = vec2(0.20, 0.25);
	vec2 jump3 = vec2(0.22, 0.27);
	float time = TIME * flow_speed;
	vec3 flow_uvA = FlowUVW(UV, flow, jump1, uv_scale, time, false);
	vec3 flow_uvB = FlowUVW(UV, flow, jump1, uv_scale, time, true);
	vec3 flowx2_uvA = FlowUVW(UV, flow, jump2, uv_scale * 2.5, time, false);
	vec3 flowx2_uvB = FlowUVW(UV, flow, jump2, uv_scale * 2.5, time, true);

	// Level 1 Water
	vec3 water_a = texture(normal_bump_texture, flow_uvA.xy).rgb;
	vec3 water_b = texture(normal_bump_texture, flow_uvB.xy * 1.4).rgb;
	vec3 water = water_a * flow_uvA.z + water_b * flow_uvB.z;

	vec2 water_norFBM = water.rg;
	float water_foamFBM = water.b;

	// Level 2 Water, only add in if closer than lod 0 distance
	if (-VERTEX.z < i_lod0_distance) {
		vec3 waterx2_a = texture(normal_bump_texture, flowx2_uvA.xy).rgb;
		vec3 waterx2_b = texture(normal_bump_texture, flowx2_uvB.xy * 2.8, 0.0).rgb;
		vec3 waterx2 = waterx2_a * flowx2_uvA.z + waterx2_b * flowx2_uvB.z;

		water_norFBM *= 0.65;
		water_norFBM += waterx2.rg * 0.35;
		water_foamFBM *= waterx2.b * 2.0;
	}

	float foam_randomness = texture(i_texture_foam_noise, UV * uv_scale.xy).r;

	// Depthtest
	float depth_tex = texture(depth, SCREEN_UV, 0.0).r;
	float depth_tex_unpacked = depth_tex * 2.0 - 1.0;
	float surface_dist = PROJECTION_MATRIX[3][2] / (depth_tex_unpacked + PROJECTION_MATRIX[2][2]);
	float water_depth = surface_dist + VERTEX.z;


	float alb_t = clamp(water_depth / albedo_depth, 0.0, 1.0);
	alb_t = ease(alb_t, albedo_depth_curve);
	SPECULAR = 0.25; // Supposedly clear water has approximately a 0.25 specular value
	ROUGHNESS = roughness;
	NORMAL_MAP = vec3(water_norFBM, 0);
	NORMAL_MAP_DEPTH = normal_scale;


	// Refraction - has to be done after normal is set
	vec3 unpacted_normals = NORMAL_MAP * 2.0 - 1.0;
	//vec3 ref_normal = normalize( mix(NORMAL, TANGENT * unpacted_normals.x + BINORMAL * unpacted_normals.y + NORMAL, NORMAL_MAP_DEPTH) );
	vec3 ref_normal = normalize(TANGENT * unpacted_normals.x + BINORMAL * unpacted_normals.y) * NORMAL_MAP_DEPTH * .1;
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * transparency_refraction;
	float clar_t = clamp(water_depth / transparency_clarity, 0.0, 1.0);
	clar_t = ease(clar_t, transparency_depth_curve);

	// Depthtest 2
	float depth_tex2 = texture(depth, ref_ofs, 0.0).r;
	float depth_tex_unpacked2 = depth_tex2 * 2.0 - 1.0;
	float surface_dist2 = PROJECTION_MATRIX[3][2] / (depth_tex_unpacked2 + PROJECTION_MATRIX[2][2]);
	float water_depth2 = surface_dist2 + VERTEX.z;

	if (surface_dist2 < -VERTEX.z) {
		ref_ofs = SCREEN_UV;
	} else {
		clar_t = clamp(water_depth2 / transparency_clarity, 0.0, 1.0);
		clar_t = ease(clar_t, transparency_depth_curve);
		alb_t = clamp(water_depth2 / albedo_depth, 0.0, 1.0);
		alb_t = ease(alb_t, albedo_depth_curve);
	}
	mat4 albedo_color_srgb = gradient_lin2srgb(mat4(_albedo_color_far, _albedo_color_near, vec4(1,1,1,1), vec4(0,0,0,0)));
	vec3 albedo_color_near = vec3(albedo_color_srgb[0].x, albedo_color_srgb[0].y, albedo_color_srgb[0].z);
	vec3 albedo_color_far = vec3(albedo_color_srgb[1].x, albedo_color_srgb[1].y, albedo_color_srgb[1].z);
	ALBEDO = mix(albedo_color_near.rgb, albedo_color_far.rgb, alb_t);
	// TODO - Go over to using texelfetch to get the texture to avoid edge artifacts
	EMISSION += texture(screen, ref_ofs, ROUGHNESS * water_depth2).rgb;// * ref_amount;

	//ALBEDO *= 1.0 - ref_amount;
	ALPHA = 1.0;
	BACKLIGHT = vec3(0.9);

	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
	world_pos.xyz /= world_pos.w;
	ALPHA *= clamp(1.0 - smoothstep(world_pos.z + edge_fade, world_pos.z, VERTEX.z), 0.0, 1.0);
}