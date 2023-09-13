extends FeatureLayerCompositionRenderer

var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var flat_roof_scene = preload("res://Buildings/Components/FlatRoof.tscn")
var pointed_roof_scene = preload("res://Buildings/Components/PointedRoof.tscn")

var fallback_wall = preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres")

var wall_resources = [
	# "apartments": 0
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "house": 1
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "shack": 2
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "industrial": 3
	preload("res://Resources/Textures/Buildings/PlainWallResources/Industrial.tres"),
	# "office": 4
	preload("res://Resources/Textures/Buildings/PlainWallResources/Office.tres"),
	# "supermarket": 5
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "retail_restaurant": 6
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "historic": 7
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "religious": 8
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "roof": 9
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "greenhouse": 10
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "concrete": 11
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
]

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_height = 10
var cellar_height = floor_height # For preventing partially floating buildings checked uneven surfaces

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
	max_features = 2000
	radius = max(500, Vegetation.get_max_extent())


# To increase performance, create an array of textures which the same shader can
# read from
func _create_and_set_texture_arrays():
	var albedo_images = []
	var normal_images = []
	var roughness_metallic_emission_images = []
	# Build texture-arrays of format: 
	# [type1_basement, type1_ground, type1_middle, type1_top, type2_basement, ...]
	for r in wall_resources:
		var res: PlainWallResource = r
		for bundle in [res.basement_texture, res.ground_texture, res.middle_texture, res.top_texture]:
			var images = []
			for texture in [bundle.albedo_texture, bundle.normal_texture, bundle.bundled_texture]:
				# Ensure all images are the same size and same format and have mipmaps generated
				var new_image: Image = texture.get_image() \
					if  texture != null else Image.create(
						1024, 1024, false, Image.FORMAT_RGB8)
				new_image.decompress()
				new_image.flip_y()
				new_image.resize(1024, 1024)
				new_image.convert(Image.FORMAT_RGB8)
				new_image.generate_mipmaps()
				images.append(new_image)
			
			albedo_images.append(images[0])
			normal_images.append(images[1])
			roughness_metallic_emission_images.append(images[2])
	
	var albedo_texture_array = Texture2DArray.new()
	var normal_texture_array = Texture2DArray.new()
	var roughness_metallic_emission_texture_array = Texture2DArray.new()
	
	albedo_texture_array.create_from_images(albedo_images)
	normal_texture_array.create_from_images(normal_images)
	roughness_metallic_emission_texture_array.create_from_images(roughness_metallic_emission_images)
	
	var shader = preload("res://Buildings/Components/Walls/PlainWalls.tscn").instantiate().material
	shader.set_shader_parameter("texture_albedo", albedo_texture_array)
	shader.set_shader_parameter("texture_normal", normal_texture_array)
	shader.set_shader_parameter("texture_roughness_metallic_emission", roughness_metallic_emission_texture_array)


func load_feature_instance(feature):
	var building = building_base_scene.instantiate()
	var building_metadata: Dictionary = get_building_metadata(feature)
	
	var num_floors = max(1, building_metadata["height"] / floor_height)
	var building_type = feature.get_attribute("render_type")
	var walls_scene = preload("res://Buildings/Components/Walls/PlainWalls.tscn")
	var walls_resource: PlainWallResource = wall_resources[int(building_type)] \
		 if int(building_type) in range(0, wall_resources.size()) else fallback_wall
	
	# Random facade texture
	var random_gen = RandomNumberGenerator.new()
	random_gen.seed = hash(building_metadata["footprint"])

	var wall_color = Color.WHITE_SMOKE
	var random = random_gen.randi_range(0, 10)
	
	if random >= 0 and random <= 5:
		wall_color = walls_resource.random_colors[0]
	elif random > 5 and random <= 8:
		wall_color = walls_resource.random_colors[1]
	elif random == 9:
		wall_color = walls_resource.random_colors[2]
	elif random == 10:
		wall_color = walls_resource.random_colors[3]

	# FIXME: Find a way not to have a half window texture here
	
	# Indexing textures from texture2Darray
	# Each bundle consists of: basement, ground, mid, top
	# => building_type 1 basement => 1 * 4 + 3
	# => building_type 3 top => 3 * 4 + 3
	var get_cellar_index = func(building_type): return int(building_type) * 4 + 0
	var get_ground_index = func(building_type): return int(building_type) * 4 + 1
	var get_mid_index = func(building_type): return int(building_type) * 4 + 2
	var get_top_index = func(building_type): return int(building_type) * 4 + 3
	
	# Add a cellar
	var cellar = walls_scene.instantiate()
	cellar.set_color(Color.WHITE_SMOKE)
	cellar.set_texture_index(get_cellar_index.call(building_type))
	if walls_resource.apply_colors & flag.basement:
		cellar.set_color(wall_color)
	building.add_child(cellar)
	
	# Add ground floor
	num_floors -= 1
	var ground_floor = walls_scene.instantiate()
	ground_floor.set_texture_index(get_ground_index.call(building_type))
	ground_floor.set_color(Color.WHITE_SMOKE)
	if walls_resource.apply_colors & flag.ground: 
		ground_floor.set_color(wall_color)
		
	building.add_child(ground_floor)
	
	# Add mid floors (only if there is are enough floors left)
	if num_floors >= 1:
		for i in range(num_floors - 1):
			var walls = walls_scene.instantiate()
			walls.set_texture_index(get_mid_index.call(building_type))
			walls.set_color(Color.WHITE_SMOKE)
			if walls_resource.apply_colors & flag.mid:
				walls.set_color(wall_color)
			building.add_child(walls)

		# Add top floor
		var top_floor = walls_scene.instantiate()
		top_floor.set_texture_index(get_top_index.call(building_type))
		top_floor.set_color(Color.WHITE_SMOKE)
		if walls_resource.apply_colors & flag.top:
			top_floor.set_color(wall_color)
		building.add_child(top_floor)

	# Add the roof
	if layer_composition.render_info is LayerComposition.BuildingRenderInfo:
		var slope = feature.get_attribute(layer_composition.render_info.slope_attribute_name)
		var roof = null
		
		var can_build_roof := false
		if util.str_to_var_or_default(slope, 35) > 15:
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
		color.v *= 0.9
		color.s *= 1.6

		roof.color = color

		building.add_child(roof)

	# Set parameters in the building base
	building.set_metadata(building_metadata)
	building.position = building_metadata["engine_center_position"]
	building.name = str(feature.get_id())

	# Build!
	building.build()

	return building


func get_building_metadata(feature: GeoPolygon):
	# Actual geo coordinates
	var geo_footprint = Array(feature.get_outer_vertices())
	var geo_holes = feature.get_holes()
	var geo_center = geo_footprint.reduce(func(accum, vertex):
		return accum + vertex, Vector2.ZERO) / geo_footprint.size()
	
	# Coordinates as used in engine
	var engine_footprint = Array(
		feature.get_offset_outer_vertices(center[0], center[1]))
	
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
