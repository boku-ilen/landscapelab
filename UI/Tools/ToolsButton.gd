tool
extends "res://UI/CustomElements/AutoTextureButton.gd"
class_name ToolsButton


#
# Making a new toolbar-button requires a script that extends this class.
#

onready var my_popups = get_children()
var popups_container : HBoxContainer = null


func _ready():
	set_mouse_filter(MOUSE_FILTER_PASS) 
	set_toggle_mode(true)


func set_popups_container(container : HBoxContainer):
	popups_container = container
	
	for child in my_popups:
		remove_child(child)
		popups_container.add_child(child)


func _toggled(button_pressed):
	for child in my_popups:
		child.visible = !child.visible
