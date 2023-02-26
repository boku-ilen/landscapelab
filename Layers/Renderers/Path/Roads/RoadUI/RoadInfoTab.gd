extends Control
class_name RoadInfoTab

func add_property(property_name: String, property_value: String) -> void:
	var property: Label = Label.new()
	property.clip_text = true
	property.text = property_name
	$Properties.add_child(property)
	
	var value: Label = Label.new()
	value.clip_text = true
	value.text = property_value
	$Values.add_child(value)
