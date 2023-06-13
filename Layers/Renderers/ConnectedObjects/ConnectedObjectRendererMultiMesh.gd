extends FeatureLayerCompositionRendererMultiMesh


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

var last_update_pos := Vector2.INF
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

	max_features = 100
	
	radius = 120.0
	connection_radius = 100.0


func load_feature_instance(geo_line: GeoFeature) -> Node3D:
	var line_root = Node3D.new()
	line_root.name = str(geo_line.get_id())

	var engine_line: Curve3D = geo_line.get_offset_curve3d(-center[0], 0, -center[1])
	var previous_point := Vector3.INF
	var next_point := Vector3.INF

	for index in range(engine_line.get_point_count()):
		# Obtain current point and its height 
		var current_point = engine_line.get_point_position(index)
		current_point.y = _get_height_at_ground(current_point)

		# Try to obtain the next point on the line
		if index+1 < engine_line.get_point_count():
			next_point = engine_line.get_point_position(index + 1)
			next_point.y = _get_height_at_ground(next_point)

		# Create a specified connector-object or use fallback
		var current_object := Node3D.new()

		#
		# Try to resemble a realistic rotation of the connector-objects  
		# (i.e. they have to face each other); 3 cases:
		# 1. First point, only next point exists
		# 2. x_i; i > 0 & i < n; previous and next point exist
		# 3. Last point, only previous point exists
		# 

		# Case 1 or 2 
		if previous_point != Vector3.INF:
			try_look_at_from_pos(current_object, current_point, previous_point)

			# Case 2 
			if index+1 < engine_line.get_point_count():
				# Find the angle between (p_before - p_now) and (p_now - p_next)
				var v1 = current_point - previous_point
				var v2 = next_point - current_point
				var angle = v1.signed_angle_to(v2, Vector3.UP)
				# add this angle so its actually the mean between before and next
				current_object.rotation.y += angle / 2

		# Case 3
		elif index+1 < engine_line.get_point_count():
			try_look_at_from_pos(current_object, current_point, next_point)

		# Only y rotation is relevant
		current_object.rotation.x = 0
		current_object.rotation.z = 0

		previous_point = current_point
		# Prevent error p_elem->root != this ' is true via call_deferred
		line_root.add_child(current_object)

	return line_root


func _get_height_at_ground(query_position: Vector3) -> float:
	return layer_composition.render_info.ground_height_layer.get_value_at_position(
		center[0] + query_position.x, center[1] - query_position.z)


# FIXME: Is this still necessary? Error came from: 
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
