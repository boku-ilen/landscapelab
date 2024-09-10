extends Button


# If visible, allows the user to save the current GameSystem state.
# If not visible, periodically saves the GameSystem state automatically.


func _ready():
	pressed.connect(save)
	if has_node("AutoSaveTimer"):
		$AutoSaveTimer.timeout.connect(save)


func save():
	if not visible:
		logger.info("Saving GameSystem state...")
		GameSystem.save()
		logger.info("Done saving GameSystem state.")
