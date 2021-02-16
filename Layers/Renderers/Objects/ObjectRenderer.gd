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
		instance.transform.origin = feature.get_offset_vector3(-pos_x, 0, -pos_y)
		
		add_child(instance)
	
	set_heights()


func set_heights():
	var height_layer = layer.render_info.ground_height_layer
	
	for object in get_children():
		# TODO: We just use this to get the value of a single pixel.
		#  As this will likely be done more often, we'll want to add this as a
		#  function to Geodot.
		var geoimage = height_layer.get_image(
			# TODO: Get position from outside
			object.transform.origin.x + 420776.711,
			-object.transform.origin.z + 453197.501,
			1,
			1,
			1
		)
		var height = geoimage.get_image()
		
		height.lock()
		object.translation.y = height.get_pixel(0, 0).r
		height.unlock()
