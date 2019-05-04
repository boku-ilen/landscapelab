extends TextureButton


# emit the switch of the debug button
func _pressed():
	if pressed:
		GlobalSignal.emit_signal("debug_enable")
	else:
		GlobalSignal.emit_signal("debug_disable")
