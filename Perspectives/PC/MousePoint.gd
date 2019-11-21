extends Spatial

#
# This object is a child of a camera.
# It rotates itself so that it points in the direction the mouse is pointing at.
# It is used in the 3rd person camera to align a raycast (ItemSpawner); that way,
# the position the mouse is clicking at in the 3D world can be found. 
#


onready var camera: Camera = get_parent()
onready var cursor: RayCast = get_node("InteractRay")

var RAY_LENGTH = Settings.get_setting("item-spawner", "camera-ray-length") # Distance that will be checked for collision with the ground


func _ready():
	cursor.cast_to = Vector3(0, 0, -RAY_LENGTH)


# Whenever the mouse moves, align the rotation again
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Direct the mouse position on the screen along the camera
		# We use a local ray since it should be relative to the rotation of any parent node
		var mouse_point_vector = camera.project_local_ray_normal(event.position)
		
		# Transform the forward vector to this projected vector (-z is forward)
		transform.basis.z = -mouse_point_vector
