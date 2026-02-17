#[compute]
#version 450

// Adapted from https://chrisoat.com/papers/Oat-ScenePostprocessing.pdf

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D light_image;
layout(rgba16f, set = 1, binding = 0) uniform image2D out_image;

// Our push constant
layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    vec2 streak_direction;
    int streak_samples;
    float attenuation;
    int iteration;
} params;

// The code we want to execute in each invocation
void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    vec4 new_color = vec4(0.0, 0.0, 0.0, 1.0); //imageLoad(light_image, uv);

    float b = pow(params.streak_samples, params.iteration);

    for (int sample_num = 0; sample_num < params.streak_samples; sample_num++) {
        float weight = pow(params.attenuation, b * sample_num);

        ivec2 texture_coordinates_here = uv + ivec2(params.streak_direction * b * sample_num);

        new_color.rgb += clamp(weight, 0.0, 1.0) * imageLoad(light_image, texture_coordinates_here).rgb;
    }

    imageStore(out_image, uv, new_color);
}
