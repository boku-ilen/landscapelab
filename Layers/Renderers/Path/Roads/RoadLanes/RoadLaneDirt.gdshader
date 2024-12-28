shader_type spatial;
render_mode unshaded;

#include "res://Layers/Renderers/Path/Roads/RoadLanes/RoadLane.gdshaderinc"

uniform vec3 lid_color;
uniform float banquet_width = 0.0;

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


void vertex() {
	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		VERTEX += NORMAL * banquet_width;
	}

	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

void fragment() {
	float depth = (1.0 - FRAGCOORD.z) / FRAGCOORD.w;

	if (((int(CAMERA_VISIBLE_LAYERS) & int(pow(2, 16))) == int(pow(2, 16)))) {
		ALBEDO = lid_color;
		ALPHA = 1.0;
	} else {
		vec3 color = fractal_texture(road_texture, WORLD_UV.xz, depth).rgb;

		// Map UV to the upper face of the polygon
		vec2 uv = UV * 8.0 * width;

		ALBEDO = min(color, vec3(1.0,1.0, 1.0));
		ALPHA = smoothstep(0, width / 3.0, uv.y) - smoothstep(width / 3.0, 0, width - uv.y);
	}
}
