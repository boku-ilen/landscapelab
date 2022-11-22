extends Camera2D

var mouse_start_pos
var screen_start_position

var dragging = false


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				mouse_start_pos = event.position
				screen_start_position = position
				dragging = true
			else:
				dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in(0.25)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out(0.25)
	elif event is InputEventMouseMotion and dragging:
		position = (mouse_start_pos - event.position) / zoom + screen_start_position


func zoom_out(factor: float):
	zoom -= Vector2.ONE * factor 


func zoom_in(factor: float):
	zoom += Vector2.ONE * factor
