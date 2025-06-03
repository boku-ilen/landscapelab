shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"
#include "res://Resources/Meshes/Trees/Tree_HueMix.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 albedo_multiply : source_color = vec3(1.0);

uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;

/**
* This is added to value coming from Red channel of "Rough AO Transmission Tex", to allow fast tweaking.
*/
uniform float roughness_offset : hint_range(-1.0, 1.0) = 0.0;

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
* Finally multiplies the resulting Backlight with this strength.
*/
uniform float backlight_strength : hint_range (0.0, 10.0) = 1.0;

uniform int sprite_count = 8;
varying flat float spritesheet_index;
varying flat float random_instance_factor;
varying flat float is_detailed;

varying float camera_distance;

void vertex() {
	// Increase the width as the camera gets towards the middle between the two intersecting planes
	// to compensate for the perspective decreasing the perceived size in that angle
	float normal_to_camera = abs(dot(normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xz), normalize((INV_VIEW_MATRIX * vec4(0.0, 0.0, -1.0, 0.0)).xz)));
	normal_to_camera = 1.0 - (0.5 + abs(normal_to_camera - 0.5));

	vec4 view_vertex = MODELVIEW_MATRIX * vec4(VERTEX, 0.0);
	view_vertex.x *= 1.0 + normal_to_camera;
	VERTEX = (inverse(MODELVIEW_MATRIX) * view_vertex).xyz;

	spritesheet_index = INSTANCE_CUSTOM.r;
	random_instance_factor = INSTANCE_CUSTOM.g;
	is_detailed = INSTANCE_CUSTOM.b;

	camera_distance = distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, CAMERA_POSITION_WORLD);
	
	hue_mix_to = get_hue_mix_to_values(NODE_POSITION_WORLD);
}

void fragment() {
	vec2 base_uv = UV;

	base_uv.x -= floor(base_uv.x);
	base_uv.y -= floor(base_uv.y);

	base_uv.y /= float(sprite_count) / 2.0;  // / 2.0 because of how the mesh UVs are
	base_uv.y += spritesheet_index / float(sprite_count);

	vec4 albedo_w_alpha = texture(albedo_tex, base_uv);
	vec3 rough_ao_trans = vec3(1.0);

	// Randomised HYC Shifts of whole Albedo Tex depending on Node's Worldspace Position.
	// Separate settings for Branch or Leaf (using Transmission Tex, unfortunately Branch changes mip-bleed over into Leaf)
	// For organic randomisation: WS PosX shifts Hue, PosY shifts Chroma, PosZ shifts Luminance.
	// -> Make sure Trunk Shader/Material uses same calculation/value as branches!
	vec3 albedo_hcy = RGBtoHCY(albedo_w_alpha.rgb);
	albedo_hcy.r += hue_mix_to.r;
	albedo_hcy.g += hue_mix_to.g;
	albedo_hcy.b += hue_mix_to.b;
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
