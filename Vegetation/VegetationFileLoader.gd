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
		
		var billboard_array = [[]]
		
		for plant in plants:
			var billboard = plant.get_billboard()
			billboard_array.front().append(billboard)
		
		return SpritesheetHelper.create_spritesheet(
				Vector2(sprite_size, sprite_size),
				billboard_array)


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
