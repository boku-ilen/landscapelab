extends FeatureLayerCompositionRendererMultiMesh


#
# Repeated objects along a line - can be used for e.g. Hedges
# Objects will be placed with predefined width from one another
#
# Notes:
# - To remove the repetitiveness of the mesh it will be randomly rotated
# - Extends the multimesh feature layer to drastically improve performance
#


var multimeshes := {}


func _ready():
	mutex.lock()
	_load_meshes()
	mutex.unlock()
	super._ready()
	max_features = 500
	radius = 120.0


func _load_meshes():
	# FIXME: Does adding multiple multimeshes drastically decrease performance?
	# FIXME: If so use different custom data and read according texture in shader 
	for key in layer_composition.render_info.meshes.keys():
		var multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.multimesh = MultiMesh.new()
		multimesh_instance.multimesh.set_transform_format(MultiMesh.TRANSFORM_3D)
		multimesh_instance.multimesh.mesh = load(layer_composition.render_info.meshes[key])
		multimesh_instance.set_layer_mask_value(1, false)
		multimesh_instance.set_layer_mask_value(3, true)
		multimeshes[key] = multimesh_instance
		add_child(multimesh_instance)


func apply_new_data():
	mutex.lock()
	# Set the instance count to all cummulated vertecies
	var intermediate_transforms = _calculate_intermediate_transforms()
	
	# Reset
	var attribute_name = layer_composition.render_info.selector_attribute_name
	var compare_type = func(type: String, f: GeoFeature): 
		return f.get_attribute(attribute_name) == type
	
	var indices = {}
	for key in layer_composition.render_info.meshes.keys():
		var filtered_features = features.filter(func(f): return compare_type.call(key, f))
		
		var instance_count = filtered_features.reduce(func(accum, f):
			return accum + intermediate_transforms[f.get_id()].size(), 0
		)

		multimeshes[key].multimesh.instance_count = instance_count
		indices[key] = 0
	
	for f in features:
		for t in intermediate_transforms[f.get_id()]:
			var type = f.get_attribute(attribute_name)
			multimeshes[type].multimesh.set_instance_transform(indices[type], t)
			indices[type] += 1
	
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
	
	for multimesh in multimeshes.values():
		multimesh.set_custom_aabb(AABB(begin, size))


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
			try_look_at_from_pos(current_object, current_point, previous_point)

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
			try_look_at_from_pos(current_object, current_point, next_point)

		# Only y rotation is relevant
		current_object.rotation.x = 0
		current_object.rotation.z = 0

		previous_point = current_point
		# Prevent error p_elem->root != this ' is true via call_deferred
		line_root.add_child(current_object)

	return line_root


func _calculate_intermediate_transforms():
	var transforms := {}
	for feature in features:
		var f_id = feature.get_id()
		var vertices: Curve3D = feature.get_curve3d()
		var starting_point: Vector3 = instances[f_id].get_child(0).position
		var end_point: Vector3
		var get_ground_height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
		
		var t: Transform3D
		transforms[f_id] = []
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
				
				transforms[f_id].append(t)
			
			starting_point = end_point
	
	return transforms


# https://github.com/godotengine/godot/blob/4.0.1-stable/scene/resources/curve.cpp#L1784
# avoid "look_at_from_position: Node origin and target are in the same position, look_at() failed."
func try_look_at_from_pos(object: Node3D, from: Vector3, target: Vector3):
	if not from.is_equal_approx(target) and not target.is_equal_approx(Vector3.ZERO):
		object.position = from
		object.look_at_from_position(from, target, object.transform.basis.y)
	else:
		object.position = from


func _get_height_at_ground(query_position: Vector3) -> float:
	return layer_composition.render_info.ground_height_layer.get_value_at_position(
		center[0] + query_position.x, center[1] - query_position.z)


func get_debug_info() -> String:
	return ""
