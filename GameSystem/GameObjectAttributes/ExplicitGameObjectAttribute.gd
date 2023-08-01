extends GameObjectAttribute
class_name ExplicitGameObjectAttribute

# Explicit attributes correspond directly to attributes of features.
# This class thus remembers the name of the corresponding attribute in the GeoFeature.


var geo_attribute_name


func _init(initial_name,initial_geo_attribute_name):
	name = initial_name
	geo_attribute_name = initial_geo_attribute_name


func get_value(game_object):
	return game_object.geo_feature.get_attribute(geo_attribute_name)
