extends GameObjectAttribute
class_name StaticAttribute

# An attribute with a static value which it always returns, regardless of the game object.


var value


func _init(initial_name,initial_value):
	name = initial_name
	value = initial_value


func get_value(_game_object):
	return value
