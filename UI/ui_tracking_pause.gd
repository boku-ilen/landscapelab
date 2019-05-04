extends TextureButton


# change the toggle based on the UI signals
func _ready():
	GlobalSignal.connect("tracking_play", self, "set_visible", [true])
	GlobalSignal.connect("tracking_stop", self, "set_visible", [false])


# if we start tracking emit the signal and hide the button
func _pressed():
		GlobalSignal.emit_signal("tracking_pause")
		set_visible(false)
