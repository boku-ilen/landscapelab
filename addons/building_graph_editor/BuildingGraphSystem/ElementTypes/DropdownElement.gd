extends GraphNodeElement
class_name DropdownElement

var options: Array

func _init()->void:
	pass

func get_input_type() -> String:
	return ""
func get_output_type() -> String:
	return ""

var dropdown_field: OptionButton

func create_ui(label: String) -> void:
	for c in get_children():
		c.queue_free()
	var label_control = Label.new()
	label_control.text = label
	label_control.custom_minimum_size.y = label_control.get_line_height(-1)
	label_control.update_minimum_size()
	add_child(label_control)
	dropdown_field = OptionButton.new()
	for option in options:
		dropdown_field.add_item(option)
	add_child(dropdown_field)

func get_additional_serialization_data() -> Dictionary:
	return {
		"choice": options[dropdown_field.selected]
	}