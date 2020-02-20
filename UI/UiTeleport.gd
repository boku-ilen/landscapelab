extends ToolsButton


func _ready():
	connect("toggled", self, "_on_toggle")
	GlobalSignal.connect("teleported", self, "_on_teleported")


func _on_toggle(toggled: bool):
	if toggled:
		UISignal.emit_signal("set_teleport_mode", true)
	else:
		UISignal.emit_signal("set_teleport_mode", false)


func _on_teleported():
	set_pressed(false)
	
	for popup in my_popups:
		popup.set_visible(false)
