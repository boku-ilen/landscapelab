#[compute]
#version 450

// Adapted from https://john-chapman-graphics.blogspot.com/2013/02/pseudo-lens-flare.html

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;
layout(rgba16f, set = 1, binding = 0) uniform image2D output_image;

// Our push constant
layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    float scale;
    float bias;
    float desaturation;
} params;

// The code we want to execute in each invocation
void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    vec4 color = imageLoad(color_image, uv);

    vec3 scale = vec3(1.0) * params.scale;
    vec3 bias = vec3(-1.0) * params.bias;

    color.rgb = max(vec3(0.0, 0.0, 0.0), color.rgb + bias) * scale;

    // Move each channel a bit towards the highest channel to desaturate while keeping darks
    float highest_color = max(color.r, max(color.g, color.b));
    color.rgb = mix(color.rgb, vec3(highest_color), vec3(params.desaturation));

    imageStore(output_image, uv, color);
}
