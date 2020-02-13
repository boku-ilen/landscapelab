extends TextureButton


onready var settings = get_node("Panel")


func _ready():
	get_node("Panel/ScrollContainer/VBoxContainer/HBoxContainer/CheckButton").connect("toggled", self, "_on_debug")
	connect("pressed", self, "_on_Settings_pressed")


func _on_Settings_pressed():
	settings.visible = !settings.visible


func _on_CheckButton_toggled(button_pressed):
	if button_pressed:
		UISignal.emit_signal("debug_enable")
	else:
		UISignal.emit_signal("debug_disable")
