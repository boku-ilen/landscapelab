shader_type spatial;
render_mode cull_disabled;

uniform sampler2D distribution;
uniform sampler2D spritesheet : hint_albedo;
uniform int sprite_count;
uniform float distribution_pixels_per_meter;

uniform float base_light = 0.5;  // Base value which vegetation is lit by any light, regardless of diretion
uniform float light_factor = 2.0;  // Changes how much of an effect lighting has
uniform float opacity_cutoff = 0.9;  // Opacity starts decreasing at uv.y > opacity_cutoff
uniform float max_opacity_cutoff_scale = 1.0;  // Maximum scale (in meters) of plants where the opacity cutoff occurs

uniform vec3 pos;
uniform float size;
uniform float scale;

varying flat vec3 v_obj_pos;

void vertex () {
	// Calculate the in-engine position of this object
	v_obj_pos = ((WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz - pos);
}

void light() {
	// Vegetation lets a lot of light through and thus shouldn't really be dark on the back.
	// That's why every light adds a base value, regardless of direction.
	float custom_light = base_light + dot(NORMAL, LIGHT) * (1.0 - base_light);
	
	DIFFUSE_LIGHT += light_factor * custom_light * ATTENUATION * ALBEDO;
}

void fragment () {
	// Material parameters
	ROUGHNESS = 0.95;
	METALLIC = 0.1;

	// Convert global position to according position on distribution map (between 0,0 and 1,1)
	vec3 obj_pos = v_obj_pos / 20.0;

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
		vec2 uv = UV * ratio_mult + offset_vec;
		color = texture(spritesheet, uv);
		
		// Decrease the opacity further down the sprite if it's a small plant to prevent a harsh color
		//  difference between it and the ground, causing it to instead blend in more
		if ((scale <= max_opacity_cutoff_scale) && (uv.y >= opacity_cutoff)) {
			// Opacity factor will be between 0.0 (when uv.y == opaxity_cutoff) and 1.0 (when uv.y == 1.0)
			float opacity_factor = 1.0 - (1.0 - (uv.y)) / (1.0 - opacity_cutoff);
			color.a -= opacity_factor;
			
			// Clamp the opacity to 0
			color.a = max(0, color.a);
		}
	}
	
	ALPHA = color.a;// - clamp(1.4 - UV.y, 0.0, 1.0);//* 0.5 + 0.5*cos(2.0*TIME);
	ALPHA_SCISSOR = 0.8;
	
	ALBEDO = color.rgb;
}