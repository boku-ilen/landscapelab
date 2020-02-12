extends ToolsButton


func _ready():
	connect("pressed", self, "_pressed")
	GlobalSignal.connect("teleported", self, "_on_teleported")


func _pressed():
	GlobalSignal.emit_signal("teleport")


func _on_teleported():
	set_visible(false)
	set_pressed(false)
	
	for popup in my_popups:
		popup.set_visible(false)
