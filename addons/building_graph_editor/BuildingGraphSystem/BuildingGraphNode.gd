@tool
extends GraphNode
class_name BuildingGraphNode

@export var node_title: String
@export var node_tooltip: String
@export var node_slots: Array
var is_end = false
var type_nums = {}


var elements_by_slot: Array[GraphNodeElement] = []
var is_in_library: bool
var graph_editor: BuildingGraphEditor

const type_num_colors := [
	Color.GREEN,
	Color.RED,
	Color.BLUE,
	Color.WHITE,
	Color.GRAY
]

func build(type_names: Dictionary, graph_edit: BuildingGraphEditor) -> void:
	graph_editor = graph_edit
	title = node_title
	clear_all_slots()
	elements_by_slot = []
	for c in get_children():
		c.queue_free()
	
	for k in type_names:
		type_nums[type_names[k]] = k

	for slot in node_slots.size():
		var slot_elem: GraphNodeElement = GraphNodeElement.element_type_to_class(node_slots[slot]["type"])
		add_child(slot_elem)
		if slot_elem.get_input_type() != "":
			set_slot_enabled_left(slot, true)
			set_slot_type_left(slot, type_nums[slot_elem.get_input_type()])
			set_slot_color_left(slot, type_num_colors[type_nums[slot_elem.get_input_type()]])
		else:
			set_slot_enabled_left(slot, false)
			
			
		if slot_elem.get_output_type() != "":
			set_slot_enabled_right(slot, true)
			set_slot_type_right(slot, type_nums[slot_elem.get_output_type()])
			set_slot_color_right(slot, type_num_colors[type_nums[slot_elem.get_output_type()]])

		else:
			set_slot_enabled_right(slot, false)
			
		if "options" in node_slots[slot].keys():
			slot_elem.options = node_slots[slot]["options"]

		slot_elem.create_ui(node_slots[slot]["label"])
		elements_by_slot.append(slot_elem)
		slot_elem.slot_type = node_slots[slot]["type"]
	
	for slot in node_slots.size():
		var slot_elem = elements_by_slot[slot]
		if slot_elem.has_method("set_array_data") and "element_type" in node_slots[slot].keys():
			var source = int(node_slots[slot]["iterable_slot"])
			elements_by_slot[source].input_connection_updated.connect(
				func (new_source, source_slot): 
					#print("new input")
					var data = new_source.calculate_output(source_slot)
					slot_elem.set_array_data(node_slots[slot]["element_type"], data.map(func (d): return str(d)))
					slot_elem.create_ui(node_slots[slot]["label"])
			)
			slot_elem.set_array_data(node_slots[slot]["element_type"], ["Placeholder"])
			slot_elem.create_ui(node_slots[slot]["label"])
	await get_tree().process_frame
	reset_size()

func calculate_output(slot: int) -> Variant:
	if elements_by_slot[slot] is ConstantValueElement:
		return (elements_by_slot[slot] as ConstantValueElement).get_value()
	elif node_slots[slot]["source_identifier"]:
		return graph_editor.source_data[node_slots[slot]["source_identifier"]].get_value()
	
	return null


func get_id()-> int:
	return hash(name)

func _get_drag_data(at_position: Vector2) -> Variant:
	if is_in_library: 
		var clone: BuildingGraphNode = self.duplicate()
		#print(clone.is_end)
		clone.is_end = is_end
		return clone
	return null
