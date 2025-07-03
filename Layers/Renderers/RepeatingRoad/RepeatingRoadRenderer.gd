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

var highway_type_to_scene := {
	"default": preload("res://Objects/Roads/RoadSegmentCar.tscn"),
	"track": preload("res://Objects/Roads/RoadSegmentTrack.tscn"),
	"path": preload("res://Objects/Roads/RoadSegmentTrack.tscn"),
}


func _ready() -> void:
	super._ready()
	
	radius = layer_composition.render_info.radius


func load_feature_instance(feature: GeoFeature):
	mutex.lock()
	
	var mesh_key = _get_mesh_dict_key_from_feature(feature)
	var mesh_path = layer_composition.render_info.meshes[mesh_key]["path"]
	
	var instances = Node3D.new()
	
	var vertices: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
	
	var type = feature.get_attribute("highway")
	
	var prototype_scene
	
	if type in highway_type_to_scene:
		prototype_scene = highway_type_to_scene[type].instantiate()
	else:
		prototype_scene = highway_type_to_scene["default"].instantiate()
	
	prototype_scene.setup(feature)
	
	for i in range(vertices.point_count - 1):
		var point = vertices.get_point_position(i)
		var next_point = vertices.get_point_position(min(i + 1, vertices.point_count - 1))
		var next_next_point = vertices.get_point_position(min(i + 2, vertices.point_count - 1))
		
		if i + 2 > vertices.point_count - 1:
			# This is the last point -> interpolate forward
			var direction = next_point - point
			next_next_point = next_point + direction
		
		point.y = layer_composition.render_info.ground_height_layer.get_value_at_position(
			center[0] + point.x,
			center[1] - point.z,
		)
		next_point.y = layer_composition.render_info.ground_height_layer.get_value_at_position(
			center[0] + next_point.x,
			center[1] - next_point.z,
		)
		next_next_point.y = layer_composition.render_info.ground_height_layer.get_value_at_position(
			center[0] + next_next_point.x,
			center[1] - next_next_point.z,
		)
		
		## Smaller roads go further down at their start and end, producing a bit nicer intersections
		#if i == 0: point.y -= 1.0 / width
		#if i == vertices.point_count - 2: next_point.y -= 1.0 / width
		
		var start_transform = Transform3D(Basis.IDENTITY, point)
		start_transform = start_transform.looking_at(next_point)
		
		var end_transform = Transform3D(Basis.IDENTITY, next_point)
		end_transform = end_transform.looking_at(next_next_point)
		
		var instance = prototype_scene.duplicate()
		instance.material_override = instance.material_override.duplicate()
		
		instance.set_segment_start_end(start_transform, end_transform)
		
		instance.custom_aabb = AABB(
			Vector3(
				min(point.x, next_point.x),
				min(point.y, next_point.y),
				min(point.z, next_point.z),
			),
			abs(next_point - point)
		).grow(3.0)
		
		instances.add_child(instance)
	
	mutex.unlock()
	
	return instances


func _get_mesh_dict_key_from_feature(feature: GeoFeature):
	var attribute_name = layer_composition.render_info.selector_attribute_name
	var possible_meshes = layer_composition.render_info.meshes.keys()
	var mesh_key = feature.get_attribute(attribute_name) if attribute_name != null else "default"
	mesh_key = mesh_key if mesh_key != "" else "default"
	mesh_key = possible_meshes[0] if not mesh_key in possible_meshes else mesh_key
	
	return mesh_key
