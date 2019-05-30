extends TextureButton


# emit the switch of the debug button
func _toggled(button_pressed: bool) -> void:
	if button_pressed:
		GlobalSignal.emit_signal("debug_enable")
	else:
		GlobalSignal.emit_signal("debug_disable")