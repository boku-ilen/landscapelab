extends Layer
class_name FeatureLayer

# is of type Geodot.GeoFeatureLayer
# TODO: look up how to access classes from gdnative for typing
var geo_feature_layer


func create_feature():
	return geo_feature_layer.create_feature()


func get_feature_by_id(id):
	return geo_feature_layer.get_feature_by_id(id)


func get_all_features():
	return geo_feature_layer.get_all_features()


func get_features_near_position(pos_x: float, pos_y: float, radius: float, max_features: int):
	return geo_feature_layer.get_features_near_position(pos_x, pos_y, radius, max_features)


func is_valid():
	return geo_feature_layer && geo_feature_layer.is_valid()


# Workaround as sometimes it is necessary to do [...].geo_feature_layer.geo_feature_layer
# and so on ...
# FIXME: it works but might be a bit confusing ...
func get_lowest_geo_feature_layer(current=geo_feature_layer):
	if geo_feature_layer in current:
		return get_lowest_geo_feature_layer(current.geo_feature_layer)
	else:
		return current


func get_path():
	if geo_feature_layer.get_dataset() == null:
		return geo_feature_layer.get_name()
	return geo_feature_layer.get_dataset().get_path()


func get_name():
	if geo_feature_layer.get_dataset() == null:
		return geo_feature_layer.get_name().substr(geo_feature_layer.get_name().find_last("/"))
	return geo_feature_layer.get_name()
