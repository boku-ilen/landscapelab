extends Node


func _focus(event: InputEvent):
	if event.is_pressed() and event.button_index == BUTTON_LEFT:
		is_dragging = true
		if cursor.is_colliding() and cursor.get_collider() is PolygonPoint:
			set_current_point(cursor.get_collider())
			set_current_profile(current_point.get_parent())
		else:
			set_current_point(null)
			set_current_profile(null)
			set_current_object(null)
	elif event.is_pressed() and event.button_index == BUTTON_RIGHT:
		is_dragging = true
		if cursor.is_colliding() and not cursor.get_collider() is PolygonPoint:
			set_current_object(cursor.get_collider().get_parent())
		else:
			set_current_point(null)
			set_current_profile(null)
			set_current_object(null)
	else:
		is_dragging = false
