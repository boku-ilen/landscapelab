extends LayerCompositionConnection
class_name OutlinePolygon


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
	# 1. Filter new features for a set "outline" field to create a barrier around it
	# 2. Obtain the nodes from renderer with outline set
	var relevant_new = new_features \
			.filter(func(feature: GeoFeature): 
				return feature.get_attribute("outline") != "") \
			.map(func(f: GeoFeature): 
				return source_composition.render_info.render_scene.get_node(var_to_str(f.get_id())))
	var relevant_old = removed_features \
			.filter(func(feature: GeoFeature): 
				return feature.get_attribute("outline") != "") \
			.map(func(f: GeoFeature): 
				return source_composition.render_info.render_scene.get_node(var_to_str(f.get_id())))
	return {"new": relevant_new, "removed": relevant_old}


func apply_to_target(target: LayerComposition, parent_nodes: Variant):
	var new_parents = parent_nodes["new"]
	var removed_parents = parent_nodes["removed"]
	
	# FIXME: this does not appear to work yet
	for parent in removed_parents:
		var feature_id = parent.name
		var line_layer: GeoFeatureLayer = target.render_info.geo_feature_layer
		line_layer.remove_feature(line_layer.get_feature_by_id(str_to_var(feature_id)))
	
	for parent in new_parents:
		var node_positions = parent.get_children().map(
			func(c: Node): return Vector2(c.position.x, c.position.z))
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
		
		var hulls = ConcaveHull.get_hulls(node_positions_typed)
		
		var line_layer: GeoFeatureLayer = target.render_info.geo_feature_layer
		var height_layer: GeoRasterLayer = target.render_info.ground_height_layer
		var center = target.render_info.render_scene.center
		for hull in hulls:
			var directions = GeometryUtil.get_polygon_vertex_directions(hull)
			var offset_verts = GeometryUtil.offset_polygon_vertices(hull, directions, -source_composition.render_info.render_scene.offset)
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
