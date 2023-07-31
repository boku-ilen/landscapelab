extends LayerCompositionRenderer

var radius = 3000.0
var max_features = 2000

var features
var feature_add_queue = []
var feature_remove_queue = []
var is_loading

var weather_manager: WeatherManager :
	get:
		return weather_manager 
	set(new_weather_manager):
		weather_manager = new_weather_manager


func set_time_manager():
	for child in get_children():
		if "time_manager" in child:
			child.set("time_manager", time_manager)


func is_new_loading_required(position_diff: Vector3) -> bool:
	if Vector2(position_diff.x, position_diff.z).length_squared() >= pow(radius / 4.0, 2):
		return true
	
	return false


func full_load():
	is_loading = true
	features = layer_composition.render_info.geo_feature_layer.get_features_near_position(float(center[0]), float(center[1]), radius, max_features)


func adapt_load(_diff: Vector3):
	super.adapt_load(_diff)
	
	# Essentially the same as full_load since that is already optimized
	features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
			float(center[0]) + position_manager.center_node.position.x,
			float(center[1]) - position_manager.center_node.position.z,
			radius, max_features
	)
	call_deferred("apply_new_data")


func apply_new_data():
	var features_to_persist = {}
	
	for feature in features:
		var node_name = var_to_str(feature.get_id())
		
		if not has_node(node_name):
			# This feature is new
			apply_new_feature(feature)

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
		if not has_node(var_to_str(feature.get_id())):
			apply_new_feature(feature)
	
	for feature in feature_remove_queue:
		remove_feature(feature)
	
	feature_add_queue.clear()
	feature_remove_queue.clear()
	
	logger.info("Applied new ObjectRenderer data for %s" % [name])


func apply_new_feature(feature):
	var instance = load(layer_composition.render_info.object).instantiate()
	
	instance.name = var_to_str(feature.get_id())
	feature.connect("point_changed",Callable(self,"update_instance_position").bind(feature, instance))
	
	if "weather_manager" in instance and weather_manager:
		instance.set("weather_manager", weather_manager)
	
	if "time_manager" in instance and time_manager:
		instance.set("time_manager", time_manager)
	
	if "feature" in instance:
		instance.set("feature", feature)
	
	if "render_info" in instance:
		instance.set("render_info", layer_composition.render_info)
	
	if "center" in instance:
		instance.set("center", center)
	
	if "height_layer" in instance:
		instance.set("height_layer", layer_composition.render_info.ground_height_layer)
	
	add_child(instance)


func remove_feature(feature):
	if has_node(var_to_str(feature.get_id())):
		get_node(var_to_str(feature.get_id())).queue_free()


func update_instance_position(feature, obj_instance: Node3D):
	var local_object_pos = feature.get_offset_vector3(-center[0], 0, -center[1])
	
	if obj_instance.has_method("set_height"):
		# Object has custom method for getting the height
		obj_instance.set_height(local_object_pos)
		local_object_pos.y = 0.0
	elif not obj_instance.transform.origin.y > 0.0:
		local_object_pos.y = layer_composition.render_info.ground_height_layer.get_value_at_position(
			center[0] + local_object_pos.x, center[1] - local_object_pos.z)
	else:
		local_object_pos.y = obj_instance.transform.origin.y
	
	obj_instance.transform.origin = local_object_pos
	
	if feature.get_attribute("LL_rot"):
		obj_instance.rotation.y = deg_to_rad(float(feature.get_attribute("LL_rot")))


func _ready():
	super._ready()
	layer_composition.render_info.geo_feature_layer.connect("feature_added",Callable(self,"_on_feature_added").bind())
	layer_composition.render_info.geo_feature_layer.connect("feature_removed",Callable(self,"_on_feature_removed").bind())

	if not layer_composition.is_valid():
		logger.error("ObjectRenderer was given an invalid layer!")


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
		# TODO: We could potentially already remove_at the feature here as well since we check whether
		#  it exists when removing later; needs to be tested
		feature_remove_queue.append(feature)


func get_debug_info() -> String:
	return "{0} of maximally {1} objects loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
