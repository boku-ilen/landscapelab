extends Node3D

#
# This object is a child of a camera.
# It rotates itself so that it points in the direction the mouse is pointing at.
# It is used in the 3rd person camera to align a raycast (ItemSpawner); that way,
# the position the mouse is clicking at in the 3D world can be found. 
#

@onready var camera: Camera3D = get_parent()
@onready var cursor: RayCast3D = get_node("InteractRay")
@onready var info := get_node("CursorInfoDialog")

var RAY_LENGTH = Settings.get_setting("mouse-point", "camera-ray-length") # Distance that will be checked for collision with the ground


func set_visible(new_is_visible):
	visible = new_is_visible


func _ready():
	cursor.target_position = Vector3(0, 0, -RAY_LENGTH)
	$MouseCollisionIndicator.cursor = cursor
	$MouseCollisionIndicator.camera = camera
	
	# Reparent the info dialog to the root node in order to ensure that mouse clicks are handled by
	# it first, rather than having the player handle the clicks (which would happen without this
	# workaround), thus making it impossible to interact with it
	remove_child(info)
	get_tree().get_root().call_deferred("add_child", info)


func _process(delta):
	if not Engine.is_editor_hint():
		# Direct the mouse position checked the screen along the camera
		# We use a local ray since it should be relative to the rotation of any parent node
		# This is done here rather than in _input to prevent missing updates during framerate drops
		var mouse_point_vector = camera.project_local_ray_normal(get_viewport().get_mouse_position())
		
		# Transform3D the forward vector to this projected vector (-z is forward)
		transform.basis.z = -mouse_point_vector


# Whenever the mouse moves, align the rotation again
func _input(event):
	pass
#	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
#		# Fill the info window with values and display it
#		var distance = (cursor.get_collision_point() - camera.global_transform.origin).length()
#		info.set_distance(distance)
#		info.popup_at_mouse_position()
