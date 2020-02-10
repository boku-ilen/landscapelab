extends Container


func _ready():
	GlobalSignal.connect("retranslate", self, "_reload")


func _input(event):
	if event.is_action_pressed("toggle_ui"):
		visible = !visible


# React to the language settings being changed
func _reload():
	get_tree().reload_current_scene()
