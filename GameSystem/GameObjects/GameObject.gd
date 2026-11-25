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
	return util.evaluate_formula(formula,
		func(name): return "(%f)" % float(get_attribute(name))  # Parentheses avoid errors with negative values
	)


func set_attribute(attribute_name, value):
	if not collection.attributes.has(attribute_name):
		logger.error("Invalid attribute with name {n}".format({"n": attribute_name}))
	else:
		collection.attributes[attribute_name].set_value(self, value)


func set_position(_new_position: Vector3):
	pass # To be implemented


func get_position() -> Vector3:
	return Vector3.ZERO # To be implemented
