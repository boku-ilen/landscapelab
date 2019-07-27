extends Button

#
# A button which emits GlobalSignals when it's pressed / released. 
#

export(String) var signal_pressed


# emit the switch of the debug button
func _pressed() -> void:
		GlobalSignal.emit_signal(signal_pressed)