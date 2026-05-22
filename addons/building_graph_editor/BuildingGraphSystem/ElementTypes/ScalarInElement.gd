extends GraphNodeElement
class_name ScalarInElement

func _init()->void:
	pass

func get_input_type() -> String:
	return "Scalar"
func get_output_type() -> String:
	return ""
	
func create_ui(label: String) -> void:
	for c in get_children():
		c.queue_free()
	var label_control = Label.new()
	label_control.text = label
	label_control.custom_minimum_size.y = label_control.get_line_height(-1)
	label_control.update_minimum_size()
	add_child(label_control)


