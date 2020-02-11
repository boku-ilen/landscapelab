extends TextureButton
class_name ToolsButton


#
# Making a new toolbar-button requires a script that extends this class.
#

onready var my_popups = get_children()
var popups_container : HBoxContainer = null


func set_popups_container(container : HBoxContainer):
	popups_container = container
	
	for child in my_popups:
		remove_child(child)
		popups_container.add_child(child)


func _toggled(button_pressed):
	for child in my_popups:
		child.visible = !child.visible
