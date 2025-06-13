extends FeatureLayerCompositionRenderer


#
# Repeated objects along a line - can be used for e.g. Hedges
# Objects will be placed with predefined width from one another
#
# Notes:
# - To remove the repetitiveness of the mesh it will be randomly rotated
# - Extends the multimesh feature layer to drastically improve performance
#

var rand_angle := 0.0


func _ready() -> void:
	radius = layer_composition.render_info.radius


func load_feature_instance(feature: GeoFeature):
	rand_angle = 0.0
	mutex.lock()
	# Get the configured path or default
	var mesh_key = _get_mesh_dict_key_from_feature(feature)
	
	# Create one multimesh per feature
	var multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.multimesh = MultiMesh.new()
	multimesh_instance.multimesh.set_transform_format(MultiMesh.TRANSFORM_3D)
	var mesh_path = layer_composition.render_info.meshes[mesh_key]["path"]
	multimesh_instance.multimesh.mesh = load(mesh_path)
	multimesh_instance.set_layer_mask_value(1, false)
	multimesh_instance.set_layer_mask_value(3, true)
	
	# Calculate transforms for the intermediate meshes
	var intermediate_transforms = _calculate_intermediate_transforms(feature)
	
	# Set the instance count to all cummulated vertecies and populate multimesh
	multimesh_instance.multimesh.instance_count = intermediate_transforms.size()
	for index in intermediate_transforms.size():
		var t = intermediate_transforms[index]
		multimesh_instance.multimesh.set_instance_transform(index, t)
	
	build_aabb(intermediate_transforms, multimesh_instance)
	mutex.unlock()
	
	return multimesh_instance


# AABBs have to be set manually in order to increase rendering performance
func build_aabb(transforms: Array, multimesh_instance: MultiMeshInstance3D):
	var begin = Vector3(INF, INF, INF)
	var end = Vector3(-INF, -INF, -INF)
	
	var height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
	
	for t in transforms:
		begin.x = min(begin.x, t.origin.x)
		begin.y = min(begin.y, t.origin.y)
		begin.z = min(begin.z, t.origin.z)
		end.x = max(end.x, t.origin.x)
		end.y = max(end.y, t.origin.y)
		end.z = max(end.z, t.origin.z)
	
	var mesh_aabb = multimesh_instance.multimesh.mesh.get_aabb()
	
	begin.x -= mesh_aabb.size.x / 2.0
	end.x += mesh_aabb.size.x / 2.0
	
	begin.y -= mesh_aabb.size.y / 2.0
	end.y += mesh_aabb.size.y / 2.0
	
	var size = abs(end - begin)
	
	multimesh_instance.set_custom_aabb(AABB(begin, size))


func _calculate_intermediate_transforms(feature: GeoFeature):
	var f_id = feature.get_id()
	var vertices: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
	
	var height_fit_rotation = 0.0
	
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
		
		# FIXME: Multiplying by 0.9 shouldn't be necessary, but without it, the rotation is incorrect
		height_fit_rotation = atan((height_at_last - height_at_first) / length) * 0.9
		
		get_ground_height_at_pos = func(position_x, position_z):
			var lerp_factor = first_point.distance_to(Vector3(position_x, 0.0, position_z)) / length
			return lerp(height_at_first, height_at_last, lerp_factor)
	else:
		# Otherwise, get heights for all individual points from the height dataset.
		get_ground_height_at_pos = func(position_x, position_z):
			return layer_composition.render_info.ground_height_layer.get_value_at_position(
				center[0] + position_x,
				center[1] - position_z,
			)
	
	var transforms := []
	
	var mesh_key = _get_mesh_dict_key_from_feature(feature)
	var width = layer_composition.render_info.meshes[mesh_key]["width"]
	var random_angle = layer_composition.render_info.meshes[mesh_key]["random_angle"] \
			if "random_angle" in layer_composition.render_info.meshes[mesh_key] else layer_composition.render_info.random_angle
	
	width *= ll_scale
	
	var curve_length = vertices.get_baked_length()
	var distance_covered := 0.0
	
	# Make an exact number of objects fit between start and end
	var how_many_fit = ceil(curve_length / width)
	var scaled_width = curve_length / how_many_fit
	var scale_factor = scaled_width / width
	var previous_height := 0.0
	
	for i in range(how_many_fit):
		# Note that we sample from end to start because that aligns with how we expect objects
		#  to be oriented (+X forward)
		var starting_point = vertices.sample_baked(curve_length - distance_covered)
		var end_point = vertices.sample_baked(curve_length - distance_covered - scaled_width)
		
		var real_distance = (end_point - starting_point).length()
		var instance_scale_factor = real_distance / width
		
		var direction = starting_point.direction_to(end_point)
		direction.y = 0
		direction = direction.normalized()
		
		var t = Transform3D(Basis.IDENTITY, starting_point)
		
		# Construct a basis using Forward, Up, and Right vectors
		t.basis.z = -direction
		t.basis.y = Vector3.UP
		t.basis.x = t.basis.y.cross(t.basis.z)
		
		t = t.scaled_local(Vector3(1, 1, instance_scale_factor))
		t = t.scaled_local(Vector3.ONE * ll_scale)
		
		# Rotate by height slant if needed
		t = t.rotated_local(Vector3.RIGHT, -height_fit_rotation)
		
		# Rotate by base rotation (to account for assets rotated differently than needed)
		t = t.rotated_local(Vector3.UP, deg_to_rad(layer_composition.render_info.base_rotation))
		
		# Randomly add 90, 180 or 270 degrees to previous rotation
		if  random_angle:
			var pseudo_random = abs(int(t.origin.x * 43758.5453 + t.origin.z * 78233.9898))
			rand_angle = rand_angle + (PI / 2.0) * ((pseudo_random % 3) + 1.0)
			rand_angle = fmod(rand_angle, PI * 2.0)
			t = t.rotated_local(Vector3.UP, rand_angle)
		
		# Set the mesh on ground and add some buffer for uneven grounds
		var height_position = t.origin
		
		# For some objects, like fences ,we want to sample the height in the middle, for others,
		#  like reflector posts,we want to sample the height at the start, since that's where the
		#  object is.
		if layer_composition.render_info.sample_height_at_center:
			height_position += direction * scaled_width  / 2.0
		var new_height = get_ground_height_at_pos.call(height_position.x, height_position.z) + height_offset
		
		t.origin.y = new_height
		
		transforms.append(t)
		
		distance_covered += scaled_width
	
	return transforms


func _get_mesh_dict_key_from_feature(feature: GeoFeature):
	var attribute_name = layer_composition.render_info.selector_attribute_name
	var possible_meshes = layer_composition.render_info.meshes.keys()
	var mesh_key = feature.get_attribute(attribute_name) if attribute_name != null else "default"
	mesh_key = mesh_key if mesh_key != "" else "default"
	mesh_key = possible_meshes[0] if not mesh_key in possible_meshes else mesh_key
	
	return mesh_key
