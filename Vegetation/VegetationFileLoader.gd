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

var phytocoenosis_by_name = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load phytocoenosis data
	var path = base_path.plus_file("phytocoenosis.csv")
	
	var phyto_csv = File.new()
	phyto_csv.open(path, phyto_csv.READ)
	
	if not phyto_csv.is_open():
		logger.error("Phytocoenosis CSV file does not exist, expected it at %s" % [path])
		return
	
	var headings = phyto_csv.get_csv_line()
	
	while !phyto_csv.eof_reached():
		# Format: Name, ID, Ground texture
		var csv = phyto_csv.get_csv_line()
		phytocoenosis_by_name[csv[0].to_lower()] = Phytocoenosis.new(csv[1], csv[0], csv[2])
	
	# Load plant data
	var plant_path = base_path.plus_file("plants.csv")
	
	var plant_csv = File.new()
	plant_csv.open(plant_path, phyto_csv.READ)
	
	if not plant_csv.is_open():
		logger.error("Phytocoenosis CSV file does not exist, expected it at %s" % [plant_path])
		return
	
	var plant_headings = plant_csv.get_csv_line()
	
	var plant_by_name = {}
	
	while !plant_csv.eof_reached():
		# Format: Phytocoenosis Name, Avg height, sigma height, density, billboard
		var csv = plant_csv.get_csv_line()
		phytocoenosis_by_name[csv[0].to_lower()].plants.append(Plant.new("", csv[1], csv[2], csv[3], csv[4], base_path.plus_file("plant-textures")))
	
	var tex = ImageTexture.new()
	
	print(phytocoenosis_by_name.values()[10].plants.size())
	tex.create_from_image(get_billboard_sheet([phytocoenosis_by_name.values()[10], phytocoenosis_by_name.values()[11]]))
	
	get_node("MeshInstance").material_override.albedo_texture = tex


func get_billboard_sheet(phytocoenosis_array):
	# Array holding the rows of vegetation - each vegetation loaded from the 
	#  given vegetation_names becomes a row in this table
	var billboard_table = Array()
	billboard_table.resize(phytocoenosis_array.size())
	
	var row = 0
	
	for phytocoenosis in phytocoenosis_array:
		billboard_table[row] = []
		
		if phytocoenosis.plants.size() > 0:
			for plant in phytocoenosis.plants:
				var billboard = plant.get_billboard()
				billboard_table[row].append(billboard)
				
			row += 1
		
	return SpritesheetHelper.create_spritesheet(
			Vector2(sprite_size, sprite_size),
			billboard_table)


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
