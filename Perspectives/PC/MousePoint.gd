extends Spatial

#
# This object is a child of a camera.
# It rotates itself so that it points in the direction the mouse is pointing at.
# It is used in the 3rd person camera to align a raycast (ItemSpawner); that way,
# the position the mouse is clicking at in the 3D world can be found. 
#


onready var camera = get_parent()


# Whenever the mouse moves, align the rotation again
func _input(event):
	if event is InputEventMouseMotion:
		# Direct the mouse position on the screen along the camera
		var mouse_point_vector = camera.project_ray_normal(event.position)
		
		# FIXME: We need to do this in order to keep in mind the rotation of the parent (the
		# 3rd person camera). However, this should obviously be dynamic, not hardcoded!
		mouse_point_vector = mouse_point_vector.rotated(Vector3(1, 0, 0), 0.87266)
		
		# Transform the forward vector to this projected vector (-z is forward)
		transform.basis.z = -mouse_point_vector
