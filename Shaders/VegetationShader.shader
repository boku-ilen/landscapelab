shader_type spatial;
render_mode cull_disabled;

uniform sampler2D density_map;

uniform sampler2D sprite1;
uniform sampler2D sprite2;
uniform sampler2D sprite3;
uniform sampler2D sprite4;
uniform sampler2D sprite5;
uniform sampler2D sprite6;

uniform vec3 pos;
uniform float size;

varying vec3 v_obj_pos;

void vertex () {
	v_obj_pos = ((WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz - pos) / size;
}

void fragment () {
	ALPHA_SCISSOR = 0.1;
	ROUGHNESS = 0.9;
	
	vec3 obj_pos = v_obj_pos;

	obj_pos.x = obj_pos.x - floor(obj_pos.x);
	obj_pos.z = obj_pos.z - floor(obj_pos.z);
	
	float density_at_pos = texture(density_map, obj_pos.xz).b;
	vec4 col;
	
	if (density_at_pos < 1.0/6.0) {
		col = texture(sprite1, UV);
	} else if (density_at_pos < 2.0/6.0) {
		col = texture(sprite2, UV);
	} else if (density_at_pos < 3.0/6.0) {
		col = texture(sprite3, UV);
	} else if (density_at_pos < 4.0/6.0) {
		col = texture(sprite4, UV);
	} else if (density_at_pos < 5.0/6.0) {
		col = texture(sprite5, UV);
	} else {
		col = texture(sprite6, UV);
	}
	
	ALPHA = col.a * COLOR.a;// - clamp(1.4 - UV.y, 0.0, 1.0);//* 0.5 + 0.5*cos(2.0*TIME);
	
	ALBEDO = col.rgb;
}