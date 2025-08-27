extends Button


func _input(event):
	if not is_visible_in_tree(): return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		if get_global_rect().has_point(event.position):
				if toggle_mode:
					button_pressed = not button_pressed
				else:
					pressed.emit()
				get_viewport().set_input_as_handled()
