extends Object
class_name StraightSkeleton

static func _travel_direction(point_before: Vector2, point: Vector2, point_after: Vector2) -> Vector2:
	var to_before := (point_before - point).normalized()
	var to_after := (point_after - point).normalized()
	var direction := to_before.slerp(to_after, 0.5).normalized()
	if (point - point_before).angle_to(to_after) > 0:
		direction = -direction
	return direction

class EdgeEvent:
	var combined_vertices: Array[int]
	var t: float
	var new_point: Vector2

class StraightSkeletonInfo:
	class EventState:
		var base_poly: Array[Vector2]
		var new_shrink_events: Array[EdgeEvent]
	
	var bisectors: Array[BisectorArc]
	var edge_events: Array[EventState]
	var triangles: Array[Array]
	var triangle_normals: Array[Vector3]
	var vertex_uvs: Array[Vector2]
	var vertex_uv_addends_unscaled: Array[float]
	var vertex_uv_scales: Array[float]
	var max_t: float
	
static func _offset_polygon_by(polygon: Array[Vector2], vertex_directions: Array[Vector2], edge_normals: Array[Vector2], offset: float) -> Array[Vector2]:
	var new_poly: Array[Vector2] = []
	for vert_i in polygon.size():
		var index_before := (vert_i - 1 + polygon.size()) % polygon.size()
		var index_after := (vert_i + 1) % polygon.size()
		
		var corner_angle := (polygon[index_before] - polygon[vert_i]).angle_to(polygon[index_after] - polygon[vert_i])
		var actual_distance := 0.0
#		if abs(corner_angle) < PI/2:
#			# convex corner
#			actual_distance = offset / sin(abs(corner_angle) / 2)
#		else:
		actual_distance = offset / cos(abs(vertex_directions[vert_i].angle_to(edge_normals[vert_i])))
#		if Geometry2D.get_closest_point_to_segment_uncapped(polygon[vert_i] + vertex_directions[vert_i] * actual_distance, polygon[vert_i], polygon[(vert_i + 1) % polygon.size()]).distance_to(polygon[vert_i] + vertex_directions[vert_i] * actual_distance) > offset + 0.01:
#			print("foo")
		new_poly.append(polygon[vert_i] + vertex_directions[vert_i] * actual_distance)
	return new_poly

static func _offset_vertex_by(prev_vertex: Vector2, vertex: Vector2, next_vertex: Vector2, vertex_direction: Vector2, edge_normal: Vector2, offset: float) -> Vector2:
	var corner_angle := (prev_vertex - vertex).angle_to(next_vertex - vertex)
	var actual_distance := 0.0
	if abs(corner_angle) < PI/2:
		# convex corner
		actual_distance = offset / sin(abs(corner_angle) / 2)
	else:
		actual_distance = offset / cos(abs(vertex_direction.angle_to(edge_normal)))
	return vertex + vertex_direction * actual_distance

static func _centered_position_along_segment(point: Vector2, s1: Vector2, s2: Vector2):
	var closest = Geometry2D.get_closest_point_to_segment(point, s1, s2)
	var midpoint = s1 + (s2 - s1) * 0.5
	var side_len = s1.distance_to(s2)
	if closest.distance_squared_to(s1) < closest.distance_squared_to(s2):
		return clamp(-closest.distance_to(midpoint) / side_len, -0.5, 0.5)
	return clamp(closest.distance_to(midpoint) / side_len, -0.5, 0.5)

static func _next_edge_events(polygon: Array[Vector2], normals: Array[Vector2], inward_directions: Array[Vector2]) -> Array[EdgeEvent]:
	if polygon.size() <= 3:
		return []
		
	var found_events: Array[EdgeEvent] = []
	for vert_i in polygon.size():
		var travel_directions: Array[Vector2] = [
			inward_directions[vert_i] * cos(abs(inward_directions[vert_i].angle_to(normals[vert_i]))),
			inward_directions[(vert_i + 1) % polygon.size()] * cos(abs(inward_directions[(vert_i + 1) % polygon.size()].angle_to(normals[(vert_i + 1) % polygon.size()])))
		]
		# time of intersection in terms of travel_directions[0]
		var intersection_t: float = (polygon[vert_i].y - polygon[(vert_i + 1) % polygon.size()].y - 
			(travel_directions[1].y * (polygon[vert_i].x - polygon[(vert_i + 1) % polygon.size()].x)) / 
			travel_directions[1].x) / ((travel_directions[1].y * travel_directions[0].x) / 
			travel_directions[1].x - travel_directions[0].y);
		
		if intersection_t > 0:
			var intersection_point := polygon[vert_i] + intersection_t * travel_directions[0]
			var t_multiplier = cos(abs(travel_directions[0].angle_to(normals[vert_i])))
			var candidate_event = EdgeEvent.new()
			candidate_event.new_point = intersection_point
			candidate_event.t = intersection_t  * t_multiplier * t_multiplier #intersection_point.distance_to(Geometry2D.get_closest_point_to_segment_uncapped(intersection_point, polygon[vert_i], polygon[(vert_i + 1) % polygon.size()]))
			candidate_event.combined_vertices.assign([vert_i, (vert_i + 1) % polygon.size()])
			found_events.append(candidate_event)
		
	if found_events.size() > 0:
		found_events.sort_custom(func (a,b): return a.t < b.t)
		return found_events.filter(func (ev): return ev.t <= found_events[0].t + 0.01 and ev.t > 0)
		
	return []

class BisectorArc:
	var origin: Vector2
	var endpoint: Vector2
	var start_t: float
	var end_t: float

static func _to_3d(v: Vector2, h: float)->Vector3:
	return Vector3(v.x, h, v.y)

class SubPolyInfo:
	var verts: Array[Vector2]
	var bisectors: Array[BisectorArc]
	var original_indices: Array[int]
	
static func _get_split_polygons(poly_info, old_verts, t, events) -> Array[SubPolyInfo]:
	if events.size() == 0:
		return poly_info
	
	var all_polys: Array[SubPolyInfo] = []
	
	var poly_info_before := SubPolyInfo.new()
	var poly_info_after := SubPolyInfo.new()
	var verts = poly_info.verts
	var bisectors = poly_info.bisectors
	var event = events[0]
	var original_segment = event["segment"]
	event["segment"] = poly_info.original_indices.find(event["segment"])
	
	
	var new_before = old_verts[(event["arc"] - 1 + old_verts.size()) % old_verts.size()]
	var new_point = old_verts[event["arc"]]
	var new_after = verts[(event["segment"] + 1) % verts.size()]
	var new_normal = -Vector2(new_after.y - new_point.y, -(new_after.x - new_point.x)).normalized()
	#print(new_before, new_point, new_after, new_normal)



	
	#event["point"] -= vertex_directions[event["arc"]]*t * 0.5
	var points_before: Array[Vector2] = []
	var bisectors_before: Array[BisectorArc] = []
	var before_point = new_point
	
	var before_split_bisector = BisectorArc.new()
	before_split_bisector.origin = before_point
	before_split_bisector.start_t = bisectors[poly_info.original_indices.find(event["arc"])].start_t + t
	#bisectors_before.append(before_split_bisector)
	
	
	
	new_before = verts[event["segment"]]
	new_after = old_verts[(event["arc"] + 1) % verts.size()]
	new_normal = Vector2(new_after.y - new_point.y, -(new_after.x - new_point.x)).normalized()

	var after_point = old_verts[event["arc"]]#verts[event["segment"]]
	var after_split_bisector = BisectorArc.new()
	after_split_bisector.origin = old_verts[event["arc"]]
	before_split_bisector.start_t = bisectors[poly_info.original_indices.find(event["arc"])].start_t + t
	
	var before_connect_bisector = bisectors[poly_info.original_indices.find(event["arc"])]
	before_connect_bisector.endpoint = old_verts[event["arc"]]
	before_connect_bisector.end_t = before_connect_bisector.start_t + t
	bisectors[poly_info.original_indices.find(event["arc"])] = BisectorArc.new()
	bisectors[poly_info.original_indices.find(event["arc"])].start_t = before_connect_bisector.end_t
	bisectors[poly_info.original_indices.find(event["arc"])].origin = old_verts[event["arc"]]
	

	var before_connect_seg1 = bisectors[event["segment"]]
	before_connect_seg1.endpoint = verts[event["segment"]]
	before_connect_seg1.end_t = before_connect_bisector.start_t + t
	
	var before_connect_seg2 = bisectors[(event["segment"] - 1 + verts.size()) % verts.size()]
	before_connect_seg2.endpoint = verts[(event["segment"] - 1 + verts.size()) % verts.size()]
	before_connect_seg2.end_t = before_connect_bisector.start_t + t
	
	var new_before_bisector = BisectorArc.new()
	new_before_bisector.origin = old_verts[event["arc"]]
	new_before_bisector.start_t = before_connect_bisector.start_t + t
	


	
	var vert_cursor = (event["segment"] + 1) % verts.size()
	if original_segment in poly_info.original_indices and event["arc"] in poly_info.original_indices:
		while vert_cursor != (poly_info.original_indices.find(event["arc"]) ) % verts.size():
			#print("before_vc", vert_cursor)
			points_before.append(verts[vert_cursor])
			bisectors_before.append(bisectors[vert_cursor])
			poly_info_before.original_indices.append(poly_info.original_indices[vert_cursor])
			vert_cursor = (vert_cursor + 1) % verts.size()
	
		points_before.append(before_point)
		poly_info_before.original_indices.append(event["arc"])#event["arc"])
		bisectors_before.append(new_before_bisector)
		
		points_before.append(Geometry2D.get_closest_point_to_segment(old_verts[event["arc"]], verts[event["segment"]], verts[(event["segment"] + 1) % verts.size()]))
		poly_info_before.original_indices.append(old_verts.size() + randi_range(0,100))
		bisectors_before.append(new_before_bisector)	

		

	

	
	
		var points_after: Array[Vector2] = []
		var bisectors_after: Array[BisectorArc] = []
		
		points_after.append(after_point)
		poly_info_after.original_indices.append(event["arc"])#event["arc"])
		bisectors_after.append(after_split_bisector)
		
		vert_cursor = (poly_info.original_indices.find(event["arc"]) +1 ) % verts.size()
		while vert_cursor != (event["segment"] + 1) % verts.size():
			#print("after_vc", vert_cursor)
	
			points_after.append(verts[vert_cursor])
			bisectors_after.append(bisectors[vert_cursor])
			poly_info_after.original_indices.append(poly_info.original_indices[poly_info.original_indices.find(vert_cursor)])
			vert_cursor = (vert_cursor + 1) % verts.size()
		
	
		points_after.append(Geometry2D.get_closest_point_to_segment(old_verts[event["arc"]], verts[event["segment"]], verts[(event["segment"] + 1) % verts.size()]))
		poly_info_after.original_indices.append(99999)
		bisectors_after.append(after_split_bisector)
		
		
		
		
		poly_info_before.verts = points_before
		poly_info_before.bisectors = bisectors_before
		poly_info_after.verts = points_after
		poly_info_after.bisectors = bisectors_after
		if events.size() > 1:
			#print("recurse maybe ", events[1])
			var did_rec = false
			var next_events = events.duplicate()
			next_events.remove_at(0)
			if poly_info_before.original_indices.find(next_events[0]["segment"]) >= 0:
				#print("recurse before")
				var before_splits = _get_split_polygons(poly_info_before, old_verts, t, next_events)
				all_polys.append_array(before_splits)
				did_rec = true
			else:
				all_polys.append(poly_info_before)
				
			if poly_info_after.original_indices.find(next_events[0]["segment"]) >= 0:
				#print("recurse after")
				var after_splits = _get_split_polygons(poly_info_after, old_verts, t, next_events)
				all_polys.append_array(after_splits)
			else:
				all_polys.append(poly_info_after)
		else:
			all_polys.append(poly_info_before)
			all_polys.append(poly_info_after)
	return all_polys

static func calculate(vertices: Array[Vector2], partial_bisectors: Array[BisectorArc] = [], on_poly_callback: Callable = func (x): return, overall_t: float = 0.0, full_perimeter_length = -1.0) -> StraightSkeletonInfo:
	var verts: Array[Vector2] = vertices.duplicate()
	var edge_normals: Array[Vector2] = []
	var vertex_directions: Array[Vector2] = []
	var vertex_is_reflex: Array[bool]
	
	var vertex_position_along_perimeter = []
	var side_lengths = []
	var original_side_lengths = []
	
	var original_vertex_map: Dictionary[int, int] = {}
	for i in vertices.size():
		original_vertex_map[i]=i
	
	var unfinished_bisectors: Array[BisectorArc]
	if partial_bisectors.size() > 0:
		#print("got bisectors, ", partial_bisectors.size(), " for ", vertices.size(), " verts")
		unfinished_bisectors = partial_bisectors.duplicate()
	
	var result := StraightSkeletonInfo.new()
	
	var current_t = overall_t
	
	var last_untriangulated = vertices.duplicate()
	
	var duplicates = {}
	
	for vert_i in verts.size():
		for vert_j in verts.size():
			if vert_i == vert_j:
				continue
			if verts[vert_i].distance_squared_to(verts[vert_j]) < 0.01:
				duplicates[max(vert_i, vert_j)] = true
	var to_remove = duplicates.keys()
	to_remove.sort_custom(func (a,b): return a > b)
	for dup in to_remove:
		verts.remove_at(dup)
		unfinished_bisectors.remove_at(dup)
	
	if verts[0].distance_squared_to(verts[-1]) < 0.01:
		verts.remove_at(0)
		unfinished_bisectors.remove_at(0)
		last_untriangulated.remove_at(0)
	
	var closed_bisectors: Array[BisectorArc]
	
	to_remove = []
	var distance_acc = 0.0
	for vert_i in verts.size():
		var l = verts[vert_i].distance_to(verts[(vert_i + 1) % verts.size()])
		vertex_position_along_perimeter.append(distance_acc + (l * 0.5))
		side_lengths.append(l)
		distance_acc += l
	
		# edge <=> vertex to next vertex
		var edge_dir := (verts[(vert_i + 1) % verts.size()] - verts[vert_i]).normalized()
		var edge_normal := Vector2(edge_dir.y, -edge_dir.x)
		var travel_dir = -_travel_direction(verts[(vert_i - 1 + verts.size()) % verts.size()], verts[vert_i], verts[(vert_i + 1) % verts.size()])
		
		if abs(edge_dir.angle_to((verts[(vert_i ) % verts.size()] - verts[(vert_i - 1 + verts.size()) % verts.size()]).normalized())) < 0.01:
			to_remove.append(vert_i)
			continue
		
		edge_normals.append(-edge_normal)
		vertex_directions.append(travel_dir)
		
		var prev = verts[(vert_i - 1 + verts.size()) % verts.size()]
		var curr = verts[vert_i]
		var next = verts[(vert_i + 1) % verts.size()]
		#vertex_is_reflex.append(true)
		vertex_is_reflex.append((curr - prev).angle_to(next - curr) < 0)
		if partial_bisectors.size() == 0:
			var bisector = BisectorArc.new()
			bisector.origin = verts[vert_i]
			bisector.start_t = 0.0
			
			unfinished_bisectors.append(bisector)
	
	var perimeter_length = side_lengths.reduce(func (a,b): return a + b, 0.0)
	
	if full_perimeter_length >= 0:
		distance_acc /= perimeter_length / full_perimeter_length
		perimeter_length = full_perimeter_length
	
	#print("Dacc ", distance_acc, ", full ", perimeter_length)
	
	original_side_lengths = side_lengths.duplicate()
	for p_i in vertex_position_along_perimeter.size():
		
		vertex_position_along_perimeter[p_i] /= distance_acc
		side_lengths[p_i] /= distance_acc
	
	to_remove.reverse()
	for remove_i in to_remove:
		verts.remove_at(remove_i)
		vertex_position_along_perimeter.remove_at(remove_i)
		side_lengths.remove_at(remove_i)
		original_side_lengths.remove_at(remove_i)
		if partial_bisectors.size() != 0:
			unfinished_bisectors.remove_at(remove_i)
		
	#print(side_lengths, vertex_position_along_perimeter)
	#print(vertex_directions.size(), ",", verts.size())
	var offset := -5.0
	
	while true:
		
		on_poly_callback.call(verts)
#		for i in 10:
#			on_poly_callback.call(_offset_polygon_by(verts, vertex_directions, edge_normals, 4 * i))
#		if partial_bisectors.size() > 0:
#			return []
		var next_events := _next_edge_events(verts, edge_normals, vertex_directions)
		if next_events == []:
			if verts.size() <= 3:
				#print("triangle verts ", verts.size(), ", open bisectors ", unfinished_bisectors.size())
				var centroid = Vector2.ZERO
				for v in verts:
					centroid += v
				centroid /= verts.size()
				for bisector_i in unfinished_bisectors.size():
					var open_bisector = unfinished_bisectors[bisector_i]
					open_bisector.endpoint = verts[bisector_i]
					# might be nonsense (?)
					open_bisector.end_t = open_bisector.start_t + open_bisector.endpoint.distance_to(open_bisector.origin)
					result.bisectors.append(open_bisector)
					var in_triangle_bisector = BisectorArc.new()
					in_triangle_bisector.origin = verts[bisector_i]
					in_triangle_bisector.start_t = open_bisector.end_t
					in_triangle_bisector.endpoint = centroid
					in_triangle_bisector.end_t = in_triangle_bisector.start_t + in_triangle_bisector.origin.distance_to(centroid)
					result.bisectors.append(in_triangle_bisector)
				if verts.size() == 3:
					var centroid_t = current_t + centroid.distance_to(Geometry2D.get_closest_point_to_segment(centroid, verts[0], verts[1]))
					for vert_i in verts.size():
						centroid_t = min(centroid_t, current_t + centroid.distance_to(Geometry2D.get_closest_point_to_segment(centroid, verts[vert_i], verts[(vert_i + 1) % verts.size()])))
					for vert_i in verts.size():
						var tri: Array[Vector3]= [
							_to_3d(verts[vert_i], current_t),
							_to_3d(verts[(vert_i + 1) % verts.size()], current_t),
							_to_3d(centroid, centroid_t)
						]
						result.triangles.append(tri)
						result.triangle_normals.append((tri[1] - tri[2]).cross(tri[0] - tri[2]).normalized())
						
						var uv_centroid = (vertex_position_along_perimeter[vert_i] + vertex_position_along_perimeter[(vert_i + 1) % verts.size()]) / 2
						
						result.vertex_uvs.append_array([
							Vector2(vertex_position_along_perimeter[vert_i], current_t),
							Vector2(vertex_position_along_perimeter[vert_i], current_t),
							Vector2(vertex_position_along_perimeter[vert_i], centroid_t)
						])
						result.vertex_uv_addends_unscaled.append_array([
							-side_lengths[vert_i] * 0.5,
							side_lengths[vert_i] * 0.5,
							_centered_position_along_segment(centroid, verts[vert_i], verts[(vert_i + 1) % verts.size()]) * side_lengths[vert_i]
						])
						result.vertex_uv_scales.append_array([
							original_side_lengths[vert_i],
							original_side_lengths[vert_i],
							original_side_lengths[vert_i]
						])
#					result.triangles.append(verts.map(func (v): return Vector3(v.x, current_t, v.y)))
#					result.triangle_normals.append(Vector3.UP)
				
			break
		#print(next_events[0].t)
		var candidate_verts := _offset_polygon_by(verts, vertex_directions, edge_normals, next_events[0].t)
		#on_poly_callback.call(candidate_verts)
		#print("@129 ", vertex_directions.size(), ",", verts.size())
		
		var candidate_directions = vertex_directions.duplicate()
		var candidate_normals = edge_normals.duplicate()
		var candidate_is_reflex = vertex_is_reflex.duplicate()
		var candidate_bisectors = unfinished_bisectors.duplicate()
		var candidate_untriangulated = last_untriangulated.duplicate()


		
		for next_event in next_events:			
			candidate_verts[next_event.combined_vertices[0]] = next_event.new_point
			
		#for next_event in next_events:
		
			
		
			#candidate_directions[next_event.combined_vertices[0]] = -_travel_direction(candidate_verts[(next_event.combined_vertices[0] - 1 + verts.size()) % verts.size()], candidate_verts[next_event.combined_vertices[0]], candidate_verts[(next_event.combined_vertices[1] + 1) % verts.size()])
			var candidate_edge_dir_next := (candidate_verts[(next_event.combined_vertices[1] + 1) % candidate_verts.size()] - candidate_verts[next_event.combined_vertices[0]]).normalized()
			var candidate_edge_dir_prev := (candidate_verts[(next_event.combined_vertices[0] - 1 + candidate_verts.size()) % candidate_verts.size()] - candidate_verts[next_event.combined_vertices[0]]).normalized()
			
			#candidate_normals[next_event.combined_vertices[0]] = -Vector2(candidate_edge_dir_next.y, -candidate_edge_dir_next.x)
			#candidate_normals[(next_event.combined_vertices[0] - 1 + candidate_verts.size()) % candidate_verts.size()] = -Vector2(candidate_edge_dir_prev.y, -candidate_edge_dir_prev.x)
			
		#print(vertex_is_reflex)
		var is_valid = true
		var intersecting_arcs = []
#		var intersecting_arcs = range(0,verts.size() - 1)
		#print("@145 ", vertex_directions.size(), ",", verts.size())
		# check for self-intersection (->split event)
		for vert_i in candidate_is_reflex.size():
			if not candidate_is_reflex[vert_i]:
				continue
								
			intersecting_arcs.append(vert_i)

#			print(vert_i, " is reflex")
#			intersecting_arcs.append(vert_i)
#			continue
			var prev := candidate_verts[(vert_i - 1 + candidate_verts.size()) % candidate_verts.size()]
			var curr := candidate_verts[vert_i]
			var next := candidate_verts[(vert_i + 1) % candidate_verts.size()]
			var intersection_exists := false
			for vert_j in candidate_verts.size():
				if vert_j == (vert_i - 1 + candidate_verts.size()) % candidate_verts.size():# or vert_j == vert_i:
					continue
				var prev_intersect = Geometry2D.segment_intersects_segment(prev, curr, candidate_verts[vert_j], candidate_verts[(vert_j + 1) % candidate_verts.size()])
				var next_intersect = Geometry2D.segment_intersects_segment(curr, next, candidate_verts[vert_j], candidate_verts[(vert_j + 1) % candidate_verts.size()])
				if prev_intersect != null or next_intersect != null:
					#print("vertex ", vert_i, " intersects edge ", vert_j)
					
					intersection_exists = true


			if intersection_exists:
				is_valid = false
		#print("@166 ", is_valid)

		
		#if intersecting_arcs.size() > 0:
		if not is_valid:
			var split_events: Array[Dictionary] = []
			#on_poly_callback.call(verts)
			for arc in intersecting_arcs:
				var arc_vert := verts[arc]
				var arc_dir = vertex_directions[arc]
				for vert_i in verts.size():
					if vert_i == arc or (vert_i - 1 + verts.size()) % verts.size() == arc or (vert_i + 1) % verts.size() == arc:
					
						continue
				
					var potential_intersection_point = Geometry2D.line_intersects_line(
						arc_vert, arc_dir, verts[vert_i], (verts[(vert_i + 1) % verts.size()] - verts[vert_i]).normalized()
					)
					
					# lines parallel
					if potential_intersection_point == null:
						#print("split: parallel")
						continue
					
					
					var candidate_segment = vert_i
					
					# intersection point not on segment
					if (potential_intersection_point as Vector2).distance_to(Geometry2D.get_closest_point_to_segment(potential_intersection_point, verts[vert_i], verts[(vert_i + 1) % verts.size()])) > 0.01:
						#print("split: outside")
						if not vertex_is_reflex[vert_i]:
							continue
						
						# verts[vert_i] is reflex, maybe we intersect their arc?
						var potential_arc_intersection = Geometry2D.line_intersects_line(arc_vert, arc_dir, verts[vert_i], vertex_directions[vert_i])
						if potential_arc_intersection == null:
							continue
						
						if abs(((potential_arc_intersection as Vector2) - arc_vert).angle_to(arc_dir)) > PI/2:
							continue
						
						var intersect_before = Geometry2D.line_intersects_line(arc_vert, arc_dir, verts[vert_i], (verts[(vert_i - 1 + verts.size()) % verts.size()] - verts[vert_i]).normalized())
						
						#print("arc/arc ", arc, "/", vert_i, "at", potential_intersection_point)

#						if intersect_before != null:
#							print("b4_maybe")
#							if (intersect_before as Vector2).distance_squared_to(arc_vert) < (potential_intersection_point as Vector2).distance_squared_to(arc_vert):
#								print("b4_def")
#								potential_intersection_point = intersect_before
#								candidate_segment = (vert_i - 1 + verts.size()) % verts.size()
												
											
					
					var distance_modifier_a := 1 / cos(abs(arc_dir.angle_to(edge_normals[arc])))
					var relative_dir = Vector2.from_angle(-abs((arc_dir).angle_to(edge_normals[(arc - 1 + verts.size()) % verts.size()])))
					relative_dir = relative_dir / relative_dir.x
					var distance_modifier = distance_modifier_a#relative_dir.length()
					
					
					#distance_modifier = 1.0 / sin(abs(arc_dir.angle_to(edge_normals[arc])) / 2)
					var arc_normal_angle: float = abs((-arc_dir).angle_to(edge_normals[candidate_segment]))
					var distance_along_normal := arc_vert.distance_to(Geometry2D.get_closest_point_to_segment_uncapped(arc_vert, verts[candidate_segment], verts[(candidate_segment + 1) % verts.size()]))
					
					if abs(arc_dir.angle_to(potential_intersection_point - arc_vert)) > PI/2:
						#print("angle fucked up")
						continue
					
					#print(cos(arc_normal_angle), ", ", arc_normal_angle)	
					#var t = (distance_along_normal / (distance_modifier * sin((PI / 2) - arc_normal_angle))) * 0.5
					
					
					var t = (distance_along_normal * cos(arc_normal_angle) / ((distance_modifier  + 1) * (cos(arc_normal_angle) + 1)))#* (cos(arc_normal_angle) + 1)))
					if t < 0:
						#print("negative t ", t)
						continue
					#var t = ((distance_along_normal * distance_modifier) / (distance_modifier + sin((PI / 2) - arc_normal_angle))) * 0.5
					#print(arc_normal_angle, ", ", (PI/2) - arc_normal_angle, ", ", sin((PI/2) - arc_normal_angle), ", ", distance_along_normal, ", ", t)
					
					if split_events.any(func (ev): return ev["segment"] == candidate_segment and ev["arc"] == arc):
						continue
					
					if not Geometry2D.is_point_in_polygon(potential_intersection_point + edge_normals[vert_i] * t, verts):
						#print("outside")
						continue
					# we will split here into two polygons
					split_events.append(
						{
							"t": t,
							"segment": candidate_segment,
							"point": verts[arc] + vertex_directions[arc] * t * distance_modifier,
							"arc": arc
						}
					)
			#print(split_events)
			split_events = split_events.filter(func (e): return e["t"] < next_events[0].t + 0.1)
			if split_events.size() > 0:
				split_events.sort_custom(func (a,b): return a["t"] < b["t"])

				split_events = split_events.filter(func (e): return e["t"] < split_events[0].t + 0.1)

				var same_time_events = split_events#split_events.filter(func (e): return e["t"] < split_events[0]["t"] + 0.1)
				var before_sets: Array[Array]
				var before_bisector_sets: Array[Array]
				var after_sets: Array[Array]
				var after_bisector_sets: Array[Array]
				
				var t = split_events[0]["t"]
				#print("split t ca ", t, split_events[0])
				
				
				var old_verts = verts.duplicate_deep()

				verts = _offset_polygon_by(verts, vertex_directions, edge_normals, t)
				#on_edge_callback.call(verts[split_events[0]["arc"]])
				#on_poly_callback.call(verts)
				for vert_i in verts.size():
					result.triangles.append([
						_to_3d(old_verts[vert_i], current_t),
						_to_3d(old_verts[(vert_i + 1) % verts.size()], current_t),
						_to_3d(verts[vert_i], current_t + t)
					])
					result.vertex_uvs.append_array([
						Vector2(vertex_position_along_perimeter[vert_i], current_t),
						Vector2(vertex_position_along_perimeter[vert_i], current_t),
						Vector2(vertex_position_along_perimeter[vert_i], current_t + t),
					])
					result.vertex_uv_addends_unscaled.append_array([
						- side_lengths[vert_i] * 0.5,
						side_lengths[vert_i] * 0.5,
						_centered_position_along_segment(verts[vert_i], old_verts[vert_i], old_verts[(vert_i + 1) % old_verts.size()]) * side_lengths[vert_i],
					])
					result.vertex_uv_scales.append_array([
						original_side_lengths[vert_i],
						original_side_lengths[vert_i],
						original_side_lengths[vert_i]
					])
					
					result.triangles.append([
						_to_3d(verts[(vert_i + 1) % verts.size()], current_t+t),
						_to_3d(verts[vert_i], current_t+t),
						_to_3d(old_verts[(vert_i + 1) % verts.size()], current_t),
					])
					result.vertex_uvs.append_array([
						Vector2(vertex_position_along_perimeter[vert_i], current_t + t),
						Vector2(vertex_position_along_perimeter[vert_i], current_t + t),
						Vector2(vertex_position_along_perimeter[vert_i], current_t),
					])
#					result.vertex_uv_addends_unscaled.append_array([
#						side_lengths[vert_i] * 0.5,
#						-side_lengths[vert_i] * 0.5,
#						side_lengths[vert_i] * 0.5,
#					])
					result.vertex_uv_addends_unscaled.append_array([
						_centered_position_along_segment(verts[(vert_i + 1) % verts.size()], old_verts[vert_i], old_verts[(vert_i + 1) % verts.size()]) * side_lengths[vert_i],
						_centered_position_along_segment(verts[vert_i], old_verts[vert_i], old_verts[(vert_i + 1) % verts.size()]) * side_lengths[vert_i],
						side_lengths[vert_i] * 0.5,
					])
					result.vertex_uv_scales.append_array([
						original_side_lengths[vert_i],
						original_side_lengths[vert_i],
						original_side_lengths[vert_i]
					])
					
					var to_first = _to_3d(old_verts[vert_i], current_t) - _to_3d(verts[vert_i], current_t + t)
					var to_second = _to_3d(old_verts[(vert_i + 1) % verts.size()], current_t) - _to_3d(verts[vert_i], current_t + t)
					var normal = to_second.cross(to_first).normalized()
					result.triangle_normals.append(normal)
					result.triangle_normals.append(normal)
				var segment_normal = edge_normals[split_events[0]["segment"]]
				
				var poly_info_initial = SubPolyInfo.new()
				poly_info_initial.original_indices.assign(range(verts.size()))
				poly_info_initial.verts = verts
				poly_info_initial.bisectors = unfinished_bisectors
				#print("rec?: ", same_time_events.size())
				var initial_splits := _get_split_polygons(poly_info_initial, verts, t, same_time_events)
				
				#print("polys: ", initial_splits.size())
				for poly in initial_splits:
					var poly_result = calculate(poly.verts, poly.bisectors, on_poly_callback, current_t + t, perimeter_length)
					
					result.bisectors.append_array(poly_result.bisectors)
					result.triangles.append_array(poly_result.triangles)
					result.triangle_normals.append_array(poly_result.triangle_normals)
					result.vertex_uvs.append_array(poly_result.vertex_uvs)
					result.vertex_uv_addends_unscaled.append_array(poly_result.vertex_uv_addends_unscaled)
					result.vertex_uv_scales.append_array(poly_result.vertex_uv_scales)
					result.max_t = max(result.max_t, poly_result.max_t)
				var new_before = verts[(split_events[0]["arc"] - 1 + verts.size()) % verts.size()]
				var new_point = verts[(split_events[0]["arc"]) % verts.size()]
				var new_after = verts[(split_events[0]["segment"] + 1) % verts.size()]
				var new_normal = -Vector2(new_after.y - new_point.y, -(new_after.x - new_point.x)).normalized()
				#print(new_before, new_point, new_after, new_normal)



				
				#split_events[0]["point"] -= vertex_directions[split_events[0]["arc"]]*t * 0.5
				var points_before: Array[Vector2] = []
				var bisectors_before: Array[BisectorArc] = []
				var before_point = new_point
				
				var before_split_bisector = BisectorArc.new()
				before_split_bisector.origin = before_point
				before_split_bisector.start_t = unfinished_bisectors[split_events[0]["arc"]].start_t + t
				#bisectors_before.append(before_split_bisector)
				
				unfinished_bisectors[split_events[0]["arc"]].endpoint = verts[split_events[0]["arc"]]# - vertex_directions[split_events[0]["arc"]] * t * 0.5
				result.bisectors.append(unfinished_bisectors[split_events[0]["arc"]])
				
				
				new_before = verts[split_events[0]["segment"]]
				new_after = verts[(split_events[0]["arc"] + 1) % verts.size()]
				new_normal = Vector2(new_after.y - new_point.y, -(new_after.x - new_point.x)).normalized()

				var after_point = verts[split_events[0]["arc"]]#verts[split_events[0]["segment"]]
				var after_split_bisector = BisectorArc.new()
				after_split_bisector.origin = verts[split_events[0]["arc"]]
				before_split_bisector.start_t = unfinished_bisectors[split_events[0]["arc"]].start_t + t
				
				var before_connect_bisector = unfinished_bisectors[split_events[0]["arc"]]
				before_connect_bisector.endpoint = verts[split_events[0]["arc"]]
				before_connect_bisector.end_t = before_connect_bisector.start_t + t
				unfinished_bisectors[split_events[0]["arc"]] = BisectorArc.new()
				unfinished_bisectors[split_events[0]["arc"]].start_t = before_connect_bisector.end_t
				unfinished_bisectors[split_events[0]["arc"]].origin = verts[split_events[0]["arc"]]
				

				var before_connect_seg1 = unfinished_bisectors[split_events[0]["segment"]]
				before_connect_seg1.endpoint = verts[split_events[0]["segment"]]
				before_connect_seg1.end_t = before_connect_bisector.start_t + t
				
				var before_connect_seg2 = unfinished_bisectors[(split_events[0]["segment"] - 1 + verts.size()) % verts.size()]
				before_connect_seg2.endpoint = verts[(split_events[0]["segment"] - 1 + verts.size()) % verts.size()]
				before_connect_seg2.end_t = before_connect_bisector.start_t + t
				
				points_before.append(before_point)
				var new_before_bisector = BisectorArc.new()
				new_before_bisector.origin = verts[split_events[0]["arc"]]
				new_before_bisector.start_t = before_connect_bisector.start_t + t
				bisectors_before.append(new_before_bisector)
				var vert_cursor = (split_events[0]["segment"] + 1) % verts.size()
				while vert_cursor != split_events[0]["arc"]:
					points_before.append(verts[vert_cursor])
					bisectors_before.append(unfinished_bisectors[vert_cursor])
					vert_cursor = (vert_cursor + 1) % verts.size()
				
				
				
				var points_after: Array[Vector2] = []
				var bisectors_after: Array[BisectorArc] = []

				vert_cursor = (split_events[0]["arc"] + 1) % verts.size()
				while vert_cursor != (split_events[0]["segment"] +1) % verts.size():
					points_after.append(verts[vert_cursor])
					bisectors_after.append(unfinished_bisectors[vert_cursor])
					vert_cursor = (vert_cursor + 1) % verts.size()
				points_after.append(after_point)
				bisectors_after.append(after_split_bisector)
				
				#print("verts ", points_before.size(), ", bisectors ", bisectors_before.size())

				
				#print("split")
#				var bisectors_before_rec := calculate(points_before, bisectors_before, on_poly_callback, current_t + t)
#				var bisectors_after_rec := calculate(points_after, bisectors_after, on_poly_callback, current_t + t)
				
				
				
				result.bisectors.append(before_connect_bisector)
				result.bisectors.append(before_connect_seg1)
				result.bisectors.append(before_connect_seg2)
				
#				result.bisectors.append_array(bisectors_before_rec.bisectors)
#				result.triangles.append_array(bisectors_before_rec.triangles)
#				result.triangle_normals.append_array(bisectors_before_rec.triangle_normals)
#				result.bisectors.append_array(bisectors_after_rec.bisectors)
#				result.triangles.append_array(bisectors_after_rec.triangles)
#				result.triangle_normals.append_array(bisectors_after_rec.triangle_normals)
				return result
			else:
				is_valid = true
					
					
		#print("@318 ", is_valid)
		if is_valid:
			var event_state := StraightSkeletonInfo.EventState.new()
			event_state.base_poly = verts
			event_state.new_shrink_events = next_events
			result.edge_events.append(event_state)

			#on_poly_callback.call(_offset_polygon_by(verts, vertex_directions, edge_normals, next_events[0].t))
			next_events.sort_custom(func (ev1, ev2): return ev1.combined_vertices[1] > ev2.combined_vertices[1])
			
			for vert_i in verts.size():
				if next_events.filter(func (x): return x.combined_vertices[0] == vert_i).size() != 0:
					continue
					
				#var face_direction = _to_3d(candidate_verts[vert_i], current_t + next_events[0].t) - ((_to_3d(verts[vert_i], current_t) + _to_3d(verts[(vert_i+1) % verts.size()], current_t)) / 2.0)
				var to_first = _to_3d(verts[vert_i], current_t) - _to_3d(candidate_verts[vert_i], current_t + next_events[0].t)
				var to_second = _to_3d(verts[(vert_i + 1) % verts.size()], current_t) - _to_3d(candidate_verts[vert_i], current_t + next_events[0].t)
				var normal = to_second.cross(to_first).normalized()
				
				result.triangles.append([
					_to_3d(verts[vert_i], current_t),
					_to_3d(verts[(vert_i + 1) % verts.size()], current_t),
					_to_3d(candidate_verts[vert_i], current_t + next_events[0].t)
				])
				result.vertex_uvs.append_array([
					Vector2(vertex_position_along_perimeter[vert_i], current_t),
					Vector2(vertex_position_along_perimeter[vert_i], current_t),
					Vector2(vertex_position_along_perimeter[vert_i], current_t + next_events[0].t),
				])
#				result.vertex_uv_addends_unscaled.append_array([
#					- side_lengths[vert_i] * 0.5,
#					side_lengths[vert_i] * 0.5,
#					-side_lengths[vert_i] * 0.5,
#				])
				result.vertex_uv_addends_unscaled.append_array([
					- side_lengths[vert_i] * 0.5,
					side_lengths[vert_i] * 0.5,
					_centered_position_along_segment(candidate_verts[vert_i], verts[vert_i] ,verts[(vert_i + 1) % verts.size()]) * side_lengths[vert_i],
				])
				
				result.vertex_uv_scales.append_array([
					original_side_lengths[vert_i],
					original_side_lengths[vert_i],
					original_side_lengths[vert_i]
				])
				result.triangle_normals.append(normal)
				result.triangle_normals.append(normal)
				
				result.triangles.append([
					_to_3d(candidate_verts[vert_i], current_t+next_events[0].t),
					_to_3d(verts[(vert_i + 1) % verts.size()], current_t),
					_to_3d(candidate_verts[(vert_i + 1) % verts.size()], current_t+next_events[0].t),
				])
				result.vertex_uvs.append_array([
					Vector2(vertex_position_along_perimeter[vert_i], current_t + next_events[0].t),
					Vector2(vertex_position_along_perimeter[vert_i], current_t),
					Vector2(vertex_position_along_perimeter[vert_i], current_t + next_events[0].t),
				])
#				result.vertex_uv_addends_unscaled.append_array([
#					-side_lengths[vert_i] * 0.5,
#					side_lengths[vert_i] * 0.5,
#					side_lengths[vert_i] * 0.5,
#				])
				result.vertex_uv_addends_unscaled.append_array([
					_centered_position_along_segment(candidate_verts[vert_i], verts[vert_i], verts[(vert_i + 1) % verts.size()]) * side_lengths[vert_i],
					side_lengths[vert_i] * 0.5,
					_centered_position_along_segment(candidate_verts[(vert_i + 1) % verts.size()], verts[vert_i], verts[(vert_i + 1) % verts.size()]) * side_lengths[vert_i],
				])
				
				result.vertex_uv_scales.append_array([
					original_side_lengths[vert_i],
					original_side_lengths[vert_i],
					original_side_lengths[vert_i]
				])
			var candidate_position_perimeter = vertex_position_along_perimeter.duplicate()
			var candidate_lengths = side_lengths.duplicate()
			var candidate_real_lengths = original_side_lengths.duplicate()
			
			#print("t is ", current_t)
			for next_event in next_events:
			
				result.triangles.append([
					_to_3d(verts[next_event.combined_vertices[0]], current_t), 
					_to_3d(verts[next_event.combined_vertices[1]], current_t),
					_to_3d(next_event.new_point, current_t + next_event.t)
				])
				result.vertex_uvs.append_array([
					Vector2(vertex_position_along_perimeter[next_event.combined_vertices[0]], current_t),
					Vector2(vertex_position_along_perimeter[next_event.combined_vertices[0]], current_t),
					Vector2(vertex_position_along_perimeter[next_event.combined_vertices[0]], current_t + next_event.t),
				])
				result.vertex_uv_addends_unscaled.append_array([
					- side_lengths[next_event.combined_vertices[0]] * 0.5,
					side_lengths[next_event.combined_vertices[0]] * 0.5,
					_centered_position_along_segment(next_event.new_point, verts[next_event.combined_vertices[0]], verts[next_event.combined_vertices[1]]) * side_lengths[next_event.combined_vertices[0]],
				])
				result.vertex_uv_scales.append_array([
					original_side_lengths[next_event.combined_vertices[0]],
					original_side_lengths[next_event.combined_vertices[0]],
					original_side_lengths[next_event.combined_vertices[0]]
				])
				var to_first = _to_3d(verts[next_event.combined_vertices[0]], current_t) - _to_3d(next_event.new_point, current_t  + next_event.t)
				var to_second = _to_3d(verts[next_event.combined_vertices[1]], current_t) - _to_3d(next_event.new_point, current_t  + next_event.t)
				
				var normal = to_second.cross(to_first).normalized()
				if next_event.combined_vertices[0] > next_event.combined_vertices[1] and next_event.combined_vertices[0] < verts.size() - 1:
					normal = to_first.cross(to_second)
				
				result.triangle_normals.append(normal)
				candidate_verts.remove_at(next_event.combined_vertices[1])
				candidate_normals.remove_at(next_event.combined_vertices[1])
				candidate_directions.remove_at(next_event.combined_vertices[1])
				candidate_is_reflex.remove_at(next_event.combined_vertices[1])
				candidate_untriangulated.remove_at(next_event.combined_vertices[1])
				candidate_position_perimeter.remove_at(next_event.combined_vertices[1])
				candidate_lengths.remove_at(next_event.combined_vertices[1])
				candidate_real_lengths.remove_at(next_event.combined_vertices[1])
				
				
				for v in next_event.combined_vertices:
					var bisector = unfinished_bisectors[v]
					bisector.endpoint = next_event.new_point
					bisector.end_t = bisector.start_t + next_event.t
					result.bisectors.append(bisector)
				var new_bisector = BisectorArc.new()
				new_bisector.origin = next_event.new_point
				new_bisector.start_t = result.bisectors[-1].end_t
				unfinished_bisectors[next_event.combined_vertices[0]] = new_bisector
				candidate_bisectors.remove_at(next_event.combined_vertices[1])
				
			
			
			
			#on_edge_callback.call(next_event.new_point)
			
#			for vert_i in candidate_verts.size():
#				# edge <=> vertex to next vertex
#				var edge_dir := (candidate_verts[(vert_i + 1) % candidate_verts.size()] - candidate_verts[vert_i]).normalized()
#				var edge_normal := Vector2(edge_dir.y, -edge_dir.x)
#				edge_normals[vert_i] = -edge_normal
#				vertex_directions[vert_i] = -_travel_direction(candidate_verts[(vert_i - 1 + candidate_verts.size()) % candidate_verts.size()], candidate_verts[vert_i], candidate_verts[(vert_i + 1) % candidate_verts.size()])
#				var prev = candidate_verts[(vert_i - 1 + candidate_verts.size()) % candidate_verts.size()]
#				var curr = candidate_verts[vert_i]
#				var next = candidate_verts[(vert_i + 1) % candidate_verts.size()]
#				#vertex_is_reflex.append(true)
#				candidate_is_reflex[vert_i] = (curr - prev).angle_to(next - curr) < 0
			if Geometry2D.is_polygon_clockwise(candidate_verts):
				#print("reversing")
				candidate_verts.reverse()
				candidate_normals.reverse()
				candidate_directions.reverse()
				candidate_is_reflex.reverse()
				candidate_bisectors.reverse()
				candidate_untriangulated.reverse()
				candidate_position_perimeter.reverse()
				candidate_lengths.reverse()
				candidate_real_lengths.reverse()
				
			
			verts = candidate_verts
			edge_normals = candidate_normals
			vertex_directions = candidate_directions
			vertex_is_reflex = candidate_is_reflex
			unfinished_bisectors = candidate_bisectors
			last_untriangulated = candidate_untriangulated
			vertex_position_along_perimeter = candidate_position_perimeter
			side_lengths = candidate_lengths
			original_side_lengths = candidate_real_lengths
			current_t += next_events[0].t
			result.max_t = current_t
			to_remove = []
			for vert_i in verts.size():
				# edge <=> vertex to next vertex
				var edge_dir := (verts[(vert_i + 1) % verts.size()] - verts[vert_i]).normalized()
				var edge_normal := Vector2(edge_dir.y, -edge_dir.x)
				edge_normals[vert_i] = -edge_normal
				vertex_directions[vert_i] = -_travel_direction(verts[(vert_i - 1 + verts.size()) % verts.size()], verts[vert_i], verts[(vert_i + 1) % verts.size()])
#				if abs(vertex_directions[vert_i].angle_to(edge_normals[vert_i])) < 0.1:
#					to_remove.append(vert_i)
				var prev = verts[(vert_i - 1 + verts.size()) % verts.size()]
				var curr = verts[vert_i]
				var next = verts[(vert_i + 1) % verts.size()]
				#vertex_is_reflex.append(true)
				vertex_is_reflex[vert_i] = (curr - prev).angle_to(next - curr) < 0
			
			to_remove.reverse()
			for remove_i in to_remove:
				verts.remove_at(remove_i)
				edge_normals.remove_at(remove_i)
				vertex_directions.remove_at(remove_i)
				vertex_is_reflex.remove_at(remove_i)
				unfinished_bisectors.remove_at(remove_i)
				last_untriangulated.remove_at(remove_i)
			
			var new_perimeter = 0.0
			var new_lengths = []
			for vert_i in verts.size():
				var seg_length = verts[vert_i].distance_to(verts[(vert_i + 1) % verts.size()])
				new_perimeter += seg_length
				new_lengths.append(seg_length)
			for side_i in side_lengths.size():
				side_lengths[side_i] = (new_lengths[side_i] / new_perimeter) * (new_perimeter / perimeter_length)
			
			#verts = _offset_polygon_by(verts, vertex_directions, edge_normals, -0.1)
			#print("edge event ", verts)
			#on_poly_callback.call(verts)
			#return result
			
					

	#verts = _offset_polygon_by(verts, vertex_directions, edge_normals, 10)
	

	return result


static func get_mesh(footprint: Array[Vector2], max_height: float, material: Material, initial_offset: float)->ArrayMesh:
	var mesh := ArrayMesh.new()
	var scaled_footprint: Array[Vector2]
	var offset_footprint = Geometry2D.offset_polygon(footprint, initial_offset)[0]
	scaled_footprint.assign(offset_footprint)
	scaled_footprint.assign(scaled_footprint.map(func (x): return x * 200)) 
	var skeleton_result := calculate(scaled_footprint)
	var tri_verts = []
	var tri_norms = []
	var tri_uvs = skeleton_result.vertex_uvs
	for t_i in skeleton_result.triangles.size():
		var t = skeleton_result.triangles[t_i]
		tri_verts.append_array(t)
		tri_norms.append_array([skeleton_result.triangle_normals[t_i], skeleton_result.triangle_normals[t_i], skeleton_result.triangle_normals[t_i]])
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var overall_length = 0.0
	for vert_i in footprint.size():
		overall_length += footprint[vert_i].distance_to(footprint[(vert_i + 1) % footprint.size()])
	overall_length /= 4
	#print(res.max_t)
	for p_i in tri_verts.size():
		var p = tri_verts[p_i]
		#st.set_normal(tri_norms[p_i])
		
		#print("uvx addn t=", tri_uvs[p_i].y," addend=",res.vertex_uv_addends_unscaled[p_i]," becomes=", Vector2(tri_uvs[p_i].x + res.vertex_uv_addends_unscaled[p_i] * (1 - (tri_uvs[p_i].y / res.vertex_uv_scales[p_i])), tri_uvs[p_i].y / res.vertex_uv_scales[p_i]))
		st.set_uv(Vector2(tri_uvs[p_i].x * overall_length + skeleton_result.vertex_uv_addends_unscaled[p_i] * overall_length, tri_uvs[p_i].y / (skeleton_result.max_t)))# * (1 - (tri_uvs[p_i].y / (res.vertex_uv_scales[p_i] * 0.5))), tri_uvs[p_i].y / (res.max_t)))
		p.y = (p.y / skeleton_result.max_t) * max_height
		p.x /= 200
		p.z /= 200
		st.add_vertex(p)
	st.generate_normals()

	var bottom_surf = Geometry2D.triangulate_polygon(offset_footprint)
	bottom_surf.reverse()
	for v_i in bottom_surf:
		st.set_uv(offset_footprint[v_i])
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(offset_footprint[v_i].x, 0, offset_footprint[v_i].y))
	st.generate_tangents()
	st.commit(mesh)
	mesh.surface_set_material(0, material)
	return mesh