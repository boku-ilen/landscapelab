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
		initial_source="", initial_snar_code="", initial_snarx10="",
		initial_snar_name="", initial_name_de="", initial_snar_group=""):
	self.id = int(initial_id)
	self.name_en = initial_name_en
	
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


func get_plant_ids():
	var plant_ids = []
	for plant in plants:
		plant_ids.append(plant.id)
	
	return plant_ids
