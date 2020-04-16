extends Node

#
# Loads vegetation data and provides it wrapped in Godot classes with
# functionality such as generating spritesheets.
# 
# The data is expected to be laid out like this:
# vegetation-data-base-path
# 	- name1.phytocoenosis
# 		- name1.csv
# 		- billboard1.png
# 		- billboard2.png
# 	- name2.phytocoenosis
# 		- name2.csv
# ...
#


var base_path = GeodataPaths.get_absolute("vegetation-data")

const phytocoenosis_ending = ".phytocoenosis"
const csv_ending = ".csv"
const sprite_size = 1024


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var phyto = load_phytocoenosis("grass")
	var tex = ImageTexture.new()
	
	tex.create_from_image(phyto.get_spritesheet_row())
	
	get_node("MeshInstance").material_override.albedo_texture = tex


# Get a Phytocoenosis object from the data at base_path/name.phyto.
func load_phytocoenosis(name) -> Phytocoenosis:
	var folder_path = base_path.plus_file(name) + phytocoenosis_ending
	var path = folder_path.plus_file(name) + csv_ending
	var phyto = Phytocoenosis.new(name)
	
	var phyto_csv = File.new()
	phyto_csv.open(path, phyto_csv.READ)
	
	if not phyto_csv.is_open():
		logger.error("Phytocoenosis CSV file does not exist, expected it at %s" % [path])
		return phyto
	
	var headings = phyto_csv.get_csv_line()
	
	while !phyto_csv.eof_reached():
		var csv = phyto_csv.get_csv_line()
		
		if csv.size() == 5:
			phyto.add_plant(Plant.new(csv[0], csv[1], csv[2], csv[3], csv[4], folder_path))
	
	return phyto


class Phytocoenosis:
	var name
	var plants: Array
	
	func _init(name, plants = null):
		self.name = name
		
		if plants:
			self.plants = plants
	
	func add_plant(plant: Plant):
		plants.append(plant)
	
	# Get an image containing the billboards of all plants in this phytocoenosis.
	# The image is always 1024px high; the width is 1024px multiplied by the number of plants.
	# The order of the billboards is preserved from their order in the CSV.
	func get_spritesheet_row():
		var plant_count = plants.size()
		
		# Create the image which will be filled with data.
		# The height is always 1024, while the width is a multiple of 1024.
		# For example, if there are 3 plants, the image will be 3072x1024.
		var row = Image.new()
		row.create(sprite_size * plant_count, sprite_size, false, Image.FORMAT_RGBA8)
		
		# Will be 0, 1024, 2048, ...
		var current_offset = 0
		
		for plant in plants:
			var billboard = plant.get_billboard()
			var billboard_size = billboard.get_size()
			
			# Ratio of width to height of the billboard
			var aspect = billboard_size.x / billboard_size.y
			
			var current_height = billboard_size.y
			var desired_height = sprite_size  # TODO: Take the size parameter of the plant into account
			var desired_width = int(aspect * desired_height)
			
			# Scale the billboard to the desired size
			billboard.resize(desired_width, desired_height)
			
			# We want the billboards to always be centered, so check how big the offset has to be
			var centering_offset = (sprite_size - desired_width) / 2
			
			# Add the scaled billboard to the spritesheet
			row.blit_rect(billboard, Rect2(Vector2(0, 0),
					Vector2(desired_width, desired_height)),
					Vector2(current_offset + centering_offset,
					0))
			
			current_offset += sprite_size
		
		return row


class Plant:
	var name
	var avg_height
	var sigma_height
	var density
	var billboard_path: String
	var base_path: String
	
	func _init(name, avg_height, sigma_height, density, billboard_path, base_path):
		self.name = name
		self.avg_height = avg_height
		self.sigma_height = sigma_height
		self.density = density
		self.billboard_path = billboard_path
		self.base_path = base_path
	
	# Return the billboard of this plant as an unmodified Image.
	func get_billboard():
		var full_path = base_path.plus_file(billboard_path)
		
		var img = Image.new()
		img.load(full_path)
		
		if img.is_empty():
			logger.error("Invalid billboard path in CSV of phytocoenosis %s: %s" % [name, full_path])
		
		return img
