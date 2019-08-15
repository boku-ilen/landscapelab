extends TextureButton


# emit signal for change of follow mode
func _pressed():
	GlobalSignal.emit_signal("toggle_follow_mode")
