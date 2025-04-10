extends FeatureLayerCompositionRenderer

@export var check_roof_type := true

var building_base_scene = preload("res://Buildings/BuildingBase.tscn")

var window_bundles = [
	preload("res://Resources/Textures/Buildings/window/Shutter/Shutter.tres"),
	preload("res://Resources/Textures/Buildings/window/Window/Window.tres"),
]

# Circle through distances loading new refinments (squared distances!)
var refine_distances := [100, 2500, 10000]
var refined_buildings: Array[Node3D] = []

# It is important to reference a wall_resource and not loading another 
var fallback_wall_id := 1

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_height = 4
var fallback_num_floors = 1
var cellar_height = floor_height # For preventing partially floating buildings checked uneven surfaces
var plinth_height_factor = 0.025

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
		
	var wall_texture_arrays = TextureArrays.texture_arrays_from_wallres(WallFactory.wall_resources)
	
	shader.set_shader_parameter("texture_wall_albedo", wall_texture_arrays[0])
	shader.set_shader_parameter("texture_wall_normal", wall_texture_arrays[1])
	shader.set_shader_parameter("texture_wall_rme", wall_texture_arrays[2])
	
	# TODO: implement logic for multiple windows
	var albedo_images = []
	var normal_images = []
	var roughness_metallic_emission_images = []
	for bundle in window_bundles:
		var images = TextureArrays.formatted_images_from_textures([
				bundle.albedo_texture, 
				bundle.normal_texture, 
				bundle.bundled_texture])
		
		albedo_images.append(images[0])
		normal_images.append(images[1])
		roughness_metallic_emission_images.append(images[2])
	
	shader.set_shader_parameter("texture_window_albedo", TextureArrays.texture2Darrays_from_images(albedo_images))
	shader.set_shader_parameter("texture_window_normal", TextureArrays.texture2Darrays_from_images(normal_images))
	shader.set_shader_parameter("texture_window_rme", TextureArrays.texture2Darrays_from_images(roughness_metallic_emission_images))


func load_feature_instance(feature):
	var building := building_base_scene.instantiate()
	var building_metadata: Dictionary = get_building_metadata(feature)
	
	var num_floors = max(fallback_num_floors, round(building_metadata["height"] / floor_height))
	var building_type = util.str_to_var_or_default(feature.get_attribute("render_type"), fallback_wall_id)
	
	if building_type != -1:
		WallFactory.prepare_plain_walls(building_type, building_metadata, building, num_floors)
	else:
		WallFactory.prepare_pillars(building_metadata, building, num_floors)
	
	if building_type not in range(0, WallFactory.wall_resources.size()):
		building_type = fallback_wall_id
	
	var walls_resource: PlainWallResource = WallFactory.wall_resources[building_type]
	
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
	building.position = building_metadata["engine_center_position"]
	building.name = str(feature.get_id())
	
	var roof_surface_material_callback: Callable = RoofFactory.set_surface_overrides.bind(roof_and_material["roof"], roof_and_material["material"])
	# Build!
	building.build([roof_surface_material_callback])
	
	buildings_to_refine.append(building)

	return building


var buildings_to_refine = []


func refine_load():
	super.refine_load()
	
	if buildings_to_refine.size() > 0:
		var building = buildings_to_refine.pop_front()
		
		# No longer loaded
		if not building or not is_instance_valid(building) or building.get_parent() != self:
			return
		
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
		return 
	
	# Undo all refinments no longer in render distances
	if refined_buildings.size() > 0:
		var building = refined_buildings.pop_back()
		
		if not building or not is_instance_valid(building) or building.get_parent() != self:
			return
		
		if not building.is_refined:
			return
		
		if building.position.distance_squared_to(position_manager.center_node.position) > refine_distances.back():
			for child in building.get_children():
				if "undo_refinment" in child:
					child.undo_refinment()
			return
		
		refined_buildings.push_back(building)


func get_building_metadata(feature: GeoPolygon):
	# Actual geo coordinates
	var geo_footprint = Array(feature.get_outer_vertices())
	var geo_holes = feature.get_holes()
	var geo_center = geo_footprint.reduce(func(accum, vertex):
		return accum + vertex, Vector2.ZERO) / geo_footprint.size()
	
	# Coordinates as used in engine
	var engine_footprint = Array(
		feature.get_offset_outer_vertices(-center[0], -center[1]))
	
	# Min and max value to get an extent of the footprint
	var min_vertex = Vector2(INF, INF)
	var max_vertex = Vector2(-INF, -INF)
	
	for vertex in engine_footprint:
		min_vertex.x = min(vertex.x, min_vertex.x)
		max_vertex.x = max(vertex.x, max_vertex.x)
		min_vertex.y = min(vertex.y, min_vertex.y)
		max_vertex.y = max(vertex.y, max_vertex.y)
	
	var extent = (max_vertex - min_vertex).length()
	
	# Swap z-value sign as godot uses -z for forward
	engine_footprint = engine_footprint.map(
		func(vert): return Vector2(vert.x, -vert.y))
	var engine_center = engine_footprint.reduce(func(accum, vertex): 
		return accum + vertex, Vector2.ZERO) / engine_footprint.size()
	engine_footprint = engine_footprint.map(func(vert): 
		return vert - engine_center)
	
	# Height at which the building center will be positioned
	var ground_height = layer_composition.render_info.ground_height_layer.get_value_at_position(
		geo_center.x,
		geo_center.y
	) - cellar_height
	var engine_center_pos = Vector3(engine_center.x, ground_height, engine_center.y)
	
	# Load the components based checked the building attributes
	var height = util.str_to_var_or_default(
		feature.get_attribute(height_attribute), fallback_height)
	var height_stdev = util.str_to_var_or_default(feature.get_attribute(
		layer_composition.render_info.height_stdev_attribute_name), 2)
	var roof_height = fmod(height, floor_height) + height_stdev
	
	return {
		"extent": extent,
		"geo_center": geo_center,
		"engine_center_position": engine_center_pos,
		"ground_height": ground_height,
		"footprint": engine_footprint,
		"height": height,
		"roof_height": roof_height,
		"holes": geo_holes,
		"geo_offset": [-center[0], -center[1]]
	}


func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
