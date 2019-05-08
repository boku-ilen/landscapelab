extends TextureButton


# change the toggle based on the UI signals
func _ready():
	GlobalSignal.connect("input_lego", self, "set_pressed", [false])
	GlobalSignal.connect("input_disabled", self, "set_pressed", [false])


# if the status is changed to pressed emit the controller signal
func _toggled(button_pressed) -> void:
	if self.is_pressed():
		GlobalSignal.emit_signal("input_controller")
	else:
		GlobalSignal.emit_signal("input_disabled")
