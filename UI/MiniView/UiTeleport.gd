extends TextureButton

# Emit a global signal for using the pc-perspective onclick teleport.
func _pressed():
	GlobalSignal.emit("teleport")
