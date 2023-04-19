extends RefCounted
class_name RoadInfoData

var property_name: String
var property_value
var property_value_postfix: String
var editable: bool

var object_to_mutate: Object
var variable_to_mutate: String

func _init(property_name: String, property_value, property_value_postfix: String = "", \
			editable: bool = false, object_to_mutate: Object = null, variable_to_mutate: String = ""):
	self.property_name = property_name
	self.property_value = property_value
	self.property_value_postfix = property_value_postfix
	self.editable = editable
	
	self.object_to_mutate = object_to_mutate
	self.variable_to_mutate = variable_to_mutate
