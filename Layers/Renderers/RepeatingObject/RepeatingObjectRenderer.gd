extends LayerCompositionRenderer


#
# Repeated objects along a line - can be used for e.g. Hedges
# Objects will be placed with predefined width from one another
#
# Notes:
# - To remove the repetitiveness of the mesh it will be randomly rotated
# - Extends the multimesh feature layer to drastically improve performance
#


var multimeshes := {}


# Define variables for loading features
var mutex = Mutex.new()
var features := []
var load_features := []
var radius = 120.0
var max_features = 500


func _ready():
	if layer_composition.render_info.get("radius"):
		radius = layer_composition.render_info.radius
	mutex.lock()
	_load_meshes()
	mutex.unlock()
	super._ready()


func full_load():
	super.full_load()
	
	mutex.lock()
	features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]), float(center[1]), radius, max_features)
	mutex.unlock()


func adapt_load(_diff: Vector3):
	super.adapt_load(_diff)
	
	mutex.lock()
	var new_features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]) + position_manager.center_node.position.x,
		float(center[1]) - position_manager.center_node.position.z,
		radius, max_features
	)
	
	var old_feature_ids = features.map(func(f): return f.get_id())
	load_features = new_features.filter(func(f): return not f.get_id() in old_feature_ids)
	features = new_features
	mutex.unlock()
	
	call_deferred("apply_new_data")


func _load_meshes():
	# FIXME: Does adding multiple multimeshes drastically decrease performance?
	# FIXME: If so use different custom data and read according texture in shader 
	for key in layer_composition.render_info.meshes.keys():
		var multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.multimesh = MultiMesh.new()
		multimesh_instance.multimesh.set_transform_format(MultiMesh.TRANSFORM_3D)
		multimesh_instance.multimesh.mesh = load(layer_composition.render_info.meshes[key]["path"])
		multimesh_instance.set_layer_mask_value(1, false)
		multimesh_instance.set_layer_mask_value(3, true)
		multimeshes[key] = multimesh_instance
		add_child(multimesh_instance)


func apply_new_data():
	mutex.lock()
	# Set the instance count to all cummulated vertecies
	var intermediate_transforms = _calculate_intermediate_transforms()
	
	var attribute_name = layer_composition.render_info.selector_attribute_name
	var indices = {}
	for key in layer_composition.render_info.meshes.keys():
		var filtered_features = features.filter(func(f): return f.get_attribute(attribute_name) == key) \
				if not layer_composition.render_info.selector_attribute_name.is_empty() else features
		
		var instance_count = filtered_features.reduce(func(accum, f):
			return accum + intermediate_transforms[f.get_id()].size(), 0
		)

		multimeshes[key].multimesh.instance_count = instance_count
		indices[key] = 0
	
	for f in features:
		for t in intermediate_transforms[f.get_id()]:
			var type = f.get_attribute(attribute_name) if not layer_composition.render_info.selector_attribute_name.is_empty() else "default"
			multimeshes[type].multimesh.set_instance_transform(indices[type], t)
			indices[type] += 1
	
	build_aabb(intermediate_transforms)
	mutex.unlock()
	
	super.apply_new_data()


# AABBs have to be set manually in order to increase rendering performance
func build_aabb(transforms):
	var begin = Vector3(INF, INF, INF)
	var end = Vector3(-INF, -INF, -INF)
	
	var height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
	
	for key in transforms:
		for t in transforms[key]:
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


func _calculate_intermediate_transforms():
	var transforms := {}
	for feature in features:
		var f_id = feature.get_id()
		var vertices: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
		var starting_point: Vector3
		var end_point: Vector3
		
		var get_ground_height_at_pos
		
		var height_offset = 0.0
		if feature.get_attribute("LL_h_off"):
			height_offset = float(feature.get_attribute("LL_h_off"))
		
		var ll_scale = 1.0
		if feature.get_attribute("LL_scale"):
			ll_scale = float(feature.get_attribute("LL_scale"))
		
		if layer_composition.render_info.height_gradient:
			# For things like bridges, we want to interpolate between the height at the first point and the height at the last point.
			var first_point = vertices.get_point_position(0)
			var last_point = vertices.get_point_position(vertices.get_point_count() - 1)
			var length = vertices.get_baked_length()
			
			var height_at_first = layer_composition.render_info.ground_height_layer.get_value_at_position(center[0] + first_point.x, center[1] - first_point.z)
			var height_at_last = layer_composition.render_info.ground_height_layer.get_value_at_position(center[0] + last_point.x, center[1] - last_point.z)
			
			get_ground_height_at_pos = func(position_x, position_z):
				var lerp_factor = first_point.distance_to(Vector3(position_x - center[0], 0.0, -position_z + center[1])) / length
				return lerp(height_at_first, height_at_last, lerp_factor)
		else:
			# Otherwise, get heights for all individual points from the height dataset.
			get_ground_height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
		
		var t: Transform3D
		transforms[f_id] = []
		
		var attribute_name = layer_composition.render_info.selector_attribute_name
		var attribute_value = feature.get_attribute(attribute_name) if not layer_composition.render_info.selector_attribute_name.is_empty() else "default"
		var width = layer_composition.render_info.meshes[attribute_value]["width"]
		
		width *= ll_scale
		
		var curve_length = vertices.get_baked_length()
		var distance_covered := 0.0
		
		# Make an exact number of objects fit between start and end
		var how_many_fit = ceil(curve_length / width)
		var scaled_width = curve_length / how_many_fit
		var scale_factor = scaled_width / width
		var previous_height := 0.0
		
		for i in range(how_many_fit):
			starting_point = vertices.sample_baked(distance_covered)
			t = Transform3D(Basis.IDENTITY, starting_point)
			end_point = vertices.sample_baked(distance_covered + scaled_width)
			
			var direction = starting_point.direction_to(end_point)
			direction.y = 0
			direction = direction.normalized()
			
			t.basis.z = direction
			t.basis.y = Vector3.UP
			t.basis.x = t.basis.y.cross(t.basis.z)
			
			t = t.scaled_local(Vector3(1, 1, scale_factor))
			t = t.scaled_local(Vector3.ONE * ll_scale)
			
			var rand_angle := 0.0

			var pos = t.origin + direction * scaled_width
			
			# Rotate by base rotation (to account for assets rotated differently than needed)
			t = t.rotated_local(Vector3.UP, deg_to_rad(layer_composition.render_info.base_rotation))
			
			# Randomly add 90, 180 or 270 degrees to previous rotation
			if layer_composition.render_info.random_angle:
				var pseudo_random = int(pos.x * 43758.5453 + pos.z * 78233.9898)
				rand_angle = rand_angle + (PI / 2.0) * ((pseudo_random % 3) + 1.0)
				t = t.rotated_local(Vector3.UP, rand_angle)
			t.origin = pos #* Vector3(1, 1, scale_factor)
			
			# Set the mesh on ground and add some buffer for uneven grounds
			var new_height = get_ground_height_at_pos.call(
				center[0] + t.origin.x, center[1] - t.origin.z)
			
			if previous_height == 0.0: previous_height = new_height  # for the first iteration
			t.origin.y = lerp(previous_height, new_height, 0.5) + height_offset
			
			transforms[f_id].append(t)
			
			previous_height = t.origin.y
			starting_point = end_point
			distance_covered += scaled_width
	
	return transforms


func get_debug_info() -> String:
	return ""


func is_new_loading_required(position_diff: Vector3) -> bool:
	if Vector2(position_diff.x, position_diff.z).length_squared() >= pow(radius / 4.0, 2):
		return true
	
	return false
