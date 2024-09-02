extends Object
class_name GameObject

var id := -1
var collection: GameObjectCollection


func _init(initial_id: int, initial_collection):
	id = initial_id
	collection = initial_collection


func get_attribute(_attribute_name):
	return null # To be implemented


func set_attribute(_attribute_name, _value):
	pass # To be implemented


func set_position(_new_position: Vector3):
	pass # To be implemented


func get_position() -> Vector3:
	return Vector3.ZERO # To be implemented
