extends LayerRenderer

var radius = 800
var max_features = 50

var features


func load_new_data():
	features = layer.get_features_near_position(center[0], center[1], radius, max_features)


func apply_new_data():
	# First clear the old objects, then add the new ones
	for child in get_children():
		child.free()
	
	for feature in features:
		apply_new_feature(feature)


func apply_new_feature(feature):
	var instance = layer.render_info.object.instance()
	
	update_instance_position(feature, instance)
	feature.connect("point_changed", self, "update_instance_position", [feature, instance])
	
	add_child(instance)


func update_instance_position(feature, obj_instance):
	var local_object_pos = feature.get_offset_vector3(-center[0], 0, -center[1])
	
	local_object_pos.y = layer.render_info.ground_height_layer.get_value_at_position(
		center[0] + local_object_pos.x, center[1] - local_object_pos.z)
	obj_instance.transform.origin = local_object_pos


func _ready():
	layer.geo_feature_layer.connect("feature_added", self, "apply_new_feature")
	if not layer is FeatureLayer or not layer.is_valid():
		logger.error("ObjectRenderer was given an invalid layer!")
