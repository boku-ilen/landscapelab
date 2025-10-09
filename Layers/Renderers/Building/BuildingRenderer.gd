extends FeatureLayerCompositionRenderer

@export var check_roof_type := true

var building_base_scene = preload("res://Buildings/BuildingBase.tscn")

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
	var building := building_base_scene.instantiate()
	var building_metadata = BuildingMetadata.new(feature, center, layer_composition.render_info)
	
	var building_type = util.str_to_var_or_default(feature.get_attribute("render_type"), fallback_wall_id)
	
	if not Geometry2D.is_polygon_clockwise(building_metadata.footprint):
		building_metadata.footprint.reverse()
		
	if building_type != -1:
		WallFactory.prepare_plain_walls(building_type, building_metadata, building, layer_composition.render_info)
	else:
		WallFactory.prepare_pillars(building_metadata, building)
	
	if building_type not in range(0, layer_composition.render_info.wall_resources.size()):
		building_type = fallback_wall_id
	
	var walls_resource: PlainWallResource = layer_composition.render_info.wall_resources[building_type]
	
	# Add the roof
	var roof_and_material = RoofFactory.prepare_roof(
		layer_composition, 
		feature, 
		addon_layers, 
		addon_objects,
		building_metadata, 
		check_roof_type,
		walls_resource)
	building.add_child(roof_and_material["roof"])

	# Set parameters in the building base
	building.set_metadata(building_metadata)
	building.position = building_metadata.engine_center
	building.name = str(feature.get_id())
	
	var roof_surface_material_callback: Callable = RoofFactory.set_surface_overrides.bind(roof_and_material["roof"], roof_and_material["material"])
	# Build!
	building.build([roof_surface_material_callback])
	
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
