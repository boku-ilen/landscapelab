extends TextureButton


# emmit global signal zoom_in if button was pressed
func _pressed():
	GlobalSignal.emit_signal("toggle_follow_mode")
