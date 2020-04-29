tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here
	# Add the new type with a name, a parent type, a script and an icon
	add_custom_type("GameMode", "Node", preload("GameMode.gd"), preload("Icons/GameModeIcon.svg"))
	add_custom_type("GameState", "Node", preload("GameState.gd"), preload("Icons/GameStateIcon.svg"))


func _exit_tree():
	# Clean-up of the plugin goes here
	# Always remember to remove it from the engine when deactivated
	remove_custom_type("GameMode")
	remove_custom_type("GameState")
