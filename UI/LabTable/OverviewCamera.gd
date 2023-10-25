extends Camera2D


signal recenter(center)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			recenter.emit(get_global_mouse_position())
