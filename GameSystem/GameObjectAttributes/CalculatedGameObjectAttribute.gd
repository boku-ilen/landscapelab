extends GameObjectAttribute
class_name CalculatedGameObjectAttribute

# Attribute which is the result of multiple other attributes calculated with a formula.
# The formula has a format like $attribute_name_1$ * $attribute_name_2$ + 1


var formula: String


func _init(initial_name, initial_formula):
	name = initial_name
	formula = initial_formula


func get_value(game_object):
	# Insert attribute values into formula
	var formated_string = formula
	
	while formated_string.find("$") > 0:
		var begin_index = formated_string.find("$", 0)
		var length = formated_string.find("$", begin_index + 1) - begin_index
		var slice = formated_string.substr(begin_index + 1, length - 1)
		
		var value = game_object.get_attribute(slice)
		
		formated_string = formated_string.left(begin_index) + str(value) + formated_string.right(-(begin_index + length + 1))
	
	var expression = Expression.new()
	expression.parse(formated_string)
	var result = expression.execute()
	
	return result
