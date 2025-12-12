#[compute]
#version 450

// Adapted from https://john-chapman-graphics.blogspot.com/2013/02/pseudo-lens-flare.html

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D downsampled_image;
layout(rgba16f, set = 1, binding = 0) uniform image2D color_image;

// Our push constant
layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    vec2 reserved;
} params;

// The code we want to execute in each invocation
void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    vec4 color = imageLoad(color_image, uv);

    vec2 resolution = vec2(imageSize(color_image));

    vec2 uv_norm = uv / resolution;
    vec2 texcoord = vec2(1.0) - uv_norm;

    int uGhosts = 3;
    float uGhostDispersal = 0.3;

    vec2 ghostVec = (vec2(0.5) - texcoord) * uGhostDispersal;

    vec3 result = vec3(0.0);
    for (int i = 0; i < uGhosts; ++i) {
        vec2 offset = fract(texcoord + ghostVec * float(i));

        float weight = length(vec2(0.5) - offset) / length(vec2(0.5));
        weight = pow(1.0 - weight, 10.0);

        result += imageLoad(downsampled_image, ivec2(offset * resolution)).rgb * weight;
    }

    color.rgb += result.rgb;

    imageStore(color_image, uv, color);
}
