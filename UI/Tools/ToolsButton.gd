extends AutoIconButton
tool


#
# Making a new toolbar-button requires a script that extends this class.
#


func _ready():
	set_mouse_filter(MOUSE_FILTER_PASS) 
	
	# To prevent the tool from removing this node in the editor do this only when it
	# is not inside the editor
	if not Engine.editor_hint:
		set_popups_container()


func set_popups_container():
	if get_child_count() > 1:
		var my_popup = get_child(1)
		
		if my_popup:
			assert(my_popup is Container, "The child has to be of type Container")
			
			var popup_size = Vector2(
				max(my_popup.rect_min_size.x, my_popup.rect_size.x),
				max(my_popup.rect_min_size.y, my_popup.rect_size.y)
			)
			remove_child(my_popup)
			$WindowDialog.add_child(my_popup)
			$WindowDialog.window_title = my_popup.name
			my_popup.visible = true
			
			$WindowDialog.rect_min_size = popup_size
			$WindowDialog.rect_size = popup_size


func _toggled(button_pressed):
	if button_pressed:
		if $WindowDialog.get_child_count() > 1:
			$WindowDialog.popup(Rect2(rect_global_position, rect_size * rect_scale))
