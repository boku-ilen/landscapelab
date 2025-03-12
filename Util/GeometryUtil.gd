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
