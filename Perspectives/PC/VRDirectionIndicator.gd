extends Control


export var vr_node: NodePath
var vr_camera: Spatial


func _ready():
	get_node(vr_node).connect("initialized", self, "set_visible", [true])
	vr_camera = get_node(vr_node).get_node("ARVRCamera")


func _process(delta):
	# Find a projection in front of the camera
	var position = vr_camera.global_transform.origin + vr_camera.global_transform.basis.z * -10
	# Project into screen space
	var projected_position = get_viewport().get_camera().unproject_position(
						position
					)
	# Clamp inside the rect on x-axis
	projected_position.x = clamp(
		projected_position.x,
		0,
		get_viewport_rect().size.x - rect_size.x
	)
	# Clamp inside the rect on y-axis
	projected_position.y = clamp(
		projected_position.y, 
		0, 
		get_viewport_rect().size.y - rect_size.y
	)
	# If the point is behind the camera invert the position and stick to one side on x-axis
	if get_viewport().get_camera().is_position_behind(position):
		projected_position.y = get_viewport_rect().size.y - projected_position.y - rect_size.y
		if projected_position.x < get_viewport_rect().size.x / 2:
			projected_position.x = get_viewport_rect().size.x - rect_size.x
		else:
			projected_position.x = 0
	
	rect_position = projected_position
