extends Control


@export var vr_camera_path: NodePath
@onready var vr_camera := get_node(vr_camera_path)


func _ready():
	visible = XRServer.find_interface("OpenXR").is_initialized()
	XRServer.interface_added.connect(
		set_visible.bind(XRServer.find_interface("OpenXR").is_initialized()))


func _process(delta):
	# Find a projection in front of the camera
	var pos = vr_camera.global_transform.origin + vr_camera.global_transform.basis.z * -10
	# Project into screen space
	var projected_position = get_viewport().get_camera_3d().unproject_position(pos)
	
	# Clamp inside the rect checked x-axis
	projected_position.x = clamp(
		projected_position.x,
		0,
		get_viewport_rect().size.x - size.x
	)
	# Clamp inside the rect checked y-axis
	projected_position.y = clamp(
		projected_position.y, 
		0, 
		get_viewport_rect().size.y - size.y
	)
	# If the point is behind the camera reverse the position and stick to one side checked x-axis
	if get_viewport().get_camera_3d().is_position_behind(pos):
		projected_position.y = get_viewport_rect().size.y - projected_position.y - size.y
		if projected_position.x < get_viewport_rect().size.x / 2:
			projected_position.x = get_viewport_rect().size.x - size.x
		else:
			projected_position.x = 0

	position = projected_position
