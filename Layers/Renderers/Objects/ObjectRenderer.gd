extends LayerRenderer

var radius = 1000
var max_features = 50


func load_new_data():
	var features = layer.get_features_near_position(center[0], center[1], radius, max_features)
	
	for feature in features:
		var instance = layer.render_info.object.instance()
		
		var local_object_pos = feature.get_offset_vector3(-center[0], 0, -center[1])
		local_object_pos.y = layer.render_info.ground_height_layer.get_value_at_position(
			center[0] + local_object_pos.x, center[1] - local_object_pos.z)
		
		instance.transform.origin = local_object_pos
		
		add_child(instance)


func apply_new_data():
	# FIXME: add_children here instead of in load_new_data!
	pass


func _ready():
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("ObjectRenderer was given an invalid layer!")
