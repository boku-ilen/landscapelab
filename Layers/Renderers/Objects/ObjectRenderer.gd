extends LayerRenderer

var radius = 1000
var max_features = 50


func _ready():
	# get_features_near_position(pos_x: float, pos_y: float, radius: float, max_features: int)
	# add `object` instances at those positions
	# if asset_to_spawn:
	#	var instance = asset_to_spawn.instance()
	#	instance.transform.origin = geopoint.get_offset_vector3(pos_manager.x, 0, -pos_manager.z)
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("ObjectRenderer was given an invalid layer!")
	
	# TODO: Move this position out, pass it from the World node down to here
	var pos_x = 420776.711
	var pos_y = 453197.501
	
	var features = layer.get_features_near_position(pos_x, pos_y, radius, max_features)
	
	for feature in features:
		var instance = layer.render_info.object.instance()
		# TODO: Get the actual height at this position - add a height layer to this?
		instance.transform.origin = feature.get_offset_vector3(-pos_x, 500, -pos_y)
		
		add_child(instance)
