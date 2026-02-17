#[compute]
#version 450

// From https://github.com/BastiaanOlij/RERadialSunRays

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform restrict readonly image2D input_image;
layout(rgba16f, set = 1, binding = 0) uniform restrict writeonly image2D output_image;

// Our push PushConstant
layout(push_constant, std430) uniform Params {
    vec2 image_size;
    vec2 blur_size;
} params;

// Gaussian coefficients
const int M = 16;
const int N = 2 * M + 1;

// sigma = 10
const float coeffs[N] = float[N](
    0.012318109844189502,
    0.014381474814203989,
    0.016623532195728208,
    0.019024086115486723,
    0.02155484948872149,
    0.02417948052890078,
    0.02685404941667096,
    0.0295279624870386,
    0.03214534135442581,
    0.03464682117793548,
    0.0369716985390341,
    0.039060328279673276,
    0.040856643282313365,
    0.04231065439216247,
    0.043380781642569775,
    0.044035873841196206,
    0.04425662519949865,
    0.044035873841196206,
    0.043380781642569775,
    0.04231065439216247,
    0.040856643282313365,
    0.039060328279673276,
    0.0369716985390341,
    0.03464682117793548,
    0.03214534135442581,
    0.0295279624870386,
    0.02685404941667096,
    0.02417948052890078,
    0.02155484948872149,
    0.019024086115486723,
    0.016623532195728208,
    0.014381474814203989,
    0.012318109844189502
);

// The code we want to execute in each invocation
void main() {
    vec2 uv = vec2(gl_GlobalInvocationID.xy);

    // Just in case the effect_size size is not divisable by 8
    if ((uv.x >= params.image_size.x) || (uv.y >= params.image_size.y)) {
        return;
    }

    vec4 blurred = vec4(0.0);
    float half_size = float(M);

    for (int i = 0; i < N; i ++) {
        ivec2 uv_adj = ivec2(uv + (params.blur_size * (float(i) - half_size) / half_size));
        blurred += coeffs[i] * imageLoad(input_image, uv_adj).rgba;
    }

    imageStore(output_image, ivec2(gl_GlobalInvocationID.xy), blurred);
}
