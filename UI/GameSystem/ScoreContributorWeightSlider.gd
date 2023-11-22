extends HBoxContainer


func _ready():
	$HSlider.value_changed.connect(_on_slider_changed)
	update_value_label()


func _on_slider_changed(new_value):
	update_value_label()
	
	for score in GameSystem.current_game_mode.game_scores.values():
		if score.name.begins_with("Profit"):
			for contributor in score.contributors:
				if contributor.attribute_name.begins_with("Stromerzeugung"):
					contributor.weight = new_value
			
			score.recalculate_score()


func update_value_label():
	$Value.text = "(" + "%1.2f" % $HSlider.value + ")"
