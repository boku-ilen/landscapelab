extends Camera2D


signal offset_changed(_offset, viewport_size, _zoom)

var position_before := Vector2.ZERO
var mouse_start_pos
var screen_start_position

var dragging = false
var zoom_action_counter = 0
# Time to wait between scrolls before loading new data
var zoom_reload_delay = 0.15


# if the position from the camera is changed from outside of this script
# it comes in handy to have a function that automatically emits the necessary
# data too
func add_offset_and_emit(offset_summand: Vector2):
	position += offset_summand
	offset_changed.emit(position - position_before, get_viewport_rect().size, zoom)
	position_before = position


func set_offset_and_emit(_offset: Vector2):
	position = _offset
	offset_changed.emit(position - position_before, get_viewport_rect().size, zoom)
	position_before = position


func input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				mouse_start_pos = event.position
				screen_start_position = position
				dragging = true
			else:
				dragging = false
				offset_changed.emit(position - position_before, get_viewport_rect().size, zoom)
				position_before = position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			do_zoom(1.1, get_viewport().get_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			do_zoom(0.9, get_viewport().get_mouse_position())
	elif event is InputEventMouseMotion and dragging:
		position = (mouse_start_pos - event.position) / zoom + screen_start_position


# Zoom and keep the current pixel at it's relative same position
# such that zooming in and out feels fluent and intuitive
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
	
	# Usually the user will scroll more than one zoom-level => wait a short time
	# before loading new to avoid unnecessary work load
	zoom_action_counter += 1
	await get_tree().create_timer(zoom_reload_delay).timeout
	zoom_action_counter -= 1
	if not bool(zoom_action_counter):
		offset_changed.emit(position - position_before, get_viewport_rect().size, zoom)
		position_before = position
