extends RigidBody
class_name  InteractableObject

var controller: ARVRController
var _is_picked_up: bool = false


# Onready add it to the group of interactable, so the ObjectInteraction node can
# checks for it.
func _ready():
	add_to_group("Interactable")


# This method will be called, when the interaction-button is pressed on the current controller
func interact():
	pass


# This happens when the pick-up-button is pressed on the current controller
func picked_up(my_controller: ARVRController):
	controller =  my_controller
	_is_picked_up = true


# This happens when the pick-up-button is released on the current controller
# Get the current position and wait two physics-frames (so it is not frame dependent)
# then check for the position again. The direction will be the difference of those two positions
func dropped():
	if not controller == null:
		var position_before = controller.global_transform.origin
		yield(get_tree(), "physics_frame")
		yield(get_tree(), "physics_frame")
		var direction = controller.global_transform.origin - position_before
		apply_impulse(transform.origin, direction * 100)
		controller = null
	
	_is_picked_up = false
