extends GameObjectAttribute
class_name ImplicitRasterGameObjectAttribute

# Implicit attributes are values at the game object's position in a different layer.
# This class remembers the raster layer from which to fetch these values.



var raster_layer


func _init(initial_name, initial_raster_layer):
	name = initial_name
	raster_layer = initial_raster_layer


func get_value(game_object):
	var position = game_object.geo_feature.get_vector3()
	return raster_layer.get_value_at_position(position.x, -position.z)
