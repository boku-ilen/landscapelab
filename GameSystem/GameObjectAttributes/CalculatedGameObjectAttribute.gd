extends GameObjectAttribute
class_name CalculatedGameObjectAttribute

# Attribute which is the result of multiple other attributes calculated with a formula.
# The formula has a format like $attribute_name_1$ * $attribute_name_2$ + 1


var formula: String
var geo_attribute_name

var previous_value = {}


func _init(initial_name, initial_formula, initial_geo_attribute_name = ""):
	name = initial_name
	formula = initial_formula
	geo_attribute_name = initial_geo_attribute_name


func get_value(game_object):
	# Insert attribute values into formula
	var formated_string = formula
	
	while formated_string.find("$") >= 0:
		var begin_index = formated_string.find("$", 0)
		var length = formated_string.find("$", begin_index + 1) - begin_index
		var slice = formated_string.substr(begin_index + 1, length - 1)
		
		var value = float(game_object.get_attribute(slice))
		
		var value_string = "(%f)" % [value]  # Surround with parentheses to avoid errors with negative values
		
		formated_string = formated_string.left(begin_index) + value_string + formated_string.right(-(begin_index + length + 1))
	
	var expression = Expression.new()
	expression.parse(formated_string)
	
	var result = expression.execute()
	
	if expression.has_execute_failed():
		logger.warn("Parse error with expression: %s" % [formated_string])
		result = 0.0
	
	if geo_attribute_name and allow_change and (not game_object in previous_value or result != previous_value[game_object]):
		previous_value[game_object] = result
		game_object.geo_feature.set_attribute(geo_attribute_name, str(result))
	
	return result
