extends FeatureLayerCompositionRendererMultiMesh


#
# Repeated objects along a line - can be used for e.g. Hedges
# Objects will be placed with predefined width from one another
#
# Notes:
# - To remove the repetitiveness of the mesh it will be randomly rotated
# - Extends the multimesh feature layer to drastically improve performance
#

func _ready():
	super._ready()

	max_features = 500
	
	radius = 120.0


func apply_new_data():
	mutex.lock()
	# Set the instance count to all cummulated vertecies
	var intermediate_transforms = _calculate_intermediate_transforms()
	
	multimesh.instance_count = features.reduce(
		func(i, f): return i + f.get_curve3d().get_point_count(), 0) + intermediate_transforms.size()
	
	var current_index := 0
	for t in intermediate_transforms:
		multimesh.set_instance_transform(current_index, t)
		current_index += 1
	
	build_aabb()
	mutex.unlock()
	
	super.apply_new_data()


func build_aabb():
	var begin = Vector3(INF, INF, INF)
	var end = Vector3(-INF, -INF, -INF)
	
	var height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
	
	for feature in features:
		for vert_id in feature.get_curve3d().get_point_count():
			var t: Transform3D = instances[feature.get_id()].get_child(vert_id).transform
			begin.x = min(begin.x, t.origin.x)
			begin.y = min(begin.y, t.origin.y)
			begin.z = min(begin.z, t.origin.z)
			end.x = max(end.x, t.origin.x)
			end.y = max(end.y, t.origin.y)
			end.z = max(end.z, t.origin.z)
	
	begin.y -= 10
	end.y += 10
	var size = abs(end - begin)
	$MultiMeshInstance3D.set_custom_aabb(AABB(begin, size))


# Although we use a multimesh, we load the transforms via nodes as they drastically
# simplify some matrix calculations
func load_feature_instance(geo_line: GeoFeature) -> Node3D:
	var line_root = Node3D.new()
	line_root.name = str(geo_line.get_id())

	var engine_line: Curve3D = geo_line.get_offset_curve3d(-center[0], 0, -center[1])
	var previous_point := Vector3.INF
	var next_point := Vector3.INF

	for index in range(engine_line.get_point_count()):
		# Obtain current point and its height 
		var current_point = engine_line.get_point_position(index)
		current_point.y = _get_height_at_ground(current_point)

		# Try to obtain the next point on the line
		if index+1 < engine_line.get_point_count():
			next_point = engine_line.get_point_position(index + 1)
			next_point.y = _get_height_at_ground(next_point)

		# Create a specified connector-object or use fallback
		var current_object := Node3D.new()

		#
		# Try to resemble a realistic rotation of the connector-objects  
		# (i.e. they have to face each other); 3 cases:
		# 1. First point, only next point exists
		# 2. x_i; i > 0 & i < n; previous and next point exist
		# 3. Last point, only previous point exists
		# 

		# Case 1 or 2 
		if previous_point != Vector3.INF:
			current_object.look_at_from_position(current_point, previous_point, current_object.transform.basis.y)

			# Case 2 
			if index+1 < engine_line.get_point_count():
				# Find the angle between (p_before - p_now) and (p_now - p_next)
				var v1 = current_point - previous_point
				var v2 = next_point - current_point
				var angle = v1.signed_angle_to(v2, Vector3.UP)
				# add this angle so its actually the mean between before and next
				current_object.rotation.y += angle / 2

		# Case 3
		elif index+1 < engine_line.get_point_count():
			current_object.look_at_from_position(current_point, next_point, current_object.transform.basis.y)

		# Only y rotation is relevant
		current_object.rotation.x = 0
		current_object.rotation.z = 0

		previous_point = current_point
		# Prevent error p_elem->root != this ' is true via call_deferred
		line_root.add_child(current_object)

	return line_root


func _calculate_intermediate_transforms():
	var transforms := []
	for feature in features:
		var f_id = feature.get_id()
		var vertices: Curve3D = feature.get_curve3d()
		var starting_point: Vector3 = instances[f_id].get_child(0).position
		var end_point: Vector3
		var get_ground_height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
		
		var t: Transform3D
		for v_id in range(1, vertices.get_point_count()):
			t = instances[f_id].get_child(v_id).transform
			end_point = instances[f_id].get_child(v_id).position
			
			var distance = starting_point.distance_to(end_point)
			var width = 0.8
			var num_between = ceil(distance / width)
			var direction = end_point.direction_to(starting_point)
			
			t.basis.z = -direction
			
			var rand_angle := 0.0
			for i in range(num_between):
				var pos = t.origin + width * direction
				# Randomly add 90, 180 or 270 degrees to previous rotation
				var pseudo_random = int(pos.x + pos.z)
				rand_angle = rand_angle + (PI / 2.0) * ((pseudo_random % 3) + 1.0)
				t = t.rotated_local(Vector3.UP, rand_angle)
				t.origin = pos
				
				# Set the mesh on ground and add some buffer for uneven grounds
				t.origin.y = get_ground_height_at_pos.call(
					center[0] + t.origin.x, center[1] - t.origin.z) - 0.2 
				
				transforms.append(t)
			
			starting_point = end_point
	
	return transforms


func _get_height_at_ground(query_position: Vector3) -> float:
	return layer_composition.render_info.ground_height_layer.get_value_at_position(
		center[0] + query_position.x, center[1] - query_position.z)


func get_debug_info() -> String:
	return ""
