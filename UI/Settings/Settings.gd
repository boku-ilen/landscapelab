extends Control


onready var settings = get_node("SettingsWindow")
onready var debug = get_node("SettingsWindow/ScrollContainer2/VBoxContainer/Debug")
onready var lego = get_node("SettingsWindow/ScrollContainer/VBoxContainer/Lego")
onready var button = get_node("ShowSettingsButton")

func _ready():
	lego.get_node("EnableLego").connect("toggled", self, "_on_lego")
	button.connect("pressed", self, "_on_Settings_pressed")


func _on_Settings_pressed():
	settings.popup()


func _on_lego(button_pressed):
	if button_pressed:
		GlobalSignal.emit_signal("sync_moving_assets")
	else:
		GlobalSignal.emit_signal("stop_sync_moving_assets")
