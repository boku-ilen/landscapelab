extends LayerRenderer

var radius = 1000
var max_features = 500

var instances = []


func load_new_data():
	var lines = layer.get_features_near_position(center[0], center[1], radius, max_features)
	
	for line in lines:
		var line_visualization_instance = layer.render_info.line_visualization.instance()
		line_visualization_instance.curve = line.get_offset_curve3d(-center[0], 0, -center[1])
		
		for index in range(line_visualization_instance.curve.get_point_count()):
			var point = line_visualization_instance.curve.get_point_position(index)
			var adjusted = Vector3(point.x, _adjust_height(point), point.z)
			line_visualization_instance.curve.set_point_position(index, adjusted)
		
		var width = float(line.get_attribute("WIDTH"))
		width = max(width, 2) # It's sometimes -1 in the data
	
		# FIXME: widht logic
		
		instances.append(line_visualization_instance)


# Adjust the height to represent it on the terrain
func _adjust_height(position: Vector3):
	return layer.render_info.ground_height_layer.get_value_at_position(
		center[0] + position.x, center[1] - position.z)


func apply_new_data():
	for child in get_children():
		child.queue_free()
	
	for instance in instances:
		add_child(instance)
	
	instances.clear()

func _ready():
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("PathRenderer was given an invalid layer!")
