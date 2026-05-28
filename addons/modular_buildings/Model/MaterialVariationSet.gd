extends Resource
class_name MaterialVariationSet

@export var materials_by_type: Dictionary[String, Material]

func get_available()->Array[String]:
	return materials_by_type.keys()

# to be extended by different types
func get_material(type: String, seed = 0):
	return materials_by_type[type]
