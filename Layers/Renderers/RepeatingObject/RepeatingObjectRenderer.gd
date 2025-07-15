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
	super._ready()
	
	radius = layer_composition.render_info.radius


func load_feature_instance(feature: GeoFeature):
	rand_angle = 0.0
	mutex.lock()
	
	# Get the configured properties
	var property_dict
	if not layer_composition.render_info.attributes_to_properties.is_empty():
		property_dict = AttributeToPropertyInterpreter.get_properties_for_feature(
			feature,
			layer_composition.render_info.attributes_to_properties
		)
	elif not layer_composition.render_info.meshes.is_empty():
		property_dict = AttributeToPropertyInterpreter.get_mesh_dict_key_from_feature(
			feature,
			layer_composition.render_info.selector_attribute_name,
			layer_composition.render_info.meshes
		)
	
	# Create one multimesh per feature
	var multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.multimesh = MultiMesh.new()
	multimesh_instance.multimesh.set_transform_format(MultiMesh.TRANSFORM_3D)
	var mesh_path = property_dict["path"]
	multimesh_instance.multimesh.mesh = load(mesh_path)
	multimesh_instance.set_layer_mask_value(1, false)
	multimesh_instance.set_layer_mask_value(3, true)
	
	# Calculate transforms for the intermediate meshes
	var intermediate_transforms = _calculate_intermediate_transforms(feature, property_dict)
	
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


func _calculate_intermediate_transforms(feature: GeoFeature, property_dict: Dictionary):
	var vertices: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
	
	var height_offset = 0.0
	if feature.get_attribute("LL_h_off"):
		height_offset = float(feature.get_attribute("LL_h_off"))
	
	var ll_scale = 1.0
	if feature.get_attribute("LL_scale"):
		ll_scale = float(feature.get_attribute("LL_scale"))
	
	var transforms := []
	
	var width = property_dict["width"]
	var random_angle = property_dict["random_angle"] \
			if "random_angle" in property_dict else layer_composition.render_info.random_angle
	
	var base_rotation = property_dict["base_rotation"] \
			if "base_rotation" in property_dict else layer_composition.render_info.base_rotation
	
	var height_getter
	
	if layer_composition.render_info.height_gradient:
		height_getter = CurveHeightGetters.LerpedLineCurveHeightGetter.new(
			vertices,  layer_composition.render_info.ground_height_layer, center)
	else:
		height_getter = CurveHeightGetters.ExactCurveHeightGetter.new(
			vertices,  layer_composition.render_info.ground_height_layer, center)
	
	# Per-mesh override, if available
	if "height_type" in property_dict:
		if property_dict["height_type"] == "Lerped Vertex":
			height_getter = CurveHeightGetters.LerpedVertexCurveHeightGetter.new(
				vertices, layer_composition.render_info.ground_height_layer, center)
		elif property_dict["height_type"] == "Lerped Line":
			height_getter = CurveHeightGetters.LerpedLineCurveHeightGetter.new(
				vertices, layer_composition.render_info.ground_height_layer, center)
	
	width *= ll_scale
	
	var curve_length = vertices.get_baked_length()
	var distance_covered := 0.0
	
	# Make an exact number of objects fit between start and end
	var how_many_fit = ceil(curve_length / width)
	var scaled_width = curve_length / how_many_fit
	
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
		
		# Set the mesh on ground and add some buffer for uneven grounds
		var height_progress = curve_length - distance_covered
		
		# For some objects, like fences ,we want to sample the height in the middle, for others,
		#  like reflector posts,we want to sample the height at the start, since that's where the
		#  object is.
		if layer_composition.render_info.sample_height_at_center:
			height_progress += scaled_width  / 2.0
		var new_height = height_getter.get_height(height_progress) + height_offset
		
		t.origin.y = new_height
		
		if "offset" in property_dict:
			var offset = property_dict["offset"]
			t = t.translated_local(Vector3.RIGHT * offset)
			
			# TODO: We need to adapt the scale to this offset as well, otherwise we get overlaps in
			#  curves which get more narrow and gaps in curves which get more wide.
		
		t = t.scaled_local(Vector3(1, 1, instance_scale_factor))
		t = t.scaled_local(Vector3.ONE * ll_scale)
		
		# Rotate by height slant if needed
		t = t.rotated_local(Vector3.RIGHT, height_getter.get_angle(curve_length - distance_covered))
		
		# Rotate by base rotation (to account for assets rotated differently than needed)
		t = t.rotated_local(Vector3.UP, deg_to_rad(base_rotation))
		
		# FIXME: Generalize, currently only works for flipping
		if base_rotation == 180.0: t = t.translated_local(-Vector3.FORWARD * width)
		
		# Randomly add 90, 180 or 270 degrees to previous rotation
		if  random_angle:
			var pseudo_random = abs(int(t.origin.x * 43758.5453 + t.origin.z * 78233.9898))
			rand_angle = rand_angle + (PI / 2.0) * ((pseudo_random % 3) + 1.0)
			rand_angle = fmod(rand_angle, PI * 2.0)
			t = t.rotated_local(Vector3.UP, rand_angle)
		
		transforms.append(t)
		
		distance_covered += scaled_width
	
	return transforms
