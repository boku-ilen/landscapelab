extends TextureButton


# make this button visible again under conditions
func _ready():
	GlobalSignal.connect("missing_3rd", self, "set_visible", [true])


# emit the 3rd person mode signal if button is pressed
func _pressed():
	GlobalSignal.emit_signal("miniview_3rd")
	self.set_visible(false)
	
