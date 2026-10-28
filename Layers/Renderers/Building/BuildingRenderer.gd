extends FeatureLayerCompositionRenderer

@export var check_roof_type := true

var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var node_types = preload("res://addons/building_graph_editor/BuildingGraphSystem/node_types.json")
var selector_node_types = preload("res://addons/building_graph_editor/BuildingGraphSystem/selector_node_types.json")
var wall_normal_mat: ShaderMaterial = preload("res://Resources/Materials/BuildingMaterials/PlasterWallTriplanar.tres")

var refine_ridge_meshes = [
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Rect_Large.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Pentagonal_Large.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Round_Large.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Rect_Small.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Round_Large_Overhang.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Round_Small.obj"),
]
var refine_gutter_mesh = load("res://Buildings/Components/Roofs/Resources/Gutters.res")
# Circle through distances loading new refinments (squared distances!)
var refine_distances := [100, 2500, 10000]

var lod_distances := { 
	BuildingFactory.BuildingDetail.Full:750, 
	BuildingFactory.BuildingDetail.SimpleMesh: 2000, 
	BuildingFactory.BuildingDetail.Billboard:10000
}

var loaded_buildings: Array[ModularBuilding]

var refined_buildings: Array[Node3D] = []

# It is important to reference a wall_resource and not loading another 
var fallback_wall_id := 1

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_num_floors = 1

var slope_attribute_name: String

# Roof addon logic (i.e. pantelleria domes, chimneys, ...)
var roof_id_to_addon_ids = {}
@onready var addon_layer_paths: Dictionary = layer_composition.render_info.addon_layers
@onready var addon_layers: Dictionary
@onready var addon_object_paths: Dictionary = layer_composition.render_info.addon_objects
@onready var addon_objects = {}

enum flag {
	basement = 0b1,
	ground = 0b10,
	mid = 0b100,
	top = 0b1000
}

@onready var height_attribute = layer_composition.render_info.height_attribute_name
@onready var stdev_attribute = layer_composition.render_info.height_stdev_attribute_name

var execution_graph_cache: Dictionary[FloorDefinition, BuildingGraphRunner.RunnableNode] = {}

var material_variants: Dictionary[ModularBuildingMetadata, Dictionary]

var selector_graph: BuildingGraphRunner.RunnableNode

func _ready():
	_create_and_set_texture_arrays()
	_prepare_addons()
	
	
	
	super._ready()


func _prepare_addons():
	addon_layers = LLFileAccess.new().convert_dict_to_geolayers(addon_layer_paths)
	for key in addon_object_paths.keys():
		addon_objects[key] = load(addon_object_paths[key])


# To increase performance, create an array of textures which the same shader can
# read from
func _create_and_set_texture_arrays():
	var shader = preload("res://Buildings/Components/Walls/PlainWalls.tscn").instantiate().material
		
	var wall_texture_arrays = TextureArrays.texture_arrays_from_wallres(layer_composition.render_info.wall_resources)
	var window_texture_arrays = TextureArrays.texture_arrays_from_window_bundle(layer_composition.render_info.window_resources)
	
	shader.set_shader_parameter("texture_wall_albedo", wall_texture_arrays[0])
	shader.set_shader_parameter("texture_wall_normal", wall_texture_arrays[1])
	shader.set_shader_parameter("texture_wall_rme", wall_texture_arrays[2])
	
	shader.set_shader_parameter("texture_window_albedo", window_texture_arrays[0])
	shader.set_shader_parameter("texture_window_normal", window_texture_arrays[1])
	shader.set_shader_parameter("texture_window_rme", window_texture_arrays[2])


func load_feature_instance(feature: GeoFeature):
	#var building = Node3D.new()
	var modular_metadata_instance = ModularBuildingMetadata.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = feature.get_id()
	
	var all_modular_definitions: Array[Resource] = layer_composition.render_info.modular_resources
	var modular_definition_names: Array[String] = []
	var modular_definition_by_name: Dictionary[String, Resource] = {}
	
	for modular_definition in all_modular_definitions:
		modular_definition_by_name[modular_definition.resource_path.split("/")[-1].split(".")[0]] = modular_definition
	modular_definition_names = modular_definition_by_name.keys()
	var selector_data_sources: Dictionary[String, NodeDataSource] = {
		"all_definitions": FixedInputDataSource.new(modular_definition_names),
		"rand": DynamicInputDataSource.new(func (): return rng.randf()),
		"geo_feature": FixedInputDataSource.new(feature) 
	} 
	selector_graph = BuildingGraphRunner.setup_executable_graph(layer_composition.render_info.selector_graph.data, selector_node_types.data, selector_data_sources)
	var selected_definition = selector_graph.get_slot_input(0)
	
	var building_type = util.str_to_var_or_default(feature.get_attribute("render_type"), fallback_wall_id)
	
	var original_metadata: ModularBuildingMetadata = layer_composition.render_info.modular_resources[building_type]
	
	# FIXME: remove the special case for 13, couldn't work out why it's needed in time
	if selected_definition != null and selected_definition in modular_definition_names and building_type != 13:
		original_metadata = modular_definition_by_name[selected_definition] as ModularBuildingMetadata
	
	modular_metadata_instance.floor_definitions = original_metadata.floor_definitions
	var building_metadata = BuildingMetadata.new(feature, center, layer_composition.render_info)
	
	# door locations from point features in door_layer
	modular_metadata_instance.feature_positions["door"] = []
	if layer_composition.render_info.door_layer:
		var door_layer: GeoFeatureLayer = layer_composition.render_info.door_layer
		var door_features: Array = door_layer.get_features_by_attribute_filter("id='" + str(feature.get_attribute("id")) +"'")
		if len(door_features) > 0:
			#modular_metadata_instance.feature_positions["door"] = []
			for door_feature: GeoPoint in door_features: 
				var feature_geo_position = door_feature.get_vector3() + Vector3(building_metadata.geo_offset[0], 0, -building_metadata.geo_offset[1])
				var relative_position = feature_geo_position - building_metadata.engine_center
				modular_metadata_instance.feature_positions["door"].append(Vector2(relative_position.x, relative_position.z))
	if not Geometry2D.is_polygon_clockwise(building_metadata.footprint):
		building_metadata.footprint.reverse()
	var footprint: Array[Vector2]
	footprint.assign(building_metadata.footprint)
	
	# straight skeleton implementation expects a polygon without duplicate start/end vertices
	footprint.remove_at(len(footprint)-1)
	
	modular_metadata_instance.footprint = footprint
	modular_metadata_instance.building_height = building_metadata.height
	
	if original_metadata.roof_height > 0.0:
		modular_metadata_instance.roof_height = original_metadata.roof_height
	else:
		modular_metadata_instance.roof_height = building_metadata.roof_height
	
	# setup data sources for building graph
	# FIXME dummy data (necessary?)
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
	
	var exec_graphs: Array[BuildingGraphRunner.RunnableNode] = []
	
	# get materials for walls and details
	var material_replacements: Dictionary[String, Material] = {}
	if original_metadata.material_variation_set:
		var available_replacements = original_metadata.material_variation_set.get_available()
		
		# seed unique per building, same variations for all elements in the building
		var selection_seed := feature.get_id()
		if available_replacements.size() > 0:
			for type in available_replacements:
				material_replacements[type] = original_metadata.material_variation_set.get_material(type, selection_seed)
	
	# precompute executable graphs for selection
	for floor_def in modular_metadata_instance.floor_definitions:
		var node_graph := BuildingGraphRunner.setup_executable_graph(floor_def.selection_rules.data, node_types.data, data_sources)
		exec_graphs.append(node_graph)

	# create building object with all necessary data
	var building_controller := ModularBuilding.new(modular_metadata_instance, building_metadata, exec_graphs, material_replacements,feature, layer_composition, addon_layers, addon_objects)

	building_controller.construct_with_lod(BuildingFactory.BuildingDetail.SimpleMesh)
	# facade construction
	#BuildingFactory.build_building(building, modular_metadata_instance, exec_graphs, data_sources, material_replacements, feature)

	building_controller.position = building_metadata.engine_center + Vector3.UP * (building_metadata.cellar_height - 1.0)
	building_controller.name = str(feature.get_id())
		
	loaded_buildings.append(building_controller)
	
	# Scale to exact nDOM height
	
	building_controller.name = str(feature.get_id())

	return building_controller

	
var buildings_to_refine = {}
var roofs_to_refine: Array[Dictionary] = []
var refined_roofs: Array[Dictionary] = []

func _process(_delta):
	super._process(_delta)
	
	# refine all queued buildings, since execution fails quietly if done in refine_load
	var to_refine = buildings_to_refine.keys()
	if to_refine.size() > 0:
		for building in to_refine:
			building.construct_with_lod(buildings_to_refine[building])
	buildings_to_refine.clear()

func refine_load():
	super.refine_load()
	
	mutex.lock()
	
	# forget all deleted buildings
	loaded_buildings = loaded_buildings.filter(
		func(b): return is_instance_valid(b)
	)
	
	
	# check whether buildings have the correct LOD, otherwise update them
	if loaded_buildings.size() > 0:
		for building in loaded_buildings:
			var correct_lod = BuildingFactory.BuildingDetail.Billboard
			var distance = building.position.distance_to(position_manager.center_node.position)
			for lod_level in [BuildingFactory.BuildingDetail.Full, BuildingFactory.BuildingDetail.SimpleMesh, BuildingFactory.BuildingDetail.Billboard]:
				if distance < lod_distances[lod_level]:
					if building.last_lod != lod_level:
						# FIXME construct_with_lod does not execute if called from within refine_load -> why?
						buildings_to_refine[building] = lod_level
						#building.construct_with_lod(lod_level)
					break
	
	mutex.unlock()
	
	
func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
