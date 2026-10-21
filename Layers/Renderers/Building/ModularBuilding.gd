extends Node3D
class_name ModularBuilding

var metadata_instance: ModularBuildingMetadata
var graphs_by_floor: Array[BuildingGraphRunner.RunnableNode]
var feature: GeoFeature
var material_table: Dictionary[String, Material]

var last_lod := BuildingFactory.BuildingDetail.Billboard

func _init(modular_metadata: ModularBuildingMetadata, node_graphs: Array[BuildingGraphRunner.RunnableNode], materials: Dictionary[String, Material], geo_feature: GeoFeature) -> void:
	metadata_instance = modular_metadata
	graphs_by_floor = node_graphs
	feature = geo_feature
	material_table = materials
	
func construct_with_lod(lod_level: BuildingFactory.BuildingDetail):
	for child in get_children():
		child.queue_free()
		remove_child(child)
	var data_sources: Dictionary[String, NodeDataSource] = {
		"prev_module_id": FixedInputDataSource.new("prev_id"),
		"below_module_id": FixedInputDataSource.new("low_id"),
		"edge_dist": FixedInputDataSource.new(4.2),
		"edge_length": FixedInputDataSource.new(22.3),
		"edge_normal": FixedInputDataSource.new(Vector3(1,0,1)),
		"is_most_distant_edge": FixedInputDataSource.new(false),
		"floor_num": FixedInputDataSource.new(2.0),
		"floor_amount": FixedInputDataSource.new(5.0),
		"all_module_ids": FixedInputDataSource.new(["x"]),
		"rand": FixedInputDataSource.new(0.1),
		"geo_feature": FixedInputDataSource.new(feature) 
	}
	BuildingFactory.build_building(self, metadata_instance, graphs_by_floor, data_sources, material_table, feature, lod_level)