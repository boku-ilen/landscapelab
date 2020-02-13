shader_type spatial;
render_mode unshaded;

uniform sampler2D worley;
uniform sampler2D weather_map;

uniform float depth = 128.0;

// Increasing this value increases noise, but hides 3D aliasing
uniform float random_vector_offset_amount = 2000.0;

uniform float max_step_length = 5000.0;

// Raymarching steps taken for each sample. Increasing improves quality, but decreases performance
uniform int num_steps = 48;

varying vec3 offset;

// y height at which the clouds start
uniform float cloud_begin = 1500.0;

// Maximum y height at which the clouds end (usually below)
uniform float cloud_end = 10000.0;

// One step is taken towards the sun for lighting. This value changes how far away
// that step is. Should probably be left around this value, weird shadows otherwise.
uniform float sun_march_distance = 2000.0;

// Factor for how much alpha is added based on the density.
// Increasing causes clouds to have much clearer edges; decreasing causes them to be more transparent.
uniform float cloud_definition_factor = 0.0006;

// Rain absorption range which the G weather texture channel is mapped to
uniform float min_rain_absorption = 0.5;
uniform float max_rain_absorption = 4.3;

// Density range which the R weather texture channel is mapped to
uniform float min_density = 0.1;
uniform float max_density = 0.9;

// Worley noise scale range which the B weather texture channel is mapped to
uniform float min_scale = 0.00002;
uniform float max_scale = 0.00006;

// Factor for simulating light scattering. Should be left around this value for forward scattering.
uniform float eccentricity = 0.1;

uniform float earth_radius = 6370000.0f;
uniform float lowest_march_limit = -5000.0;

uniform float sun_energy = 1.0;
uniform vec3 sun_direction = vec3(0.0, -0.5, 0.5);

// Get the value by which vertex at given point must be lowered to simulate the earth's curvature 
float get_curve_offset(float distance_squared, float radius) {
	return sqrt(radius * radius + distance_squared) - radius;
}

// Adapted from https://github.com/BastiaanOlij/godot-worley-shader/blob/master/raymarch.shader
vec4 texture3d(sampler2D p_texture, vec3 p_uvw, float scale) {
	p_uvw *= scale;
	vec3 mod_uvw = mod(p_uvw + offset, 1.0);
	
	float fd = mod_uvw.z * depth;
	float fz = floor(fd);
	
	vec2 uv1 = vec2(mod_uvw.x, (mod_uvw.y + fz) / depth);
	vec2 uv2 = vec2(mod_uvw.x, mod((mod_uvw.y + fz + 1.0) / depth, 1.0));
	
	vec4 col1 = texture(p_texture, uv1);
	vec4 col2 = texture(p_texture, uv2);
	
	return mix(col1, col2, fd - fz);
}

float cloud_density(vec3 p_pos, float scale) {
	vec4 density_in_texture = texture3d(worley, p_pos, scale);
	
	// join our octaves
	float value = density_in_texture.r + (0.5 * density_in_texture.g) + (0.25 * density_in_texture.b);
	
	// inverse and clamp
	value = clamp(1.0 - value, 0.0, 1.0);
	
	return value;
}

// Adapted from https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code
// Returns the 3-dimensional point of intersection and the distance from the ray origin to there in the 4th dimension
// Returns a 0 vector when no hit occured
vec4 ray_sphere_intersect(vec3 ray_origin, vec3 ray_direction, vec3 sphere_origin, float sphere_radius) {
	vec3 m = ray_origin - sphere_origin; 
	float b = dot(m, ray_direction); 
	float c = dot(m, m) - sphere_radius * sphere_radius; 
	
	// Exit if r’s origin outside s (c > 0) and r pointing away from s (b > 0) 
	if (c > 0.0f && b > 0.0f) return vec4(0.0); 
	float discr = b*b - c; 
	
	// A negative discriminant corresponds to ray missing sphere 
	if (discr < 0.0f) return vec4(0.0); 
	
	// Ray now found to intersect sphere, compute smallest t value of intersection
	float t1 = -b - sqrt(discr);
	float t2 = -b + sqrt(discr); 
	
	if (t1 < 0.0 && t2 < 0.0) {return vec4(0.0);}
	float t = t1;
	
	if (t1 < t2 && t1 > 0.0) {
		t = t1;
	} else {
		t = t2;
	}
	
	// If t is negative, ray started inside sphere so clamp t to zero
	if (t < 0.0) {return vec4(0.0);}
	vec3 q = ray_origin + t * ray_direction; 
	
	return vec4(q, t);
}

// Returns a random value for a given coefficient.
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float get_light_energy(float density, float rain_absorption) {
	return 2.0 * exp(-density * rain_absorption) * (1.0 - exp(-2.0 * density));
}

float henyey_greenstein(float cos_light_view_angle) {
	return ( ( 1.0 - eccentricity * eccentricity ) / pow ( ( 1.0 + eccentricity * eccentricity - 2.0 * eccentricity * cos_light_view_angle ), 3.0 / 2.0) ) / 4.0 * 3.1415;
}

void vertex() {
	// Cover the viewport with the mesh
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	// Calculate the depth (the value from DEPTH_TEXTURE isn't linear!)
	float screen_depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, screen_depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	// Calculate the maximum depth (the far clip plane)
	vec4 max_depth_view = (INV_PROJECTION_MATRIX * vec4(1.0));
	max_depth_view.xyz /= max_depth_view.w;
	float max_depth = -max_depth_view.z;

	// Get the camera position (the translation)
	vec3 camera_position = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0f)).xyz;
	
	// Calculate the direction using the camera projection matrix and the UV coordinates
	// Without taking the UV coordinates into account, this would be an orthogonal camera
	vec2 centered_uv = vec2(UV.x - 0.5, -UV.y + 0.5) * 2.0f;
	vec3 direction = (INV_PROJECTION_MATRIX * vec4(centered_uv, 0.0, 1.0)).xyz;
	direction = normalize((CAMERA_MATRIX * vec4(direction, 0.0)).xyz);
	
	// The cloud layer is spherical, so we check where our ray intersects with the outer limit sphere and the inner limit sphere
	vec3 earth_center = vec3(camera_position.x, -earth_radius, camera_position.z);
	
	vec4 march_start = ray_sphere_intersect(camera_position, direction, earth_center, earth_radius + cloud_begin);
	vec4 march_end = ray_sphere_intersect(camera_position, direction, earth_center, earth_radius + cloud_end);
	
	// If we didn't intersect with any sphere, we're above the clouds, looking into space
	if (march_start == vec4(0.0) && march_end == vec4(0.0)) {return;}
	
	// march_start and march_end are only correct if we're below the clouds. If we're inside or above the clouds,
	//  things get a bit more complicated:
	if (camera_position.y > cloud_begin) {
		if (camera_position.y > cloud_end) {
			// Above the clouds
			if (march_start == vec4(0.0)) {
				// We only intersected with the outer sphere - most likely twice. We could get the second intersection
				//  point, but we just use a fixed distance for marching here for simplicity.
				march_start = march_end + vec4(direction, 0.0) * 10000.0;
			}
			// Since we're above the clouds, the intersection with the other sphere is actually our starting point,
			//  so swap start and end!
			vec4 buffer = march_start;
			march_start = march_end;
			march_end = buffer;
		} else {
			// Inside the clouds
			if (march_start != vec4(0.0)) {
				// If we did intersect with the inner sphere, that should be our end point (we're looking downwards)
				march_end = march_start;
			}
			
			// If we're inside the clouds, there could be one right in front of us, so our camera position is
			//  our starting point
			march_start = vec4(camera_position, 0.0);
		}
	}
	
	// If the clouds begin further away than the closest other object, we can stop
	if (linear_depth < max_depth && march_start.w >= linear_depth) {
		return;
	}
	
	// Something like this for temporal AA:
	march_start -= vec4(direction, 0.0) * rand(direction.xz * TIME) * random_vector_offset_amount;
	
	// Choose the step length so that we always march from march_start to march_end, with our constant num_steps.
	// However, we do limit this step_length because extremely large steps only cause artifacts.
	float step_length = min(length(march_end.xyz - march_start.xyz) / float(num_steps), max_step_length);
	
	vec3 projected_sun_direction = normalize((vec4(-sun_direction, 0.0)).xyz);
	
	// March forward
	float distance_to_camera = 0.0f;
	vec3 cloud_color = vec3(0.0);
	float light_energy = 0.0;
	float transmittance = 1.0;
	float cloud_alpha = 0.0f;
	
	for (int i = 0; i < num_steps; i++) {
		// If we're already fully opaque, there's no point in continuing
		if (cloud_alpha > 0.99) {
			cloud_alpha = 1.0;
			break;
		}
		
		// Calculate the position of the current sample point
		vec3 position = march_start.xyz + distance_to_camera * direction;
		
		// Get the weather map value at this position
		vec3 weather = texture(weather_map, position.xz * 0.00001).xyz;
		
		float density_cutoff = mix(min_density, max_density, 1.0 - weather.x);
		float rain_absorption = mix(min_rain_absorption, max_rain_absorption, weather.y);
		float worley_uv_scale = mix(min_scale, max_scale, weather.z);
		
		// Step forward (for the next iteration)
		distance_to_camera += step_length;
		
		// We don't need to render clouds on the other side of the earth, so if we're too far down, we stop
		if (position.y < lowest_march_limit) {break;}
		
		float distance_to_center = length(earth_center - position);
		
		// Calculate the cloud density - we mix two textures, scaled and offset by time, to get some dynamics
		float density = cloud_density(position + vec3(TIME * 50.0), worley_uv_scale);
		
		if (density > 0.0) {
			// Calculate how far we're in the layer from 0 (start of clouds, closer to earth) to 1 (end of clouds) 
			float distance_within_cloudlayer = (distance_to_center - earth_radius - cloud_begin) / (cloud_end - cloud_begin);
			
			// We give clouds a more cloudy shape by applying a vertical cosine to the density
			// This causes the typical flat bottom of cumulus clouds
			density = density * (1.0 + -cos((distance_within_cloudlayer * 4.2831853 + 2.8))) / 2.0;
			
			// We use a density cutoff to have some areas with clear sky
			if (density > density_cutoff
				// TODO: Very ugly testing stuff
				// Basically we want the edges of the cloud to fade out nicely, so we check another scaled texture at the border
				// The time scaled differently makes these edges fade around nicely
				|| density > density_cutoff - cloud_density(position * 10.0 + vec3(TIME * 100.0) * 10.0, worley_uv_scale) * 0.11) {
				// March towards the sun
				
				if (!(density > density_cutoff)) {
					// Add the faded edges again (INEFFICIENT)
					density -= cloud_density(position * 10.0 + vec3(TIME * 100.0) * 10.0, worley_uv_scale) * 0.05;
				}
				
				vec3 sun_march_position = position + sun_march_distance * projected_sun_direction;
				float light_density = cloud_density(sun_march_position + vec3(TIME * 50.0), worley_uv_scale);
				float light_transmittance = get_light_energy(light_density, rain_absorption);
				
				float cos_light_view_angle = dot(direction, projected_sun_direction);
				light_transmittance *= henyey_greenstein(cos_light_view_angle);
				
				light_energy += density * transmittance * light_transmittance * 3.0 * sun_energy;
				
				transmittance *= exp(-density * 0.5) * 0.3; // Changes how much of the cloud is white
			
				cloud_alpha += density * cloud_definition_factor * step_length;
			}
			
		}
	}
	
	if (light_energy > 1.0) { light_energy = 1.0; }
	if (cloud_alpha > 1.0) { cloud_alpha = 1.0; }
	
	// TODO: This would be physically correct, but it doesn't look good...
	//  cloud_alpha = 1.0 - transmittance;
	cloud_color = vec3(light_energy + transmittance);
	
	// Apply our color and alpha
	ALBEDO = cloud_color;
	ALPHA = cloud_alpha;
}