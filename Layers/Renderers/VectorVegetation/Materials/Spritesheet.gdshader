shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.01) = 0.15;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 albedo_multiply : source_color = vec3(1.0);
uniform float albedo_node_rand_hue_branch : hint_range(0.0, 1.0) = 0.08;
uniform float albedo_node_rand_hue_leaf : hint_range(0.0, 1.0) = 0.1;
uniform float albedo_node_rand_chroma_branch : hint_range(0.0, 1.0) = 0.01;
uniform float albedo_node_rand_chroma_leaf : hint_range(0.0, 1.0) = 0.005;
uniform float albedo_node_rand_luma_branch : hint_range(0.0, 1.0) = 0.02;
uniform float albedo_node_rand_luma_leaf : hint_range(0.0, 1.0) = 0.01;

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
uniform float ao_strength : hint_range(0.0, 10.0) = 1.0;

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

varying float normal_to_camera;

uniform int sprite_count = 7;
varying flat float spritesheet_index;
varying flat float random_instance_factor;
varying flat float is_detailed;

varying float camera_distance;

void vertex() {
	// Increase the width as the camera gets towards the middle between the two intersecting planes
	// to compensate for the perspective decreasing the perceived size in that angle
	normal_to_camera = abs(dot(normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xz), normalize((INV_VIEW_MATRIX * vec4(0.0, 0.0, -1.0, 0.0)).xz)));
	normal_to_camera = 1.0 - (0.5 + abs(normal_to_camera - 0.5));

	vec4 view_vertex = MODELVIEW_MATRIX * vec4(VERTEX, 0.0);
	view_vertex.x *= 1.0 + normal_to_camera;
	VERTEX = (inverse(MODELVIEW_MATRIX) * view_vertex).xyz;

	spritesheet_index = INSTANCE_CUSTOM.r;
	random_instance_factor = INSTANCE_CUSTOM.g;
	is_detailed = INSTANCE_CUSTOM.b;

	camera_distance = distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, CAMERA_POSITION_WORLD);
}

void fragment() {
	vec2 base_uv = UV;

	base_uv.x -= floor(base_uv.x);
	base_uv.y -= floor(base_uv.y);

	base_uv.y /= float(sprite_count) / 2.0;  // / 2.0 because of how the mesh UVs are
	base_uv.y += spritesheet_index / float(sprite_count);

	//base_uv.y *= 2.0;

	vec4 albedo_w_alpha = texture(albedo_tex, base_uv);
	vec3 rough_ao_trans = vec3(1.0);//texture(rough_ao_transmission_tex, base_uv).rgb;

	// Randomised HYC Shifts of whole Albedo Tex depending on Node's Worldspace Position.
	// Separate settings for Branch or Leaf (using Transmission Tex, unfortunately Branch changes mip-bleed over into Leaf)
	// For organic randomisation: WS PosX shifts Hue, PosY shifts Chroma, PosZ shifts Luminance.
	// -> Make sure Trunk Shader/Material uses same calculation/value as branches!
	vec3 albedo_hcy = RGBtoHCY(albedo_w_alpha.rgb);
	albedo_hcy.r += mix(
		sin(NODE_POSITION_WORLD.x * 2.0 * PI * 71.33) * PI * albedo_node_rand_hue_branch,
		sin(NODE_POSITION_WORLD.x * 2.0 * PI * 62.691) * PI * albedo_node_rand_hue_leaf,
		rough_ao_trans.b);
	albedo_hcy.g += mix(
		sin(NODE_POSITION_WORLD.y * 132.935) * albedo_node_rand_chroma_branch,
		sin(NODE_POSITION_WORLD.y * 538.217) * albedo_node_rand_chroma_leaf,
		rough_ao_trans.b);
	albedo_hcy.b += mix(
		sin(NODE_POSITION_WORLD.z * 387.247) * albedo_node_rand_luma_branch,
		sin(NODE_POSITION_WORLD.z * 239.871) * albedo_node_rand_luma_leaf,
		rough_ao_trans.b);
	albedo_w_alpha.rgb = HCYtoRGB(albedo_hcy);

	ALPHA = albedo_w_alpha.a;
	ALPHA_SCISSOR_THRESHOLD = mix(0.3, 0.6, smoothstep(1500.0, 500.0, camera_distance));
	ALBEDO = albedo_w_alpha.rgb * albedo_multiply.rgb;

	METALLIC = 0.0;
	SPECULAR = 0.15;
	ROUGHNESS = 0.1 + roughness_offset;

	NORMAL_MAP = texture(normal_tex, base_uv).rgb;
	NORMAL_MAP_DEPTH = 1.0;

	AO = 0.8;
	AO_LIGHT_AFFECT = 1.0;

	vec3 overall_backlight = backlight_strength
	* backlight_tint
	* mix(vec3(0.3), albedo_w_alpha.rgb, backlight_color_from_albedo);

	BACKLIGHT = clamp(overall_backlight, 0.0, 500.0);
}
