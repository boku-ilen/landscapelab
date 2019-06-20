extends HBoxContainer

#
# UI element with a toggle which activates or deactivates wireframe mode.
#


onready var toggle = get_node("CheckButton")


func _ready() -> void:
	toggle.connect("toggled", self, "_on_toggled")


func _on_toggled(button_pressed):
	GlobalSignal.emit_signal("wireframe_toggle", button_pressed)
