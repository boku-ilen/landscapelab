extends TextureButton


# change the visibility based on the UI signals
func _ready():
	GlobalSignal.connect("miniview_show", self, "set_visible", [true])
	
	GlobalSignal.connect("hide_perspective_controls", self, "set_visible", [false])
	GlobalSignal.connect("show_perspective_controls", self, "set_visible", [true])


# if the close button was pressed completely
func _pressed():

	# make sure to set this icon invisible
	self.set_visible(false)

	# close the miniview viewport
	GlobalSignal.emit_signal("miniview_close")
