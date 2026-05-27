@tool
extends GraphEdit
class_name BuildingGraphEditor

@export var library_container: BoxContainer
@export var floor_definition_picker: FloorDefinitionPicker
@export var load_button: Button
@export var validate_button: Button
@export var save_button: Button
var current_resource: FloorDefinition
@export var node_definitions: JSON
@export var sample_json_data: JSON
@export var validation_runner: BuildingGraphRunner
var source_data: Dictionary[String, NodeDataSource] = {
	"all_module_ids": FixedInputDataSource.new(["a"])
}

@export var preview_building: PreviewBuilding

var types_by_id = {}
var node_objects: Dictionary[StringName, BuildingGraphNode] = {}

func _ready() -> void:
	var available_nodes = node_definitions.data["available_nodes"]
	for node in available_nodes.keys():
		var node_elem = BuildingGraphNode.new()
		node_elem.node_title = node
		node_elem.node_tooltip = available_nodes[node]["tooltip"]
		var slot_objs = []
		for slot in available_nodes[node]["slots"]:
			var str_type = slot["type"]
			slot_objs.append({
				"type": GraphNodeElement.element_type_to_class(str_type),
				"label": slot["label"]
			})
		if "is_end" in available_nodes[node].keys():
			node_elem.is_end = available_nodes[node]["is_end"]
		node_elem.node_slots = available_nodes[node]["slots"]
		node_elem.is_in_library = true
		library_container.add_child(node_elem)
		node_elem.build(type_names, self)
	floor_definition_picker.resource_changed.connect(func (r: Resource): 
		if not r:
			save_button.visible = false
			return
		
		current_resource = r as FloorDefinition
		if not current_resource.selection_rules or not current_resource.selection_rules.data:
			var dialog = FileDialog.new()
			add_child(dialog)
			dialog.filters = PackedStringArray(["*.json;JSON files;application/json"])
			dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			dialog.popup()
			await dialog.file_selected
			#print("file selected: ", dialog.current_dir, "/", dialog.current_file)
			var filename = dialog.current_dir + "/" + dialog.current_file
			remove_child(dialog)
			dialog.queue_free()
			var file = FileAccess.open(filename, FileAccess.WRITE)
			var empty_save = "{\"nodes\":[], \"connections\":[]}"			
			file.store_string(empty_save)
			file.flush()
			file.close()
			current_resource.selection_rules = JSON.new()
			current_resource.selection_rules.resource_path = filename
			deserialize_tree(JSON.parse_string(empty_save))
		else:
			deserialize_tree(current_resource.selection_rules.data)
		save_button.visible = true
		source_data["all_module_ids"].held_data = current_resource.walls.map(func (w: WallTileDefinition): return w.facade_feature_id)
	)
	connection_request.connect(process_connection_request)
	disconnection_request.connect(disconnect_node)
	load_button.pressed.connect(func (): 
		var dialog = FileDialog.new()
		add_child(dialog)
		dialog.filters = PackedStringArray(["*.json;JSON files;application/json"])
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.popup()
		await dialog.file_selected
		#print("file selected: ", dialog.current_dir, "/", dialog.current_file)
		var filename = dialog.current_dir + "/" + dialog.current_file
		remove_child(dialog)
		dialog.queue_free()
		var file = FileAccess.open(filename, FileAccess.READ)
		
		deserialize_tree(JSON.parse_string(file.get_as_text()))
	)
	save_button.pressed.connect(func ():
		var text := serialize_tree()
		var file := FileAccess.open(current_resource.selection_rules.resource_path, FileAccess.WRITE)
		file.store_string(text)
		file.flush()
		file.close()
		current_resource.selection_rules.data = JSON.parse_string(text)
		)
	validate_button.pressed.connect(validate_graph)
	
func get_actual_slot(node, port, is_input):
	#print("finding actual slot for port", port)
	var slots := node_objects[node].elements_by_slot
	var real_idx = port
	var remaining_ports = port
	for i in slots.size():
		if ((slots[i].get_input_type() != "") == is_input and (slots[i].get_output_type() != "") == not is_input):
			remaining_ports -= 1
			if remaining_ports < 0:
				real_idx = i 
				break
	return real_idx

func get_actual_port(node, slot, is_input):
	var slots := node_objects[node].elements_by_slot
	var relevant = slots.filter(func (x): return (x.get_input_type() != "") == is_input and (x.get_output_type() != "") == not is_input)
	var actual_idx = relevant.find(slots[slot])
	return actual_idx
func process_connection_request(from_node, from_port, to_node, to_port):
	var real_to = to_node
	var real_to_port = get_actual_slot(to_node, to_port, true)
	#print(real_to_port, ", ", node_objects[to_node].elements_by_slot[real_to_port].get_input_type())
	var real_from = from_node
	var real_from_port = get_actual_slot(from_node, from_port, false)
	var inverted = false
	if node_objects[to_node].elements_by_slot[real_to_port].get_input_type() == "":
		real_to = from_node
		real_to_port = get_actual_slot(from_node, from_port, true)
		real_from = to_node
		real_from_port = get_actual_slot(to_node, to_port, false)
		inverted = true
		if node_objects[real_to].elements_by_slot[real_to_port].get_input_type() == "":
			print("neither input nor output?")
			return

	#print(real_to, ", ", real_to_port)
	var existing = connections.filter(func (dict): return (dict["to_node"] == real_to and get_actual_slot(dict["to_node"],dict["to_port"],true) == real_to_port))
	#print(existing)
	if existing.size() > 0:
		return
	var real_dest_port = to_port
	if inverted:
		real_dest_port = from_port
	connect_node(real_from, get_actual_port(real_from, real_from_port, false), real_to, get_actual_port(real_to, real_to_port, true))
	node_objects[real_to].elements_by_slot[real_to_port].input_connection_updated.emit(node_objects[real_from], real_from_port)
	
func serialize_tree()->String:
	var end_nodes: Array[BuildingGraphNode] = node_objects.values().filter(func (e): return e.is_end)
	if len(end_nodes) != 1:
		print("incorrect number of end nodes!")
		return ""
	var end_node: BuildingGraphNode = end_nodes[0]
	var all_nodes: Array[BuildingGraphNode] = node_objects.values()
	var edges: Array = _serialize_recursive(end_node.name)
	var slots_by_node: Dictionary[BuildingGraphNode, Array]= {}
	for node in all_nodes:
		var definition = node_definitions.data["available_nodes"][node.title]

		slots_by_node[node] = []
		for slot_i in node.elements_by_slot.size():
			var input_type_str = "connection"
			if definition["slots"].size() > slot_i:
				if "source_identifier" in definition["slots"][slot_i].keys():
					input_type_str = "data_source"
				elif "constant_value" in node.elements_by_slot[slot_i].get_additional_serialization_data().keys():
					input_type_str = "constant"
			var slot_dict = {
				"slot_data": node.elements_by_slot[slot_i].get_additional_serialization_data(),
				"slot_input_type": input_type_str,
				"type": node.elements_by_slot[slot_i].slot_type
			}
			if input_type_str == "data_source":
				slot_dict["data_source_identifier"] = definition["slots"][slot_i]["source_identifier"]
			slots_by_node[node].append(slot_dict)
	return JSON.stringify({
		"nodes": all_nodes.map(func (n: BuildingGraphNode): return {
			"node_type": n.title,
			"node_id": n.get_id(),
			"slots": slots_by_node[n]
		}),
		"connections": edges
	})
	
func deserialize_tree(data: Dictionary):
	for node_obj in node_objects.values():
		node_obj.queue_free()
	node_objects = {}
	connections = []
	var node_data: Array = data["nodes"]
	var edge_data: Array = data["connections"]
	var candidates: Dictionary = node_definitions.data["available_nodes"]
	var new_nodes: Array[BuildingGraphNode]
	var nodes_by_id: Dictionary[float, BuildingGraphNode]
	for node_element in node_data:
		var type = node_element["node_type"]
		var template = candidates[type]
		
		var node_elem = BuildingGraphNode.new()
		node_elem.node_title = type
		node_elem.node_tooltip = template["tooltip"]
		var slot_objs = []
		for slot_i in template["slots"].size():
			var slot = template["slots"][slot_i]
			var str_type = slot["type"]
			slot_objs.append({
				"type": GraphNodeElement.element_type_to_class(str_type),
				"label": slot["label"]
			})
			
		if "is_end" in template.keys():
			node_elem.is_end = template["is_end"]
		node_elem.node_slots = template["slots"]
		nodes_by_id[node_element["node_id"]] = node_elem
		add_child(node_elem)
		node_objects[node_elem.name] = node_elem
		node_elem.build(type_names, self)
		for slot in template["slots"].size():
			if "constant_value" in node_element["slots"][slot]["slot_data"]:
				(node_elem.elements_by_slot[slot] as ConstantValueElement).set_value(node_element["slots"][slot]["slot_data"]["constant_value"])
			if "choice" in node_element["slots"][slot]["slot_data"]:
				(node_elem.elements_by_slot[slot] as DropdownElement).dropdown_field.selected = template["slots"][slot]["options"].find(node_element["slots"][slot]["slot_data"]["choice"])
			if node_elem.elements_by_slot[slot] is DynamicPopulateElement:
				(node_elem.elements_by_slot[slot] as DynamicPopulateElement).set_array_data(template["slots"][slot]["element_type"],node_element["slots"][slot]["slot_data"]["option_elements"])
				(node_elem.elements_by_slot[slot] as DynamicPopulateElement).create_ui("foo")
	var skipped_edges = []
	for connection in edge_data:
		if connection["from_slot"] >= nodes_by_id[connection["from_node"]].elements_by_slot.size() or connection["to_slot"] >= nodes_by_id[connection["to_node"]].elements_by_slot.size():
			skipped_edges.append(connection)
			continue
		process_connection_request(nodes_by_id[connection["from_node"]].name, get_actual_port(nodes_by_id[connection["from_node"]].name, int(connection["from_slot"]), false),
		nodes_by_id[connection["to_node"]].name, get_actual_port(nodes_by_id[connection["to_node"]].name, int(connection["to_slot"]), true))
	for connection in skipped_edges:
		process_connection_request(nodes_by_id[connection["from_node"]].name, get_actual_port(nodes_by_id[connection["from_node"]].name, int(connection["from_slot"]), false),
			nodes_by_id[connection["to_node"]].name, get_actual_port(nodes_by_id[connection["to_node"]].name, int(connection["to_slot"]), true))
	
	await get_tree().process_frame
	arrange_nodes()

func _serialize_recursive(root_node: StringName)-> Array:
	var root_node_obj: BuildingGraphNode = node_objects[root_node]
	var edges := []
	for slot_i in root_node_obj.elements_by_slot.size():
		var slot = root_node_obj.elements_by_slot[slot_i]
		if slot.get_input_type() == "":
			continue
		var slot_connections_in: Array = connections.filter(func (d): return d["to_node"] == root_node and get_actual_slot(d["to_node"], d["to_port"], true) == slot_i)
		if len(slot_connections_in) == 0:
			continue
		var connected_node = slot_connections_in[0]["from_node"]
		var connected_slot = get_actual_slot(connected_node, slot_connections_in[0]["from_port"], false)
		edges.append(
			{
				"from_node": node_objects[connected_node].get_id(),
				"from_slot": connected_slot,
				"to_node": root_node_obj.get_id(), 
				"to_slot": slot_i
			}
		)
		for e in _serialize_recursive(connected_node):
			edges.append(e)
		
	return edges
	
	
func validate_graph():
	var serialized_data := JSON.parse_string(serialize_tree())
	
	var runnable_node := BuildingGraphRunner.setup_executable_graph(
		serialized_data,
		node_definitions.data,
		{
			"prev_module_id": FixedInputDataSource.new("prev_id"),
			"below_module_id": FixedInputDataSource.new("low_id"),
			"edge_dist": FixedInputDataSource.new(4.2),
			"edge_length": FixedInputDataSource.new(22.3),
			"edge_normal": FixedInputDataSource.new(Vector3(1,0,1)),
			"floor_num": FixedInputDataSource.new(2.0),
			"floor_amount": FixedInputDataSource.new(5.0),
			"all_module_ids": source_data["all_module_ids"],
			"rand": FixedInputDataSource.new(0.1),
			"geo_feature": FixedInputDataSource.new(MockGeoFeature.new())
		}
	)
	var calc_result = runnable_node.get_slot_input(0)
	if calc_result != null:
		validate_button.text = "Validate (last: OK)"
		if preview_building != null:
			preview_building.metadata.floor_definitions[1] = current_resource.duplicate()
			preview_building.metadata.floor_definitions[1].selection_rules = JSON.new()
			preview_building.metadata.floor_definitions[1].selection_rules.data = serialized_data
			preview_building.build()

	else: 
		validate_button.text = "Validate (last: NOT OK)"
	
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is BuildingGraphNode
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var actual_node = data as BuildingGraphNode
	add_child(actual_node)
	actual_node.position_offset = (at_position / (zoom)) + scroll_offset / zoom
	actual_node.build(type_names, self)
	node_objects[actual_node.name] = actual_node
