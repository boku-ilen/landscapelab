extends GameObject
class_name PlayerGameObject


var player_node


func _init(initial_id: int, initial_collection, initial_player_node).(initial_id, initial_collection):
	id = initial_id
	collection = initial_collection
	player_node = initial_player_node


func get_attribute(attribute_name):
	return null # TODO: Implement specific to the player?


func set_position(new_position: Vector3):
	new_position.z = -new_position.z  # FIXME: why is this needed?
	player_node.set_world_position(new_position)


func get_position():
	var world_pos_array = player_node.get_world_position()
	return Vector3(world_pos_array[0], world_pos_array[1], world_pos_array[2])
