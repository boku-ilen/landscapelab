extends GameObjectAttribute
class_name ClassGameObjectAttribute

# Explicit attributes correspond directly to attributes of features.
# This class thus remembers the name of the corresponding attribute in the GeoFeature.


var class_names_to_attribute_values
var game_objects_to_current_class_names = {}
var default_class


func _init(initial_name, initial_class_names_to_attribute_names):
	name = initial_name
	class_names_to_attribute_values = initial_class_names_to_attribute_names


func get_value(game_object):
	if game_object in game_objects_to_current_class_names:
		return game_objects_to_current_class_names[game_object]
	elif default_class:
		return default_class
	#else:
		#return class_names_to_attribute_values.keys()[0]


func set_value(game_object, new_value):
	if allow_change:
		game_objects_to_current_class_names[game_object] = new_value
		
		for attribute_name in class_names_to_attribute_values[new_value].keys():
			game_object.set_attribute(attribute_name, class_names_to_attribute_values[new_value][attribute_name])
