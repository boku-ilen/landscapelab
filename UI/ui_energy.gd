extends TextureButton

#
# This button activates/disactivates the energy tooltips 
# with signals and toggles the visibility of the energy 
# details view
#


func _ready():
	for child in get_children():
		child.visible = false


func _toggled(button_pressed) -> void:
	for child in get_children():
		child.visible = !child.visible


func _pressed():
	if pressed:
		GlobalSignal.emit_signal("energy_details_enabled")
	else:
		GlobalSignal.emit_signal("energy_details_disabled")
