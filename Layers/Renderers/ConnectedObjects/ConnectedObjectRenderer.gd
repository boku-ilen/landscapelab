extends LayerRenderer

var radius = 800
var max_features = 100
var connection_radius = 500
var max_connections = 100

var connector_instances = []
var connection_instances = []

func load_new_data():
	var geo_lines = layer.get_features_near_position(center[0], center[1], radius, max_features)
	
	for geo_line in geo_lines:
		update_connected_object(geo_line)


func apply_new_data():
	# First clear the old objects, then add the new ones
	# connectors as well as connections
	for child in $Connectors.get_children():
		child.queue_free()
	for child in $Connections.get_children():
		child.queue_free()
	
	for instance in connector_instances:
		$Connectors.add_child(instance)
	
	for instance in connection_instances:
		$Connections.add_child(instance)
		# AbstractConnection.apply_connection()
		instance.apply_connection()
	
	connector_instances.clear()
	connection_instances.clear()


func update_connected_object(geo_line):
	# Get the specifying attribute or null (=> fallbacks)
	var attribute_name = layer.render_info.selector_attribute_name
	var selector_attribute = geo_line.get_attribute(attribute_name) \
										if attribute_name else null
	
	# The line-dataset
	var course: Curve3D = geo_line.get_offset_curve3d(-center[0], 0, -center[1])
	# Object and translation of the previous connector
	var object_before: Spatial = null
	var point_before: Vector3
	# Translation of the next connector
	var point_next: Vector3
	
	for index in range(course.get_point_count()):
		# Create a specified connector-object or use fallback
		var object: Spatial

		if selector_attribute and selector_attribute in layer.render_info.connectors:
			object = layer.render_info.connectors[selector_attribute].instance()
		else:
			object = layer.render_info.fallback_connector.instance()
		
		# Obtain the next point (required for the orientation of the current)
		if index+1 < course.get_point_count():
			point_next = course.get_point_position(index + 1)
			point_next = Vector3(point_next.x, _get_height_at_ground(point_next), point_next.z)
		
		# Obtain the height at the current point
		var point = course.get_point_position(index)
		point = Vector3(point.x, _get_height_at_ground(point), point.z)
		
		if object_before:
			# Vec3 cant be null so we check differently
			# "if point_next:"
			if index+1 < course.get_point_count():
				# Look at the next object
				object.look_at_from_position(point, point_before, object.transform.basis.y)
				# Then find the angle between (p_before - p_now) and (p_now - p_next)
				var v1 = point - point_before
				var v2 = point_next - point
				var angle = v1.angle_to(v2)
				# FIXME: Godot has no signed_angle_to yet
				if v1.cross(v2).dot(Vector3.UP) < 0: angle = -angle
				# add this angle so its actually the mean between before and next
				object.rotation.y += angle / 2
				
			else:
				object.look_at_from_position(point, point_before, object.transform.basis.y)
				
			# Only y rotation is relevant
			object.rotation.x = 0
			object.rotation.z = 0
			_connect(object, object_before, selector_attribute)
			
		# Vec3 cant be null so we check differently
		# "if point_next:"
		elif index+1 < course.get_point_count():
			object.look_at_from_position(point, point_next, object.transform.basis.y)
			# Only y rotation is relevant
			object.rotation.x = 0
			object.rotation.z = 0
		
		object_before = object
		point_before = point
		
		connector_instances.append(object)


func _connect(object: Spatial, object_before: Spatial, selector_attribute: String):	
	if not object.has_node("Docks"):
		logger.warning("Connected Object %s defines no Docks and cannot be connected" % [object.name], LOG_MODULE)
		return
	
	if object.translation.distance_to(Vector3.ZERO) > connection_radius \
		and object_before.translation.distance_to(Vector3.ZERO) > connection_radius:
			return
	
	if max_connections <= connection_instances.size():
		return
	
	# Dock parent might have a transform -> apply it too
	var dock_parent: Spatial = object.get_node("Docks")
	
	# Vector between current and next dock of the current connection and it's predecessors 
	# might be the same => cache!
	var catenary_curve_cache = []
	for dock in dock_parent.get_children():
		# Create a specified connection-object or use fallback
		var connection: AbstractConnection
		if not selector_attribute or not selector_attribute in layer.render_info.connections:
			connection = layer.render_info.fallback_connection.instance()
		else:
			connection = layer.render_info.connections[selector_attribute].instance()
		
		var dock_before: Spatial = object_before.get_node("Docks/" + dock.name)
		
		var p1: Vector3 = (object.transform * dock_parent.transform * dock.transform).origin
		var p2: Vector3 = (object_before.transform * dock_parent.transform * dock_before.transform).origin
		
		catenary_curve_cache = connection.find_connection_points(p1, p2, 0.0033, catenary_curve_cache)
		connection_instances.append(connection)


# Returns the current ground height
func _get_height_at_ground(position: Vector3) -> float:
	return layer.render_info.ground_height_layer.get_value_at_position(
		center[0] + position.x, center[1] - position.z)


func _ready():
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("ConnectedObjectRenderer was given an invalid layer!", LOG_MODULE)


func get_debug_info() -> String:
	return "{0} of maximally {1} connectors loaded.\n{2} of maximally {3} connections loaded.".format([
		str($Connectors.get_child_count()),
		str(max_features),
		str($Connections.get_child_count()),
		str(max_connections),
	])
