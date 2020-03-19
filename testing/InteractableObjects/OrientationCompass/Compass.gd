extends InteractableObject

#
# A compass indicating the orientation of the firstPerson.
# Rotates with the latest global player position from PlayerInfo.
#

onready var compass_symbol = get_node("Spatial")


func _process(delta):
	if _is_picked_up:
		var compass_plate_plane = Plane(controller.global_transform.basis.y, 0)
		
		var new_forward = compass_plate_plane.project(Vector3.FORWARD).normalized()
		var new_up = controller.global_transform.basis.y
		var new_right = new_forward.cross(new_up)
		
		compass_symbol.global_transform.basis = Basis(new_right, new_up, -new_forward)
