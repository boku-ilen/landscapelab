extends LayerRenderer

var radius = 1000
var max_features = 500


func load_new_data():
	var lines = layer.get_features_near_position(center[0], center[1], radius, max_features)

	for line in lines:
		var line_visualization_instance = layer.render_info.line_visualization.instance()
		line_visualization_instance.curve = line.get_offset_curve3d(-center[0], 0, -center[1])

		var width = float(line.get_attribute("WIDTH"))
		width = max(width, 2) # It's sometimes -1 in the data

		# FIXME: widht logic
		add_child(line_visualization_instance)


func apply_new_data():
	# FIXME: add_children here instead of in load_new_data!
	pass


func _ready():
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("PathRenderer was given an invalid layer!")
