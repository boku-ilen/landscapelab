extends Node
class_name AlphaShaper

func concave_hull(points: Array, alpha: float = 10.0) -> Array:
	if points.size() < 4:
		return []  # Not enough points to form a concave hull

	var edges = {}  # Stores all unique edges
	var perimeter_edges = {}  # Tracks the final boundary edges

	# Step 1: Compute Delaunay triangulation and filter triangles by alpha
	var alpha_simplices = get_alpha_simplices(points)
	
	for indices_radii in alpha_simplices:
		var indices = indices_radii[0]  # Triangle vertex indices
		var radius = indices_radii[1]  # Triangle circumradius

		# Debug: Check alpha filtering
		print("Triangle: ", indices, ", Circumradius: ", radius, ", Alpha: ", 1.0 / alpha)
		
		# Alpha condition (smaller radius means tighter fit)
		if radius < 1.0 / alpha:
			for edge in get_combinations(indices, 2):  # Extract triangle edges
				var edge_tuple = edge.duplicate()
				
				# Step 2: Check if this edge is unique or already exists
				if not edges.has(edge_tuple):
					edges[edge_tuple] = true
					perimeter_edges[edge_tuple] = true
				else:
					perimeter_edges.erase(edge_tuple)  # Remove duplicate edges
	
	# Debug: Check if edges exist
	print("Final Perimeter Edges:", perimeter_edges.keys())

	# Step 3: Convert edge indices into actual Vector2 points
	var edge_points = []
	for edge in perimeter_edges.keys():
		edge_points.append(edge.map(func(index): return points[index]))

	return edge_points
	# Step 4: Polygonize edges into a closed shape
	return polygonize_edges(edge_points)


func get_alpha_simplices(points: Array) -> Array:
	var triangles = Delaunator.new(points).triangles
	var simplex_indices_array = []

	# Extract triangles from the Delaunay structure
	for i in range(0, triangles.size(), 3):
		simplex_indices_array.append([
			triangles[i],
			triangles[i + 1],
			triangles[i + 2]
		])

	# Compute circumradii for each triangle
	var indices_circumradii = []
	for simplex_indices in simplex_indices_array:
		var simplex_points = simplex_indices.map(func(index): return points[index])
		indices_circumradii.append([simplex_indices, circumradius(simplex_points)])

	return indices_circumradii


func polygonize_edges(edges: Array) -> Array:
	"""
	Manually reconstruct polygons from a list of edges.
	Equivalent to `polygonize()` in Shapely.
	"""
	var polygons = []
	var used_edges = {}
	
	print(edges)

	for edge in edges:
		used_edges[edge] = false

	for edge in edges:
		if used_edges[edge]:
			continue

		var polygon = []
		var current_edge = edge
		var start_point = edge[0]

		while true:
			polygon.append(current_edge[0])
			used_edges[current_edge] = true

			var next_edge = null
			for e in edges:
				if not used_edges[e] and e[0] == current_edge[1]:
					next_edge = e
					break
				elif not used_edges[e] and e[1] == current_edge[1]:
					next_edge = [e[1], e[0]]  # Reverse edge
					break

			if next_edge == null or next_edge[1] == start_point:
				polygon.append(current_edge[1])
				polygons.append(polygon)
				break

			current_edge = next_edge

	return polygons


func get_combinations(arr: Array, r: int) -> Array:
	"""
	Generate all possible combinations of `r` elements from `arr`.
	Equivalent to Python's itertools.combinations.
	"""
	if r == 0:
		return [[]]
	if arr.is_empty():
		return []

	var result = []
	for i in range(arr.size()):
		var elem = arr[i]
		var rest_combinations = get_combinations(arr.slice(i + 1), r - 1)
		for comb in rest_combinations:
			result.append([elem] + comb)

	return result


func circumradius(points: Array) -> float:
	if points.size() < 2:
		push_error("At least two points are required to compute circumradius.")
		return 0.0

	var center = circumcenter(points)
	return points[0].distance_to(center)


func circumcenter(points: Array) -> Vector2:
	if points.size() < 2:
		push_error("At least two points are required to compute circumcenter.")
		return Vector2.ZERO

	var num_rows = points.size()
	
	# Build matrix A
	var A = []
	for i in range(num_rows):
		var row = []
		for j in range(num_rows):
			row.append(2 * points[i].dot(points[j]))  # 2 * dot product
		row.append(1.0)  # Extra column for ones
		A.append(row)

	# Add last row of ones
	var last_row = []
	for _i in range(num_rows):
		last_row.append(1.0)
	last_row.append(0.0)  # Bottom-right corner is zero
	A.append(last_row)

	# Construct vector b
	var b = []
	for i in range(num_rows):
		b.append(points[i].dot(points[i]))  # Sum of squared coordinates
	b.append(1.0)

	# Solve Ax = b using Gaussian elimination
	var solution = _solve_linear_system(A, b)
	
	if solution == null:
		push_error("Failed to solve for circumcenter.")
		return Vector2.ZERO
	
	return _barycentric_to_cartesian(points, solution)


func _barycentric_to_cartesian(points: Array, weights: Array) -> Vector2:
	var result = Vector2.ZERO
	for i in range(points.size()):
		result += points[i] * weights[i]
	return result


func _solve_linear_system(A: Array, b: Array) -> Array:
	var n = b.size()
	var augmented_matrix = []

	# Create augmented matrix
	for i in range(n):
		augmented_matrix.append(A[i] + [b[i]])

	# Gaussian elimination
	for i in range(n):
		if abs(augmented_matrix[i][i]) < 1e-10:
			return []  # Singular matrix

		var scale = augmented_matrix[i][i]
		for j in range(n + 1):
			augmented_matrix[i][j] /= scale

		for k in range(n):
			if k != i:
				var factor = augmented_matrix[k][i]
				for j in range(n + 1):
					augmented_matrix[k][j] -= factor * augmented_matrix[i][j]

	# Extract solution
	var solution = []
	for i in range(n):
		solution.append(augmented_matrix[i][n])

	return solution
