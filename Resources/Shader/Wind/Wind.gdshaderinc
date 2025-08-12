uniform sampler2D wind_map: hint_default_black;
uniform vec2 wind_speed = vec2(0.0, 0.0);
uniform float wind_factor = 1.0;

vec3 get_vertex_offset(vec3 vertex, mat4 model_matrix, float time) {
	vec3 vertex_offset = vec3(0.0);

	// The bend increases by the distance to the root, causing an overall bend.
	float distance_from_zero = length(vertex);
	distance_from_zero = pow(distance_from_zero, 2.0);
	
	// The bend also increases by the distance to the main stem, causing leaves to flutter around it.
	float distance_from_center = 0.2 + length(vertex.xz) * 0.8;
	// At low wind speeds, it's only the further outside branches and leaves which move, while the
	// stem remains static. At higher wind speeds, the entire tree should bend.
	distance_from_center = mix(distance_from_center, 1.0, min(length(wind_speed) * 0.01, 1.0));

	// Read the normalized wind amount in 0..1 from the texture
	float wind_amount = texture(wind_map, (model_matrix * vec4(vertex, 1.0)).xz / 512.0 - time * wind_speed / 2500.0).r;
	
	// Direction and scale of the wind: transform from model space to world space
	vec2 wind_vector = (inverse(model_matrix) * vec4(wind_speed.x, 0.0, wind_speed.y, 0.0)).xz;
	// We don't want the wind offset to scale directly proportionally to wind speed, but level off a bit.
	wind_vector = normalize(wind_vector) * sqrt(length(wind_speed) * 0.01);
	
	vec2 wind_offset_vector = wind_vector * 0.1 * wind_amount * distance_from_zero * distance_from_center * wind_factor;

	// Apply the wind and add a downwards bend to compensate for elongated polys
	vertex_offset.xz += wind_offset_vector;
	vertex_offset.y -= length(wind_offset_vector) * 0.5;

	// Larger plants move more, but not directly proportionally; the relative movement decreases by size
	vertex_offset *= sqrt(length(model_matrix[0]));

	return vertex_offset;
}