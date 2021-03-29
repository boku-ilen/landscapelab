extends Object
class_name PlantGroup

var id
var plants: Array
var ground_texture_folder

# Misc
var source
var snar_code
var snarx10
var snar_name
var name_de
var name_en
var snar_group

func _init(id, name_en, plants = null, ground_texture_folder = null, source="", snar_code="",
		snarx10="", snar_name="", name_de="", snar_group=""):
	self.id = int(id)
	self.name_en = name_en
	
	if ground_texture_folder:
		self.ground_texture_folder = ground_texture_folder
	
	if plants:
		self.plants = plants
	
	self.source = source
	self.snar_code = snar_code
	self.snarx10 = snarx10
	self.snar_name = snar_name
	self.name_de = name_de
	self.snar_group = snar_group
	
func add_plant(plant: Plant):
	plants.append(plant)

func remove_plant(plant: Plant):
	plants.erase(plant)

func get_ground_image(base_path, image_name):
	if not ground_texture_folder: return null
	
	var full_path = base_path \
			.plus_file(ground_texture_folder) \
			.plus_file(image_name + ".jpg")
	
	VegetationImages.ground_image_mutex.lock()
	if not VegetationImages.ground_image_cache.has(full_path):
		var img = Image.new()
		img.load(full_path)
		
		if img.is_empty():
			logger.error("Invalid ground texture path in CSV of group %s: %s"
					 % [name_en, full_path])
		
		VegetationImages.ground_image_cache[full_path] = img
	VegetationImages.ground_image_mutex.unlock()
	
	return VegetationImages.ground_image_cache[full_path]

func get_ground_texture(base_path, image_name):
	var image = get_ground_image(base_path, image_name)
	if not image: return null
	
	var tex = ImageTexture.new()
	tex.create_from_image(image, Texture.FLAG_MIPMAPS + Texture.FLAG_FILTER + Texture.FLAG_REPEAT)
	
	return tex

func get_plant_ids():
	var plant_ids = []
	for plant in plants:
		plant_ids.append(plant.id)
	
	return plant_ids
