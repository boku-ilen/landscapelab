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

const LOG_MODULE := "VEGETATION"


func _init(id, name_en, plants = null, ground_texture = null, fade_texture = null, source="",
		snar_code="", snarx10="", snar_name="", name_de="", snar_group=""):
	self.id = int(id)
	self.name_en = name_en
	
	self.ground_texture = ground_texture
	self.fade_texture = fade_texture
	
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

func _get_image(image_name, texture):
	if not texture: return null
	
	var full_path = VegetationImages.ground_image_base_path \
			.path_join(texture.texture_name) \
			.path_join(image_name + ".jpg")
	
	VegetationImages.ground_image_mutex.lock()
	if not VegetationImages.ground_image_cache.has(full_path):
		var path = VegetationImages.ground_image_base_path.path_join(texture.texture_name)
		if not File.new().file_exists(full_path):
			logger.warn("Invalid ground texture file: %s (ID %s)" % [full_path, str(texture.id)], LOG_MODULE)
		
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
