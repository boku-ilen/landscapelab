shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

global uniform vec3 HCY_SHIFT;

uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.01) = 0.7;
uniform float alpha_scissor_threshold_low : hint_range(0.0, 1.0, 0.01) = 0.1;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 albedo_multiply : source_color = vec3(1.0);

uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength : hint_range(-16.0, 16.0) = 1.0;

/**
* R: Roughness
* G: Ambient Occlusion
* B: Transmission:
* . =0.0: No Backlight
* . >0.0: Backlight is used there
* . Bake Branches/Twigs/LeafStems as Black/DarkGray, and Leaf surfaces as pure White.
*/
uniform sampler2D rough_ao_transmission_tex : hint_default_white, filter_linear_mipmap, repeat_enable;

/**
* This is added to value coming from Red channel of "Rough AO Transmission Tex", to allow fast tweaking.
*/
uniform float roughness_offset : hint_range(-1.0, 1.0) = 0.0;

/**
* [b]0[/b]: No AO.
* [b]>0[/b]: Uses Green channel of "Rough AO Transmission Tex".
 */
uniform float ao_strength : hint_range(0.0, 10.0) = 0.6;

/**
* [b]0[/b]: AO only affects ambient light.
* [b]1[/b]: Affects direct lights just as much as it affects ambient light. This can be used to impact the strength of the ambient occlusion effect, but typically looks unrealistic.
 */
uniform float ao_light_affect : hint_range(0.0, 1.0) = 0.8;

/**
* [b]0[/b]: Uses darkish grey (so it has similar brightness to Albedo Tex and isn't unnaturally bright).
* [b]1[/b]: Uses color from Albedo Tex.
* Backlight is only visible where Blue channel (= Transmission) of "Rough AO Transmission Tex" > 0.0 !
* Result is finally multiplied by "Backlight Tint" & "Backlight Strength" for finetuning.
*/
uniform float backlight_color_from_albedo : hint_range(0.0, 1.0) = 1.0;

/**
* Multiplies the resulting Backlight with this color.
* This is independent of "Color from Albedo".
* ATTENTION: Reducing this color's Value reduces the effect!
*/
uniform vec3 backlight_tint : source_color = vec3(1.0);

/**
* Multiplies down Backlight intensity where AO is present in "Rough AO Transmission Tex".
*/
uniform float backlight_affected_by_ao : hint_range (0.0, 10.0) = 0.5;

/**
* Finally multiplies the resulting Backlight with this strength.
*/
uniform float backlight_strength : hint_range (0.0, 10.0) = 1.0;

uniform float rim_strength : hint_range(0.0, 1.0) = 0.03;

/**
* [b]0[/b]: Uses Light's color.
* [b]1[/b]: Uses color from Albedo Tex - which makes effect less visible! Might need to increase "Rim Strength"!
* Should use medium value.
*/
uniform float rim_color_from_albedo : hint_range(0.0, 1.0) = 0.5;

#include "res://Resources/Shader/Wind/Wind.gdshaderinc"
#include "res://Resources/Meshes/Trees/Tree_HueMix.gdshaderinc"

varying float vertex_distance_from_zero;

void vertex() {
	// Concept for forest trees:
	//if (VERTEX.y < 0.5) VERTEX = vec3(1.0 / 0.0);

	VERTEX += get_vertex_offset(VERTEX, MODEL_MATRIX, TIME);

	vertex_distance_from_zero = pow(length(VERTEX), 2.0);

	hue_mix_branch = get_hue_mix_branch_values(NODE_POSITION_WORLD);
	hue_mix_leaf = get_hue_mix_leaf_values(NODE_POSITION_WORLD);
}

void fragment() {
	vec2 base_uv = UV;
	// See https://github.com/godotengine/godot/issues/42411
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	vec4 albedo_w_alpha = texture(albedo_tex, base_uv);
	vec3 rough_ao_trans = texture(rough_ao_transmission_tex, base_uv).rgb;

	// Randomised HYC Shifts of whole Albedo Tex depending on Node's Worldspace Position.
	// Separate settings for Branch or Leaf (using Transmission Tex, unfortunately Branch changes mip-bleed over into Leaf)
	// For organic randomisation: WS PosX shifts Hue, PosY shifts Chroma, PosZ shifts Luminance.
	// -> Make sure Trunk Shader/Material uses same calculation/value as branches!
	vec3 albedo_hcy = RGBtoHCY(albedo_w_alpha.rgb);
	albedo_hcy.r += mix(
		hue_mix_branch.r,
		hue_mix_leaf.r,
		rough_ao_trans.b);
	albedo_hcy.g += mix(
		hue_mix_branch.g,
		hue_mix_leaf.g,
		rough_ao_trans.b);
	albedo_hcy.b += mix(
		hue_mix_branch.b,
		hue_mix_leaf.b,
		rough_ao_trans.b);
	
	albedo_hcy.r += HCY_SHIFT.r;
	albedo_hcy.g *= HCY_SHIFT.g;
	albedo_hcy.b *= HCY_SHIFT.b;
	
	albedo_w_alpha.rgb = HCYtoRGB(albedo_hcy);

	float depth = (1.0 - FRAGCOORD.z) / FRAGCOORD.w;

	ALPHA = albedo_w_alpha.a;

	// To get fine detail up-close and good coverage at a distance, we lerp the threshold based on
	//  the distance of this fragment to the camera, with min threshold at 20m and max at 5m
	ALPHA_SCISSOR_THRESHOLD = mix(alpha_scissor_threshold_low, alpha_scissor_threshold, smoothstep(20.0, 5.0, depth));
	ALBEDO = albedo_w_alpha.rgb * albedo_multiply.rgb;

	METALLIC = 0.0;
	SPECULAR = 0.15;
	ROUGHNESS = rough_ao_trans.r + roughness_offset;

	NORMAL_MAP = texture(normal_tex, base_uv).rgb;
	NORMAL_MAP_DEPTH = mix(0.35, 1.0, smoothstep(300.0, 100.0, depth)) * normal_strength;

	AO = rough_ao_trans.g * ao_strength * mix(0.0, 0.5, vertex_distance_from_zero * 1.25);
	
	// With our settings, the sunlight has its first split at 75 units. This causes a lot of
	// self-shadowing to be lost. Therefore, we make AO more drastic at that distance
	AO *= mix(1.0, AO, mix(0.2, 0.8, smoothstep(55.0, 75.0, depth)));
	
	AO_LIGHT_AFFECT = ao_light_affect;

	vec3 overall_backlight =
	rough_ao_trans.b
	* backlight_strength
	* backlight_tint
	* mix(vec3(0.3), albedo_w_alpha.rgb, backlight_color_from_albedo)
	* mix(1.0, rough_ao_trans.g, backlight_affected_by_ao);

	BACKLIGHT = clamp(overall_backlight, 0.0, 500.0);

	RIM = rim_strength;
	RIM_TINT = rim_color_from_albedo;
}
