extends HBoxContainer

#
# A hover menu for all the tools that are to follow so the GUI does not look 
# as overloaded as it currently does. The mouse property of children has to be 
# set to pass in order for it to function properly.
#


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("mouse_entered", self, "_on_mouse_entered") 


func _on_mouse_entered():
	for child in get_children():
		child.visible = true	


func _on_mouse_exited():
	for child in get_children():
		if child.name != "Hoverable" and not child.pressed:
			child.visible = false 
