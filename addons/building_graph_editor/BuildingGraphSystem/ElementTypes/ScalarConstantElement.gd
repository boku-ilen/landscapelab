extends ConstantValueElement
class_name ScalarConstantElement

var last_valid_value = "0.0"
var input_field: LineEdit
func _init()->void:
	pass

func get_input_type() -> String:
	return ""
func get_output_type() -> String:
	return "Scalar"
	
func get_value() -> Variant:
	return float(last_valid_value)

func set_value(value):
	last_valid_value = str(value)
	input_field.text = last_valid_value

func create_ui(label: String) -> void:
	for c in get_children():
		c.queue_free()
	var label_control = Label.new()
	label_control.text = label
	label_control.custom_minimum_size.y = label_control.get_line_height(-1)
	label_control.update_minimum_size()
	add_child(label_control)
	input_field = LineEdit.new()
	input_field.text = last_valid_value
	input_field.text_submitted.connect(
		func (new_text: String):
			if new_text.is_valid_float():
				#print(new_text)
				last_valid_value = new_text 
			else:
				input_field.text = last_valid_value
	)
	add_child(input_field)
	
