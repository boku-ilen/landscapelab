extends Node

#
# Loads vegetation data and provides it wrapped in Godot classes with
# functionality such as generating spritesheets.
# 
# The data is expected to be laid out like this:
# plants.csv
# phytocoenosis.csv
# plant-texutres
# 	billboard1.png
# 	billboard2.png
# ground-textures
# 	Grass
# 		albedo.jpg
# 		normal.jpg
# 		displacement.jpg
#
# phytocoenosis.csv must have the columns:
# Name, ID, Ground texture
# For example:
# Meadow, 1, Grass
#
# plants.csv must have the columns:
# Phytocoenosis Name, Avg height, sigma height, density, billboard
# For example:
# Meadow, 0.8, 0.1, 0.9, billboard1.png
# 

const distribution_size = 16

const sprite_size = 1024
const texture_size = 1024

var base_path = GeodataPaths.get_absolute("vegetation-data")

var phytocoenosis_by_name = {}
var phytocoenosis_by_id = {}

var plant_image_cache = {}
var ground_image_cache = {}

var ground_image_mutex = Mutex.new()


func _ready() -> void:
	_load_data_from_csv()


# Read the CSV files at the path provided by GeodataPaths and save the
#  metadata of all phytocoenosis with their plants.
func _load_data_from_csv() -> void:
	# Load phytocoenosis data
	var phytocoenosis_path = base_path.plus_file("phytocoenosis.csv")
	
	var phyto_csv = File.new()
	phyto_csv.open(phytocoenosis_path, phyto_csv.READ)
	
	if not phyto_csv.is_open():
		logger.error("Phytocoenosis CSV file does not exist, expected it at %s"
				 % [phytocoenosis_path])
		return
	
	var phytocoenosis_headings = phyto_csv.get_csv_line()
	
	while !phyto_csv.eof_reached():
		# Format: Name, ID, Ground texture
		var csv = phyto_csv.get_csv_line()
		phytocoenosis_by_name[csv[0].to_lower()] = Phytocoenosis.new(csv[1], csv[0], csv[2])
	
	# Load plant data
	var plant_path = base_path.plus_file("plants.csv")
	
	var plant_csv = File.new()
	plant_csv.open(plant_path, phyto_csv.READ)
	
	if not plant_csv.is_open():
		logger.error("Plants CSV file does not exist, expected it at %s"
				 % [plant_path])
		return
	
	var plant_headings = plant_csv.get_csv_line()
	
	while !plant_csv.eof_reached():
		# Format: Phytocoenosis Name, Avg height, sigma height, density, billboard
		var csv = plant_csv.get_csv_line()
		
		if csv[0] == "": break
		
		var p = phytocoenosis_by_name[csv[0].to_lower()]
		
		p.plants.append(
				Plant.new(p.plants.size(), "", float(csv[1]), float(csv[2]),
				float(csv[3]), csv[4],
				base_path.plus_file("plant-textures")))
	
	# Add a map of ID to phytocoenosis as well, since that is frequently required
	for phytocoenosis in phytocoenosis_by_name.values():
		phytocoenosis_by_id[int(phytocoenosis.id)] = phytocoenosis


# Returns the Phytocoenosis objects which correspond to the given IDs.
func get_phytocoenosis_array_for_ids(id_array):
	var phytocoenosis_array = []
	
	for id in id_array:
		if phytocoenosis_by_id.has(id):
			phytocoenosis_array.append(phytocoenosis_by_id[id])
	
	return phytocoenosis_array


# Returns an array with the same phytocoenosis as were given to the function,
#  but with each phytocoenosis' plant array only consisting of plants within the
#  given height range.
func filter_phytocoenosis_array_by_height(phytocoenosis_array, min_height: float, max_height: float):
	var new_array = []
	
	for phytocoenosis in phytocoenosis_array:
		var plants = []
		
		for plant in phytocoenosis.plants:
			if plant.avg_height > min_height and plant.avg_height < max_height:
				plants.append(plant)
		
		# Append a new Phytocoenosis which is identical to the one in the passed
		#  array, but with the filtered plants
		new_array.append(Phytocoenosis.new(phytocoenosis.id,
				phytocoenosis.name,
				phytocoenosis.ground_texture_path,
				plants))
	
	return new_array


# Shortcut for get_phytocoenosis_array_for_ids + get_billboard_sheet
func get_billboard_sheet_for_ids(id_array, max_size):
	var phytocoenosis_array = []
	
	for id in id_array:
		phytocoenosis_array.append(phytocoenosis_by_id[id])
	
	return get_billboard_sheet(phytocoenosis_array, max_size)


# Get a spritesheet with all billboards of the phytocoenosis in the given
#  phytocoenosis_array.
# A row of the spritesheet corresponds to one phytocoenosis, with its plants in
#  the columns.
func get_billboard_sheet(phytocoenosis_array, max_size):
	# Array holding the rows of vegetation - each vegetation loaded from the 
	#  given vegetation_names becomes a row in this table
	var billboard_table = Array()
	billboard_table.resize(phytocoenosis_array.size())
	
	var scale_table = Array()
	scale_table.resize(phytocoenosis_array.size())
	
	var row = 0
	
	for phytocoenosis in phytocoenosis_array:
		billboard_table[row] = []
		scale_table[row] = []
		
		for plant in phytocoenosis.plants:
			var billboard = plant.get_billboard()
			billboard_table[row].append(billboard)
			scale_table[row].append(plant.avg_height / max_size)
			
		row += 1
		
	return SpritesheetHelper.create_spritesheet(
			Vector2(sprite_size, sprite_size),
			billboard_table,
			SpritesheetHelper.SCALING.KEEP_ASPECT,
			scale_table)


# Returns a 1x? spritesheet with each phytocoenosis' ground texture in the rows.
func get_ground_sheet(phytocoenosis_array, texture_name):
	var texture_table = Array()
	texture_table.resize(phytocoenosis_array.size())
	
	var row = 0
	
	for phytocoenosis in phytocoenosis_array:
		texture_table[row] = [phytocoenosis.get_ground_image(texture_name)]
		
		row += 1
	
	return SpritesheetHelper.create_spritesheet(
			Vector2(texture_size, texture_size),
			texture_table,
			SpritesheetHelper.SCALING.STRETCH)


# Returns a 1x? spritesheet with each phytocoenosis' distribution texture in the
#  rows.
func get_distribution_sheet(phytocoenosis_array):
	var texture_table = Array()
	texture_table.resize(phytocoenosis_array.size())
	
	var row = 0
	
	for phytocoenosis in phytocoenosis_array:
		texture_table[row] = [generate_distribution(phytocoenosis)] \
				if phytocoenosis.plants.size() > 0 else null
		
		row += 1
	
	return SpritesheetHelper.create_spritesheet(
			Vector2(distribution_size, distribution_size),
			texture_table)


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
func get_ground_sheet_texture(phytocoenosis_array, texture_name):
	var tex = ImageTexture.new()
	tex.create_from_image(get_ground_sheet(phytocoenosis_array, texture_name))
	
	return tex


# Wrapper for get_billboard_sheet, but returns an ImageTexture instead of an
#   Image for direct use in materials.
func get_billboard_texture(phytocoenosis_array, max_size):
	var tex = ImageTexture.new()
	tex.create_from_image(get_billboard_sheet(phytocoenosis_array, max_size))
	
	return tex


# Returns a newly generated distribution map for the plants in the given
#  phytocoenosis.
# This map is a 16x16 images whose values correspond to the IDs of the plants.
func generate_distribution(phytocoenosis: Phytocoenosis):
	var distribution = Image.new()
	distribution.create(distribution_size, distribution_size,
			false, Image.FORMAT_R8)
	
	var dice = RandomNumberGenerator.new()
	dice.randomize()
	
	distribution.lock()
	
	for y in range(0, distribution_size):
		for x in range(0, distribution_size):
			var highest_roll = 0
			var highest_roll_plant
			
			for plant in phytocoenosis.plants:
				# Roll the dice weighed by the plant density. A small factor is
				#  added because some plants never show up otherwise.
				var roll = dice.randf_range(0.0, plant.density + 0.3)
				
				if roll > highest_roll:
					highest_roll_plant = plant
					highest_roll = roll
			
			# TODO: Edge case with highest_roll_plant being null due to no plants or all densities being 0?
			distribution.set_pixel(x, y, Color(highest_roll_plant.id / 255.0, 0.0, 0.0))
	
	distribution.unlock()
	
	return distribution




class Phytocoenosis:
	var id
	var name
	var plants: Array
	var ground_texture_path
	
	func _init(id, name, ground_texture_path = null, plants = null):
		self.id = id
		self.name = name
		
		if ground_texture_path:
			self.ground_texture_path = ground_texture_path
		
		if plants:
			self.plants = plants
	
	func add_plant(plant: Plant):
		plants.append(plant)
	
	func get_ground_image(image_name):
		var full_path = Vegetation.base_path.plus_file("ground-textures").plus_file(ground_texture_path).plus_file(image_name + ".jpg")
		
		Vegetation.ground_image_mutex.lock()
		if not Vegetation.ground_image_cache.has(full_path):
			var img = Image.new()
			img.load(full_path)
			
			if img.is_empty():
				logger.error("Invalid ground texture path in CSV of phytocoenosis %s: %s"
						 % [name, full_path])
			
			Vegetation.ground_image_cache[full_path] = img
		Vegetation.ground_image_mutex.unlock()
		
		return Vegetation.ground_image_cache[full_path]


class Plant:
	var id
	var name
	var avg_height
	var sigma_height
	var density
	var billboard_path: String
	var base_path: String
	var billboard_image: Image
	
	func _init(id, name, avg_height, sigma_height, density, billboard_path, base_path):
		self.id = id
		self.name = name
		self.avg_height = avg_height
		self.sigma_height = sigma_height
		self.density = density
		self.billboard_path = billboard_path
		self.base_path = base_path
	
	# Return the billboard of this plant as an unmodified Image.
	func get_billboard():
		var full_path = base_path.plus_file(billboard_path)
		
		if not Vegetation.plant_image_cache.has(full_path):
			var img = Image.new()
			img.load(full_path)
			
			if img.is_empty():
				logger.error("Invalid billboard path in CSV of phytocoenosis %s: %s"
						 % [name, full_path])
			
			Vegetation.plant_image_cache[full_path] = img
		
		return Vegetation.plant_image_cache[full_path]

