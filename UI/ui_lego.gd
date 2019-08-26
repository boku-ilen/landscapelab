extends TextureButton


# change the toggle based on the UI signals
func _ready():

	# initialize the input scene invisible
	for child in get_children():
		child.visible = false	

	GlobalSignal.connect("stop_sync_moving_assets", self, "_setpressedfalse")


# if the status is changed to pressed emit the lego signal
func _toggled(button_pressed) -> void:

	if self.is_pressed():
		GlobalSignal.emit_signal("sync_moving_assets")
		for child in get_children():
			child.visible = true
	else:
		GlobalSignal.emit_signal("stop_sync_moving_assets")


# if we set the pressed status to false also hide the editing menu
func _setpressedfalse():

	self.set_pressed(false)
	
	for child in get_children():
		child.visible = false
