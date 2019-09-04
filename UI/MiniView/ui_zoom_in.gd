extends TextureButton


# make this button visible again under conditions
func _ready():
	GlobalSignal.connect("miniview_map", self, "set_visible", [true])
	
	GlobalSignal.connect("hide_perspective_controls", self, "set_visible", [false])
	GlobalSignal.connect("show_perspective_controls", self, "set_visible", [true])


# emmit global signal zoom_in if button was pressed
func _pressed():
	GlobalSignal.emit_signal("minimap_zoom_in")
