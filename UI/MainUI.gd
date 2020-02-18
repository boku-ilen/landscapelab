extends Container


func _ready():
	UISignal.emit_signal("ui_loaded")


func _input(event):
	if event.is_action_pressed("toggle_ui"):
		visible = !visible
