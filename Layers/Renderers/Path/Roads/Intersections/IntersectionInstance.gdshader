shader_type spatial;
render_mode unshaded;

uniform sampler2D intersection_texture: source_color;
uniform float world_uv_scaling = 0.35;
varying vec3 WORLD_UV;

void vertex() {
	WORLD_UV = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * world_uv_scaling;
}

void fragment() {
	vec3 color = texture(intersection_texture, WORLD_UV.xz).rgb;
	ALBEDO = min(color, vec3(1.0,1.0, 1.0));
}
