extends FeatureLayerCompositionRenderer


var instance_mapping: Dictionary
var weather_manager: WeatherManager :
	get:
		return weather_manager 
	set(new_weather_manager):
		weather_manager = new_weather_manager


func set_time_manager():
	for child in get_children():
		if "time_manager" in child:
			child.set("time_manager", time_manager)


func _ready():
	radius = layer_composition.render_info.radius
	
	# "Pre"load instances to save time during instantiation (duplicate with FLAG=5)
	for key in layer_composition.render_info.objects:
		instance_mapping[key] = load(layer_composition.render_info.objects[key]).instantiate()
	
	super._ready()


func load_feature_instance(feature: GeoFeature) -> Node3D:
	var instance_key = "default"
	# If selector attribute is set and we find an object then overwrite
	var selector_attrib = layer_composition.render_info.selector_attribute_name
	if feature.get_attribute(selector_attrib) in layer_composition.render_info.objects:
		instance_key = feature.get_attribute(selector_attrib)
	
	var instance = instance_mapping[instance_key].duplicate(5)
	instance.name = str(feature.get_id())
	
	# Set meta infos
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
	
	set_instance_pos(feature, instance)

	return instance


func set_instance_pos(feature, obj_instance):
	if not feature is GeoPoint:
		logger.warn("Provided feature: %s is not a valid GeoPoint" % [feature])
		return
	
	var local_object_pos = feature.get_offset_vector3(-center[0], 0, -center[1])
	
	if obj_instance.has_method("set_height"):
		# Object has custom method for getting the height
		obj_instance.set_height(local_object_pos)
		local_object_pos.y = 0.0
	elif not obj_instance.transform.origin.y > 0.0:
		local_object_pos.y = layer_composition.render_info.ground_height_layer.get_value_at_position(
			center[0] + local_object_pos.x, center[1] - local_object_pos.z)
		
		# FIXME: Workaround for nodata value when placing offshore wind turbines outside of data
		local_object_pos.y = max(local_object_pos.y, 0.0)
	else:
		local_object_pos.y = obj_instance.transform.origin.y
	
	obj_instance.transform.origin = local_object_pos
	
	if feature.get_attribute("LL_rot"):
		obj_instance.rotation.y = -deg_to_rad(float(feature.get_attribute("LL_rot")))
	
	if feature.get_attribute("LL_scale"):
		obj_instance.scale = Vector3.ONE * float(feature.get_attribute("LL_scale"))
	
	if feature.get_attribute("LL_h_off"):
		obj_instance.transform.origin.y += float(feature.get_attribute("LL_h_off"))


func get_debug_info() -> String:
	return "{0} of maximally {1} objects loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
