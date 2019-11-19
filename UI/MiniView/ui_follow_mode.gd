extends TextureButton


# emit signal for change of follow mode
func _toggled(active: bool):
	GlobalSignal.emit_signal("toggle_follow_mode")
