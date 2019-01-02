shader_type spatial;
render_mode unshaded, skip_vertex_transform;

uniform sampler2D albedo_texture : hint_albedo;
uniform float depth = 128.0;
uniform vec3 light_dir = vec3(0.0, 1.0, -1.0);

uniform float cloud_density_factor = 5.0;
uniform float cloud_steps = 128.0;

uniform float light_density_factor = 5.0;
uniform float light_steps = 32.0;

uniform float cube_extent = 10000.0; // half width/height of the cube which this is rendered in
uniform float step_constant = 50000.0; // used for calculating the step length of one raymarch iteration - lower means better visuals, but more performance draw (very GPU-heavy!)
uniform float uv_scale = 0.0002; // Scale of the texture (worley)

uniform vec3 player_uv_offset = vec3(0.0, 0.0, 0.0);

varying vec3 pos;
varying vec3 dir;
varying vec3 ldir;
varying vec3 offset;

vec4 texture3d(sampler2D p_texture, vec3 p_uvw) {
	vec3 mod_uvw = mod(p_uvw + offset + player_uv_offset / cube_extent, 1.0);
	
	float fd = mod_uvw.z * depth;
	float fz = floor(fd);
	
	vec2 uv1 = vec2(mod_uvw.x, (mod_uvw.y + fz) / depth);
	vec2 uv2 = vec2(mod_uvw.x, mod((mod_uvw.y + fz + 1.0) / depth, 1.0));
	
	vec4 col1 = texture(p_texture, uv1);
	vec4 col2 = texture(p_texture, uv2);
	
	return mix(col1, col2, fd - fz);
}

void vertex() {
	// get our pos on the surface of our mesh in model space
	pos = VERTEX;
	
	// make our vertex position
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// get our direction for our raymarch
	dir = (inverse(MODELVIEW_MATRIX) * vec4(normalize(VERTEX), 0.0)).xyz;
	
	// and our light dir
	ldir = (inverse(WORLD_MATRIX) * vec4(normalize(light_dir),0.0)).xyz;
	
	// wind..
	offset = vec3(TIME*0.01, 0.0, TIME*0.02);
}

float cloud_density(vec3 p_pos) {
	vec4 worley = texture3d(albedo_texture, p_pos * uv_scale);
	
	// join our octaves
	float value = worley.r + (0.5 * worley.g) + (0.25 * worley.b);
	
	// inverse and clamp
	value = clamp(1.0 - value, 0.0, 1.0);
	
	return value;
}

float light_density(vec3 p_pos) {
	float ld = 0.0;
	float lf = light_density_factor / light_steps;
	
	vec3 p = p_pos;
	vec3 d = step_constant * normalize(ldir) / light_steps;
	for(int i = 0; i < int(light_steps); i++) {
		ld += cloud_density(p * 0.5) * lf;
		
		// move towards the light...
		p = p + d;
		
		// still within our cube?
		if (p.x < -cube_extent || p.x > cube_extent || p.y < -cube_extent || p.y > cube_extent || p.z < -cube_extent || p.z > cube_extent) {
			break;
		}
	}
	
	return ld;
}

void fragment() {
	vec3 color = vec3(0.0, 0.0, 0.0);
	float alpha = 0.0;
	float transmittance = 1.0;
	float cdf = cloud_density_factor / cloud_steps;
	
	// lets raymarch...
	vec3 p = pos;
	vec3 d = step_constant * normalize(dir) / cloud_steps;
	for(int i = 0; i < int(cloud_steps); i++) {
		float density = clamp(cloud_density(p * 0.5), 0.0, 1.0) * cdf;
		
		if (density > 0.001) {
			float ld = light_density(p);
			
			// update our colour
			float ld_exp = exp(-ld);
			color += vec3(ld_exp, ld_exp, ld_exp) * density * transmittance;
			
			// Add to our alpha
			alpha += density;
			transmittance *= 1.0 - density;
		
			// reached the end?
			if (alpha > 1.0) {
				alpha = 1.0;
				break;
			}
		}
		
		// move through our cube
		p = p + d;
		
		// still within our cube?
		if (p.x < -cube_extent || p.x > cube_extent || p.y < -cube_extent || p.y > cube_extent || p.z < -cube_extent || p.z > cube_extent) {
			break;
		}
	}
	
	if (alpha > 0.01) {
		// alpha will be applied to our color so reverse apply it
		color = color / alpha;
	}
	
	ALBEDO = clamp(color, 0.0, 1.0);
	ALPHA = alpha;
}