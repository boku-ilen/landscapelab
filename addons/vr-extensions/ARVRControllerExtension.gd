tool
extends Spatial

export (NodePath) var _origin_path = null
export (float) var floor_threshold = 0.9

onready var world_scale = ARVRServer.world_scale
onready var controller = get_parent()
onready var origin = get_node(_origin_path)
onready var world = get_viewport().find_world()
onready var state = world.get_direct_space_state()

var query = PhysicsShapeQueryParameters.new()
var is_on_floor = true
var joystick_pos = Vector2()


func _ready():
	controller.connect("button_pressed", self, "_on_button_pressed")
	controller.connect("button_released", self, "_on_button_released")


func _process(delta):
	if not controller == null:
		joystick_pos = Vector2(controller.get_joystick_axis(0), controller.get_joystick_axis(1))


func _get_configuration_warning():
	if not get_parent() is ARVRController:
		return "Node must be child of an ARVRController"
	if not get_node(_origin_path) is ARVROrigin:
		return "ARVR origin has to be set"
	
	return ""


# Virtual function for button pressed
func _on_button_pressed(id: int):
	pass


# Virtual function for button released
func _on_button_released(id: int):
	pass
