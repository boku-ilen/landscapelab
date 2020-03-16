tool
extends AutoTextureButton


# change the visibility based on the UI signals
func _ready():
	GlobalSignal.connect("miniview_close", self, "set_visible", [false])
	GlobalSignal.connect("miniview_show", self, "set_visible", [true])
	GlobalSignal.connect("hide_perspective_controls", self, "set_visible", [false])
	GlobalSignal.connect("show_perspective_controls", self, "set_visible", [true])


# emit the switch signal if button is pressed
func _pressed():
	GlobalSignal.emit_signal("miniview_switch")
