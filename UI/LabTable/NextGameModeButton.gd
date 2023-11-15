extends Button


func _ready():
	pressed.connect(_on_pressed)


func _on_pressed():
	GameSystem.activate_next_game_mode()
