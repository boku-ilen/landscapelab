extends LayerRenderer

var radius = 10000
var max_features = 200

var features
var feature_add_queue = []
var feature_remove_queue = []
var is_loading

var weather_manager: WeatherManager setget set_weather_manager


func set_weather_manager(new_weather_manager):
	weather_manager = new_weather_manager


func load_new_data():
	is_loading = true
	features = layer.get_features_near_position(center[0], center[1], radius, max_features)


func apply_new_data():
	var features_to_persist = {}
	
	for feature in features:
		var node_name = String(feature.get_id())
		
		if not has_node(node_name):
			# This feature is new
			apply_new_feature(feature)
		else:
			# This feature already exists -> persist it
			features_to_persist[node_name] = feature
	
	for child in get_children():
		if not features_to_persist.has(child.name):
			# Remove features which should not be persisted
			child.free()
		else:
			# Move the feature according to the new offset
			update_instance_position(features_to_persist[child.name], child)
	
	is_loading = false
	
	# Apply queues
	for feature in feature_add_queue:
		if not has_node(String(feature.get_id())):
			apply_new_feature(feature)
	
	for feature in feature_remove_queue:
		remove_feature(feature)
	
	feature_add_queue.clear()
	feature_remove_queue.clear()


func apply_new_feature(feature):
	var instance = layer.render_info.object.instance()
	
	instance.name = String(feature.get_id())
	
	update_instance_position(feature, instance)
	feature.connect("point_changed", self, "update_instance_position", [feature, instance])
	
	if "weather_manager" in instance:
		instance.set("weather_manager", weather_manager)
	
	if "feature" in instance:
		instance.set("feature", feature)
	
	if "render_info" in instance:
		instance.set("render_info", layer.render_info)
	
	if "center" in instance:
		instance.set("center", center)
	
	add_child(instance)


func remove_feature(feature):
	if has_node(String(feature.get_id())):
		get_node(String(feature.get_id())).queue_free()


func update_instance_position(feature, obj_instance: Spatial):
	var local_object_pos = feature.get_offset_vector3(-center[0], 0, -center[1])
	
	local_object_pos.y = layer.render_info.ground_height_layer.get_value_at_position(
		center[0] + local_object_pos.x, center[1] - local_object_pos.z)
	obj_instance.transform.origin = local_object_pos
	
	if feature.get_attribute("LL_rot"):
		obj_instance.rotation_degrees.y = float(feature.get_attribute("LL_rot"))


func _ready():
	layer.geo_feature_layer.geo_feature_layer.connect("feature_added", self, "_on_feature_added", [])
	layer.geo_feature_layer.geo_feature_layer.connect("feature_removed", self, "_on_feature_removed", [])
	
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("ObjectRenderer was given an invalid layer!", LOG_MODULE)


func _on_feature_added(feature):
	if not is_loading:
		apply_new_feature(feature)
	else:
		# TODO: We could add a temporary object here for immediate feedback
		feature_add_queue.append(feature)


func _on_feature_removed(feature):
	if not is_loading:
		remove_feature(feature)
	else:
		# TODO: We could potentially already remove the feature here as well since we check whether
		#  it exists when removing later; needs to be tested
		feature_remove_queue.append(feature)


func get_debug_info() -> String:
	return "{0} of maximally {1} objects loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
