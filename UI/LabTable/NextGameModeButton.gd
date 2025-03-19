extends Button


func _input(event):
	if not is_visible_in_tree(): return
	
	if event is InputEventMouseButton and not event.pressed:
			if get_global_rect().has_point(event.position):
				# On left click (new brick placed), close immediately
				get_viewport().set_input_as_handled()
				GameSystem.activate_next_game_mode()
