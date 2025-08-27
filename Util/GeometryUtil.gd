extends Node
class_name GeometryUtil



static func get_polygon_vertex_directions(polygon: Array) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	directions.resize(polygon.size())
	
	for idx in polygon.size():
		var current_vert: Vector2 = polygon[idx]
		var prev_vert: Vector2 = polygon[(idx - 1) % polygon.size()]
		var next_vert: Vector2 = polygon[(idx + 1) % polygon.size()]
		
		# To connect a polygon, starting and finishing vertex sometimes are duplicates
		# if so, skip them
		if   current_vert == next_vert: next_vert = polygon[(idx + 2) % polygon.size()]
		elif current_vert == prev_vert: prev_vert = polygon[(idx - 2) % polygon.size()]
		
		var current_to_prev: Vector2 = current_vert.direction_to(prev_vert)
		var current_to_next: Vector2 = current_vert.direction_to(next_vert)
		
		# Find the vertex direction given the two previous vertices 
		var angle: float = current_to_prev.angle_to(current_to_next)
		var direction: Vector2 = (-current_to_prev - current_to_next).normalized()
		if direction == Vector2.ZERO:
			direction = current_to_prev.rotated(PI / 2)
		else:
			direction *= -sign(angle)
		
		directions[idx] = direction
	
	return directions


static func offset_polygon_vertices(
	polygon: Array, directions: Array[Vector2], offset: float):
	assert(polygon.size() == directions.size())
	
	for idx in polygon.size():
		polygon[idx] += directions[idx] * -offset
	
	return polygon


static func project_triangle_to_uv(p0: Vector3, p1: Vector3, p2: Vector3) -> Array:
	# 1. Plane normal
	var e0 = p1 - p0
	var e1 = p2 - p0
	var normal = e0.cross(e1).normalized()

	# 2. Pick a tangent that isn't parallel to the normal.
	var tangent : Vector3
	if abs(normal.y) < 0.999:             # normal not almost straight up
		tangent = Vector3.UP.cross(normal).normalized()
	else:                                  # fallback if normal is ~UP
		tangent = Vector3.RIGHT.cross(normal).normalized()

	# 3. Bitangent completes the 2D basis
	var bitangent = normal.cross(tangent).normalized()

	# 4. Project each vertex into that basis
	var uv0 = Vector2(0, 0)                                   # p0 is origin
	var uv1 = Vector2(e0.dot(tangent), e0.dot(bitangent))     # p1 relative to p0
	var uv2 = Vector2(e1.dot(tangent), e1.dot(bitangent))     # p2 relative to p0

	return [uv0, uv1, uv2]
