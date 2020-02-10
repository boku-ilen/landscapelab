extends Node


#
# Handles hotkeys and shortcuts for GUI elements, etc. to their according signal
# for consistent behaviour
#


# Called when the node enters the scene tree for the first time.
func _unhandled_input(event):
	if event.is_action_pressed("imaging"):
		InputSignal.emit_signal("imaging")
	elif event.is_action_pressed("toggle_imaging_view"):
		InputSignal.emit_signal("toggle_imaging_view")
