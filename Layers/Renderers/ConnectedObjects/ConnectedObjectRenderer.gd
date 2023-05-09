extends FeatureLayerCompositionRenderer


var connection_radius = 800.0
var max_connections = 100
# Connector = objects, connection = lines in-between
var intermediate_connector_instances = {}
var connection_instances = {}


func _ready():
	super._ready()
	radius = 800.0
	max_features = 100


func refine_load():
	var any_change_done := false
	
	for geo_line in features:
		for i in range(1, geo_line.get_curve3d().get_point_count()):
			var access_str = "{0}_{1}".format([geo_line.get_id(), i])

			var current_connector = instances[geo_line.get_id()].get_node(str(i))
			var previous_connector = instances[geo_line.get_id()].get_node(str(i - 1))

			# GeoLines will be loaded fully, even if only one segment is inside
			# the load-radius, hence manual checking for each segment is required
			var distance_to_con = position_manager.center_node.position.distance_to(current_connector.position)
			if connection_radius < distance_to_con:
				if connection_instances.has(access_str):
					mutex.lock()
					for key in intermediate_connector_instances.keys():
						if key.begins_with(access_str):
							intermediate_connector_instances.erase(key)
					connection_instances[access_str] = false
					mutex.unlock()
					any_change_done = true
				# Go to the next vertex
				continue

			# If it is within the radius and already in the dict no further processing is required
			if connection_instances.has(access_str): continue 

			var current_connections = outer_connect(
				current_connector, previous_connector, geo_line)

			if current_connections != null and max_connections > connection_instances.size():
				current_connections.name = access_str
				mutex.lock()
				connection_instances[access_str] = current_connections
				mutex.unlock()
				any_change_done = true

	if any_change_done:
		call_deferred("apply_refined_data")


func apply_refined_data():
	for access_str in connection_instances.keys():
		if connection_instances[access_str] is bool:
			if $Connections.has_node(str(access_str)):
				$Connections.get_node(str(access_str)).queue_free()
			mutex.lock()
			connection_instances.erase(access_str)
			mutex.unlock()
			continue
			
		if not $Connections.has_node(access_str):
			$Connections.add_child(connection_instances[access_str])
			for connection in connection_instances[access_str].get_children():
				connection.apply_connection()
	
	# Only add features here - remove them in adapt_load
	for intermediate_name in intermediate_connector_instances.keys():
		if not has_node(intermediate_name):
			add_child(intermediate_connector_instances[intermediate_name])
	
	for child in get_children():
		if not child.name.contains("_"): continue
		if not intermediate_connector_instances.has(child.name):
			child.queue_free()


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
		current_object.name = str(index)
		
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


func outer_connect(object: Node3D, previous_object: Node3D, geo_line: GeoFeature) -> Node3D:
	# Vector between current and next dock of the current connection and it's predecessors 
	# might be the same => cache!
	var connection_cache = []
	
	# In some cases connectors need to be set automatically between large distances
	var connection_scene = _get_scene_for_feature(geo_line, true)
	var connector_scene = _get_scene_for_feature(geo_line, false)
	var connection_max_length = connection_scene.instantiate().max_length
	var distance = object.position.distance_to(previous_object.position)
	
	var current_connections = Node3D.new()
	# Decide whether to take intermediate connectors as there is a max length
	# (e.g. for fences)
	if connection_max_length > 0:
		var num_connectors_between = int(distance / connection_max_length)
		# If the connection max length is long enough there is no need to take
		# intermediate steps
		if num_connectors_between < 1:
			for connection in explicit_connect(connection_scene, object, previous_object, []):
				current_connections.add_child(connection)
			return current_connections
			
		# Get the amount of connectors that shall be put between
		var step_size = distance / num_connectors_between
		var direction = (object.position - previous_object.position).normalized()
		var previous_connector = previous_object
		var vertex_id = int(str(previous_object.name))
		# For all connectors between call inner_connect (i.e. places an object and connects)
		for i in range(num_connectors_between):
			var new_connections = inner_connect(
				previous_connector, 
				direction * step_size,
				connector_scene, 
				connection_scene,
				geo_line.get_id(),
				vertex_id,
				i
			)
			for connection in new_connections:
				current_connections.add_child(connection)
			
			if intermediate_connector_instances.has("{0}_{1}_{2}".format([geo_line.get_id(), vertex_id, i])):
				previous_connector = intermediate_connector_instances[
					"{0}_{1}_{2}".format([geo_line.get_id(), vertex_id, i])]
		
		return current_connections
	else:
		for connection in explicit_connect(connection_scene, object, previous_object, []):
			current_connections.add_child(connection)
		
		return current_connections


func explicit_connect(connection_scene: PackedScene, 
		current_object: Node3D, previous_object: Node3D, connection_cache: Array) -> Array:
	# Dock parent might have a transform -> apply it too
	var current_docks: Node3D = current_object.get_node("Docks")
	var previous_docks: Node3D = previous_object.get_node("Docks")
	
	var current_connections = []
	for dock in current_docks.get_children():
		# Create a specified connection-object or use fallback
		var connection: AbstractConnection = connection_scene.instantiate()
		var previous_dock: Node3D = previous_docks.get_node(String(dock.name))
		
		var p1: Vector3 = (current_object.transform * current_docks.transform * dock.transform).origin
		var p2: Vector3 = (previous_object.transform * previous_docks.transform * previous_dock.transform).origin
		
		connection_cache = connection.find_connection_points(p1, p2, 0.0013, [])
		current_connections.append(connection)
	
	return current_connections


# Put an itermediate connector at p2 and connect it with the previous object
func inner_connect(previous_connector: Node3D, step: Vector3, connector: PackedScene,
		connection: PackedScene, feature_id: int, vertex_id: int, intermediate_id: int) -> Array:

	var intermediate_connector: Node3D = connector.instantiate()
	# As they will be strung on a line they have the same rotation
	intermediate_connector.transform = previous_connector.transform
	intermediate_connector.position = previous_connector.position + step
	intermediate_connector.name = "{0}_{1}_{2}".format([feature_id, vertex_id, intermediate_id])
	
	if intermediate_connector_instances.size() > max_connections:
		return []
	
	mutex.lock()
	intermediate_connector_instances[intermediate_connector.name] = intermediate_connector
	mutex.unlock()
	return explicit_connect(connection, intermediate_connector, previous_connector, [])


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
