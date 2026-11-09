extends Object
class_name GameObject

var id := -1
var collection: GameObjectCollection


func _init(initial_id: int, initial_collection):
	id = initial_id
	collection = initial_collection


func get_attributes():
	var attributes = {}
	
	for attribute_name in collection.attributes.keys():
		attributes[attribute_name] = get_attribute(attribute_name)
	
	return attributes


func get_attribute(attribute_name: String):
	if not collection.attributes.has(attribute_name):
		logger.error("Invalid attribute with name {n}".format({"n": attribute_name}))
		return null
	
	return collection.attributes[attribute_name].get_value(self)


func parse_expression(formula: String):
	# Insert attribute values into formula
	var formated_string = formula
	
	while formated_string.find("$") >= 0:
		var begin_index = formated_string.find("$", 0)
		var length = formated_string.find("$", begin_index + 1) - begin_index
		var slice = formated_string.substr(begin_index + 1, length - 1)
		
		var value = float(get_attribute(slice))
		
		var value_string = "(%f)" % [value]  # Surround with parentheses to avoid errors with negative values
		
		formated_string = formated_string.left(begin_index) + value_string + formated_string.right(-(begin_index + length + 1))
	
	var expression = Expression.new()
	expression.parse(formated_string)
	
	var result = expression.execute()
	
	if expression.has_execute_failed():
		logger.warn("Parse error with expression: %s" % [formated_string])
		result = 0.0
	
	return result


func set_attribute(attribute_name, value):
	if not collection.attributes.has(attribute_name):
		logger.error("Invalid attribute with name {n}".format({"n": attribute_name}))
	else:
		collection.attributes[attribute_name].set_value(self, value)


func set_position(_new_position: Vector3):
	pass # To be implemented


func get_position() -> Vector3:
	return Vector3.ZERO # To be implemented
