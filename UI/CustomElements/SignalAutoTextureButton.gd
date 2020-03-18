tool
extends AutoTextureButton

#
# A AutoTextureButton which emits GlobalSignals when it's pressed / released. 
#

export(String) var signal_pressed
export(String) var signal_released


# emit the switch of the debug button
func _toggled(button_pressed: bool) -> void:
	if is_inside_tree(): # This check prevents errors in the editor due to script being a tool
		if button_pressed:
			GlobalSignal.emit_signal(signal_pressed)
		else:
			GlobalSignal.emit_signal(signal_released)
