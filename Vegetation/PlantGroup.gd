extends Object
class_name PlantGroup

#
# A group of multiple Plant objects along with some additional parameters.
# These can be displayed by a vegetation renderer.
#


var id
var plants: Array
var ground_texture: GroundTexture
var fade_texture: GroundTexture

# Misc
var source
var snar_code
var snarx10
var snar_name
var name_de
var name_en
var snar_group


func _init(initial_id, initial_name_en, initial_plants = null,
		initial_ground_texture = null, initial_fade_texture = null,
		initial_source="", initial_snar_code="", initial_snarx10="",
		initial_snar_name="", initial_name_de="", initial_snar_group=""):
	self.id = int(initial_id)
	self.name_en = initial_name_en
	
	self.ground_texture = initial_ground_texture
	self.fade_texture = initial_fade_texture
	
	self.plants = initial_plants
	
	self.source = initial_source
	self.snar_code = initial_snar_code
	self.snarx10 = initial_snarx10
	self.snar_name = initial_snar_name
	self.name_de = initial_name_de
	self.snar_group = initial_snar_group
	
func add_plant(plant: Plant):
	plants.append(plant)

func remove_plant(plant: Plant):
	plants.erase(plant)

func _get_image(image_name, texture):
	if not texture: return null
	
	var full_path = VegetationImages.ground_image_base_path \
			.path_join(texture.texture_name) \
			.path_join(image_name + ".jpg")
	
	VegetationImages.ground_image_mutex.lock()
	if not VegetationImages.ground_image_cache.has(full_path):
		if not FileAccess.file_exists(full_path):
			logger.warn("Invalid ground texture file: %s (ID %s)" % [full_path, str(texture.id)])
		
		var img = StructuredTexture.get_image(VegetationImages.ground_image_base_path \
			.path_join(texture.texture_name), image_name)
		
		VegetationImages.ground_image_cache[full_path] = img
	VegetationImages.ground_image_mutex.unlock()
	
	return VegetationImages.ground_image_cache[full_path]

func get_fade_image(image_name):
	return _get_image(image_name, fade_texture)

func get_ground_image(image_name):
	return _get_image(image_name, ground_texture)

func get_ground_texture(image_name):
	var image = get_ground_image(image_name)
	if not image: return null
	
	return ImageTexture.create_from_image(image) #,Texture2D.FLAG_MIPMAPS + Texture2D.FLAG_FILTER + Texture2D.FLAG_REPEAT + Texture2D.FLAG_ANISOTROPIC_FILTER

func get_fade_texture(image_name):
	var image = get_fade_image(image_name)
	if not image: return null
	
	return ImageTexture.create_from_image(image) #,Texture2D.FLAG_MIPMAPS + Texture2D.FLAG_FILTER + Texture2D.FLAG_REPEAT


func get_plant_ids():
	var plant_ids = []
	for plant in plants:
		plant_ids.append(plant.id)
	
	return plant_ids
