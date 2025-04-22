shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

uniform vec2 tex_tiling = vec2(1.0, 1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 albedo_multiply : source_color = vec3(1.0);
uniform float albedo_node_rand_hue : hint_range(0.0, 1.0) = 0.03;
uniform float albedo_node_rand_chroma : hint_range(0.0, 1.0) = 0.04;
uniform float albedo_node_rand_luma : hint_range(0.0, 1.0) = 0.05;

uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength : hint_range(-16.0, 16.0) = 1.0;

/**
* R: Roughness
* G: Ambient Occlusion
* B: Transmission: NOT USED IN THIS SHADER
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

uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;

/**
* [b]0[/b]: Uses Light's color.
* [b]1[/b]: Uses color from Albedo Tex - which makes effect less visible! Might need to increase "Rim Strength"!
* Should use medium value.
*/
uniform float rim_color_from_albedo : hint_range(0.0, 1.0) = 0.5;


void vertex() {
}

void fragment() {
	vec2 base_uv = UV * tex_tiling;
	
	vec3 albedo_rgb = texture(albedo_tex, base_uv).rgb;
	vec3 rough_ao_trans = texture(rough_ao_transmission_tex, base_uv).rgb;
	
	// Randomised HYC Shifts of whole Albedo Tex depending on Node's Worldspace Position.
	// For organic randomisation: WS PosX shifts Hue, PosY shifts Chroma, PosZ shifts Luminance.
	// Make sure LeafBranches Shader/Mats uses same calculation/values as Trunk ones!
	vec3 albedo_hcy = RGBtoHCY(albedo_rgb);
	albedo_hcy.r += sin(NODE_POSITION_WORLD.x * 2.0 * PI * 71.33) * PI * albedo_node_rand_hue;
	albedo_hcy.g += sin(NODE_POSITION_WORLD.y * 132.935) * albedo_node_rand_chroma;
	albedo_hcy.b += sin(NODE_POSITION_WORLD.z * 387.247) * albedo_node_rand_luma;
	
	albedo_rgb = HCYtoRGB(albedo_hcy);
	
	ALBEDO = albedo_rgb * albedo_multiply;
	
	METALLIC = 0.0;
	SPECULAR = 0.5;
	ROUGHNESS = rough_ao_trans.r + roughness_offset;
	
	NORMAL_MAP = texture(normal_tex, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	
	AO = mix(1.0, rough_ao_trans.g, ao_strength);
	AO_LIGHT_AFFECT = ao_light_affect;
	
	RIM = rim_strength;
	RIM_TINT = rim_color_from_albedo;
}