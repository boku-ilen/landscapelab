extends HBoxContainer
tool

#
# A hover menu for all the tools that are to follow so the GUI does not look 
# as overloaded as it currently does. The mouse property of children has to be 
# set to pass in order for it to function properly.
#


onready var _hoverable = get_node("Hoverable")
const _required_button = preload("res://UI/ToolsBar/ToolsButton.gd")


func _ready():
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("mouse_entered", self, "_on_mouse_entered") 


func _on_mouse_entered():
	print("entered")
	for child in get_children():
		child.visible = true
	
	_hoverable.set_rotation_degrees(90)


func _on_mouse_exited():
	print("exited")
	for child in get_children():
		if child.name != "Hoverable" and not child.pressed:
			child.visible = false 
	
	_hoverable.set_rotation_degrees(0)


# Tool specific tool for showing errors in the editor
func _get_configuration_warning():
	for child in get_children():
		var is_required_type = child is _required_button
		
		if child.name != "Hoverable" and not is_required_type:
			return "One or more child(ren) do not extend the required ToolsButton"
	
	return ""
