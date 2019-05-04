extends TextureButton


# change the toggle based on the UI signals
func _ready():
	GlobalSignal.connect("input_controller", self, "set_pressed", [false])
	GlobalSignal.connect("input_disabled", self, "set_pressed", [false])


# if the status is changed to pressed emit the lego signal
func _pressed():
	if pressed:
		GlobalSignal.emit_signal("input_lego")
	else:
		GlobalSignal.emit_signal("input_disabled")
