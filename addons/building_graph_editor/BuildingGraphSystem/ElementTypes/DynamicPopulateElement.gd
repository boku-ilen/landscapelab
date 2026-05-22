extends GraphNodeElement
class_name DynamicPopulateElement

var element_type: String
var element_labels: Array
var existing_instances: Array = []

func _init()->void:
	pass

func get_input_type() -> String:
	return ""
func get_output_type() -> String:
	return ""
	
func set_array_data(elem_type, elem_labels):
	element_type = elem_type
	element_labels = elem_labels

func create_ui(label: String) -> void:
	for c in get_children():
		c.queue_free()
	for e in existing_instances:
		e.queue_free()
		var parent = (get_parent() as BuildingGraphNode)
		parent.elements_by_slot = parent.elements_by_slot.filter(func (elem): return elem != e)
	existing_instances = []
	var label_control = Label.new()
	label_control.text = label
	label_control.custom_minimum_size.y = label_control.get_line_height(-1)
	label_control.update_minimum_size()
	add_child(label_control)
	var parent_node: BuildingGraphNode = get_parent()
	var current_slot_count = parent_node.elements_by_slot.size()
	for i in element_labels.size():
		var element_instance = GraphNodeElement.element_type_to_class(element_type)
		element_instance.slot_type = element_type
		var slot = current_slot_count + i
		if element_instance.get_input_type() != "":
			parent_node.set_slot_enabled_left(slot, true)
			parent_node.set_slot_type_left(slot, parent_node.type_nums[element_instance.get_input_type()])
			parent_node.set_slot_color_left(slot, parent_node.type_num_colors[parent_node.type_nums[element_instance.get_input_type()]])
		else:
			parent_node.set_slot_enabled_left(slot, false)
			
			
		if element_instance.get_output_type() != "":
			parent_node.set_slot_enabled_right(slot, true)
			parent_node.set_slot_type_right(slot, parent_node.type_nums[element_instance.get_output_type()])
			parent_node.set_slot_color_right(slot, parent_node.type_num_colors[parent_node.type_nums[element_instance.get_output_type()]])

		else:
			parent_node.set_slot_enabled_right(slot, false)
		get_parent().add_child(element_instance)
		get_parent().elements_by_slot.append(element_instance)
		existing_instances.append(element_instance)
		element_instance.create_ui(element_labels[i])

func get_additional_serialization_data() -> Dictionary:
	return {
		"option_elements": element_labels
	}