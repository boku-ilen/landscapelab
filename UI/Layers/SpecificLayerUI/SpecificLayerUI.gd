extends Node
class_name SpecificLayerUI

onready var warning = get_node("RightBox/Warning")

func init(layer=null):
	init_specific_layer_info(layer)


func assign_specific_layer_info(layer: Layer):
	pass


func init_specific_layer_info(layer: Layer):
	pass


func print_warning():
	warning.visible = true
	warning.text = "Texture or height data is not valid!"


func validate(geodata_type):
	return geodata_type != null and geodata_type.is_valid()
