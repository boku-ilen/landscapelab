@tool
extends Node
class_name BuildingGraphRunner
@export var sample_json_data: JSON
@export var node_type_json_data: JSON
@export var run_button: Button
@export var graph_controller: BuildingGraphEditor
var executable_tree: RunnableNode

class RunnableNode:
	func _init(nodes_by_id: Dictionary, edges: Array, root_node_id: int, data_source_dict: Dictionary[String, NodeDataSource], type_data: Dictionary) -> void:
		var own_node = nodes_by_id[root_node_id]
		data_sources= data_source_dict
		for slot_i in own_node["slots"].size():
			var slot = own_node["slots"][slot_i]
			var chain_next = edges.filter(func (edge: Dictionary): return edge["to_node"] == root_node_id and edge["to_slot"] == slot_i)

			if slot["slot_input_type"] == "constant":
				var callable := func (): 
					var data = slot["slot_data"]["constant_value"]
					if data is String and data[0] == "(":
						return parse_vector(data)
					return data
				input_callables.append(callable)
				output_callables.append(callable)
			elif slot["slot_input_type"] == "data_source":
				var callable: Callable = func (): return data_source_dict[slot["data_source_identifier"]].get_value()
				input_callables.append(callable)
				output_callables.append(callable)
			elif slot["slot_input_type"] == "connection" and chain_next.size() > 0 and (own_node["slots"][slot_i]["type"] as String).contains("_input"):
				var source_runnable_node = RunnableNode.new(nodes_by_id, edges, chain_next[0]["from_node"], data_source_dict, type_data)
				tree_children.append(source_runnable_node)
				#print(source_runnable_node.input_callables[chain_next[0]["from_slot"]].call())
				input_callables.append(func (): return source_runnable_node.get_slot_output(int(chain_next[0]["from_slot"])))
				output_callables.append(func (): print("bar"); return "asdf")
			elif "choice" in slot["slot_data"].keys():
				var text_functions = type_data[own_node["node_type"]]["slots"][slot_i]["option_functions"]
				var text_func = text_functions[type_data[own_node["node_type"]]["slots"][slot_i]["options"].find(slot["slot_data"]["choice"])]
				var expression = Expression.new()
				if expression.parse(text_func, ["vals"]):
					print("error parsing choice function in node ", own_node["node_id"], " slot ", slot_i)
					input_callables.append(func (): return null)
					output_callables.append(func (): return null)
					return
				input_callables.append(func (): return func (vals): print(vals);return expression.execute([vals], self))
				#print(input_callables[-1].call().call([12, 13]))
				#print((func (): return func (vals): expression.execute(vals, self)).call())
				output_callables.append(func (): return null)
			else:
				# fallthrough, this is an output-only slot
				input_callables.append(func ():
					#print("foo")
					return null
				)
#				output_callables.append(func (): return _run_by_function(own_node))
				output_callables.append(func (): return _run_by_embedded(own_node, type_data, slot_i))
	var input_callables: Array[Callable] = []
	var output_callables: Array[Callable] = []
	var tree_children: Array[RunnableNode] = []
	var data_sources: Dictionary[String, NodeDataSource]
	func get_slot_input(slot_num):
		return input_callables[slot_num].call()
		
	func get_slot_output(slot_num):
		return output_callables[slot_num].call()
	func weighted_choice(options, weights):
		#print(options, weights)
		var weighted = range(len(options)).map(func (i): return {"choice": options[i], "weight": weights[i] * randf()})
		weighted.sort_custom(func (w1, w2): return w1["weight"] > w2["weight"])
		return weighted[0]["choice"]
	static func parse_vector(s: String)->Vector3:
		var parts = s.remove_chars("()").split(", ")
		return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
		
	func _run_by_embedded(node_data_dict, type_data: Dictionary, slot_i: int):
		var slot_data = type_data[node_data_dict["node_type"]]["slots"][slot_i]
		if not "function" in slot_data.keys():
			print("no function block on node type ", node_data_dict["node_type"], " slot ", slot_i)
			return null
		var function = slot_data["function"]
		if slot_data["function"] == null:
			var option_funcs = type_data[node_data_dict["node_type"]]["slots"][slot_data["function_source"]]["option_functions"]
			var options = type_data[node_data_dict["node_type"]]["slots"][slot_data["function_source"]]["options"]
			function = option_funcs[options.find(node_data_dict["slots"][slot_data["function_source"]]["slot_data"]["choice"])]
		var inputs = []
		for slot in node_data_dict["slots"].size():
			inputs.append(get_slot_input(slot))
		#print(inputs)
		var expression = Expression.new()
		expression.parse(function, ["inputs", "data_sources"])
		var result = expression.execute([inputs, data_sources], self)
		if expression.has_execute_failed():
			print("execute failed on node of type ", node_data_dict["node_type"], expression.get_error_text())
			return null
		#print("Result at ", node_data_dict["node_type"], " was ", result)
		return result

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
#	run_button.pressed.connect(func (): 
#		var data = JSON.parse_string(graph_controller.serialize_tree())
#		var sources: Dictionary[String, NodeDataSource] = {
#			"prev_module_id": PreviousModuleId.new(),
#			"below_module_id": PreviousModuleId.new(),
#			"rand": RandomScalar.new(),
#			"all_module_ids": AllModuleIds.new()
#		}
#		executable_tree.setup_executable_graph(data, node_type_json_data, sources)
#		print(executable_tree.get_slot_input(0))
#	)
#	var e = Expression.new()
#	print(e.parse("vals[0] > vals[1]", ["vals"]))
#	print(e.execute([[1,2]], self))
#	print((func (a,b): return e.execute([[a,b]], self)).call(1,2))
#	print(e.get_error_text())
	#setup_executable_graph(sample_json_data.data, node_type_json_data)

static func setup_executable_graph(saved_data: Dictionary, node_definition_data: Dictionary, sources: Dictionary[String, NodeDataSource]) -> RunnableNode:
	var node_data = saved_data["nodes"]
	var edge_data = saved_data["connections"]
	var type_data: Dictionary = node_definition_data["available_nodes"]
	var nodes_by_id: Dictionary = {}
	for node in node_data:
		nodes_by_id[int(node["node_id"])] = node
	var end_node = nodes_by_id.keys().filter(func (node_id): return "is_end" in type_data[nodes_by_id[node_id]["node_type"]] and type_data[nodes_by_id[node_id]["node_type"]]["is_end"])[0]
	
	return RunnableNode.new(nodes_by_id, edge_data, end_node, sources, type_data)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
