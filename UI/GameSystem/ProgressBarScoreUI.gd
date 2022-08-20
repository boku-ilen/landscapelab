extends HBoxContainer


var score: GameScore setget set_score


func set_score(new_score):
	score = new_score
	
	$Name.text = score.name
	$MaxValue.text = str(score.target)
	$ProgressBar.min_value = 0.0
	$ProgressBar.max_value = score.target
	
	if score.contributors[0].color_code:
		# Get current stylebox of the progress, duplicate so it only affects this node
		# and only override the background color so it fits the rest of the theme
		var new_stylebox = $ProgressBar.get_stylebox("fg").duplicate()
		# For many themes, a texture could be used which does not have a color
		# in no styleboxflat is used, create one on our own
		if "bg_color" in new_stylebox:
			new_stylebox.bg_color = score.contributors[0].color_code
			$ProgressBar.add_stylebox_override("fg", new_stylebox)
		else: 
			new_stylebox = StyleBoxFlat.new()
			new_stylebox.bg_color = score.contributors[0].color_code
			$ProgressBar.add_stylebox_override("fg", new_stylebox)
	
	_update_data(score.value)
	score.connect("value_changed", self, "_update_data")


func _update_data(new_value):
	$CurrentValue.text = str(new_value)
	$ProgressBar.value = new_value
