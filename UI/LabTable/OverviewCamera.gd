extends Camera2D


signal recenter(center)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = event.position - get_viewport_rect().size / 2.0
			mouse_pos = position + get_global_transform().basis_xform(mouse_pos) / zoom
			recenter.emit(mouse_pos)
