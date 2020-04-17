tool
extends Spatial

export (NodePath) var _origin_path = null

onready var controller = get_parent()
onready var origin = get_node(_origin_path)
onready var camera = origin.get_node("ARVRCamera")

var joystick_position = Vector2()


func _ready():
	controller.connect("button_pressed", self, "on_button_pressed")
	controller.connect("button_release", self, "on_button_released")


func _process(delta):
	pass#joystick_position = Vector2(controller.get_joystick_axis(0), controller.get_joystick_axis(1))


func _get_configuration_warning():
	if not get_parent() is ARVRController:
		return "Node must be child of an ARVRController"
	if not get_node(_origin_path) is ARVROrigin:
		return "ARVR origin has to be set"
	
	return ""


# Virtual function for button pressed
func on_button_pressed(id: int):
	pass


# Virtual function for button released
func on_button_released(id: int):
	pass
