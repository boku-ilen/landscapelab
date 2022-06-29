extends HBoxContainer


var score: GameScore setget set_score


func set_score(new_score):
	score = new_score
	
	$Name.text = score.name
	$MaxValue.text = str(score.target)
	$ProgressBar.min_value = 0.0
	$ProgressBar.max_value = score.target
	
	_update_data()
	score.connect("value_changed", self, "_update_data")


func _update_data():
	$CurrentValue.text = str(score.value)
	$ProgressBar.value = score.value
