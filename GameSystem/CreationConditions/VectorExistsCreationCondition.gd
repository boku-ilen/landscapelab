extends CreationCondition
class_name VectorExistsCreationCondition


var vector_layer


func _init(initial_name,initial_vector_layer):
	name = initial_name
	vector_layer = initial_vector_layer


func is_creation_allowed_at_position(position):
	var game_objects_at_position = vector_layer.get_features_near_position(position.x, -position.z, 0.1, 10)
	
	if game_objects_at_position.is_empty():
		return false
	
	return true
