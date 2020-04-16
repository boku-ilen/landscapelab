shader_type spatial;
render_mode cull_disabled;

uniform sampler2D texture_map : hint_albedo;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D specular_map : hint_black;

uniform sampler2D splatmap;

uniform float amplitude = 0.1;
uniform vec2 speed = vec2(2.0, 1.5);
uniform vec2 scale = vec2(0.1, 0.2);

void vertex() {
	if (VERTEX.y > 0.0) {
		vec3 worldpos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
		VERTEX.x += amplitude * sin(worldpos.x * scale.x * 0.75 + TIME * speed.x) * cos(worldpos.z * scale.x + TIME * speed.x * 0.25);
		VERTEX.z += amplitude * sin(worldpos.x * scale.y + TIME * speed.y * 0.35) * cos(worldpos.z * scale.y * 0.80 + TIME * speed.y);
	}
}

void fragment() {
	vec4 color = texture(texture_map, UV);
	ALBEDO = color.rgb;
	if (color.a < 0.3) {
		discard;
	}
	
	NORMALMAP = texture(normal_map, UV).rgb;
	
	METALLIC = 0.0;
	SPECULAR = texture(specular_map, UV).r;
	ROUGHNESS = 1.0 - SPECULAR;
	TRANSMISSION = vec3(0.2, 0.2, 0.2);
}