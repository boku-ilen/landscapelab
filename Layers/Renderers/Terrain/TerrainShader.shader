shader_type spatial;

// Basic Terrain
uniform sampler2D orthophoto: hint_albedo;
uniform sampler2D heightmap;
uniform float height_scale = 1.0;

// Surface heights
uniform bool has_surface_heights = false;
uniform float surface_heights_start_distance = 800.0;
uniform sampler2D surface_heightmap;

// Land use-based detail textures
uniform sampler2D albedo_tex: hint_albedo;
uniform sampler2D normal_tex: hint_normal;
uniform sampler2D ambient_tex;
uniform sampler2D specular_tex;
uniform sampler2D roughness_tex;
uniform sampler2D ao_tex;

uniform float size_m;
uniform float texture_size_m;

uniform float normal_scale = 1.0;

// Increase or decrease texture values in the range 0..1
uniform bool is_roughness_increase;
uniform float roughness_scale = 0.0;

uniform bool is_specular_increase;
uniform float specular_scale = 0.0;

uniform bool is_ao_increase;
uniform float ao_scale = 0.0;

uniform bool has_distance_tex = false;
uniform sampler2D distance_tex: hint_albedo;
uniform sampler2D distance_normals: hint_normal;
uniform float distance_tex_start;
uniform float distance_texture_size_m;

varying vec3 camera_pos;
varying vec3 world_pos;

void vertex() {
	world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	VERTEX.y = texture(heightmap, UV).r * height_scale;
	
	if (has_surface_heights) {
		float surface_height_factor = float(length(world_pos.xz) > surface_heights_start_distance);
		VERTEX.y += texture(surface_heightmap, UV).r * height_scale * surface_height_factor
	}
}

void fragment() {
	ALBEDO = texture(orthophoto, UV).rgb;
}