#[compute]
#version 450

// Adapted from https://john-chapman-graphics.blogspot.com/2013/02/pseudo-lens-flare.html

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D downsampled_image;
layout(rgba16f, set = 1, binding = 0) uniform image2D color_image;
layout(set = 2, binding = 0) uniform sampler2D lens_color_ramp;

// Our push constant
layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    int ghost_count;
    float ghost_dispersal;
    float ca_scale;
    float halo_width;
    float halo_weight_power;
} params;

vec3 imageDistorted(
    in ivec2 texcoord,
    in vec2 direction, // direction of distortion
    in vec3 distortion // per-channel distortion factor
) {
    return vec3(
        imageLoad(downsampled_image, texcoord + ivec2(direction * distortion.r)).r,
        imageLoad(downsampled_image, texcoord + ivec2(direction * distortion.g)).g,
        imageLoad(downsampled_image, texcoord + ivec2(direction * distortion.b)).b
    );
}

// The code we want to execute in each invocation
void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

    vec2 resolution = params.raster_size;

    vec2 texelSize = 1.0 / vec2(resolution);

    vec2 uv_norm = uv / resolution;
    vec2 texcoord = vec2(1.0) - uv_norm;

    vec2 ghost_vec = (vec2(0.5) - texcoord) * params.ghost_dispersal;

    vec3 distortion = vec3(-1.0, 0.0, 1.0) * params.ca_scale;
    vec2 direction = normalize(ghost_vec);

    vec3 result = vec3(0.0);
    for (int i = 0; i < params.ghost_count; ++i) {
        vec2 offset = fract(texcoord + ghost_vec * float(i));

        float weight = length(vec2(0.5) - offset) / length(vec2(0.5));
        weight = pow(1.0 - weight, 2.0);

        result += imageDistorted(ivec2(offset * resolution), direction, distortion).rgb * (1.0 / weight);
    }

    // sample halo:
    vec2 haloVec = normalize(ghost_vec) * params.halo_width;
    float weight = length(vec2(0.5) - fract(texcoord + haloVec)) / length(vec2(0.5));
    weight = pow(1.0 - weight, params.halo_weight_power);
    result += imageDistorted(ivec2((texcoord + haloVec) * resolution), direction, distortion).rgb * weight;

    result *= texture(lens_color_ramp, vec2((length(vec2(0.5) - texcoord) / length(vec2(0.5))), 0.0)).rgb;

    color.rgb = result.rgb;

    imageStore(color_image, uv, color);
}
