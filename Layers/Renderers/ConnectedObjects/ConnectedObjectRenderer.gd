extends LayerRenderer

var radius = 1000
var max_features = 500

var connector_instances = []
var connection_instances = []


func load_new_data():
	var geo_lines = layer.get_features_near_position(center[0], center[1], 
												radius, max_features)
	
	for geo_line in geo_lines:
		update_connection(geo_line)


func apply_new_data():
	# First clear the old objects, then add the new ones
	# connectors as well as connections
	for child in get_children():
		child.queue_free()
	
	for instance in connector_instances:
		add_child(instance)
	
	for instance in connection_instances:
		add_child(instance)
		# AbstractConnection.apply_connection()
		instance.apply_connection()
	
	connector_instances.clear()
	connection_instances.clear()


func update_connection(geo_line):
	var course: Curve3D = geo_line.get_offset_curve3d(-center[0], 0, -center[1])
	var object_before: Spatial = null
	var point_before: Vector3
	for index in range(course.get_point_count()):
		var point = course.get_point_position(index)
		point = Vector3(point.x, _get_height_at_ground(point), point.z)
		
		var object = layer.render_info.object.instance()
		object.transform.origin = point
		
		if object_before:
			for dock in object.get_node("Docks").get_children():
				var dock_before = object_before.get_node("Docks/" + dock.name)
				var connection = layer.render_info.connection_visualization.instance()
				var p1 = point + dock.transform.origin
				var p2 = point_before + dock_before.transform.origin
				
				connection.find_connection_points(p2, p1, 1.001)
				connection_instances.append(connection)
		
		object_before = object
		point_before = point
		
		connector_instances.append(object)


# Returns the current ground height
func _get_height_at_ground(position: Vector3) -> float:
	return layer.render_info.ground_height_layer.get_value_at_position(
		center[0] + position.x, center[1] - position.z)


func _ready():
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("ConnectedObjectRenderer was given an invalid layer!")
