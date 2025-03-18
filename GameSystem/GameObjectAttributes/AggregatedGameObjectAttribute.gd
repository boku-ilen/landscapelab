extends GameObjectAttribute
class_name AggregatedGameObjectAttribute

# Attribute whose value is chosen based on the values of a number of other attributes.
# Allows translating a table with arbitrary dimension into a GameObjectAttribute.


var attributes: Array
var values: Dictionary


func _init(initial_name, initial_attributes, initial_values):
	name = initial_name
	attributes = initial_attributes
	values = initial_values


func get_value(game_object):
	var current_table_level = values
	
	for attribute in attributes:
		var attribute_value = "%d" % [int(game_object.get_attribute(attribute))]
		
		# Return 0 if this was not defined
		if not attribute_value in current_table_level: return 0
		
		var value_here = current_table_level[attribute_value]
		
		if value_here is Dictionary:
			current_table_level = value_here
		else:
			return value_here
