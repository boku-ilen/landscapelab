extends FeatureLayerCompositionRenderer

@export var check_roof_type := true

var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var node_types = preload("res://addons/building_graph_editor/BuildingGraphSystem/node_types.json")
var selector_node_types = preload("res://addons/building_graph_editor/BuildingGraphSystem/selector_node_types.json")
var wall_normal_mat: ShaderMaterial = preload("res://Resources/Materials/BuildingMaterials/PlasterWallTriplanar.tres")

var refine_ridge_mesh = preload("res://Buildings/Components/Roofs/Resources/RidgeCapMesh.tres")
var refine_gutter_mesh = load("res://Buildings/Components/Roofs/Resources/Gutters.res")
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
	var building = Node3D.new()
	var modular_metadata_instance = ModularBuildingMetadata.new()
	
	var all_modular_definitions: Array[Resource] = layer_composition.render_info.modular_resources
	var modular_definition_names: Array[String] = []
	var modular_definition_by_name: Dictionary[String, Resource] = {}
	
	for modular_definition in all_modular_definitions:
		modular_definition_by_name[modular_definition.resource_path.split("/")[-1].split(".")[0]] = modular_definition
	modular_definition_names = modular_definition_by_name.keys()
	var selector_data_sources: Dictionary[String, NodeDataSource] = {
		"all_definitions": FixedInputDataSource.new(modular_definition_names),
		"rand": DynamicInputDataSource.new(func (): return randf()),
		"geo_feature": FixedInputDataSource.new(feature) 
	} 
	selector_graph = BuildingGraphRunner.setup_executable_graph(layer_composition.render_info.selector_graph.data, selector_node_types.data, selector_data_sources)
	var selected_definition = selector_graph.get_slot_input(0)
	
	var building_type = util.str_to_var_or_default(feature.get_attribute("render_type"), fallback_wall_id)
	
	var original_metadata: ModularBuildingMetadata = layer_composition.render_info.modular_resources[building_type]
	
	if selected_definition != null and selected_definition in modular_definition_names:
		original_metadata = modular_definition_by_name[selected_definition] as ModularBuildingMetadata
	
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
		"geo_feature": FixedInputDataSource.new(feature) 
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
	randomized_footprint.assign(modular_metadata_instance.footprint.map(func (x): return x + Vector2(randf() * 0.2, randf() * 0.2)))
	
	var roof_mat: StandardMaterial3D = roof_and_material["material"].material0.duplicate()
	roof_mat.albedo_color = roof_and_material["roof"].color
	
	# compute straight skeleton roof
	var roof := StraightSkeleton.get_mesh(randomized_footprint, building_metadata.roof_height, roof_mat, 1)
	
	# determine roof y position
	var actual_height = 0.0
	var floor_num = 0
	while actual_height < modular_metadata_instance.building_height:
		actual_height += modular_metadata_instance.floor_definitions[min(floor_num, modular_metadata_instance.floor_definitions.size() - 1)].height
		floor_num += 1
	
	# if straight skeleton result is provably valid, use it
	if not roof.broken:
	
		var outer_footprint = Geometry2D.offset_polygon(randomized_footprint, 0.9)[0]
		var saved_footprint: Array[Vector2] = []
		saved_footprint.append_array(outer_footprint)
	
		var roof_node := MeshInstance3D.new()
		roof_node.mesh = roof.mesh
		building.add_child(roof_node)
		roof_node.position.y = actual_height
		roofs_to_refine.append({
			"building": building,
			"roof": roof.skeleton_info,
			"roof_node": roof_node,
			"is_refined": false,
			"height": building_metadata.roof_height,
			"refine_meshes": [],
			"color": roof_and_material["roof"].color,
			"footprint": saved_footprint,
			"original_footprint": footprint
		})
	else:
		# fallback to old roofs otherwise
		var roof_surface_material_callback: Callable = RoofFactory.set_surface_overrides.bind(roof_and_material["roof"], roof_and_material["material"])
		var roof_component = roof_and_material["roof"]
		building.add_child(roof_component)
		roof_component.build(PackedVector2Array(building_metadata.footprint))
		roof_component.position.y = actual_height
		roof_surface_material_callback.call()
		
	building.name = str(feature.get_id())

#	if "can_refine" in building:
#		buildings_to_refine.append(building)

	return building

	
var buildings_to_refine = []
var roofs_to_refine: Array[Dictionary] = []
var refined_roofs: Array[Dictionary] = []

func refine_load():
	super.refine_load()
	
	mutex.lock()

	roofs_to_refine = roofs_to_refine.filter(
		func (roof): return roof["building"] and is_instance_valid(roof["building"]) and roof["building"].get_parent() == self
	)

	roofs_to_refine.sort_custom(
		func (roof_a, roof_b): 
			return roof_a["building"].position.distance_squared_to(position_manager.center_node.position) < \
			roof_b["building"].position.distance_squared_to(position_manager.center_node.position)
	)
			
	if roofs_to_refine.size() > 0:
		
		var roof = roofs_to_refine.pop_front()
		
		for distance in refine_distances:
			if roof["building"].position.distance_squared_to(position_manager.center_node.position) < distance:
				roof = refine_roof(roof)
				refined_roofs.append(roof)
		
		if not roof["is_refined"]:
			roofs_to_refine.push_back(roof)
		
		# Start undoing refinments only after all necessary instances are loaded
		mutex.unlock()
		return 
	
	# Undo all refinments no longer in render distances

	if refined_roofs.size() > 0:
		var roof = refined_roofs.pop_back()
		
		if not roof["building"] or not is_instance_valid(roof["building"]) or roof["building"].get_parent() != self:
			mutex.unlock()
			return
		
		if not roof["is_refined"]:
			mutex.unlock()
			return
		
		if roof["building"].position.distance_squared_to(position_manager.center_node.position) > refine_distances.back():
			roof = unrefine_roof(roof)
			mutex.unlock()
			return
		
		refined_roofs.push_back(roof)
	
	mutex.unlock()

func refine_roof(roof: Dictionary)-> Dictionary:
	roof["is_refined"] = true
	logger.info("refining " + roof["building"].name)
	var skeleton_data: StraightSkeleton.StraightSkeletonInfo = roof["roof"]
	
	var bisectors := skeleton_data.bisectors
	
	var ridge_cap_multimesh = MultiMeshInstance3D.new()
	ridge_cap_multimesh.multimesh = MultiMesh.new()
	ridge_cap_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	ridge_cap_multimesh.multimesh.mesh = refine_ridge_mesh
	ridge_cap_multimesh.multimesh.instance_count = bisectors.size()
	ridge_cap_multimesh.multimesh.visible_instance_count = bisectors.size()
	var base_material = ridge_cap_multimesh.multimesh.mesh.surface_get_material(0).duplicate(true)
	base_material.albedo_color = roof["color"]
	ridge_cap_multimesh.material_overlay = base_material
	
	
	# ridge caps along bisectors
	for bisector_i in bisectors.size():
		var bisector := bisectors[bisector_i]
		var origin := Vector3(bisector.origin.x / 200, (bisector.start_t / skeleton_data.max_t) * roof["height"], bisector.origin.y / 200)
		var endpoint := Vector3(bisector.endpoint.x / 200, (bisector.end_t / skeleton_data.max_t) * roof["height"], bisector.endpoint.y / 200)
		var midpoint := (origin + endpoint) * 0.5
		var aabb: AABB = refine_ridge_mesh.get_aabb()
		var mesh_length: float = aabb.size.z
		var mesh_height: float = aabb.size.y / 4
		#print(mesh_height)
		var scale_z := origin.distance_to(endpoint) / mesh_length
		
		if not origin.distance_squared_to(midpoint) < 0.001:
			ridge_cap_multimesh.multimesh.set_instance_transform(
				bisector_i, 
				Transform3D().translated(midpoint + Vector3.UP * (roof["roof_node"].position.y + mesh_height * 0.5))\
				.looking_at(origin + Vector3.UP * (roof["roof_node"].position.y + mesh_height * 0.5))\
				.scaled_local(Vector3(0.25,0.25,scale_z))
			)
	
	# gutters offset outward from roof edge
	var offset_footprint = Geometry2D.offset_polygon(roof["footprint"], refine_gutter_mesh.get_aabb().size.x / 8, Geometry2D.JOIN_SQUARE)[0]
	
	var gutter_multimesh := MultiMeshInstance3D.new()
	gutter_multimesh.multimesh = MultiMesh.new()
	gutter_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	gutter_multimesh.multimesh.mesh = refine_gutter_mesh#.duplicate()
	gutter_multimesh.multimesh.instance_count = offset_footprint.size() + 1
	gutter_multimesh.multimesh.visible_instance_count = gutter_multimesh.multimesh.instance_count
	gutter_multimesh.material_overlay = base_material

	for vert_i in offset_footprint.size():
		var edge_start: Vector2 = offset_footprint[vert_i]
		var edge_end: Vector2 = offset_footprint[(vert_i + 1) % offset_footprint.size()]
		var from = Vector3(edge_start.x, roof["roof_node"].position.y - 0.25, edge_start.y)
		var to = Vector3(edge_end.x, roof["roof_node"].position.y - 0.25, edge_end.y)
		var mesh_length = refine_gutter_mesh.get_aabb().size.z
		gutter_multimesh.multimesh.set_instance_transform(
			vert_i, 
			Transform3D().translated((from + to) * 0.5)\
			.looking_at(to, Vector3.DOWN)\
			.scaled_local(Vector3(0.25,0.25,from.distance_to(to) / mesh_length))
		)
	
	# drain pipe - TODO model
	gutter_multimesh.multimesh.set_instance_transform(
		roof["footprint"].size(), 
		Transform3D().translated(Vector3(roof["footprint"][0].x, roof["roof_node"].position.y * 0.5 - 0.2, roof["footprint"][0].y))\
		.scaled_local(Vector3(0.3, roof["roof_node"].position.y / refine_gutter_mesh.get_aabb().size.z, 0.3))\
		.rotated_local(Vector3.RIGHT, -PI/2)
	)
	
	
	gutter_multimesh.name = "gutter_ref"
	ridge_cap_multimesh.name = "roof_ref"
	(roof["building"] as Node3D).add_child.call_deferred(ridge_cap_multimesh)
	(roof["building"] as Node3D).add_child.call_deferred(gutter_multimesh)
	roof["refine_meshes"].append(ridge_cap_multimesh)
	roof["refine_meshes"].append(gutter_multimesh)
	return roof

func unrefine_roof(roof: Dictionary) -> Dictionary:
	roof["is_refined"] = false
	
	for mesh in roof["refine_meshes"]:
		mesh.queue_free.call_deferred()
		(roof["building"] as Node3D).remove_child.call_deferred(mesh)
	roof["refine_meshes"] = []
	return roof
	
func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
