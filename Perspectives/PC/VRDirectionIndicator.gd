extends Control


@export var vr_node: NodePath
var vr_camera: Node3D

# FIXME: VR Player needs to be exchanged 

#func _ready():
#	get_node(vr_node).connect("initialized",Callable(self,"set_visible").bind(true))
#	vr_camera = get_node(vr_node).get_node("XRCamera3D")
#
#
#func _process(delta):
#	# Find a projection in front of the camera
#	var position = vr_camera.global_transform.origin + vr_camera.global_transform.basis.z * -10
#	# Project into screen space
#	var projected_position = get_viewport().get_camera_3d().unproject_position(
#						position
#					)
#	# Clamp inside the rect checked x-axis
#	projected_position.x = clamp(
#		projected_position.x,
#		0,
#		get_viewport_rect().size.x - size.x
#	)
#	# Clamp inside the rect checked y-axis
#	projected_position.y = clamp(
#		projected_position.y, 
#		0, 
#		get_viewport_rect().size.y - size.y
#	)
#	# If the point is behind the camera reverse the position and stick to one side checked x-axis
#	if get_viewport().get_camera_3d().is_position_behind(position):
#		projected_position.y = get_viewport_rect().size.y - projected_position.y - size.y
#		if projected_position.x < get_viewport_rect().size.x / 2:
#			projected_position.x = get_viewport_rect().size.x - size.x
#		else:
#			projected_position.x = 0
#
#	position = projected_position
