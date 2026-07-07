extends ConstantValueElement
class_name VectorConstantElement

var last_valid_values := ["0.0", "0.0", "0.0"]
const labels := ["x:", "y:", "z:"]
var input_fields: Array[LineEdit] = []
func _init()->void:
	last_valid_values = []
	for i in labels.size():
		last_valid_values.append("0.0")

func get_input_type() -> String:
	return ""
func get_output_type() -> String:
	return "Vector"
	
func get_value() -> Variant:
	return Vector3(float(last_valid_values[0]), float(last_valid_values[1]), float(last_valid_values[2]))
	
func set_value(text: String):
	var parts := text.remove_chars("()").split(", ")
	var value := Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	last_valid_values = [str(value.x), str(value.y), str(value.z)]
	for field_i in input_fields.size():
		input_fields[field_i].text = last_valid_values[field_i]

func create_ui(label: String) -> void:
	for c in get_children():
		c.queue_free()
	var label_control = Label.new()
	label_control.text = label
	label_control.custom_minimum_size.y = label_control.get_line_height(-1)
	label_control.update_minimum_size()
	add_child(label_control)
	for component_index in labels.size():
		var field_label = labels[component_index]
		var field_label_element = Label.new()
		field_label_element.text = field_label
		field_label_element.custom_minimum_size.y = label_control.get_line_height(-1)
		field_label_element.update_minimum_size()
		add_child(field_label_element)
		var input_field: LineEdit = LineEdit.new()
		input_field.text = last_valid_values[component_index]
		input_field.text_submitted.connect(
			func (new_text: String):
				if new_text.is_valid_float():
					#print(new_text)
					last_valid_values[component_index] = new_text 
				else:
					input_field.text = last_valid_values[component_index]
		)
		add_child(input_field)
		input_fields.append(input_field)
