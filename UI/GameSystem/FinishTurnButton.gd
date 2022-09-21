extends Button


func _ready():
	connect("pressed",Callable(self,"_on_button_pressed"))


func _on_button_pressed():
	GameSystem.current_game_mode.next_turn()
