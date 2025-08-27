extends Resource
class_name ConcaveHull

# Credits to https://www.youtube.com/watch?v=34dNx4kaLjw&t=2730s

static var triangle_was_removed = false
const MAX_STEPS = 100000


static func get_hulls(points: Array[Vector2]):
	var tris = generate_concave_tris(points)
	var boundaries = get_boundaries(tris)
	boundaries = order_boundaries(boundaries)
	return remove_redundant(boundaries)

### ---- BOUNDARY PROCESSING ---- ###

static func remove_redundant(boundaries: Array) -> Array:
	if boundaries.size() < 3:
		return boundaries
	
	var result = []
	var n = boundaries.size()
	
	for i in range(n):
		var prev = boundaries[(i - 1 + n) % n]
		var current = boundaries[i]
		var next = boundaries[(i + 1) % n]
	
		if not is_equal_approx(prev.direction_to(current).x, current.direction_to(next).x) \
			and not is_equal_approx(prev.direction_to(current).y, current.direction_to(next).y):
				result.append(current)
	
	return result

static func order_boundaries(boundaries: Array) -> Array:
	var ordered = []
	var start = boundaries.pop_front()[1]
	var from = start
	var line_no = 0
	ordered.append([start])

	for _i in range(MAX_STEPS):
		var to = null
		var delete_border = null
		
		for border in boundaries:
			if from in border:
				to = border[1] if from == border[0] else border[0]
				delete_border = border
		
		if to == null:
			ordered[line_no].append(start)
			if boundaries:
				start = boundaries.pop_front()[1]
				from = start
				line_no += 1
				ordered.append([start])
			else:
				break
		else:
			boundaries.erase(delete_border)
			ordered[line_no].append(to)
			from = to
	
	return ordered

### ---- TRIANGLE GENERATION ---- ###

static func generate_concave_tris(points: PackedVector2Array):
	triangle_was_removed = false
	var triangles = get_delaunay_triangles(points)
	var boundaries = get_boundaries(triangles)
	var boundary_triangles = get_boundary_triangles(triangles, boundaries)
	var concave_points = get_concave_points(points, boundaries)

	var current_index = 0
	
	while concave_points:
		var concave_point = concave_points[current_index]
		var concave_triangles = get_concave_triangles(concave_point, boundary_triangles)
		
		while concave_triangles:
			triangles = remove_triangles(triangles, concave_triangles, boundaries)
			
			if triangle_was_removed:
				boundaries = get_boundaries(triangles)
				boundary_triangles = get_boundary_triangles(triangles, boundaries)
				concave_points = get_concave_points(points, boundaries)
				current_index = 0
			break
		
		if triangle_was_removed:
			triangle_was_removed = false
		
		if current_index + 1 == concave_points.size():
			return triangles
				
		if current_index + 1 < concave_points.size():
			current_index += 1
		else:
			current_index = 0

	return triangles

static func get_delaunay_triangles(points: PackedVector2Array) -> Array:
	var triangulate = Geometry2D.triangulate_delaunay(points)
	var triangles = []
	
	for i in range(triangulate.size() / 3):
		var triangle = PackedVector2Array()
		for n in range(3):
			var point = points[triangulate[(i * 3) + n]]
			triangle.append(Vector2(point.x, point.y))
		triangles.append(triangle)

	return triangles

static func get_boundaries(triangles: Array) -> Array:
	var edges = []
	var edge_occurrences = {}

	for triangle in triangles:
		for i in range(3):
			var edge = [triangle[i], triangle[(i + 1) % 3]]
			edge.sort()
			edges.append(edge)

	for edge in edges:
		edge_occurrences[edge] = edge_occurrences.get(edge, 0) + 1

	var outer_edges = []
	for key in edge_occurrences.keys():
		if edge_occurrences[key] == 1:
			outer_edges.append(key)

	return outer_edges

static func get_boundary_triangles(triangles: Array, boundaries: Array) -> Array:
	var boundary_triangles = []
	for triangle in triangles:
		for i in range(3):
			var edge = [triangle[i], triangle[(i + 1) % 3]]
			edge.sort()
			if boundaries.has(edge):
				boundary_triangles.append(triangle)
	return boundary_triangles

static func get_concave_points(points: Array, boundaries: Array) -> Array:
	var concave_points = []
	var sorted_points = sort_vertices(boundaries)
	var sorted_edges = sort_edges(sorted_points)
	var deflated_shape = scale_points_by_normals(sorted_points, sorted_edges, -0.1)

	for point in points:
		if Geometry2D.is_point_in_polygon(point, deflated_shape):
			concave_points.append(point)

	return concave_points

static func get_concave_triangles(concave_point: Vector2, boundary_triangles: Array) -> Array:
	var concave_triangles = []
	for triangle in boundary_triangles:
		if triangle.has(concave_point):
			concave_triangles.append(triangle)
	return concave_triangles

### ---- EDGE PROCESSING ---- ###

static func sort_vertices(boundaries: Array) -> Array:
	var vertices = []
	for edge in boundaries:
		for vert in edge:
			if not vertices.has(vert):
				vertices.append(vert)

	var center = vertices.reduce(func(sum, v): return sum + v, Vector2.ZERO) / vertices.size()
	var angles = {}
	for vertex in vertices:
		angles[vertex] = atan2(vertex.y - center.y, vertex.x - center.x)

	vertices.sort_custom(func(v1, v2): return angles[v1] < angles[v2])
	return vertices

static func sort_edges(sorted_points: Array) -> Array:
	var sorted_edges = []
	for i in range(sorted_points.size()):
		sorted_edges.append([sorted_points[i], sorted_points[(i + 1) % sorted_points.size()]])
	return sorted_edges

static func scale_points_by_normals(sorted_points: Array, sorted_edges: Array, scale_factor: float) -> Array:
	var vertex_normals = get_vertex_normals(sorted_points, sorted_edges)
	var scaled_points = []
	for i in range(sorted_points.size()):
		scaled_points.append(sorted_points[i] + vertex_normals[i] * scale_factor)
	return scaled_points

static func get_vertex_normals(sorted_points: Array, sorted_edges: Array) -> Array:
	var vertex_normals = []
	var edge_normals = sorted_edges.map(func(edge): return get_edge_normal(edge))
	
	for i in range(sorted_points.size()):
		var prev_index = (i - 1 + sorted_edges.size()) % sorted_edges.size()
		var vertex_normal = (edge_normals[prev_index] + edge_normals[i]).normalized()
		vertex_normals.append(vertex_normal)

	return vertex_normals

static func get_edge_normal(edge: Array) -> Vector2:
	var direction = edge[1] - edge[0]
	return Vector2(-direction.y, direction.x).normalized()

### ---- TRIANGLE REMOVAL ---- ###

static func remove_triangles(triangles: Array, concave_triangles: Array, boundaries: Array) -> Array:
	for triangle in concave_triangles:
		if triangle_was_removed:
			break

		var edge_hashes = []
		var boundary_edge = null
		
		for i in range(3):
			var edge = [triangle[i], triangle[(i + 1) % 3]]
			edge.sort()
			edge_hashes.append(hash("%s_%s" % [edge[0], edge[1]]))
			if boundaries.has(edge):
				boundary_edge = edge

		if boundary_edge:
			var boundary_edge_hash = hash("%s_%s" % [boundary_edge[0], boundary_edge[1]])
			var boundary_edge_length
			var other_edges = edge_hashes.filter(func(e): return e != boundary_edge_hash)

	return triangles
