extends FeatureLayerCompositionRenderer


var connection_radius = 500.0
var max_connections = 100
# Distinguish between diffferent types of powerlines
# e.g. (line, minor_line)
var selector_attribute: String

# Connector = objects, connection = lines in-between
var connection_instances = {}


func _ready():
	super._ready()
	radius = 800.0
	max_features = 100


func refine_load():
	var any_change_done := false
	if max_connections <= connection_instances.size():
		return
		
	for geo_line in features:
		for i in range(1, geo_line.get_curve3d().get_point_count()):
			var current_connections = _connect(
				instances[geo_line.get_id()].get_child(i),
				instances[geo_line.get_id()].get_child(i - 1),
				selector_attribute
			)
			
			# Might happen if distance is too far
			if current_connections != null and not connection_instances.has(geo_line.get_id()):
				mutex.lock()
				connection_instances[geo_line.get_id()] = current_connections
				mutex.unlock()
				any_change_done = true
	
	if any_change_done:
		call_deferred("apply_refined_data")


func apply_refined_data():
	for id in connection_instances.keys():
		if not $Connections.has_node(str(id)):
			$Connections.add_child(connection_instances[id])
	
	var valid_ids_as_str = connection_instances.keys().map(func(id): return str(id))
	for child in $Connections.get_children():
		if child.name not in valid_ids_as_str:
			child.queue_free()


func load_feature_instance(geo_line: GeoFeature) -> Node3D:
	var line_root = Node3D.new()
	line_root.name = str(geo_line.get_id())
	
	# Get the specifying attribute or null (=> fallbacks)
	var attribute_name = layer_composition.render_info.selector_attribute_name
	selector_attribute = geo_line.get_attribute(attribute_name) \
										if attribute_name else null
	
	var engine_line: Curve3D = geo_line.get_offset_curve3d(-center[0], 0, -center[1])
	# Object and position of the previous connector
	var previous_object: Node3D = null
	var previous_point: Vector3
	# Translation of the next connector
	var next_point: Vector3
	
	for index in range(engine_line.get_point_count()):
		# Create a specified connector-object or use fallback
		var current_object: Node3D

		if selector_attribute != null and selector_attribute in layer_composition.render_info.connectors:
			current_object = load(
				layer_composition.render_info.connectors[selector_attribute]).instantiate()
		else:
			current_object = load(
				layer_composition.render_info.fallback_connector).instantiate()
		
		# Obtain the next point (required for the orientation of the current)
		if index+1 < engine_line.get_point_count():
			next_point = engine_line.get_point_position(index + 1)
			next_point.y = _get_height_at_ground(next_point)
		
		# Obtain the height at the current point
		var current_point = engine_line.get_point_position(index)
		current_point.y = _get_height_at_ground(current_point)
		
		if previous_object:
			if index+1 < engine_line.get_point_count():
				# Look at the next object
				current_object.look_at_from_position(
					current_point, previous_point, current_object.transform.basis.y)
				# Then find the angle between (p_before - p_now) and (p_now - p_next)
				var v1 = current_point - previous_point
				var v2 = next_point - current_point
				var angle = v1.signed_angle_to(v2, Vector3.UP)
				# add this angle so its actually the mean between before and next
				current_object.rotation.y += angle / 2
				
			else:
				current_object.look_at_from_position(
					current_point, previous_point, current_object.transform.basis.y)
				
			# Only y rotation is relevant
			current_object.rotation.x = 0
			current_object.rotation.z = 0
		elif index+1 < engine_line.get_point_count():
			current_object.look_at_from_position(current_point, next_point, current_object.transform.basis.y)
			# Only y rotation is relevant
			current_object.rotation.x = 0
			current_object.rotation.z = 0
		
		previous_object = current_object
		previous_point = current_point
		
		line_root.add_child(current_object)
		
	return line_root


func _connect(object: Node3D, object_before: Node3D, selector_attribute):
	if not object.has_node("Docks"):
		return
	
	if object.position.distance_to(position_manager.center_node.position) > connection_radius \
		and object_before.position.distance_to(position_manager.center_node.position) > connection_radius:
			return
	
	# Dock parent might have a transform -> apply it too
	var dock_parent: Node3D = object.get_node("Docks")
	
	# Vector between current and next dock of the current connection and it's predecessors 
	# might be the same => cache!
	var connection_cache = []
	var current_connections = Node3D.new()
	for dock in dock_parent.get_children():
		# Create a specified connection-object or use fallback
		var connection: AbstractConnection
		if selector_attribute == null or not selector_attribute in layer_composition.render_info.connections:
			connection = load(layer_composition.render_info.fallback_connection).instantiate()
		else:
			connection = load(layer_composition.render_info.connections[selector_attribute]).instantiate()
		
		var dock_before: Node3D = object_before.get_node("Docks/" + String(dock.name))
		
		var p1: Vector3 = (object.transform * dock_parent.transform * dock.transform).origin
		var p2: Vector3 = (object_before.transform * dock_parent.transform * dock_before.transform).origin
		
		connection_cache = connection.find_connection_points(p1, p2, 0.0013, connection_cache)
		current_connections.add_child(connection)
		connection.apply_connection()
	
	return current_connections


# Returns the current ground height
func _get_height_at_ground(query_position: Vector3) -> float:
	return layer_composition.render_info.ground_height_layer.get_value_at_position(
		center[0] + query_position.x, center[1] - query_position.z)


func get_debug_info() -> String:
	return "{0} of maximally {1} connectors loaded.\n{2} of maximally {3} connections loaded.".format([
		str(get_child_count() - 1),
		str(max_features),
		str($Connections.get_child_count()),
		str(max_connections),
	])
