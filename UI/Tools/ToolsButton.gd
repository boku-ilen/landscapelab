@tool
extends AutoIconButton


#
# Making a new toolbar-button requires a script that extends this class.
#


func _ready():
	set_mouse_filter(MOUSE_FILTER_PASS) 
	
	# To prevent the tool from removing this node in the editor do this only when it
	# is not inside the editor
	if not Engine.is_editor_hint():
		set_popups_container()


func set_popups_container():
	if get_child_count() > 1:
		var my_popup = get_child(1)
		
		if my_popup:
			assert(my_popup is Container) #,"The child has to be of type Container")
			
			var popup_size = Vector2(
				max(my_popup.custom_minimum_size.x, my_popup.size.x),
				max(my_popup.custom_minimum_size.y, my_popup.size.y)
			)
			remove_child(my_popup)
			$Window.add_child(my_popup)
			$Window.title = my_popup.name
			my_popup.visible = true
			
			$Window.size = popup_size
			$Window.min_size = popup_size
			
			$Window.connect("popup_hide",Callable(self,"set_pressed").bind(false))


func _toggled(button_pressed):
	if button_pressed:
		if $Window.get_child_count() > 1:
			$Window.popup(Rect2(global_position, size * scale))
