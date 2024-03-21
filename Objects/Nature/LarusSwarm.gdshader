shader_type particles;

uniform float radius = 10.0;
uniform sampler2D directions: repeat_disable;

uniform float texture_weight = 40.0;
uniform float random_weight = 30.0; // should be smaller than texture_weight to prevent overriding
uniform float total_weight = 20.0;
uniform float time_scale = 2.0;
uniform float y_scatter_factor = 200.0;

uniform float max_velocity = 10.0;
uniform float random_direction_weight = 1.0;
uniform float center_pull_weight = 0.01;
uniform float y_center_pull_weight = 10.0;

float rand_from_seed(in uint seed) {
  int k;
  int s = int(seed);
  if (s == 0)
    s = 305420679;
  k = s / 127773;
  s = 16807 * (s - k * 127773) - 2836 * k;
  if (s < 0)
    s += 2147483647;
  seed = uint(s);
  return float(seed % uint(65536)) / 65535.0;
}

uint hash(uint x) {
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = (x >> uint(16)) ^ x;
  return x;
}

void start() {
	uint alt_seed1 = hash(NUMBER + uint(1) + RANDOM_SEED);
	uint alt_seed2 = hash(NUMBER + uint(27) + RANDOM_SEED);
	uint alt_seed3 = hash(NUMBER + uint(43) + RANDOM_SEED);
	uint alt_seed4 = hash(NUMBER + uint(111) + RANDOM_SEED);

	CUSTOM.x = rand_from_seed(alt_seed1);
	vec3 position = vec3(rand_from_seed(alt_seed2) * 2.0 - 1.0,
	                     0.0,//rand_from_seed(alt_seed3) * 2.0 - 1.0,
	                     rand_from_seed(alt_seed4) * 2.0 - 1.0);
	
	TRANSFORM[3].xyz = EMISSION_TRANSFORM[3].xyz + position * radius;

	// Initial velocity
	vec3 addition = vec3(rand_from_seed(alt_seed2) * 2.0 - 1.0,
	                     rand_from_seed(alt_seed3) * 2.0 - 1.0,
	                     rand_from_seed(alt_seed4) * 2.0 - 1.0);

	addition.y *= 0.5;
	
	VELOCITY = addition * 10.0;
}

void process() {
	CUSTOM.z += DELTA;
	
	vec3 texture_coords = TRANSFORM[3].xyz;
	texture_coords.xyz -= EMISSION_TRANSFORM[3].xyz;
	
	vec2 texture_uv = ((texture_coords + vec3(radius)) / (radius * 2.0)).xz;
	
	// TODO: If texture_uv is larger than 1 or smaller than 0, increase the texture weight so that
	// the particles tend towards staying in the texture
	
	COLOR = vec4(texture_uv, 0.0, 1.0) * 1.0;
	
	vec3 texture_sample = texture(directions, texture_uv).xyz - vec3(0.5);
	
	uint alt_seed1 = hash(NUMBER + uint(1) + RANDOM_SEED + uint(TIME * 0.1 + rand_from_seed(hash(INDEX)) * PI));
	uint alt_seed2 = hash(NUMBER + uint(27) + RANDOM_SEED + uint(TIME * time_scale));
	uint alt_seed3 = hash(NUMBER + uint(43) + RANDOM_SEED + uint(TIME * time_scale));
	uint alt_seed4 = hash(NUMBER + uint(111) + RANDOM_SEED + uint(TIME * time_scale));

	vec3 addition = vec3(rand_from_seed(alt_seed2) * 2.0 - 1.0,
	                     rand_from_seed(alt_seed3) * 2.0 - 1.0,
	                     rand_from_seed(alt_seed4) * 2.0 - 1.0);
	
	vec3 to_center = EMISSION_TRANSFORM[3].xyz - TRANSFORM[3].xyz;
	to_center.y *= y_center_pull_weight; // birds want to get to their default altitude much more than they want to get to the center
	
	vec3 velocity_addition = addition * random_direction_weight * DELTA + to_center * center_pull_weight * rand_from_seed(alt_seed1) * DELTA;

	VELOCITY += velocity_addition;
	
	VELOCITY = clamp(VELOCITY, vec3(-max_velocity, -max_velocity / 2.0, -max_velocity), vec3(max_velocity, max_velocity / 2.0, max_velocity));
	
	TRANSFORM[2].xyz = -normalize(VELOCITY);
	TRANSFORM[0].xyz = -normalize(cross(vec3(0.0, 1.0, 0.0), TRANSFORM[2].xyz));
	TRANSFORM[1].xyz = cross(TRANSFORM[0].xyz, TRANSFORM[2].xyz);
	
	CUSTOM.y = VELOCITY.y;
}
