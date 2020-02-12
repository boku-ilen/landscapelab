extends ToolsButton


func _ready():
	connect("toggled", self, "_on_toggle")
	GlobalSignal.connect("teleported", self, "_on_teleported")


func _on_toggle(toggled: bool):
	if toggled:
		GlobalSignal.emit_signal("teleport")
	else:
		GlobalSignal.emit_signal("teleported")


func _on_teleported():
	set_visible(false)
	set_pressed(false)
	
	for popup in my_popups:
		popup.set_visible(false)
