extends Node

#
# Loads vegetation data and provides it wrapped in Godot classes with
# functionality such as generating spritesheets.
# 


# Width and height of the distribution picture -- increasing this may prevent repetitive patterns
const distribution_size = 16

# Maximum plant height -- height values in the distribution map are interpreted to be between 0.0
#  and this value
const max_plant_height = 40.0

var plants = {}
var groups = {}
var density_classes = {}
var ground_textures = {}
var fade_textures = {}

# Global plant view distance modifyer (plants per renderer row)
# TODO: Consider moving to settings
var plant_extent = 40.0 setget set_plant_extent, get_plant_extent
signal new_plant_extent(extent)

signal new_data


func _ready():
	var config = ConfigFile.new()
	config.load("user://vegetation_paths.cfg")
	
	VegetationImages.ground_image_base_path = config.get_value("paths", "ground_path")
	VegetationImages.plant_image_base_path = config.get_value("paths", "plant_path")
	
	load_data_from_csv(
		config.get_value("paths", "plant_csv_path"),
		config.get_value("paths", "group_csv_path"),
		config.get_value("paths", "density_csv_path"),
		config.get_value("paths", "texture_csv_path")
	)


func set_plant_extent(extent):
	plant_extent = extent
	emit_signal("new_plant_extent", extent)


func get_plant_extent():
	return plant_extent


# Read Plants and Groups from the given CSV files.
func load_data_from_csv(plant_path: String, group_path: String, density_path: String, texture_definition_path) -> void:
	plants = {}
	groups = {}
	
	density_classes = VegetationCSVUtil.create_density_classes_from_csv(density_path)
	ground_textures = VegetationCSVUtil.create_textures_from_csv(texture_definition_path, [], ["DISTANCE"])
	fade_textures = VegetationCSVUtil.create_textures_from_csv(texture_definition_path, ["DISTANCE"], [])
	plants = VegetationCSVUtil.create_plants_from_csv(plant_path, density_classes)
	groups = VegetationCSVUtil.create_groups_from_csv(group_path, plants, ground_textures, fade_textures)
	
	emit_signal("new_data")


# Save the current Plant and Group data to CSV files at the given locations.
# If the files exist, their content is replaced by the new data.
func save_to_files(plant_csv_path: String, group_csv_path: String):
	VegetationCSVUtil.save_plants_to_csv(plants, plant_csv_path)
	VegetationCSVUtil.save_groups_to_csv(groups, group_csv_path)


# Returns the Group objects which correspond to the given IDs, retaining the ordering.
func get_group_array_for_ids(id_array):
	var group_array = []
	group_array.resize(id_array.size())
	
	for i in range(id_array.size()):
		group_array[i] = groups[id_array[i]]
	
	return group_array


# Returns the an array containing all IDs of the given groups, retaining the ordering.
func get_id_array_for_groups(group_array):
	var id_array = []
	id_array.resize(group_array.size())
	
	for i in range(group_array.size()):
		id_array[i] = group_array[i].id
	
	return id_array


# Returns an array with the same groups as were given in the function,
#  but with each group's plant array only consisting of plants with the
#  given density class.
func filter_group_array_by_density_class(group_array: Array, density_class):
	var new_array = []
	
	for group in group_array:
		var plants = []
		
		for plant in group.plants:
			if plant.density_class == density_class:
				plants.append(plant)
		
		if not plants.empty():
			# Append a new Group which is identical to the one in the passed
			#  array, but with the filtered plants
			new_array.append(PlantGroup.new(group.id,
					group.name_en,
					plants,
					group.ground_texture))
	
	return new_array


# Shortcut for get_group_array_for_ids + get_billboard_sheet
func get_billboard_sheet_for_ids(id_array: Array):
	var group_array = []
	
	for id in id_array:
		group_array.append(groups[id])
	
	return get_billboard_sheet(group_array)


# Get a spritesheet with all billboards of the groups in the given
#  group_array.
# A row of the spritesheet corresponds to one group, with its plants in
#  the columns.
func get_billboard_sheet(group_array: Array):
	# "Reversed" because we want infinite plants per group, not infinite plant groups
	var number_of_images_within_layer = group_array.size()
	
	var number_of_layers = 0
	for group in group_array:
		if group.plants.size() > number_of_layers:
			number_of_layers = group.plants.size()
	
	var billboard_table = Array()
	billboard_table.resize(number_of_layers)
	
	for layer_id in number_of_layers:
		billboard_table[layer_id] = []
		
		for group_id in number_of_images_within_layer:
			var end_of_plants_reached = layer_id >= group_array[group_id].plants.size()
			
			billboard_table[layer_id].append(group_array[group_id].plants[layer_id].get_billboard()
					if not end_of_plants_reached else null)
	
	return SpritesheetHelper.create_layered_spritesheet(
			Vector2(VegetationImages.SPRITE_SIZE, VegetationImages.SPRITE_SIZE),
			billboard_table,
			SpritesheetHelper.SCALING.KEEP_ASPECT)


# Returns a 1x? spritesheet with each group's ground texture in the rows.
func get_ground_sheet(group_array, texture_name):
	var texture_table = Array()
	texture_table.resize(1)
	
	texture_table[0] = []
	
	for group in group_array:
		texture_table[0].append(group.get_ground_image(texture_name))
	
	return SpritesheetHelper.create_layered_spritesheet(
			Vector2(VegetationImages.GROUND_TEXTURE_SIZE, VegetationImages.GROUND_TEXTURE_SIZE),
			texture_table,
			SpritesheetHelper.SCALING.STRETCH)[0]


# Returns a 1x? spritesheet with each group's distribution texture in the
#  rows.
func get_distribution_sheet(group_array):
	var texture_table = Array()
	texture_table.resize(1)
	
	texture_table[0] = []
	
	for group in group_array:
		texture_table[0].append(generate_distribution(group, max_plant_height) \
				if group.plants.size() > 0 else null)
	
	return SpritesheetHelper.create_layered_spritesheet(
			Vector2(distribution_size, distribution_size),
			texture_table)[0]


# To map land-use values to a row from 0-7, we use a 256x1 texture.
# An array would be more straightforward, but shaders don't accept these as
#  uniform parameters.
func get_id_row_map_texture(ids):
	var id_row_map = Image.new()
	id_row_map.create(256, 1, false, Image.FORMAT_R8)
	id_row_map.lock()
	
	# id_row_map.fill doesn't work here - if that is used, the set_pixel calls
	#  later have no effect...
	for i in range(0, 256):
		id_row_map.set_pixel(i, 0, Color(1.0, 0.0, 0.0))
	
	# The pixel at x=id (0-255) is set to the row value (0-7).
	var row = 0
	for id in ids:
		id_row_map.set_pixel(id, 0, Color(row / 255.0, 0.0, 0.0))
		row += 1
	
	id_row_map.unlock()
	
	# Fill all parameters into the shader
	var id_row_map_tex = ImageTexture.new()
	id_row_map_tex.create_from_image(id_row_map, 0)
	
	return id_row_map_tex


# Wraps the result of get_ground_albedo_sheet in an ImageTexture.
func get_ground_sheet_texture(group_array, texture_name):
	var tex = ImageTexture.new()
	tex.create_from_image(get_ground_sheet(group_array, texture_name))
	
	return tex


# Wrapper for get_billboard_sheet, but returns an ImageTexture instead of an
#   Image for direct use in materials.
func get_billboard_texture(group_array):
	var images = get_billboard_sheet(group_array)
	
	if not images or images.size() == 0:
		return null
	
	var texture_array = TextureArray.new()
	texture_array.create(images[0].get_width(), images[0].get_height(), images.size(), Image.FORMAT_RGBA8)
	
	var current_layer = 0
	for image in images:
		texture_array.set_layer_data(image, current_layer)
		current_layer += 1
	
	return texture_array


# Returns a newly generated distribution map for the plants in the given group.
# This map is a 16x16 image whose R values correspond to the IDs of the plants; the G values are
#  the size scaling factors (between 0 and 1 relative to the given max_size) for each particular
#  plant instance, taking into account its min and max size.
func generate_distribution(group: PlantGroup, max_size: float):
	var distribution = Image.new()
	distribution.create(distribution_size, distribution_size,
			false, Image.FORMAT_RG8)
	
	var dice = RandomNumberGenerator.new()
	dice.randomize()
	
	distribution.lock()
	
	for y in range(0, distribution_size):
		for x in range(0, distribution_size):
			var highest_roll = 0
			var highest_roll_id = 0
			
			# Roll a dice for every plant. If it is higher than the previous highest roll,
			#  set the hihgest roll ID to the ID of this plant within the group (the position
			#  in the group's plant array).
			var current_plant_in_group_id = 0
			for plant in group.plants:
				# Roll the dice weighed by the plant density. A small factor is
				#  added because some plants never show up otherwise.
				var roll = dice.randf_range(0.0, plant.density_ha + 800.0)
				
				if roll > highest_roll:
					highest_roll_id = current_plant_in_group_id
					highest_roll = roll
				
				current_plant_in_group_id += 1
			
			# Roll another dice for getting the height of this plant instance
			#  (between the plant's min and max height)
			var plant = group.plants[highest_roll_id]
			var random_height = dice.randf_range(plant.height_min, plant.height_max)
			var scale_factor = random_height / max_size
			
			distribution.set_pixel(x, y, Color(highest_roll_id / 255.0, scale_factor, 0.0, 0.0))
	
	distribution.unlock()
	
	return distribution


# Return all renderers according to the set Density Classes. The renderers are children of the
#  returned Spatial.
func get_renderers() -> Spatial:
	var root = Spatial.new()
	root.name = "VegetationRenderers"
	
	for density_class in density_classes.values():
		var renderer = preload("res://Layers/Renderers/RasterVegetation/VegetationLayerRenderer.tscn").instance()
		
		renderer.density_class = density_class
		# TODO: Remove hardcoded path
		renderer.set_mesh(preload("res://Resources/Meshes/VegetationBillboard/1m_billboard.obj"))
		
		root.add_child(renderer)
	
	return root
