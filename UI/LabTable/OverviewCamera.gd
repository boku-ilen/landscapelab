extends Camera2D


signal recenter(center)


func screen_to_global(screen_position):
	return position + get_global_transform().basis_xform(screen_position) / zoom


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = event.position - get_viewport_rect().size / 2.0
			mouse_pos = screen_to_global(mouse_pos)
			recenter.emit(mouse_pos)
