extends FeatureLayerCompositionRenderer


var connection_radius = 800.0
var max_connections = 100
# Connector = objects, connection = lines in-between
var connector_instances = {}
var connection_instances = {}


func _ready():
	super._ready()
	radius = 800.0
	max_features = 100


#func adapt_load(_diff: Vector3):
#	features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
#		float(center[0]) + position_manager.center_node.position.x,
#		float(center[1]) - position_manager.center_node.position.z,
#		radius, max_features
#	)
#
#	for geo_line in features:
#		if not connector_instances.has(geo_line.get_id()):
#			connector_instances[geo_line.get_id()] = {}
#
#		var engine_line = geo_line.get_offset_curve3d(-center[0], 0, -center[1]) 
#		for index in range(engine_line.get_point_count()):
#			# Obtain current point and its height 
#			var current_point = engine_line.get_point_position(index)
#			current_point.y = _get_height_at_ground(current_point)
#
#			# GeoLines will be loaded fully, even if only one segment is inside
#			# the load-radius, hence manual checking for each segment is required
#			if radius < position_manager.center_node.position.distance_to(current_point):
#				continue
#
#			if not connector_instances[geo_line.get_id()].has(index):
#				connector_instances[geo_line.get_id()][index] = load_feature_instance(geo_line)
#
#
#	call_deferred("apply_new_data")


func refine_load():
	var any_change_done := false
#	if max_connections <= connection_instances.size():
#		return
	
	for geo_line in features:
		for i in range(1, geo_line.get_curve3d().get_point_count()):
			var acces_str = "{0}_{1}".format([geo_line.get_id(), i])
			
			var current_connector = instances[geo_line.get_id()].get_child(i)
			var previous_connector = instances[geo_line.get_id()].get_child(i - 1)
#			if not current_connector.has_node("Docks") or not previous_connector.has_node("Docks"):
#				continue
			
			# GeoLines will be loaded fully, even if only one segment is inside
			# the load-radius, hence manual checking for each segment is required
			if connection_radius < position_manager.center_node.position.distance_to(current_connector.position):
				if connection_instances.has(acces_str):
					mutex.lock()
					connection_instances[acces_str] = false
					mutex.unlock()
					any_change_done = true
				continue
			
			var current_connections = _connect(
				current_connector, previous_connector, geo_line)
			
			# Might happen if distance to the connection is too far
			if current_connections != null and max_connections > connection_instances.size():
				current_connections.name = acces_str
				mutex.lock()
				connection_instances[acces_str] = current_connections
				mutex.unlock()
				any_change_done = true
	
	if any_change_done:
		call_deferred("apply_refined_data")


func apply_refined_data():
	for access_str in connection_instances.keys():
		print(access_str)
		#var node_name = str(feature.get_id())
		if connection_instances[access_str] is bool:
			if $Connections.has_node(str(access_str)):
				$Connections.get_node(str(access_str)).queue_free()
			mutex.lock()
			connection_instances.erase(access_str)
			mutex.unlock()
			
		if not $Connections.has_node(access_str):# and connection_instances.has(feature.get_id()):
			$Connections.add_child(connection_instances[access_str])
			for connection in connection_instances[access_str].get_children():
				connection.apply_connection()


func load_feature_instance(geo_line: GeoFeature) -> Node3D:
	var line_root = Node3D.new()
	line_root.name = str(geo_line.get_id())
	
	var engine_line: Curve3D = geo_line.get_offset_curve3d(-center[0], 0, -center[1])
	var previous_point := Vector3.INF
	var next_point := Vector3.INF
	
	var object_packed_scene = _get_scene_for_feature(geo_line)
	
	for index in range(engine_line.get_point_count()):
		# Obtain current point and its height 
		var current_point = engine_line.get_point_position(index)
		current_point.y = _get_height_at_ground(current_point)
		
		# Try to obtain the next point on the line
		if index+1 < engine_line.get_point_count():
			next_point = engine_line.get_point_position(index + 1)
			next_point.y = _get_height_at_ground(next_point)
		
		# Create a specified connector-object or use fallback
		var current_object: Node3D = object_packed_scene.instantiate()
		
		#
		# Try to resemble a realistic rotation of the connector-objects  
		# (i.e. they have to face each other)
		#
		
		# Previous point exists ...
		if previous_point != Vector3.INF:
			current_object.look_at_from_position(
				current_point, previous_point, current_object.transform.basis.y)
			
			# Next point exists ...
			if index+1 < engine_line.get_point_count():
				# Find the angle between (p_before - p_now) and (p_now - p_next)
				var v1 = current_point - previous_point
				var v2 = next_point - current_point
				var angle = v1.signed_angle_to(v2, Vector3.UP)
				# add this angle so its actually the mean between before and next
				current_object.rotation.y += angle / 2
		
		elif index+1 < engine_line.get_point_count():
			current_object.look_at_from_position(
				current_point, next_point, current_object.transform.basis.y)
		
		# Only y rotation is relevant
		current_object.rotation.x = 0
		current_object.rotation.z = 0
		
		previous_point = current_point
		
		line_root.add_child(current_object)
		
	return line_root


func _connect(object: Node3D, object_before: Node3D, geo_line: GeoFeature):
	# Dock parent might have a transform -> apply it too
	var dock_parent: Node3D = object.get_node("Docks")
	
	# Vector between current and next dock of the current connection and it's predecessors 
	# might be the same => cache!
	var connection_cache = []
	var current_connections = Node3D.new()
	
	var connection_scene = _get_scene_for_feature(geo_line, true)

	for dock in dock_parent.get_children():
		# Create a specified connection-object or use fallback
		var connection: AbstractConnection = connection_scene.instantiate()
		
		var dock_before: Node3D = object_before.get_node("Docks/" + String(dock.name))
		
		var p1: Vector3 = (object.transform * dock_parent.transform * dock.transform).origin
		var p2: Vector3 = (object_before.transform * dock_parent.transform * dock_before.transform).origin
		
		connection_cache = connection.find_connection_points(p1, p2, 0.0013, connection_cache)
		current_connections.add_child(connection)
	
	return current_connections


# Returns the current ground height
func _get_height_at_ground(query_position: Vector3) -> float:
	return layer_composition.render_info.ground_height_layer.get_value_at_position(
		center[0] + query_position.x, center[1] - query_position.z)


# Load the scene according to attributes in the configuration
# e.g. powerlines: minor-lines, lines or a fallback if no attribute is defined
func _get_scene_for_feature(geo_line: GeoFeature, is_connection: bool = false) -> PackedScene:
	# Get the specifying attribute or null (=> fallbacks)
	var attribute_name = layer_composition.render_info.selector_attribute_name
	var selector_attribute = null
	if attribute_name:
		selector_attribute = geo_line.get_attribute(attribute_name)
	
	var access_connection_or_connector := "connector"
	if is_connection:
		access_connection_or_connector = "connection"
	
	if selector_attribute != null and selector_attribute in layer_composition.render_info.connectors:
		return load(
			layer_composition.render_info.get(access_connection_or_connector + "s")[selector_attribute]
		)
	else:
		return load(
			layer_composition.render_info.get("fallback_" + access_connection_or_connector)
		)


func get_debug_info() -> String:
	return """
		{0} of maximally {1} features with 
			{2} inside the radius ({3}) connectors loaded.
			{4} of maximally {5} connections loaded.""".format([
				str(get_child_count() - 1),
				str(max_features),
				str(get_children().reduce(
					func(accum, c): 
						return accum + (c.get_child_count() if c.name != "Connections" else 0), 0)),
				str(radius),
				str($Connections.get_child_count()),
				str(max_connections),
			])
