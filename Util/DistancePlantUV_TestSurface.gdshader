shader_type spatial;

uniform sampler2D uv_offset;
uniform sampler2D uv_normals;
uniform sampler2D plant: source_color;

// Adapted from https://www.shadertoy.com/view/mds3R4
vec4 fractal_texture(sampler2D tex, vec2 uv, float depth) {
	uv.xy *= 2.0;

	float clamped_depth = max(depth, 10.0);

    //Find the pixel level of detail
	float LOD = log(clamped_depth);
    //Round LOD down
	float LOD_floor = floor(LOD);
    //Compute the fract part for interpolating
	float LOD_fract = LOD - LOD_floor;

    //Compute scaled uvs
	vec2 uv1 = uv.xy / exp(LOD_floor - 1.0);
	vec2 uv2 = uv.xy / exp(LOD_floor + 0.0);
	vec2 uv3 = uv.xy / exp(LOD_floor + 1.0);

    //Sample at 3 scales
	vec4 tex0 = texture(tex, uv1);
	vec4 tex1 = texture(tex, uv2);
	vec4 tex2 = texture(tex, uv3);

    // Blend samples together
	// Blend fully towards tex1 at close distances in order to have a clear detail view
	return mix(tex1, mix(tex0, tex2, clamp(LOD_fract, 0.0, 1.0)), min(depth / 20.0, 0.5));
}

void fragment() {
	float depth = (1.0 - FRAGCOORD.z) / FRAGCOORD.w;

	vec2 uv = texture(uv_offset, UV).rg;

	float bias = 1.0;

	vec4 plant_sample = texture(plant, uv);

	//if (plant_sample.a < 0.5) {
		//plant_sample = texture(plant, uv - vec2(0.4, 0.4), bias);
	//}
	//if (plant_sample.a < 0.5) {
		//plant_sample = texture(plant, uv - vec2(0.6, 0.6), bias);
	//}
	//if (plant_sample.a < 0.5) {
		//plant_sample = texture(plant, uv - vec2(0.8, 0.8), bias);
	//}
	ALBEDO = plant_sample.rgb * 1.5;
	//ALPHA = plant_sample.a;
	//ALPHA_SCISSOR_THRESHOLD = 0.5 - (depth * 0.01);

	vec3 normal = texture(uv_normals, UV).rgb;
	//normal.g = 1.0 - normal.g;

	NORMAL_MAP = normal;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
