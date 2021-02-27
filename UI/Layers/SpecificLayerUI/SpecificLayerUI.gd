extends Node
class_name SpecificLayerUI

onready var warning = get_node("RightBox/Warning")


func init(layer=null):
	init_specific_layer_info(layer)


# To be implemented by a child class
func assign_specific_layer_info(layer: Layer):
	pass


# To be implemented by a child class
func init_specific_layer_info(layer: Layer):
	pass


func print_warning(warning_text: String = ""):
	warning.visible = true
	warning.text = warning_text
	logger.warning(warning_text)


func validate(geodata_type):
	return geodata_type and geodata_type.is_valid()
