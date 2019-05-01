extends TextureButton


# make this button visible again under conditions
func _ready():
	GlobalSignal.connect("missing_1st", self, "set_visible", [true])


# emit the 1st person signal if button is pressed
func _pressed():
	GlobalSignal.emit_signal("miniview_1st")
	self.set_visible(false)
