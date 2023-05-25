extends Node3D
class_name IntersectionInstance

# Intersection Info
var intersection_id: int = 0
var connected_roads: Array = []
const ALMOST_STRAIGHT_ANGLE = 3.0


func load_from_feature(intersection_feature, roads: Dictionary) -> bool:
	connected_roads.clear()
	
	intersection_id = int(intersection_feature.get_attribute("intersection_id"))
	var road_ids_string: PackedStringArray = intersection_feature.get_attribute("road_ids").split(';')
	
	# The intersection needs at least 3 roads connected to it
	if road_ids_string.size() < 3:
		return false
	
	for road_id_string in road_ids_string:
		if not roads.has(int(road_id_string)):
			return false
	
	for i in range(road_ids_string.size()):
		connected_roads.append(roads[int(road_ids_string[i])])
	
	# Sort roads by angle counter-clockwise
	for i in range(connected_roads.size() - 1):
		var road_a_direction = _get_road_direction(connected_roads[i], intersection_id)
		var smallest_angle = 2 * PI
		var index_to_swap
		for j in range(i + 1, connected_roads.size()):
			var road_b_direction = _get_road_direction(connected_roads[j], intersection_id)
			var angle = counter_clockwise_angle(road_a_direction, road_b_direction)
			if angle < smallest_angle:
				smallest_angle = angle
				index_to_swap = j
		
		# Swap elements
		var temp = connected_roads[i + 1]
		connected_roads[i + 1] = connected_roads[index_to_swap]
		connected_roads[index_to_swap] = temp
	
	return true


func update_intersection() -> void:
	var vertices: PackedVector2Array = PackedVector2Array()
	var intersection_height: float = _get_road_point_3D(connected_roads[0], intersection_id).y
	# Calculate outer road intersections, defining intersection footprint
	for i in range(connected_roads.size()):
		var road_a: RoadInstance = connected_roads[i]
		var point_a = _get_road_point(road_a, intersection_id)
		var direction_a = _get_road_direction(road_a, intersection_id)
		
		var road_b: RoadInstance = connected_roads[(i + 1) % connected_roads.size()]
		var point_b = _get_road_point(road_b, intersection_id)
		var direction_b = _get_road_direction(road_b, intersection_id)
		
		# Shift points to the side
		point_a += Vector2(-direction_a.y, direction_a.x) * (road_a.width / 2.0)
		point_b += Vector2(direction_b.y, -direction_b.x) * (road_b.width / 2.0)
		
		var angle = counter_clockwise_angle(direction_a, direction_b)
		var intersection_point: Vector2
		# Angle greater than 180° results in the corner being one of the roads shifted points
		if angle >= ALMOST_STRAIGHT_ANGLE:
			intersection_point = point_a if road_a.width > road_b.width else point_b
		else:
			intersection_point = Geometry2D.line_intersects_line(point_a, direction_a, point_b, direction_b)
		
		vertices.push_back(intersection_point)
	
	
	# Calculate intersection center (simplified)
	var intersection_center: Vector2 = Vector2(0,0)
	for vertex in vertices:
		intersection_center += vertex

	intersection_center /= vertices.size()

	# Add additional points to match the angle of the roads
	var corner_points: PackedVector2Array = PackedVector2Array(vertices)
	var added_point_amount = 0
	for i in range(corner_points.size()):
		var corner_a = corner_points[i]
		var corner_b = corner_points[(i + 1) % corner_points.size()]
		var corner_a_center_distance = corner_a.distance_squared_to(intersection_center)
		var corner_b_center_distance = corner_b.distance_squared_to(intersection_center)
		
		var road: RoadInstance = connected_roads[(i + 1) % connected_roads.size()]
		var road_direction = _get_road_direction(road, intersection_id)
		
		# Test both sides for additional points
		var road_shift_direction_left = Vector2(road_direction.y, -road_direction.x)
		var additional_point_left = corner_b + road_shift_direction_left * road.width
		
		# Only add point if its further away than the corner point
		if additional_point_left.distance_squared_to(intersection_center) > corner_a_center_distance:
			vertices.insert(i + added_point_amount + 1, additional_point_left)
			added_point_amount += 1
			
			# Remove points until moved road fits
			var intersection_edge_point = corner_b + road_shift_direction_left * (road.width / 2.0)
			var index = 0
			while true:
				if road.road_curve.point_count < 3:
					break
				
				var road_point = _get_road_point(road, intersection_id, index)
				if road_point.distance_squared_to(intersection_center) > intersection_edge_point.distance_squared_to(intersection_center):
					break
				
				_remove_road_point(road, intersection_id, 1)
				index += 1
			
			# Move road to edge of intersection
			_set_road_point(road, intersection_id, Vector3(intersection_edge_point.x, intersection_height, intersection_edge_point.y))
		
		
		var road_shift_direction_right = Vector2(-road_direction.y, road_direction.x)
		var additional_point_right = corner_a + road_shift_direction_right * road.width
		
		if additional_point_right.distance_squared_to(intersection_center) > corner_b_center_distance:
			vertices.insert(i + added_point_amount + 1, additional_point_right)
			added_point_amount += 1
		
			# Remove points until moved road fits
			var intersection_edge_point = corner_a + road_shift_direction_right * (road.width / 2.0)
			var index = 0
			while true:
				if road.road_curve.point_count < 3:
					break
				
				var road_point = _get_road_point(road, intersection_id, index)
				if road_point.distance_squared_to(intersection_center) > intersection_edge_point.distance_squared_to(intersection_center):
					break
				
				_remove_road_point(road, intersection_id, 1)
				index += 1
			
			# Move road to edge of intersection
			_set_road_point(road, intersection_id, Vector3(intersection_edge_point.x, intersection_height, intersection_edge_point.y))
		
		road.update_road_lanes()
	
	$IntersectionPolygon.polygon = vertices
	$IntersectionPolygon.transform.origin.y = intersection_height


func _get_road_direction(road: RoadInstance, intersection_id: int) -> Vector2:
	var A = _get_road_point(road, intersection_id, 1)
	var B = _get_road_point(road, intersection_id, 0)
	var direction = B - A
	return direction.normalized()


func _get_road_point(road: RoadInstance, intersection_id: int, offset: int = 0) -> Vector2:
	var road_point: Vector3 = _get_road_point_3D(road, intersection_id, offset)
	return Vector2(road_point.x, road_point.z)


func _get_road_point_3D(road: RoadInstance, intersection_id: int, offset: int = 0) -> Vector3:
	# Either use front or back
	if road.from_intersection == intersection_id:
		return road.road_curve.get_point_position(offset)
	else:
		return road.road_curve.get_point_position(road.road_curve.get_point_count() - 1 - offset)


func _set_road_point(road: RoadInstance, intersection_id: int, point: Vector3) -> void:
	if road.from_intersection == intersection_id:
		road.road_curve.set_point_position(0, point)
	else:
		road.road_curve.set_point_position(road.road_curve.point_count - 1, point)


func _remove_road_point(road: RoadInstance, intersection_id: int, offset: int) -> void:
	# FIXME: Seems like this is called too often, returning early fixes gaps at intersections
	return
	if road.from_intersection == intersection_id:
		road.road_curve.remove_point(offset)
	else:
		road.road_curve.remove_point(road.road_curve.get_point_count() - 1 - offset)

# Returns the angle between the vectors, always positive going counter-clockwise
# NOTE: As the engines z-axis (which is y topdown) is negative, clockwise and counter-clockwise are switched!
static func counter_clockwise_angle(a: Vector2, b: Vector2) -> float:
	var angle = atan2(a.y, a.x) - atan2(b.y, b.x)
	return angle if angle >= 0 else angle + 2.0 * PI


# Returns the angle between the vectors, always positive going clockwise
# NOTE: As the engines z-axis (which is y topdown) is negative, clockwise and counter-clockwise are switched!
static func clockwise_angle(a: Vector2, b: Vector2) -> float:
	var angle = atan2(b.y, b.x) - atan2(a.y, a.x)
	return angle if angle >= 0 else angle + 2.0 * PI
