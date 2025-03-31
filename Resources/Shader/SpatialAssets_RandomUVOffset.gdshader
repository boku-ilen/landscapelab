// Randomly offsets UVs depending on World Pos of Node, to create more variation in repeated assets (e.g. Fences)
// Offset amount along U and/or V controlled separately via Max UV Offset.
// Can use tiny UVOffsetMask Tex to only affect certain UV areas (0 = no Offset, 1 = use Max UV Offset), otherwise all affected.
// AO channel is NOT affected by offset, so only bake things in there that are "static"!

shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec2 max_uv_offset = vec2(1.0, 1.0);
uniform sampler2D uv_offsetmask_tex : hint_default_white;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength : hint_range(-16.0, 16.0) = 1.0;
uniform sampler2D metal_rough_ao_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float ao_strength : hint_range (0.0, 10.0) = 1.0;


void fragment() {
	vec2 uv_offsetamount = fract((NODE_POSITION_WORLD.x + NODE_POSITION_WORLD.z) * 100.0) * max_uv_offset;
	float uv_offsetmask = texture(uv_offsetmask_tex, UV).r;
	vec2 uv_manipulated = mix(UV, UV + uv_offsetamount, uv_offsetmask);
	
	ALBEDO = texture(albedo_tex, UV).rgb;
	ALBEDO = texture(albedo_tex, uv_manipulated).rgb;
	METALLIC = texture(metal_rough_ao_tex, uv_manipulated).r;
	SPECULAR = 0.5;
	ROUGHNESS = texture(metal_rough_ao_tex, uv_manipulated).g;
	NORMAL_MAP = texture(normal_tex, uv_manipulated).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	AO = mix(1.0, texture(metal_rough_ao_tex, UV).b, ao_strength); // AO uses the original UVs!
}