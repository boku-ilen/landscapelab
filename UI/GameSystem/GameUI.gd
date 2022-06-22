extends HBoxContainer


func _ready():
	for collection in GameSystem.current_game_mode.game_object_collections.values():
		$GameObjects/GameObjectCollections.add_item(collection.name)
	
	for score in GameSystem.current_game_mode.game_scores.values():
		var score_ui = preload("res://UI/GameSystem/ScoreUI.tscn").instance()
		score_ui.score = score
		$Scores.add_child(score_ui)
