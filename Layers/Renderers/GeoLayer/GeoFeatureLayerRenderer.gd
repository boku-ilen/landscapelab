extends GeoLayerRenderer


@export var radius := 10000.0
@export var max_features := 1000.0

@onready var plane = get_node("FeaturePlane")

var geo_feature_layer: GeoFeatureLayer
var current_features: Array


func load_new_data():
	var position_x = center[0]
	var position_y = center[1]
	
	if geo_feature_layer:
		geo_feature_layer.get_features_near_position(
			float(position_x),
			float(position_y),
			float(radius),
			max_features
		)
		$MultiMeshInstance2D.multimesh.instance_count = current_features.size()


func apply_new_data():
	if current_features:
		for i in current_features.size():
			var t = Transform2D(0, current_features[i].get_offset_vector3(-center[0], 0, -center[1]))
			$MultiMeshInstance2D.multimesh.set_instance_transform_2d(i, t)


func get_debug_info() -> String:
	return "GeoRasterLayer."
