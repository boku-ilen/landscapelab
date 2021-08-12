extends Control


onready var settings = get_node("SettingsWindow")
onready var labtable = get_node("SettingsWindow/ScrollContainer/VBoxContainer/LabTable")
onready var button = get_node("ShowSettingsButton")


func _ready():
	labtable.get_node("EnableLabTable").connect("toggled", self, "_on_labtable")
	button.connect("pressed", self, "_on_Settings_pressed")


func _on_Settings_pressed():
	settings.popup()


func _on_labtable(button_pressed):
	if button_pressed:
		GlobalSignal.emit_signal("sync_moving_assets")
	else:
		GlobalSignal.emit_signal("stop_sync_moving_assets")
