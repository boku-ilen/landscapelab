extends FeatureLayerCompositionRenderer

@export var check_roof_type := true

var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var flat_roof_scene = preload("res://Buildings/Components/FlatRoofPantelleria.tscn")
var pointed_roof_scene = preload("res://Buildings/Components/PointedRoof.tscn")
var saddle_roof_scene = preload("res://Buildings/Components/SaddleRoof.tscn")

var wall_resources = [
	# "apartments": 0
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "house": 1
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "shack": 2
	preload("res://Resources/Textures/Buildings/PlainWallResources/Shack.tres"),
	# "industrial": 3
	preload("res://Resources/Textures/Buildings/PlainWallResources/Industrial.tres"),
	# "office": 4
	preload("res://Resources/Textures/Buildings/PlainWallResources/Office.tres"),
	# "supermarket": 5
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "retail_restaurant": 6
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "historic": 7
	preload("res://Resources/Textures/Buildings/PlainWallResources/BrickHouse.tres"),
	# "religious": 8
	preload("res://Resources/Textures/Buildings/PlainWallResources/BrickHouse.tres"),
	# "greenhouse": 9
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "concrete": 10
	preload("res://Resources/Textures/Buildings/PlainWallResources/Concrete.tres"),
	# "stone": 11
	preload("res://Resources/Textures/Buildings/PlainWallResources/BrickHouse.tres"),
	# "mediterranean": 12
	preload("res://Resources/Textures/Buildings/PlainWallResources/PanterlleriaHouse.tres"),
]

var window_bundles = [
	preload("res://Resources/Textures/Buildings/window/Shutter/Shutter.tres"),
	preload("res://Resources/Textures/Buildings/window/DefaultWindow/DefaultWindow.tres"),
]

# It is important to reference a wall_resource and not loading another 
var fallback_wall_id := 1

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_height = 10
var fallback_num_floors = 1
var cellar_height = floor_height # For preventing partially floating buildings checked uneven surfaces
var plinth_height_factor = 0.025

enum flag {
	basement = 0b1,
	ground = 0b10,
	mid = 0b100,
	top = 0b1000
}

@onready var height_attribute = layer_composition.render_info.height_attribute_name


func _ready():
	_create_and_set_texture_arrays()
	super._ready()


# To increase performance, create an array of textures which the same shader can
# read from
func _create_and_set_texture_arrays():
	var shader = preload("res://Buildings/Components/Walls/PlainWalls.tscn").instantiate().material
		
	var wall_texture_arrays = TextureArrays.texture_arrays_from_wallres(wall_resources)
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
	var building = building_base_scene.instantiate()
	var building_metadata: Dictionary = get_building_metadata(feature)
	
	var num_floors = max(fallback_num_floors, round(building_metadata["height"] / floor_height))
	var building_type = feature.get_attribute("render_type")
	
	# TODO: make subclasses for this? 
	if int(building_type) != -1:
		prepare_plain_walls(building_type, building_metadata, building, num_floors)
	else:
		prepare_pillars(building_metadata, building, num_floors)
	
	# FIXME: Code duplicaiton from prepare_plain_walls
	var building_type_id = int(building_type) \
		if building_type != "" and int(building_type) in range(0, wall_resources.size()) \
		else fallback_wall_id
	var walls_resource: PlainWallResource = wall_resources[building_type_id]
	
	# Add the roof
	if layer_composition.render_info is LayerComposition.BuildingRenderInfo:
		var slope = feature.get_attribute(layer_composition.render_info.slope_attribute_name)
		var roof = null
		
		var can_build_roof := false
		
		if check_roof_type and walls_resource.prefer_pointed_roof:
			if feature.get_outer_vertices().size() == 5:
				roof = saddle_roof_scene.instantiate()
				roof.set_metadata(building_metadata)
				can_build_roof = true
			elif util.str_to_var_or_default(slope, 35) > 15:
				roof = pointed_roof_scene.instantiate()
				roof.set_metadata(building_metadata)
				can_build_roof = roof.can_build(
					building_metadata.geo_center,feature.get_outer_vertices())
		
		if roof == null or not can_build_roof:
			roof = flat_roof_scene.instantiate()

		var color = Color(
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.red_attribute_name), 200) / 255.0,
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.green_attribute_name), 130) / 255.0,
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.blue_attribute_name), 130) / 255.0
		)

		# Increase contrast and saturation
		color.v *= 0.4
		color.s *= 2.0

		roof.color = color

		building.add_child(roof)

	# Set parameters in the building base
	building.set_metadata(building_metadata)
	building.position = building_metadata["engine_center_position"]
	building.name = str(feature.get_id())

	# Build!
	building.build()

	return building


func prepare_pillars(building_metadata: Dictionary, building: Node3D, num_floors: int):
	var walls_scene = load("res://Buildings/Components/Walls/Pillars.tscn").instantiate()
	walls_scene.ground_height_at_center = building_metadata["engine_center_position"].y
	walls_scene.floors = num_floors
	building.add_child(walls_scene)


func prepare_plain_walls(building_type: String, building_metadata: Dictionary,
		building: Node3D, num_floors: int):
	var walls_scene = preload("res://Buildings/Components/Walls/PlainWalls.tscn")
	
	var building_type_id = int(building_type) \
		if building_type != "" and int(building_type) in range(0, wall_resources.size()) \
		else fallback_wall_id
	var walls_resource: PlainWallResource = wall_resources[building_type_id]
	
	# Random facade texture
	var random_gen = RandomNumberGenerator.new()
	random_gen.seed = hash(building_metadata["footprint"])

	var wall_color = Color.WHITE_SMOKE
	var random = random_gen.randf_range(0, 1)
	
	var color_num := 0
	var summed_weight := 0.
	for weight in walls_resource.random_color_weights:
		summed_weight += weight
		if random <= summed_weight: break
		color_num += 1
	
	wall_color = walls_resource.random_colors[color_num]
	
	# Indexing textures from texture2Darray
	# Each bundle consists of: basement, ground, mid, top
	# => building_type 1 basement => 1 * 4 + 3
	# => building_type 3 top => 3 * 4 + 3
	var get_cellar_index = func(building_id): return int(building_id) * 4 + 0
	var get_ground_index = func(building_id): return int(building_id) * 4 + 1
	var get_mid_index = func(building_id): return int(building_id) * 4 + 2
	var get_top_index = func(building_id): return int(building_id) * 4 + 3
	
	# Random texture scale
	var random_tex_scale = Vector2(random_gen.randf_range(0.7, 1.3), 1)
	
	# Add a cellar
	var cellar = walls_scene.instantiate()
	cellar.set_color(Color.WHITE_SMOKE)
	# Add an additional height to the cellar which acts as "plinth" scaled with the extent
	cellar.height += plinth_height_factor * min(20., building_metadata["extent"])
	cellar.set_wall_texture_index(get_cellar_index.call(building_type_id))
	
	# Cellars usually do not have windows
	cellar.set_window_texture_index(-1)
	cellar.texture_scale = walls_resource.basement_texture.texture_scale * random_tex_scale
	if walls_resource.apply_colors & flag.basement:
		cellar.set_color(wall_color)
	building.add_child(cellar)
	
	# TODO: add window indexing
	# Add ground floor
	num_floors -= 1
	var ground_floor = walls_scene.instantiate()
	ground_floor.set_wall_texture_index(get_ground_index.call(building_type_id))
	ground_floor.set_window_texture_index(walls_resource.ground_window_id)
	ground_floor.set_color(Color.WHITE_SMOKE)
	ground_floor.texture_scale = walls_resource.ground_texture.texture_scale * random_tex_scale
	if walls_resource.apply_colors & flag.ground: 
		ground_floor.set_color(wall_color)
		
	building.add_child(ground_floor)
	
	# Add mid floors (only if there is are enough floors left)
	if num_floors >= 1:
		for i in range(num_floors - 1):
			var walls = walls_scene.instantiate()
			walls.set_wall_texture_index(get_mid_index.call(building_type_id))
			walls.set_window_texture_index(walls_resource.middle_window_id)
			walls.set_color(Color.WHITE_SMOKE)
			walls.texture_scale = walls_resource.middle_texture.texture_scale * random_tex_scale
			if walls_resource.apply_colors & flag.mid:
				walls.set_color(wall_color)
			building.add_child(walls)

		# Add top floor
		var top_floor = walls_scene.instantiate()
		top_floor.set_wall_texture_index(get_top_index.call(building_type_id))
		top_floor.set_window_texture_index(walls_resource.top_window_id)
		top_floor.set_color(Color.WHITE_SMOKE)
		top_floor.texture_scale = walls_resource.top_texture.texture_scale * random_tex_scale
		if walls_resource.apply_colors & flag.top:
			top_floor.set_color(wall_color)
		building.add_child(top_floor)


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
		layer_composition.render_info.height_stdev_attribute_name), 10)
	var roof_height = fmod(height, floor_height) + height_stdev
	
	return {
		"extent": extent,
		"geo_center": geo_center,
		"engine_center_position": engine_center_pos,
		"ground_height": ground_height,
		"footprint": engine_footprint,
		"height": height,
		"roof_height": roof_height,
		"holes": geo_holes
	}


func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
