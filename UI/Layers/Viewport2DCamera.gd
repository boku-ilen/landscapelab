extends Camera2D


signal zoom_changed(z)

var mouse_start_pos
var screen_start_position

var dragging = false


func input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				mouse_start_pos = event.position
				screen_start_position = position
				dragging = true
			else:
				dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in(0.2, get_local_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out(0.2, get_local_mouse_position())
	elif event is InputEventMouseMotion and dragging:
		position = (mouse_start_pos - event.position) / zoom + screen_start_position


func zoom_out(factor: float, center_offset := Vector2(0, 0)):
	zoom -= zoom * factor 
	position += center_offset
	emit_signal("zoom_changed", zoom)


func zoom_in(factor: float, center_offset := Vector2(0, 0)):
	zoom += zoom * factor
	position += center_offset
	emit_signal("zoom_changed", zoom)
