extends "res://UI/CustomElements/AutoTextureButton.gd"
tool


#
# Making a new toolbar-button requires a script that extends this class.
#

onready var my_popups = get_children()


func _ready():
	set_mouse_filter(MOUSE_FILTER_PASS) 
	
	set_popups_container()


func set_popups_container():
	var max_min_size = Vector2(0,0)
	for child in my_popups:
		if child.name == "WindowDialog": continue
		if max_min_size < child.rect_min_size: max_min_size = child.rect_min_size
		remove_child(child)
		$WindowDialog.add_child(child)
		$WindowDialog.window_title = child.name
		child.visible = true
		
	$WindowDialog.rect_min_size = max_min_size


func _toggled(button_pressed):
	if button_pressed:
		if $WindowDialog.get_child_count():
			$WindowDialog.popup(Rect2(rect_global_position, rect_size * rect_scale))

