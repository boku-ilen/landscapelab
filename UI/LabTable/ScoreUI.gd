extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	if GameSystem.current_game_mode:
		update_scores()
	
	GameSystem.game_mode_changed.connect(update_scores)


func update_scores():
	for score in GameSystem.current_game_mode.game_scores.values():
		var score_ui = load("res://UI/GameSystem/%sScoreUI.tscn" % score.display_mode).instantiate()
		score_ui.score = score
		if score_ui.score.display_mode == GameScore.DisplayMode.ICONTEXT:
			add_child(score_ui)
		else:
			add_child(score_ui)
