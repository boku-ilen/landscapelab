extends TextureButton

#
# This button activates/disactivates the energy tooltips 
# with signals and toggles the visibility of the energy 
# details view
#


onready var energy_details = get_node("EnergyDetailsPanel")


func _toggled(button_pressed) -> void:

	energy_details.visible = !energy_details.visible

	if self.pressed:
		GlobalSignal.emit_signal("energy_details_enabled")
	else:
		GlobalSignal.emit_signal("energy_details_disabled")
