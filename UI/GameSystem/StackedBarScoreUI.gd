extends HBoxContainer


var score: GameScore setget set_score
var stacked_bar: StackedProgressBar


func set_score(new_score):
	score = new_score
	
	$Name.text = score.name
	$MaxValue.text = str(score.target)
	
	stacked_bar = load("res://UI/CustomElements/StackedProgressBar.tscn").instance()
	stacked_bar.set_bar_count(score.contributors.size())
	# TODO: think if it will always be 0?
	stacked_bar.min_value = 0
	stacked_bar.max_value = score.target
	add_child(stacked_bar)
	move_child(stacked_bar, 2)
	
	for index in score.contributors.size():
		var contrib: GameScore.GameScoreContributor = score.contributors[index]
		
		if contrib.color_code:
			stacked_bar.set_progress_bar_color_at_index(index, contrib.color_code)
			
		_update_data(score.value)
		score.connect("value_changed", self, "_update_data")


func _update_data(new_value):
	$CurrentValue.text = str(new_value)
	
	for index in stacked_bar.progress_bar_values.size():
		var contrib: GameScore.GameScoreContributor = score.contributors[index]
		stacked_bar.progress_bar_values[index] = score.values_per_contributor[contrib.get_name()]
