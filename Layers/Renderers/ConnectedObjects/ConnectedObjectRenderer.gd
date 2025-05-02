extends FeatureLayerCompositionRenderer


#
# Given at this moment: instances = {
#   Node3D.name == 1 --- 1_2
#      |     \   
#     1_0    1_1 
# }
#
# I.e. a dictionary with nodes to the geo-line roots (i.e. having vertex count connectors)
#
# Two cases for refine_load:
#   - load new data (inside a given radius)
#   - erase invalid data (outside a given radius)
# 
# The line data set must be cleaned with QGIS function 
#	Remvoe duplicate vertices 
# or this renderer will run into problems
# 

var last_update_pos := Vector3.INF
var connection_radius = 800.0
var max_connections = 100
# Connector = objects, connection = lines in-between
var intermediate_connectors := {}
var connections := {}
# For getting a local deep copy of instances from parent
var local_connectors: Dictionary
var local_features: Array

var connection_mutex = Mutex.new()
var loaded_connection_scenes := {}
var loaded_connector_scenes := {}


func _ready():
	super._ready()
	radius = 800.0
	max_features = 100
	_load_scenes()
	
	radius = loaded_connector_scenes["fallback"].instantiate().load_radius
	connection_radius = loaded_connection_scenes["fallback"].instantiate().load_radius
	
	feature_instance_removed.connect(func(id):
		_remove_by_access_str(str(id))
		apply_refined_data())


# Load in the scenes as configured in .ll to avoid having to load them continuously
func _load_scenes():
	loaded_connection_scenes["fallback"] = load(
		layer_composition.render_info.get("fallback_connection")
	)
	loaded_connector_scenes["fallback"] = load(
		layer_composition.render_info.get("fallback_connector")
	)
	for key in layer_composition.render_info.get("connections"):
		loaded_connection_scenes[key] = \
			load(layer_composition.render_info.get("connections")[key])
	for key in layer_composition.render_info.get("connectors"):
		loaded_connector_scenes[key] = \
			load(layer_composition.render_info.get("connectors")[key])


func _remove_by_access_str(access_str: String) -> bool:
	connection_mutex.lock()
	var any_change_done := false
	
	for id in connections.keys():
		if id.begins_with(access_str):
			connections.erase(id)
			any_change_done = true

	for id in intermediate_connectors.keys():
		if id.begins_with(access_str):
			intermediate_connectors.erase(id)
			any_change_done = true
	connection_mutex.unlock()
	
	return any_change_done


func _handle_with_intermediate(
	geo_line: GeoLine, vertex_id: int, intermediate_count: int, 
	distance: float, connector_i_0: Node3D, connector_i_1: Node3D,
	connector_scene: PackedScene, connection_scene: PackedScene):
	
	var any_change_done := false
	var access_str = "{0}_{1}".format([geo_line.get_id(), vertex_id])
	
	if not intermediate_connectors.has(access_str):
		add_intermediate_connectors(
			geo_line.get_id(), 
			vertex_id, 
			distance, 
			intermediate_count,
			connector_i_0,
			connector_i_1,
			connector_scene
		)
		any_change_done = true
	if not connections.has(access_str):
		inner_connect(
			geo_line.get_id(), 
			vertex_id,
			intermediate_count,
			connector_i_0,
			connector_i_1,
			connection_scene
		)
		any_change_done = true
	
	return any_change_done


func _handle_standard(
	geo_line: GeoLine, vertex_id: int, connector_i_0: Node3D, connector_i_1: Node3D,
	connector_scene: PackedScene, connection_scene: PackedScene):
	
	var any_change_done := false
	var access_str = "{0}_{1}".format([geo_line.get_id(), vertex_id])
	
	var new_con = explicit_connect(
		access_str,
		connector_i_0,
		connector_i_1,
		connection_scene,
		[]
	)
	
	connections[access_str] = new_con
	any_change_done = true
	
	return any_change_done


func refine_load():
	super.refine_load()
	
	var center = position_manager.center_node.position
	
	if center.distance_squared_to(last_update_pos) < pow(connection_radius / 4.0, 2.0):
		return
	
	var any_change_done := false
	
	# NOTE: is this necessary?
	mutex.lock()
	if local_connectors.keys() != instances.keys():
		local_connectors = instances.duplicate(true)
	if features != local_features:
		local_features = features.duplicate(true)
	mutex.unlock()
	
	connection_mutex.lock()
	for geo_line in local_features:
		if not (geo_line.get_id() in local_connectors \
				and is_instance_valid(local_connectors[geo_line.get_id()])): continue
		
		var specific_connectors: Node3D = local_connectors[geo_line.get_id()]
		
		if not (specific_connectors.has_node("0") and specific_connectors.has_node("1")):
			# FIXME: This happens sometimes, but it shouldn't!
			continue
		
		var connector_scene: PackedScene = _get_scene_for_feature(geo_line, false)
		var connection_scene: PackedScene = _get_scene_for_feature(geo_line, true)
		
		# Required for accessing member variable max_length
		var exemplary_connection = connection_scene.instantiate()
		var connection_max_length: float = exemplary_connection.max_length
		
		var vertices: Curve3D = geo_line.get_curve3d()
		# Connection requires at least two points
		if vertices.get_point_count() < 2: continue
		
		var connector_i_0: Node3D = specific_connectors.get_node(str(0))
		var connector_i_1: Node3D
		
		# Skip index 0 because connecting requires two objects
		for vert_id in range(1, vertices.get_point_count()):
			connector_i_1 = specific_connectors.get_node(str(vert_id))
			
			# Decide whether to take intermediate connectors
			var distance: float = connector_i_0.position.distance_to(connector_i_1.position)
			var intermediate_count := int(distance / connection_max_length)
			var make_intermediate_steps := connection_max_length > 0 and intermediate_count >= 1
			
			# Define the id/name of the connection
			var access_str = "{0}_{1}".format([geo_line.get_id(), vert_id])
			
			var avg_connection_pos = (connector_i_0.position + connector_i_1.position) / 2
			if connection_radius + abs(distance) < distance_to_center(avg_connection_pos): 
				any_change_done = _remove_by_access_str(access_str) or any_change_done
			else:
				if not make_intermediate_steps:
					if not connections.has(access_str):
						any_change_done = _handle_standard(
							geo_line, vert_id, 
							connector_i_0, connector_i_1, connector_scene, connection_scene
						) or any_change_done
				else:
					any_change_done = _handle_with_intermediate(
						geo_line, vert_id, intermediate_count, distance,
						connector_i_0, connector_i_1, connector_scene, connection_scene
					) or any_change_done
			
			connector_i_0 = connector_i_1
	connection_mutex.unlock()
	
	if any_change_done:
		call_deferred("apply_refined_data")
	
	last_update_pos = center


func apply_refined_data():
	connection_mutex.lock()
	for access_str in connections.keys():
		if not $Connections.has_node(access_str) and connections[access_str] is Node3D:
			$Connections.add_child(connections[access_str])
			for connection in connections[access_str].get_children():
				connection.apply_connection()

	for child in $Connections.get_children():
		if not connections.has(child.name):
			$Connections.remove_child(child)
			child.free()
#
	for access_str in intermediate_connectors.keys():
		if not has_node(access_str) and connections[access_str] is Node3D:
			add_child(intermediate_connectors[access_str])

	for child in get_children():
		if child.name.count("_") < 2: continue
		if not intermediate_connectors.has(child.name):
			remove_child(child)
			child.free()
	
	connection_mutex.unlock()


func explicit_connect(connection_name: String, previous_connector: Node3D, 
		current_connector: Node3D, connection_scene: PackedScene, connection_cache: Array) -> Node3D:
	# Dock parent might have a transform -> apply it too
	var current_docks: Node3D = current_connector.get_node("Docks")
	var previous_docks: Node3D = previous_connector.get_node("Docks")
	
	var current_connections = Node3D.new()
	current_connections.name = connection_name
	
	for dock in current_docks.get_children():
		# Create a specified connection-object or use fallback
		var connection: AbstractConnection = connection_scene.instantiate()
		var previous_dock: Node3D = previous_docks.get_node(String(dock.name))
		
		var p1: Vector3 = (
			current_connector.transform * 
			current_docks.transform * 
			dock.transform).origin
		var p2: Vector3 = (
			previous_connector.transform * 
			previous_docks.transform * 
			previous_dock.transform).origin
		
		connection_cache = connection.find_connection_points(p1, p2, 0.0013, [])
		current_connections.call_deferred("add_child", connection)
	
	return current_connections


# FIXME: Do we still need this?
# Connects objects and intermediate objects
func inner_connect(feature_id: int, vertex_id: int, num_connectors_between: int, 
		previous_connector: Node3D, current_connector: Node3D, connection_scene: PackedScene):
	
	var intermediate_connector
	for intermediate_id in range(num_connectors_between):
		var access_string = "{0}_{1}_{2}".format([feature_id, vertex_id, intermediate_id])
		if connections.has(access_string): continue
		intermediate_connector = intermediate_connectors.get(access_string)
		
		var new_con = explicit_connect(
			access_string, 
			previous_connector, 
			intermediate_connector, 
			connection_scene, [])
		
		connections[access_string] = new_con
		
		previous_connector = intermediate_connector
	
	var access_string = "{0}_{1}".format([feature_id, vertex_id])
	var new_con = explicit_connect(
		access_string, 
		previous_connector, 
		intermediate_connector, 
		connection_scene, [])
	
	connections[access_string] = new_con


# FIXME: Do we still need this? 
# FIXME: Seems obsolete by RepeatingObjects
func add_intermediate_connectors(feature_id: int, vertex_id: int, distance: float, num_connectors_between: float,
		previous_connector: Node3D, current_connector: Node3D, connector_scene: PackedScene): 
	# Get the amount of connectors that shall be put between
	var step_size = distance / num_connectors_between
	var direction = (current_connector.position - previous_connector.position).normalized()
	var intermediate_connector: Node3D = connector_scene.instantiate()
	intermediate_connector.transform = current_connector.transform
	intermediate_connector.position = previous_connector.position

	for intermediate_id in range(num_connectors_between):
		var access_str = "{0}_{1}_{2}".format([feature_id, vertex_id, intermediate_id])
		if intermediate_connectors.has(access_str): continue
		
		# As they will be strung on a line they have the same rotation
		intermediate_connector.position += step_size * direction
		intermediate_connector.name = "{0}_{1}_{2}".format([feature_id, vertex_id, intermediate_id])
		
		intermediate_connectors[intermediate_connector.name] = intermediate_connector
		
		intermediate_connector = intermediate_connector.duplicate(DUPLICATE_USE_INSTANTIATION)


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
		# (i.e. they have to face each other); 3 cases:
		# 1. First point, only next point exists
		# 2. x_i; i > 0 & i < n; previous and next point exist
		# 3. Last point, only previous point exists
		# 

		# Case 2 or 3
		if previous_point != Vector3.INF:
			try_look_at_from_pos(current_object, current_point, previous_point)

			# Case 2 
			if index+1 < engine_line.get_point_count():
				# Find the angle between (p_before - p_now) and (p_now - p_next)
				var v1 = current_point - previous_point
				var v2 = next_point - current_point
				
				v1.y = 0.0
				v2.y = 0.0
				
				var angle = v1.signed_angle_to(v2, Vector3.UP)
				# add this angle so its actually the mean between before and next
				current_object.rotation.y += angle / 2

		# Case 1
		elif index+1 < engine_line.get_point_count():
			var pseudo_previous = current_point - (next_point - current_point) * 2.0
			try_look_at_from_pos(current_object, current_point, pseudo_previous)

		# Only y rotation is relevant
		current_object.rotation.x = 0
		current_object.rotation.z = 0
		
		# Does the object have elements that rotate with the slant?
		if current_object.has_node("RotatingElements"):
			for element in current_object.get_node("RotatingElements").get_children():
				var rotation_addition = atan((previous_point.y - next_point.y) / next_point.distance_to(previous_point))
				if abs(abs(element.rotation.y) - PI) < 0.1: rotation_addition = -rotation_addition
				
				element.rotation.x += rotation_addition

		previous_point = current_point
		# Prevent error p_elem->root != this ' is true via call_deferred
		line_root.call_deferred("add_child", current_object)
		
	return line_root


func _get_scene_for_feature(geo_line: GeoFeature, is_connection: bool = false):
	# Get the specifying attribute or null (=> fallbacks)
	var attribute_name = layer_composition.render_info.selector_attribute_name
	var selector_attribute = null
	if attribute_name:
		selector_attribute = geo_line.get_attribute(attribute_name)
	
	var load_from = loaded_connector_scenes
	if is_connection:
		load_from = loaded_connection_scenes
	
	if selector_attribute != null and selector_attribute in layer_composition.render_info.connectors:
		return load_from[selector_attribute]
	else:
		return load_from["fallback"]


func _get_height_at_ground(query_position: Vector3) -> float:
	return layer_composition.render_info.ground_height_layer.get_value_at_position(
		center[0] + query_position.x, center[1] - query_position.z)


# https://github.com/godotengine/godot/blob/4.0.1-stable/scene/resources/curve.cpp#L1784
# avoid "look_at_from_position: Node origin and target are in the same position, look_at() failed."
func try_look_at_from_pos(object: Node3D, from: Vector3, target: Vector3):
	if not from.is_equal_approx(target) and not target.is_equal_approx(Vector3.ZERO):
		object.position = from
		object.look_at_from_position(from, target, object.transform.basis.y)
	else:
		object.position = from


func distance_to_center(pos: Vector3):
	var pos2D = Vector2(pos.x, pos.z)
	var center2D = Vector2(
		position_manager.center_node.position.x,
		position_manager.center_node.position.z)
	return center2D.distance_to(pos2D)


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
