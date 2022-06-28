extends HBoxContainer


var score: GameScore setget set_score


func set_score(new_score):
	score = new_score
	
	$Name.text = score.name
	$MaxValue.text = str(score.target)
	$ProgressBar.min_value = 0.0
	$ProgressBar.max_value = score.target
	
	_update_data(score.value)
	score.connect("value_changed", self, "_update_data")


func _update_data(new_value):
	$CurrentValue.text = str(new_value)
	$ProgressBar.value = new_value
