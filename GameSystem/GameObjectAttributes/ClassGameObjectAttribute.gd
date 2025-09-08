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
	else:
		# Try to reverse-engineer the current class
		var current_class = find_class_for_attributes(game_object)
		
		if current_class != "":
			return current_class
		elif default_class:
			return default_class


func find_class_for_attributes(game_object) -> String:
	for class_namey in class_names_to_attribute_values.keys():
		var number_of_attributes_here = class_names_to_attribute_values[class_namey].size()
		var number_of_matching_attributes = 0
		
		for attribute_name in class_names_to_attribute_values[class_namey].keys():
			var value_here = game_object.get_attribute(attribute_name)
			var class_value = class_names_to_attribute_values[class_namey][attribute_name]
			
			# Make sure that the types match for comparison
			if class_value is String: value_here = str(value_here)
			else: if value_here is String: value_here = str_to_var(value_here)
			
			if value_here == class_value:
				number_of_matching_attributes += 1
		
		if number_of_matching_attributes == number_of_attributes_here:
			return class_namey
	
	return ""


func set_value(game_object, new_value):
	if allow_change:
		game_objects_to_current_class_names[game_object] = new_value
		
		for attribute_name in class_names_to_attribute_values[new_value].keys():
			game_object.set_attribute(attribute_name, class_names_to_attribute_values[new_value][attribute_name])
