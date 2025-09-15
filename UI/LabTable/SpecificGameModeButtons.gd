extends HBoxContainer

# Instantiates a button with an icon for all game modes which have their "icon" property set.
# Pressing a button activates the corresponding game mode.


func _ready():
	for game_mode_name in GameSystem.game_mode_names_to_objects.keys():
		var game_mode = GameSystem.game_mode_names_to_objects[game_mode_name]
		
		if game_mode.icon != null:
			var new_button = Button.new()
			
			new_button.name = game_mode_name
			new_button.icon = game_mode.icon
			new_button.toggle_mode = true
			new_button.theme = preload("res://UI/Theme/TableButton.tres")
			new_button.theme_type_variation = "FlatButton"
			new_button.set_script(preload("res://UI/LabTable/TableButton.gd"))
			new_button.toggled.connect(_on_game_mode_button_toggled.bind(game_mode_name))
			
			add_child(new_button)
	
	_update_buttons_for_current_game_mode()
	GameSystem.game_mode_changed.connect(_update_buttons_for_current_game_mode)


func _on_game_mode_button_toggled(_toggled, game_mode_name):
	GameSystem.activate_game_mode_by_name(game_mode_name)
	_update_buttons_for_current_game_mode()


func _update_buttons_for_current_game_mode():
	for child in get_children():
		child.set_pressed_no_signal(false)
	
	get_node(GameSystem.current_game_mode.name).set_pressed_no_signal(true)
