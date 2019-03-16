shader_type spatial;
render_mode cull_disabled;

uniform sampler2D distribution;
uniform sampler2D spritesheet : hint_albedo;
uniform int sprite_count;
uniform float distribution_pixels_per_meter;

uniform vec3 pos;
uniform float size;

varying flat vec3 v_obj_pos;

void vertex () {
	// Calculate the in-engine position of this object
	v_obj_pos = ((WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz - pos) / size;
}

void fragment () {
	// Material parameters
	ALPHA_SCISSOR = 0.3;
	ROUGHNESS = 0.9;
	METALLIC = 0.1;
	SPECULAR = 0.4;
	
	// Convert global position to according position on distribution map (between 0,0 and 1,1)
	vec3 obj_pos = v_obj_pos * distribution_pixels_per_meter;

	obj_pos.x = obj_pos.x - floor(obj_pos.x);
	obj_pos.z = obj_pos.z - floor(obj_pos.z);
	
	// Check the distribution for what sprite to draw here
	int sprite_at_pos = int(texture(distribution, obj_pos.xz).r * 255.0); // The distribution can be scaled by multiplying obj_pos.xz with a factor!
	
	// Calculate the columns and rows in this spritesheet
	int cols = min(sprite_count, 16);
	int rows = int(ceil(float(sprite_count) / 16.0));
	
	// Calculate the row and column of the sprite we need to draw here
	int col = (sprite_at_pos - 1) % 16;
	int row = ((sprite_at_pos - 1) / 16);
	
	// The spritesheet is square in the shader, therefore we need a multiplier in order to make each individual sprite square instead
	vec2 ratio_mult = vec2(1.0 / float(cols), 1.0 / float(rows));
	
	// Calculate the offset vector as a value between (0, 0) and (1, 1)
	vec2 offset_vec = vec2(float(col) / float(cols), float(row) / float(rows));
	
	// The color the sprite will have
	vec4 color;
	
	if (sprite_at_pos == 0) {
		color = vec4(0.0); // Nothing should be here -> 0 color and opacity
	} else {
		color = texture(spritesheet, UV * ratio_mult + offset_vec);
	}
	
	ALPHA = color.a * COLOR.a;// - clamp(1.4 - UV.y, 0.0, 1.0);//* 0.5 + 0.5*cos(2.0*TIME);
	
	ALBEDO = color.rgb;
}