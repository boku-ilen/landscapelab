extends TextureButton


# make this button visible again under conditions
func _ready():
	GlobalSignal.connect("miniview_map", self, "set_visible", [true])


# emmit global signal zoom_in if button was pressed
func _pressed():
	GlobalSignal.emit_signal("minimap_zoom_in")
