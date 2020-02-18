extends TextureButton


onready var settings = get_node("Panel")
onready var debug = get_node("Panel/ScrollContainer2/VBoxContainer/Debug")
onready var lego = get_node("Panel/ScrollContainer/VBoxContainer/Lego")


func _ready():
	lego.get_node("EnableLego").connect("toggled", self, "_on_lego")
	connect("pressed", self, "_on_Settings_pressed")
	
	# Lego is enabled by default, we have to emit the signal on_ready
	GlobalSignal.emit_signal("sync_moving_assets")


func _on_Settings_pressed():
	settings.popup()


func _on_lego(button_pressed):
	if button_pressed:
		GlobalSignal.emit_signal("sync_moving_assets")
	else:
		GlobalSignal.emit_signal("stop_sync_moving_assets")
