extends RigidBody
class_name VRInteractable

# When picked up hide the hand/controller mesh
export(bool) var show_controller_hand_meshes = true
# Alwawy same position in the hand
export(bool) var fixed_position = false
export(Transform) var position_in_hand = Transform.IDENTITY

onready var original_parent = get_parent()

var controller_id: int
var object_interaction
var is_picked_up: bool = false
var _is_interacting: bool = false


# Onready add it to the group of interactable, so the ObjectInteraction node can
# checks for it.
func _ready():
	add_to_group("Interactable")


# This method will be called, when the interaction-button is pressed on the current controller
func interact():
	_is_interacting = true


# This happens when interaction-button is released
func interact_end():
	_is_interacting = false


# This happens when the pick-up-button is pressed on the current controller
func picked_up(my_controller: int, my_interactor):
	controller_id =  my_controller
	object_interaction = my_interactor
	is_picked_up = true


# This happens when the pick-up-button is released on the current controller
func dropped(velocity: Vector3):
	if not object_interaction == null:
		set_linear_velocity(velocity)
	
	controller_id = 0
	object_interaction = null
	is_picked_up = false


func get_class(): return "VRInteractable"
