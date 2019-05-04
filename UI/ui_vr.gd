extends TextureButton


# emit the switch of the vr button
func _pressed():
	if pressed:
		GlobalSignal.emit_signal("vr_enable")
	else:
		GlobalSignal.emit_signal("vr_disable")
