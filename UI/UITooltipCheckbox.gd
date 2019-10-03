extends CheckBox

#
# Manages display of the assets tooltip information.
#


func _on_toggled(button_pressed):
	if button_pressed:
		GlobalSignal.emit_signal("asset_show_tooltip")
	else:
		GlobalSignal.emit_signal("asset_hide_tooltip")
