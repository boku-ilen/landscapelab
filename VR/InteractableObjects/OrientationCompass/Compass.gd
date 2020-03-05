extends InteractableObject

#
# A compass indicating the orientation of the firstPerson.
# Rotates with the latest global player position from PlayerInfo.
#

var _is_picked_up: bool = false
onready var compass_symbol = get_node("Spatial")


func _process(delta):
	var compass_direction = Vector3(transform.origin.x, transform.origin.y, transform.origin.z - 100)
	if _is_picked_up:
		compass_symbol.look_at(compass_direction, controller.transform.basis.y)


func picked_up(my_controller: ARVRController):
	controller = my_controller
	_is_picked_up = true
