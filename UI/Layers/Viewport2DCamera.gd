extends Camera2D


signal zoom_changed(z)
signal load_new_data(world_offset, viewport_size)

var mouse_start_pos
var screen_start_position

var dragging = false


func _set(n, value):
	match n:
		"position":
			position = value
			load_new_data.emit(position, get_viewport_rect().size / zoom)


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
			do_zoom(1.1, get_viewport().get_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			do_zoom(0.9, get_viewport().get_mouse_position())
	elif event is InputEventMouseMotion and dragging:
		position = (mouse_start_pos - event.position) / zoom + screen_start_position


# Zoom and keep the current pixel at it's relative same position
func do_zoom(factor: float, mouse_pos := get_viewport_rect().size / 2):
	zoom *= factor
	# On x and y axis calculate current mouse position normalized like between -0.5 and 0.5
	#
	# Example: 
	# 0    ------------x/2--------- x
	# -0.5 ------------0------------ 0.5
	#      #
	# => zoom in (* 2)
	# <--   0    ------x/4--- x/2
	# <--   -0.5 ------0------ 0.5
	var center_offset = mouse_pos / get_viewport_rect().size
	center_offset -= Vector2.ONE * 0.5
	position += (factor - 1) * center_offset * (get_viewport_rect().size / zoom)
	
	emit_signal("zoom_changed", zoom)
