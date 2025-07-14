extends FeatureLayerCompositionRenderer


#
# Instantiates an object for every segment of a GeoLine. The object is expected to have a custom
# shader which deals with stretching it from the start to end of the vertex.
#


func _ready() -> void:
	super._ready()
	
	radius = layer_composition.render_info.radius


func load_feature_instance(feature: GeoFeature):
	mutex.lock()
	
	var mesh_key_dict = _get_mesh_dict_key_from_feature(feature)
	var object_path = mesh_key_dict["path"]
	
	# Root node of all Nodes for this Feature
	var instances = Node3D.new()
	
	var vertices: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
	
	# We setup a prototype scene which we re-use (by duplicating) for all subsequent scenes
	# That way, we only have to do the setup (reading Feature attributes, etc.) once per Feature.
	var prototype_scene = load(object_path).instantiate()
	prototype_scene.setup(feature)
	
	if "length" in mesh_key_dict:
		prototype_scene.set_mesh_length(mesh_key_dict["length"])
	
	var height_getter
	
	if "height_type" in mesh_key_dict:
		if mesh_key_dict["height_type"] == "Lerped Line":
			height_getter = CurveHeightGetters.LerpedLineCurveHeightGetter.new(
				vertices,
				layer_composition.render_info.ground_height_layer,
				center
			)
	
	# Default
	if not height_getter:
		height_getter = CurveHeightGetters.ExactCurveHeightGetter.new(
			vertices,
			layer_composition.render_info.ground_height_layer,
			center
		)
		
	# Iterate over the Curve and stretch the object between every Vertex
	# Ignore the last vertex since we're really looking at segments (current vertex -> next vertex)
	for i in range(vertices.point_count - 1):
		# We require three points: the starting point of this segment, the end point of this
		#  segment, and the point after that in order to line up the directions
		var point = vertices.get_point_position(i)
		var next_point = vertices.get_point_position(min(i + 1, vertices.point_count - 1))
		var next_next_point = vertices.get_point_position(min(i + 2, vertices.point_count - 1))
		
		if i + 2 > vertices.point_count - 1:
			# This is the last point -> interpolate forward for the direction of the last vertex
			var direction = next_point - point
			next_next_point = next_point + direction
		
		# Set heights for all points
		point.y = height_getter.get_height(vertices.get_closest_offset(point))
		next_point.y = height_getter.get_height(vertices.get_closest_offset(next_point))
		next_next_point.y = height_getter.get_height(vertices.get_closest_offset(next_next_point))
		
		# Duplicate our prototype instance to get the instance for this segment
		var instance = prototype_scene.duplicate()
		instance.material_override = instance.material_override.duplicate()
		
		# Setup the matrices for the start and end of this object
		var start_transform = Transform3D(Basis.IDENTITY, point)
		start_transform = start_transform.looking_at(next_point)
		
		var end_transform = Transform3D(Basis.IDENTITY, next_point)
		end_transform = end_transform.looking_at(next_next_point)
		
		instance.set_segment_start_end(start_transform, end_transform)
		
		# Since the object gets its position and size purely from the start and end matrices in the
		#  custom shader, the default AABB is entirely wrong and we need to construct it ourselves.
		instance.custom_aabb = AABB(
			Vector3(
				min(point.x, next_point.x),
				min(point.y, next_point.y),
				min(point.z, next_point.z),
			),
			abs(next_point - point)
		).grow(3.0)  # FIXME: Growing by width would be best, but we don't know the width here
		
		instances.add_child(instance)
	
	mutex.unlock()
	
	return instances


func _get_mesh_dict_key_from_feature(feature: GeoFeature):
	var attribute_name = layer_composition.render_info.selector_attribute_name
	var possible_meshes = layer_composition.render_info.meshes.keys()
	var mesh_key = feature.get_attribute(attribute_name) if attribute_name != null else "default"
	mesh_key = mesh_key if mesh_key != "" else "default"
	mesh_key = possible_meshes[0] if not mesh_key in possible_meshes else mesh_key
	
	var mesh_key_dict = layer_composition.render_info.meshes[mesh_key].duplicate(true)
	
	# Add extra attributes
	for att_con in layer_composition.render_info.attributes_to_mesh_settings:
		var value_here = feature.get_attribute(att_con["attribute_name"])
		
		if value_here == att_con["attribute_value"]:
			mesh_key_dict.merge(att_con["mesh_settings"], true)
	
	return mesh_key_dict
