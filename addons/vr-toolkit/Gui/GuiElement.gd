extends Control
class_name VRGuiElement

# There can only be one active controller per viewport
var active_controller: int = 1


func _ready():
	connect_mouse_entered(self)


func connect_mouse_entered(node: Control):
	for child in get_children():
		child.connect("mouse_entered", self, "controller_feedback")


# The mouse entered signal is connected to this function
func controller_feedback():
	GlobalVRAccess.controller_id_dict[active_controller].rumble = 0.3
	yield(get_tree(), "physics_frame")
	GlobalVRAccess.controller_id_dict[active_controller].rumble = 0.0


# On any input set the device to the current controller's id
# An input can also be an InputEventMouseMotion for example.
func _gui_input(event):
	active_controller = event.device
