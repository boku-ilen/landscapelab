extends Camera2D


signal offset_changed(_offset, viewport_size, _zoom)

var position_before := Vector2.ZERO
var mouse_start_pos
var screen_start_position

# TODO: This (and the surrounding signals) can probably be removed \o/
var dont_handle_next_release = false
var zoom_action_counter = 0
# Time to wait between scrolls before loading new data
var zoom_reload_delay = 0.15

const highest_zoom := 19
const resolution_at_highest_zoom := 0.298582141738970

var current_zoom_level = 13
var tile_size_pixels := 256.0


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


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				mouse_start_pos = event.position
				screen_start_position = position
			else:
				if position != position_before:
					offset_changed.emit(position - position_before, get_viewport_rect().size, zoom)
					position_before = position
				else:
					if has_node("ActionHandler"):
						$ActionHandler.handle(event)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			do_zoom(1, get_viewport().get_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			do_zoom(-1, get_viewport().get_mouse_position())
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		position = (mouse_start_pos - event.position) / zoom + screen_start_position


# Zoom and keep the current pixel at it's relative same position
# such that zooming in and out feels fluent and intuitive
func do_zoom(factor: int, mouse_pos := get_viewport_rect().size / 2):
	current_zoom_level += factor
	
	# Calculate the tile size we need for 1:1 pixel:meter for this zoom level
	var tile_size_meters = tile_size_pixels * \
		(resolution_at_highest_zoom * \
		pow(2, highest_zoom + 1 - current_zoom_level))
	
	var zoom_before = zoom
	zoom = Vector2.ONE * (get_viewport_rect().size.x / tile_size_meters)
	
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
	position += (zoom.x / zoom_before.x - 1.0) * center_offset * (get_viewport_rect().size / zoom)
	
	# Usually the user will scroll more than one zoom-level => wait a short time
	# before loading new to avoid unnecessary work load
	zoom_action_counter += 1
	await get_tree().create_timer(zoom_reload_delay).timeout
	zoom_action_counter -= 1
	if not bool(zoom_action_counter):
		offset_changed.emit(position - position_before, get_viewport_rect().size, zoom)
		position_before = position


func screen_to_global(screen_position):
	return get_canvas_transform().affine_inverse() * screen_position 
	#return position + get_global_transform().basis_xform(screen_position) / zoom
