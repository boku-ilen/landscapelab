#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D overlay_image;
layout(rgba16f, set = 1, binding = 0) uniform image2D color_image;
layout(set = 2, binding = 0) uniform sampler2D dirt_texture;

// Our push PushConstant
layout(push_constant, std430) uniform Params {
    vec2 render_size;
    float res;
    float dirt_power;
} params;

// The code we want to execute in each invocation
void main() {
    ivec2 render_size = ivec2(params.render_size.xy);

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    // Just in case the render_size size is not divisable by 8
    if ((uv.x >= render_size.x) || (uv.y >= render_size.y)) {
        return;
    }

    float dirt = texture(dirt_texture, vec2(uv) / vec2(render_size)).r;

    vec4 color = imageLoad(color_image, uv);
    vec4 overlay = imageLoad(overlay_image, uv) * mix(1.0, dirt, params.dirt_power);

    color += overlay;

    imageStore(color_image, uv, color);
}
