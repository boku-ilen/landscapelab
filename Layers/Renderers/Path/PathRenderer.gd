extends LayerRenderer

var radius = 1000
var max_features = 1000

var line_vis_instances = []


func load_new_data(position_diff: Vector3):
	var geo_lines = layer.get_features_near_position(center[0], center[1], radius, max_features)
	
	for geo_line in geo_lines:
		var line_vis_instance = layer.render_info.line_visualization.instantiate()
		update_line(geo_line, line_vis_instance)
		geo_line.connect("line_changed",Callable(self,"update_new_line").bind(geo_line, line_vis_instance))
		
		line_vis_instances.append(line_vis_instance)


func apply_new_data():
	# First clear the old objects, then add the new ones
	for child in get_children():
		child.queue_free()
	
	for instance in line_vis_instances:
		add_child(instance)
	
	line_vis_instances.clear()


func update_line(geo_line, line_vis_instance: Path3D):
	line_vis_instance.curve = geo_line.get_offset_curve3d(-center[0], 0, -center[1])
	
	var width = float(geo_line.get_attribute("WIDTH"))
	width = max(width, 2) # It's sometimes -1 in the data
	# FIXME: widht logic
	
	_adjust_height(line_vis_instance.curve)


# Adjust the height to a possible changed terrain
func _adjust_height(curve: Curve3D):
	for index in range(curve.get_point_count()):
		var point = curve.get_point_position(index)
		point = Vector3(point.x, _get_height_at_ground(point), point.z)
		curve.set_point_position(index, point)


# Returns the current ground height
func _get_height_at_ground(position: Vector3):
	return layer.render_info.ground_height_layer.get_value_at_position(
		center[0] + position.x, center[1] - position.z)


func _ready():
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("PathRenderer was given an invalid layer!", LOG_MODULE)


func get_debug_info() -> String:
	return "{0} of maximally {1} paths loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
