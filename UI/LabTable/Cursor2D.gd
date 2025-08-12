extends Sprite2D


@export var camera_2d: Camera2D


func _input(event):
	if event is InputEventMouse:
		# Place cursor at mouse position in world coordinates
		update_from_mouse_position(event.position)


func update_from_mouse_position(mouse_position):
	mouse_position -= get_viewport_rect().size / 2.0
	position = camera_2d.position + camera_2d.get_global_transform().basis_xform(mouse_position) / camera_2d.zoom
