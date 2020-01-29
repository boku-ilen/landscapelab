extends TextureButton


onready var settings = get_node("Panel")


func _on_Settings_pressed():
	settings.visible = !settings.visible
