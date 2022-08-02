extends Label


func _ready():
	_on_new_turn_beginning()
	GameSystem.current_game_mode.connect("new_turn_beginning", self, "_on_new_turn_beginning")


func _on_new_turn_beginning():
	text = "Turn {0} of {1}".format([
		GameSystem.current_game_mode.current_turn_number + 1,
		GameSystem.current_game_mode.total_turn_number
	])
