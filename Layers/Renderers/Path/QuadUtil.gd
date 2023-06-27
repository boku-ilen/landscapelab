class_name QuadUtil


# Returns the weights for a triangular interpolation using barycentric coordinates
static func triangular_interpolation(P: Vector3, A: Vector3, B: Vector3, C: Vector3) -> Vector3:
	var W1 = ((B.z - C.z) * (P.x - C.x) + (C.x - B.x) * (P.z - C.z)) / ((B.z - C.z) * (A.x - C.x) + (C.x - B.x) * (A.z - C.z))
	var W2 = ((C.z - A.z) * (P.x - C.x) + (A.x - C.x) * (P.z - C.z)) / ((B.z - C.z) * (A.x - C.x) + (C.x - B.x) * (A.z - C.z))
	var W3 = 1 - W1 - W2

	return Vector3(W1, W2, W3)


# Returns the lower left corner from the quad the point is in
# The offset can be used to get corners from adjacent quads
static func get_lower_left_point(point: Vector3, step_size: float, x_offset: int = 0, z_offset: int = 0) -> Vector3:
	var x_grid = floor(point.x / step_size) + x_offset
	var z_grid = floor(point.z / step_size) + z_offset
	return Vector3(x_grid * step_size, point.y, (z_grid + 1) * step_size)


# Returns the upper left corner from the quad the point is in
# The offset can be used to get corners from adjacent quads
static func get_upper_left_point(point: Vector3, step_size: float, x_offset: int = 0, z_offset: int = 0) -> Vector3:
	var x_grid = floor(point.x / step_size) + x_offset
	var z_grid = floor(point.z / step_size) + z_offset
	return Vector3(x_grid * step_size, point.y, z_grid * step_size)


# Returns the lower right corner from the quad the point is in
# The offset can be used to get corners from adjacent quads
static func get_lower_right_point(point: Vector3, step_size: float, x_offset: int = 0, z_offset: int = 0) -> Vector3:
	var x_grid = floor(point.x / step_size) + x_offset
	var z_grid = floor(point.z / step_size) + z_offset
	return Vector3((x_grid + 1) * step_size, point.y, (z_grid + 1) * step_size)


# Returns the upper right corner from the quad the point is in
# The offset can be used to get corners from adjacent quads
static func get_upper_right_point(point: Vector3, step_size: float, x_offset: int = 0, z_offset: int = 0) -> Vector3:
	var x_grid = floor(point.x / step_size) + x_offset
	var z_grid = floor(point.z / step_size) + z_offset
	return Vector3((x_grid + 1) * step_size, point.y, z_grid * step_size)


# Gets the intersection point with the quad diagonal (bottom-left to top-right)
static func get_diagonal_intersection(from: Vector3, to: Vector3, step_size: float):
	var direction: Vector3 = to - from
	
	# Non-Parallel to quad diagonal
	if direction.z != 0 && direction.x / direction.z == -1:
		return null
	
	var x_grid = floor(from.x / step_size)
	var z_grid = floor(from.z / step_size)
	
	var on_x_grid_and_decending: bool = (from.x / step_size) == x_grid && direction.x < 0
	var on_z_grid_and_decending: bool = (from.z / step_size) == z_grid && direction.z < 0
	
	# If point is exactly on grid and direction is negative, move points 'back'
	if on_x_grid_and_decending:
		x_grid -= 1
	
	if on_z_grid_and_decending:
		z_grid -= 1
	
	
	var A = Vector3((x_grid + 1) * step_size, 0, z_grid * step_size)
	var C = Vector3(x_grid * step_size, 0, (z_grid + 1) * step_size)
	
	# Calculate intersection values
	var den: float = (from.x - to.x) * (C.z - A.z) - (from.z - to.z) * (C.x - A.x)
	
	if den == 0:
		return null
	
	var t: float = ((from.x - C.x) * (C.z - A.z) - (from.z - C.z) * (C.x - A.x)) / den
	var u: float = -(((from.x - to.x) * (from.z - C.z) - (from.z - to.z) * (from.x - C.x)) / den)
	
	# Check if the intersection is with the line
	if t >= 0.0 && t <= 1.0 && u >= 0.0 && u <= 1.0:
		return Vector3(from.x + t * (to.x - from.x), 0, from.z + t * (to.z - from.z))
	
	return null


# Gets the intersection with the grid in x direction (parallel to z-axis)
static func get_horizontal_intersection(from: Vector3, to: Vector3, step_size: float):
	var direction = to - from
	
	var offset = _get_offset(from.x, to.x, step_size)
	if offset == null:
		return null
	
	var z = direction.z / direction.x * offset
	return Vector3(from.x + offset, 0, from.z + z)


# Gets the intersection with the grid in z direction (parallel to x-axis)
static func get_vertical_intersection(from: Vector3, to: Vector3, step_size: float):
	var direction = to - from
	
	var offset = _get_offset(from.z, to.z, step_size)
	if offset == null:
		return null
	
	var x = direction.x / direction.z * offset
	return Vector3(from.x + x, 0, from.z + offset)


# Calculates the remaining distance to the next grid with the given step_size
static func _get_offset(from: float, to: float, step_size: float):
	var direction = to - from
	
	if direction == 0:
		return null
	
	var grid_index = floor(from / step_size)
	var intersections: int = abs(floor(to / step_size) - grid_index)
	
	# From point being exactly on the grid and a negative direction, causing additinal intersection
	if (from / step_size) == grid_index && direction < 0:
		intersections -= 1
	
	# To point being exactly on the grid, causing additional intersection
	if (to / step_size) == floor((to / step_size)):
		intersections -= 1
	
	if intersections >= 1:
		# Calculate sampling grid offset
		var offset: float = 0.0
		
		# If the direction is positive, go to the next grid on the right
		if direction > 0:
			offset = (step_size - fposmod(from, step_size))
		# If the direction is negative, go to the next grid on the left
		else:
			offset = (fposmod(from, step_size)) * -1
		
		# If the offset is zero, go to next grid index
		if offset == 0.0:
			offset += step_size * sign(direction)
		
		return offset
	
	return null
