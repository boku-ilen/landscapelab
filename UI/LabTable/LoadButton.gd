extends Button


# Automatically loads the last GameSystem state on load if it is not visible.
# If the button is visible, it does not load automatically, but waits for input.


func _ready():
	pressed.connect(_on_pressed)
	
	# Initially load if the button is invisible (to easily toggle between workshop and debug mode)
	if not visible:
		GameSystem.load_last_save()


func _on_pressed():
	GameSystem.load_last_save()
