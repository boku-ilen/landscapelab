extends Layer
class_name FeatureLayer

# is of type Geodot.GeoRasterLayer
# TODO: look up how to access classes from gdnative for typing
var geo_feature_layer


func get_all_features():
	return geo_feature_layer.get_all_features()


func get_features_near_position(pos_x: float, pos_y: float, radius: float, max_features: int):
	return geo_feature_layer.get_features_near_position(pos_x, pos_y, radius, max_features)


func is_valid():
	return geo_feature_layer && geo_feature_layer.is_valid()
