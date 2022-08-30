extends GameObjectAttribute
class_name ImplicitVectorGameObjectAttribute

# Implicit attributes are values at the game object's position in a different layer.
# This class remembers the vector layer and attribute name from which to fetch these values.



var vector_layer
var attribute_name
var default_value


func _init(initial_name, initial_vector_layer, initial_attribute_name, initial_default_value=0):
	name = initial_name
	vector_layer = initial_vector_layer
	attribute_name = initial_attribute_name
	default_value = initial_default_value


func get_value(game_object):
	var game_objects_at_position = vector_layer.get_features_near_position(
			game_object.position.x, -game_object.position.z, 0)
	
	if game_objects_at_position.empty():
		return default_value
	
	var sum = 0.0
	
	for game_object in game_objects_at_position:
		sum += game_object.get_attribute(attribute_name)
	
	return sum
