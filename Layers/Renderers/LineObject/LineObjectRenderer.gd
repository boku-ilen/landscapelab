extends FeatureLayerCompositionRenderer


#
# Instantiates an object for every segment of a GeoLine. The object is expected to have a custom
# shader which deals with stretching it from the start to end of the segment.
#
# Possible properties in attributes_to_properties:
# - "path" (required): path to a scene derived from LineSegment
# - "length" (default 1.0): size of the mesh
# - "height_type" (default "Exact"): How the height of individual objects should be calculated ("Exact", "Lerped Line")
#


func _ready() -> void:
	super._ready()
	
	radius = layer_composition.render_info.radius


func load_feature_instance(feature: GeoFeature):
	mutex.lock()
	
	var property_dict = AttributeToPropertyInterpreter.get_properties_for_feature(
		feature,
		layer_composition.render_info.attributes_to_properties
	)
	var object_path = property_dict["path"]
	
	# Root node of all Nodes for this Feature
	var instances = Node3D.new()
	
	# If there's wrong geometry in this layer, skip it
	if not feature is GeoLine: return instances
	
	var vertices: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
	
	# We setup a prototype scene which we re-use (by duplicating) for all subsequent scenes
	# That way, we only have to do the setup (reading Feature attributes, etc.) once per Feature.
	var prototype_scene = load(object_path).instantiate() as LineSegment
	prototype_scene.setup(feature)
	
	prototype_scene.set_mesh_length(property_dict.get("length", 1.0))
	
	var height_getter
	var height_type = property_dict.get("height_type", "Exact")
	
	if height_type == "Lerped Line":
		height_getter = CurveHeightGetters.LerpedLineCurveHeightGetter.new(
			vertices,
			layer_composition.render_info.ground_height_layer,
			center
		)
	else:
		height_getter = CurveHeightGetters.ExactCurveHeightGetter.new(
			vertices,
			layer_composition.render_info.ground_height_layer,
			center
		)
	
	var mesh_aabb = prototype_scene.get_mesh_aabb()
		
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
		var custom_aabb = AABB(
			Vector3(
				min(point.x, next_point.x),
				min(point.y, next_point.y),
				min(point.z, next_point.z),
			),
			abs(next_point - point)
		)
		
		# Grow by the mesh and apply
		custom_aabb = custom_aabb.grow(max(mesh_aabb.size.x, mesh_aabb.size.y, mesh_aabb.size.z))
		instance.custom_aabb = custom_aabb
		
		instances.add_child(instance)
	
	mutex.unlock()
	
	return instances
