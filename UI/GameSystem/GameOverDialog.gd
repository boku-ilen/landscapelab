extends AcceptDialog


func _ready():
	GameSystem.current_game_mode.connect("game_finished", self, "_on_game_finished")


func _on_game_finished():
	# Display overview over final scores
	for score in GameSystem.current_game_mode.game_scores.values():
		var score_ui = preload("res://UI/GameSystem/ScoreUI.tscn").instance()
		score_ui.score = score
		$Scores.add_child(score_ui)
	
	popup()
