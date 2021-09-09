extends "res://UI/CustomElements/AutoTextureButton.gd"
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
	var my_popups = get_children()
	var max_min_size = Vector2(0,0)
	for child in my_popups:
		if child.name == "WindowDialog": continue
		if max_min_size < child.rect_min_size: 
			max_min_size = Vector2(
				max(child.rect_min_size.x, child.rect_size.x),
				max(child.rect_min_size.y, child.rect_size.y)
			)
		remove_child(child)
		$WindowDialog.add_child(child)
		$WindowDialog.window_title = child.name
		child.visible = true
		
	$WindowDialog.rect_min_size = max_min_size


func _toggled(button_pressed):
	if button_pressed:
		if $WindowDialog.get_child_count() > 1:
			$WindowDialog.popup(Rect2(rect_global_position, rect_size * rect_scale))
