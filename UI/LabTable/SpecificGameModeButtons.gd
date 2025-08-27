extends HBoxContainer

# Instantiates a button with an icon for all game modes which have their "icon" property set.
# Pressing a button activates the corresponding game mode.


func _ready():
	for game_mode_name in GameSystem.game_mode_names_to_objects.keys():
		var game_mode = GameSystem.game_mode_names_to_objects[game_mode_name]
		
		if game_mode.icon != null:
			var new_button = Button.new()
			
			new_button.icon = game_mode.icon
			new_button.flat = true
			new_button.set_script(preload("res://UI/LabTable/TableButton.gd"))
			new_button.pressed.connect(_on_game_mode_button_pressed.bind(game_mode_name))
			
			add_child(new_button)


func _on_game_mode_button_pressed(game_mode_name):
	GameSystem.activate_game_mode_by_name(game_mode_name)
