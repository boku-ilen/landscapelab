@tool
extends Node3D
class_name PreviewBuilding


@export_tool_button("Build") var build_func = build
@export_tool_button("Test") var test_it = test_log
func test_log():
	print("hi")

@export var metadata: ModularBuildingMetadata :
	set(v): 
		metadata = v
		build()
		
		


func build():
	for c in building_root_node.get_children():
		c.queue_free()
	
	var sources: Dictionary[String, NodeDataSource] = {
		"prev_module_id": FixedInputDataSource.new("prev_id"),
		"below_module_id": FixedInputDataSource.new("low_id"),
		"edge_dist": FixedInputDataSource.new(4.2),
		"edge_length": FixedInputDataSource.new(22.3),
		"edge_normal": FixedInputDataSource.new(Vector3(1,0,1)),
		"floor_num": FixedInputDataSource.new(2.0),
		"floor_amount": FixedInputDataSource.new(5.0),
		"all_module_ids":FixedInputDataSource.new(["x"]),
		"rand": FixedInputDataSource.new(0.1),
		"geo_feature": FixedInputDataSource.new(MockGeoFeature.new())
	}
	var graphs: Array[BuildingGraphRunner.RunnableNode] = []
	for floor_def in metadata.floor_definitions:
		graphs.append(BuildingGraphRunner.setup_executable_graph(floor_def.selection_rules.data, preload("res://addons/building_graph_editor/BuildingGraphSystem/node_types.json").data, sources))
	
	BuildingFactory.build_building(building_root_node, metadata, graphs, sources, {}, null)
	

@export var building_root_node: Node3D
