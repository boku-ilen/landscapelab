extends TextureButton


# make this button visible again under conditions
func _ready():
	GlobalSignal.connect("missing_map", self, "set_visible", [true])


# emit the map mode signal if button is pressed
func _pressed():
	GlobalSignal.emit_signal("miniview_map")
	self.set_visible(false)
