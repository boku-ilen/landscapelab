extends TextureButton

#
# This button shows/hides its child elements when pressed.
# They are hidden by default.
#


func _ready():
	for child in get_children():
		child.visible = false
	
	
func _pressed() -> void:
	for child in get_children():
		child.visible = !child.visible