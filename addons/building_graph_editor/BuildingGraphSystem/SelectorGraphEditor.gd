@tool
extends BuildingGraphEditor
class_name SelectorGraphEditor

@export var graph_picker: SelectorGraphPicker
@export var available_definitions: Array[String]
var current_graph: JSON


func _ready() -> void:
	source_data["all_definitions"] = FixedInputDataSource.new(available_definitions)
	
	# handlers for attempted connections and disconnections in the GraphEdit view	
	connection_request.connect(process_connection_request)
	disconnection_request.connect(disconnect_node)
	# load all available nodes and place them in the library container
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
	
	graph_picker.resource_changed.connect(func (r: Resource):
		if not r:
			save_button.visible = false
			return
		current_graph = r as JSON
		if current_graph.data:
			deserialize_tree(current_graph.data)
		else:
			current_graph.data = {"nodes": [], "connections": []}
		save_button.visible = true
	)
	save_button.pressed.connect(func ():
		var text = serialize_tree()
		current_graph.data = JSON.parse_string(text)
		current_graph.emit_changed()
	)
	
func validate_graph():
	var serialized_data := JSON.parse_string(serialize_tree())
	
	var runnable_node := BuildingGraphRunner.setup_executable_graph(
		serialized_data,
		node_definitions.data,
		{
			"all_definitions": source_data["all_definitions"],
			"rand": FixedInputDataSource.new(0.1),
			"geo_feature": FixedInputDataSource.new(MockGeoFeature.new())
		}
	)
	var calc_result = runnable_node.get_slot_input(0)
	if calc_result != null:
		validate_button.text = "Validate (last: OK)"

	else: 
		validate_button.text = "Validate (last: NOT OK)"
	