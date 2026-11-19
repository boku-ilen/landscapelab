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
	var result = util.evaluate_formula(formula,
		func(name): return "(%f)" % float(game_object.get_attribute(name))  # Parentheses avoid errors with negative values
	)
	
	if geo_attribute_name and allow_change and (not game_object in previous_value or result != previous_value[game_object]):
		previous_value[game_object] = result
		game_object.geo_feature.set_attribute(geo_attribute_name, str(result))
	
	return result
