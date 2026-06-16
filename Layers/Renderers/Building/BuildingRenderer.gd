extends FeatureLayerCompositionRenderer

@export var check_roof_type := true

var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var node_types = preload("res://addons/building_graph_editor/BuildingGraphSystem/node_types.json")
var wall_normal_mat: ShaderMaterial = preload("res://Resources/Materials/BuildingMaterials/PlasterWallTriplanar.tres")

# Circle through distances loading new refinments (squared distances!)
var refine_distances := [100, 2500, 10000]
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

var execution_graph_cache: Dictionary[FloorDefinition, BuildingGraphRunner.RunnableNode] = {}

var material_variants: Dictionary[ModularBuildingMetadata, Dictionary]

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
	var building = Node3D.new()
	var modular_metadata_instance = ModularBuildingMetadata.new()
	var building_type = util.str_to_var_or_default(feature.get_attribute("render_type"), fallback_wall_id)
		
	var original_metadata: ModularBuildingMetadata = layer_composition.render_info.modular_resources[building_type]
	
	modular_metadata_instance.floor_definitions = original_metadata.floor_definitions
	var building_metadata = BuildingMetadata.new(feature, center, layer_composition.render_info)
	
	# door locations from point features in door_layer
	var door_layer: GeoFeatureLayer = layer_composition.render_info.door_layer
	var door_features: Array = door_layer.get_features_by_attribute_filter("id='" + str(feature.get_attribute("id")) +"'")
	if len(door_features) > 0:
		modular_metadata_instance.feature_positions["door"] = []
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
	modular_metadata_instance.roof_height = building_metadata.roof_height
	
	# setup data sources for building graph
	var data_sources: Dictionary[String, NodeDataSource] = {
		"prev_module_id": FixedInputDataSource.new("prev_id"),
		"below_module_id": FixedInputDataSource.new("low_id"),
		"edge_dist": FixedInputDataSource.new(4.2),
		"edge_length": FixedInputDataSource.new(22.3),
		"edge_normal": FixedInputDataSource.new(Vector3(1,0,1)),
		"floor_num": FixedInputDataSource.new(2.0),
		"floor_amount": FixedInputDataSource.new(5.0),
		"all_module_ids": FixedInputDataSource.new(["x"]),
		"rand": FixedInputDataSource.new(0.1),
		"geo_feature": FixedInputDataSource.new(MockGeoFeature.new()) 
	}
	
	var exec_graphs: Array[BuildingGraphRunner.RunnableNode] = []
	
	# get materials for walls and details
	var material_replacements: Dictionary[String, Material] = {}
	if original_metadata.material_variation_set:
		var available_replacements = original_metadata.material_variation_set.get_available()
		
		# seed unique per building, same variations for all elements in the building
		var selection_seed := randi()
		if available_replacements.size() > 0:
			for type in available_replacements:
				material_replacements[type] = original_metadata.material_variation_set.get_material(type, selection_seed)
	
	# precompute executable graphs for selection
	for floor_def in modular_metadata_instance.floor_definitions:
		if floor_def in execution_graph_cache.keys():
			exec_graphs.append(execution_graph_cache[floor_def])
			continue
		var node_graph := BuildingGraphRunner.setup_executable_graph(floor_def.selection_rules.data, node_types.data, data_sources)
		exec_graphs.append(node_graph)
#		execution_graph_cache[floor_def] = node_graph

	# facade construction
	BuildingFactory.build_building(building, modular_metadata_instance, exec_graphs, data_sources, material_replacements, feature)
	
	building.position = building_metadata.engine_center + Vector3.UP * (building_metadata.cellar_height - 1.0)
	building.name = str(feature.get_id())
		
	
	# setup old roof
	var roof_and_material = RoofFactory.prepare_roof(
		layer_composition, 
		feature, 
		addon_layers, 
		addon_objects,
		building_metadata, 
		check_roof_type,
		{"prefer_pointed_roof": true})
		
	# slightly randomize footprint for robustness (avoid precise 90° angles, ...)
	var randomized_footprint: Array[Vector2]
	randomized_footprint.assign(modular_metadata_instance.footprint.map(func (x): return x + Vector2(randf() * 0.5, randf() * 0.5)))
	
	var roof_mat: StandardMaterial3D = roof_and_material["material"].material0.duplicate()
	roof_mat.albedo_color = roof_and_material["roof"].color
	
	# compute straight skeleton roof
	var roof := StraightSkeleton.get_mesh(modular_metadata_instance.footprint, building_metadata.roof_height * 2, roof_mat, 1)
	
	# determine roof y position
	var actual_height = 0.0
	var floor_num = 0
	while actual_height < modular_metadata_instance.building_height:
		actual_height += modular_metadata_instance.floor_definitions[min(floor_num, modular_metadata_instance.floor_definitions.size() - 1)].height
		floor_num += 1
	
	# if straight skeleton result is provably valid, use it
	if not roof.broken:
		var roof_node := MeshInstance3D.new()
		roof_node.mesh = roof.mesh
		building.add_child(roof_node)
		roof_node.position.y = actual_height
	else:
		# fallback to old roofs otherwise
		var roof_surface_material_callback: Callable = RoofFactory.set_surface_overrides.bind(roof_and_material["roof"], roof_and_material["material"])
		var roof_component = roof_and_material["roof"]
		building.add_child(roof_component)
		roof_component.build(PackedVector2Array(building_metadata.footprint))
		roof_component.position.y = actual_height
		roof_surface_material_callback.call()
		
	building.name = str(feature.get_id())
	
	if "can_refine" in building:
		buildings_to_refine.append(building)

	return building

	
var buildings_to_refine = []


func refine_load():
	super.refine_load()
	
	mutex.lock()
	
	buildings_to_refine = buildings_to_refine.filter(
		func(building): return building and is_instance_valid(building) and building.get_parent() == self
	)
	
	buildings_to_refine.sort_custom(func(building1, building2):
		return \
				building1.position.distance_squared_to(position_manager.center_node.position) < \
				building2.position.distance_squared_to(position_manager.center_node.position)
		)
	
	if buildings_to_refine.size() > 0:
		var building = buildings_to_refine.pop_front()
		
		for distance in refine_distances:
			if building.position.distance_squared_to(position_manager.center_node.position) < distance:
				building.is_refined = true
				for child in building.get_children():
					if "can_refine" in child and child.can_refine():
						child.refine()
				
				refined_buildings.append(building)
		
		if not building.is_refined:
			buildings_to_refine.push_back(building)
		
		# Start undoing refinments only after all necessary instances are loaded
		mutex.unlock()
		return 
	
	# Undo all refinments no longer in render distances
	if refined_buildings.size() > 0:
		var building = refined_buildings.pop_back()
		
		if not building or not is_instance_valid(building) or building.get_parent() != self:
			mutex.unlock()
			return
		
		if not building.is_refined:
			mutex.unlock()
			return
		
		if building.position.distance_squared_to(position_manager.center_node.position) > refine_distances.back():
			for child in building.get_children():
				if "undo_refinment" in child:
					child.undo_refinment()
			mutex.unlock()
			return
		
		refined_buildings.push_back(building)
	
	mutex.unlock()


func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
