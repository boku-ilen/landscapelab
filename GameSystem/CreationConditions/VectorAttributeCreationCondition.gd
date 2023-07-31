extends CreationCondition
class_name VectorAttributeCreationCondition


var vector_layer
var attribute_name
var attribute_comparator
var default_return


func _init(initial_name,initial_vector_layer,initial_attribute_name,initial_attribute_comparator,initial_default_return=false):
	name = initial_name
	vector_layer = initial_vector_layer
	attribute_name = initial_attribute_name
	attribute_comparator = initial_attribute_comparator
	default_return = initial_default_return


func is_creation_allowed_at_position(position):
	var game_objects_at_position = vector_layer.get_features_near_position(position.x, -position.z, 0.1, 10)
	
	if game_objects_at_position.is_empty():
		return default_return
	
	for game_object in game_objects_at_position:
		if game_object.get_attribute(attribute_name) != attribute_comparator:
			return false
	
	return true
