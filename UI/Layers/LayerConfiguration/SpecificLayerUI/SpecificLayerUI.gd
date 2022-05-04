extends Control
class_name SpecificLayerUI

onready var warning = get_node("RightBox/Warning")

const LOG_MODULE := "LAYERUI"

# Sometimes (e.g. when checking a checkbox) additional content will be shown
# sadly, godot does not react to this automatically, sending a resize signal
# such that the contents are inside the window works tho
signal new_size(add)


func _ready():
	connect("resized", self, "_on_resize")


func init(layer: Layer = null):
	if layer != null:
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
	logger.warning(warning_text, LOG_MODULE)


func validate(geodata_type):
	return geodata_type and geodata_type.is_valid()


func _on_resize():
	emit_signal("new_size", rect_size)
