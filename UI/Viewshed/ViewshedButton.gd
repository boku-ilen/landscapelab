extends "res://UI/Tools/ToolsButton.gd"


func _ready():
	connect("toggled", self, "_on_toggle")


func _on_toggle(toggled: bool):
	if toggled:
		UISignal.emit_signal("set_viewshed_tool", true)
	else:
		UISignal.emit_signal("set_viewshed_tool", false)
