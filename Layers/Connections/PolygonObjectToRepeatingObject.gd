extends LayerCompositionConnection
class_name PolygonObjectToRepeatingObject


var instanced_geo_lines := {}


func _build_grid_from_names(node_names: Array) -> Dictionary:
	var grid = {}
	
	for node_name in node_names:
		var x = node_name.split("_")[0]
		var y = node_name.split("_")[1]
		
		if not x in grid:
			grid[x] = {}
		
		grid[x][y] = true
	
	return grid


func _count_neighbors(grid: Dictionary) -> Dictionary:
	var neighbor_counts = {}
	
	# Define possible neighbor offsets (direct + diagonal)
	var offsets = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), # Top row (left, center, right)
		Vector2(-1, 0),                  Vector2(1, 0),  # Middle row (left, right)
		Vector2(-1, 1),  Vector2(0, 1),  Vector2(1, 1)   # Bottom row (left, center, right)
	]

	for x in grid.keys():
		for y in grid[x].keys():
			var pos := Vector2(int(x), int(y))
			var count := 0

			for offset in offsets:
				var nx = str(int(pos.x + offset.x))
				var ny = str(int(pos.y + offset.y))

				# Ensure the neighbor exists in the grid
				if grid.has(nx) and grid[nx].has(ny):
					count += 1

			# Store neighbor counts
			if not neighbor_counts.has(x):
				neighbor_counts[x] = {}
			
			neighbor_counts[x][y] = count

	return neighbor_counts


func _filter_grid_by_num_neighbors(grid, neighbor_counts, num_neighbors: int):
	for x in neighbor_counts.keys():
		for y in neighbor_counts[x].keys():
			if neighbor_counts[x][y] <= num_neighbors:
				grid[x].erase(y)


func extract_relevant_data(source: LayerComposition, 
							new_features: Array, 
							removed_features: Array) -> Variant:
	# Filter new features for a set "outline" field to create a barrier around it
	var relevant_new = new_features.filter(func(feature: GeoFeature): 
				return feature.get_attribute("outline") != "")
	var relevant_old = removed_features
	return {"new": relevant_new, "removed": relevant_old}


func apply_to_target(target: LayerComposition, features: Variant):
	var new_features = features["new"]
	var removed_features = features["removed"]
	
	# Remove all outdated features
	for feature in removed_features:
		var line_layer: GeoFeatureLayer = target.render_info.geo_feature_layer
		
		var feature_id = feature.get_id()
		if feature_id in instanced_geo_lines:
			var geo_line = instanced_geo_lines[feature_id]
			line_layer.remove_feature(geo_line)
	
	# Create new features
	for feature in new_features:
		# Obtain the source composition parent node for the feature
		var parent = source_composition.render_info.renderer_instance.get_node(
			var_to_str(feature.get_id()))
		# Obtain all positions of the set objects in this parent node
		var node_positions = parent.get_children().map(
			func(c: Node): return Vector2(c.position.x, c.position.z))
		
		# Statically typed arrays in godot require this
		var node_positions_typed: Array[Vector2]
		node_positions_typed.assign(node_positions)
		# TODO: try large areas and see whether filtering the nodes improves performance
		# TODO: otherwise we might also remove the node-naming in RepeatingObjectRenderer.spiral()
		#var node_names = parent.get_children().map(func(c: Node): return c.name)
		#var grid = _build_grid_from_names(node_names)
		#var neighbor_counts = _count_neighbors(grid)
		#_filter_grid_by_num_neighbors(grid, neighbor_counts, 4)
		#var relevant_positions = []
		#for x in grid.keys():
			#for y in grid[x].keys():
				#pass#relevant_positions.append(parent.get_node("%f_%f" % [x, y]).position)
		
		# Calculate concave hull boundary
		var hulls = ConcaveHull.get_hulls(node_positions_typed)
		
		var line_layer: GeoFeatureLayer = target.render_info.geo_feature_layer
		var height_layer: GeoRasterLayer = target.render_info.ground_height_layer
		var center = target.render_info.renderer_instance.center
		
		for hull in hulls:
			# Offset the boundary so it does not intersect with the objects
			var directions = GeometryUtil.get_polygon_vertex_directions(hull)
			var offset = source_composition.render_info.renderer_instance.offset
			if Geometry2D.is_polygon_clockwise(directions): offset *= -1
			
			var offset_verts = GeometryUtil.offset_polygon_vertices(
				hull, directions, offset)
			
			# Create geoline and its underlying curve3d
			var curve := Curve3D.new()
			curve.bake_interval = 0.
			for point in hull: 
				curve.add_point(Vector3(
					point.x, 
					height_layer.get_value_at_position(
						center[0] + point.x,
						center[1] - point.y),
					-point.y)
				)
			
			var geo_line = line_layer.create_feature()
			geo_line.set_offset_curve3d(curve, center[0], 0, center[1])
			
			# Now set the attribute for the hedge from the activation point
			geo_line.set_attribute(
				target_composition.render_info.selector_attribute_name, 
				feature.get_attribute("outline")
			)
			
			# Store the geo_line to delete when the feature is deleted
			instanced_geo_lines[feature.get_id()] = geo_line
	
	target.render_info.renderer_instance.full_load()
