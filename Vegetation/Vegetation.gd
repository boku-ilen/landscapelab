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
var paths := {}


# Global plant view distance modifyer (plants per renderer row)
# TODO: Consider moving to settings
var plant_extent_factor = 6.0
	get:
		return plant_extent_factor
	set(extent):
		plant_extent_factor = extent
		emit_signal("new_plant_extent_factor", extent)

# Overwritten when data is loaded
var max_extent = 1000.0
signal new_plant_extent_factor(extent)

signal new_data


func load_data_from_gpkg(db) -> void:
	plants = {}
	groups = {}
	
	density_classes = VegetationGPKGUtil.create_density_classes_from_gpkg(db)
	plants = VegetationGPKGUtil.create_plants_from_gpkg(db, density_classes)
	groups = VegetationGPKGUtil.create_groups_from_gpkg(db, plants, ground_textures, fade_textures)
	
	# Calculate the max extent here in order to cache it
	var max_size_factor = 0.0
	for density_class in density_classes.values():
		if density_class.size_factor > max_size_factor:
			max_size_factor = density_class.size_factor
	
	max_extent = max_size_factor * plant_extent_factor
	
	emit_signal("new_data")


# Read Plants and Groups from the given CSV files.
func load_data_from_csv(plant_path: String, group_path: String, density_path: String, texture_definition_path) -> void:
	plants = {}
	groups = {}
	
	density_classes = VegetationCSVUtil.create_density_classes_from_csv(density_path)
	plants = VegetationCSVUtil.create_plants_from_csv(plant_path, density_classes)
	groups = VegetationCSVUtil.create_groups_from_csv(group_path, plants, ground_textures, fade_textures)
	
	# Calculate the max extent here in order to cache it
	var max_size_factor = 0.0
	for density_class in density_classes.values():
		if density_class.size_factor > max_size_factor:
			max_size_factor = density_class.size_factor
	
	max_extent = max_size_factor * plant_extent_factor
	
	emit_signal("new_data")
	paths = {
		"Densities": density_path,
		"Groups": group_path,
		"Plants": plant_path
	}


# Save the current Plant and Group data to CSV files at the given locations.
# If the files exist, their content is replaced by the new data.
func save_to_files(plant_csv_path: String, group_csv_path: String):
	VegetationCSVUtil.save_plants_to_csv(plants, plant_csv_path)
	VegetationCSVUtil.save_groups_to_csv(groups, group_csv_path)


# Returns the Group objects which correspond to the given IDs, retaining the ordering.
# Note that the exact indices may not be retained - invalid entries are skipped, not filled with null!
func get_group_array_for_ids(id_array):
	var group_array = []
	
	for i in range(id_array.size()):
		if groups.has(id_array[i]):
			group_array.append(groups[id_array[i]])
		else:
			logger.debug("Invalid ID in landuse data: %s" % [id_array[i]])
	
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
		var filtered_plants = []
		
		for plant in group.plants:
			if plant.density_class == density_class:
				filtered_plants.append(plant)
		
		if not filtered_plants.is_empty():
			# Append a new Group which is identical to the one in the passed
			#  array, but with the filtered plants
			new_array.append(PlantGroup.new(group.id,
					group.name_en,
					filtered_plants))
	
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
	texture_table.resize(group_array.size())
	
	for i in range(group_array.size()):
		var group = group_array[i]
		var ground_image = group.get_ground_image(texture_name)
		if ground_image == null: return 
		
		texture_table[i] = [ground_image]
	
	return SpritesheetHelper.create_layered_spritesheet(
			Vector2(VegetationImages.GROUND_TEXTURE_SIZE, VegetationImages.GROUND_TEXTURE_SIZE),
			texture_table,
			SpritesheetHelper.SCALING.STRETCH)


# Returns a 1x? spritesheet with each group's fade texture in the rows.
func get_fade_sheet(group_array, texture_name):
	var texture_table = Array()
	texture_table.resize(group_array.size())
	
	for i in range(group_array.size()):
		var group = group_array[i]
		texture_table[i] = [group.get_fade_image(texture_name)]
	
	return SpritesheetHelper.create_layered_spritesheet(
			Vector2(VegetationImages.FADE_TEXTURE_SIZE, VegetationImages.FADE_TEXTURE_SIZE),
			texture_table,
			SpritesheetHelper.SCALING.STRETCH)


# Returns a 1x? spritesheet with each group's distribution texture in the
#  rows.
func get_distribution_sheet(group_array, density_class):
	var texture_table = Array()
	texture_table.resize(1)
	
	texture_table[0] = []
	
	for group in group_array:
		texture_table[0].append(generate_distribution(group, max_plant_height, density_class))
	
	return SpritesheetHelper.create_layered_spritesheet(
			Vector2(distribution_size, distribution_size),
			texture_table)[0]


# To map land-use values to a row from 0-7, we use a 1000x1 array.
func get_id_row_array(ids):
	var array = []
	array.resize(16)
	
	for i in range(16):
		if i >= ids.size(): break
		array[i] = ids[i]
	
	return array


# Creates a texture expressing various metadata of the groups in the given ID array.
# The texture is 1000 pixels wide, with the first row being an id-row-map (see above).
# The following rows of the texture consist of the following data for each of the Groups:
# [Ground Texture2D Scale | Fade Texture2D Scale]
# A scale of 0 means that there is no texture of this type.
# Note that each value needs to be scaled before use, since the texture only allows relative values in the 0..1 range.
func get_metadata_map(ids):
	var metadata = Image.create(1000, 1, false, Image.FORMAT_RGB8)
	
	# .fill doesn't work here - if that is used, the set_pixel calls later have no effect...
	for i in range(0, 1000):
		metadata.set_pixel(i, 0, Color(1.0, 0.0, 0.0))
	
	# The pixel at x=id (0-255) is set to the row value (0-7).
	var row = 0
	for id in ids:
		if groups.has(id):
			# Row value
			var row_color = row / 255.0
			
			# Ground Texture2D Scale
			var ground_texture_scale = groups[id].ground_texture.size_m / GroundTexture.MAX_SIZE_M \
					if groups[id].ground_texture else 0
			
			# Fade Texture2D Scale
			var fade_texture_scale = groups[id].fade_texture.size_m / GroundTexture.MAX_SIZE_M \
					if groups[id].fade_texture else 0
			
			metadata.set_pixel(id, 0, Color(row_color, ground_texture_scale, fade_texture_scale))
			row += 1
	
	# Fill all parameters into the shader
	return ImageTexture.create_from_image(metadata) #,0


# Wraps the result of get_ground_sheet in an ImageTexture.
func get_ground_sheet_texture(group_array, texture_name):
	return _image_array_to_texture_array(get_ground_sheet(group_array, texture_name))


# Wraps the result of get_fade_sheet in an ImageTexture.
func get_fade_sheet_texture(group_array, texture_name):
	return _image_array_to_texture_array(get_fade_sheet(group_array, texture_name))


# Wrapper for get_billboard_sheet, but returns an ImageTexture instead of an
#   Image for direct use in materials.
func get_billboard_texture(group_array):
	return _image_array_to_texture_array(get_billboard_sheet(group_array))


# Utility function for turning an ImageArray into a Texture2DArray.
func _image_array_to_texture_array(images):
	if images == null or images.size() == 0:
		return null
	
	var texture_array = Texture2DArray.new()
	texture_array.create_from_images(images)
	
	return texture_array


var distribution_cache = {}


# Returns a newly generated distribution map for the plants in the given group.
# This map is a 16x16 image whose R values correspond to the IDs of the plants; the G values are
#  the size scaling factors (between 0 and 1 relative to the given max_size) for each particular
#  plant instance, taking into account its min and max size.
func generate_distribution(group: PlantGroup, max_size: float, density_class):
	var id = density_class.id * 1000 + group.id
	
	if id in distribution_cache:
		return distribution_cache[id]
	
	var distribution = Image.create(distribution_size, distribution_size,
			false, Image.FORMAT_RG8)
	
	var dice = RandomNumberGenerator.new()
	dice.randomize()
	
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
	
	distribution_cache[id] = distribution
	
	return distribution


# Return all renderers according to the set Density Classes. The renderers are children of the
#  returned Node3D.
func get_renderers() -> Node3D:
	var root = Node3D.new()
	root.name = "VegetationRenderers"
	
	for density_class in density_classes.values():
		var renderer = load("res://Layers/Renderers/RasterVegetation/VegetationParticles.tscn").instantiate()
		
		renderer.density_class = density_class
		renderer.name = density_class.name
		
		root.add_child(renderer)
	
	return root


# Returns the maximum extent of vegetation so that it can by synchronized with other render distances or LOD factors.
func get_max_extent():
	return max_extent
