extends "res://UI/GameSystem/AbstractScoreUI.gd"


var current_progress_bar

var score: GameScore :
	get:
		return score 
	set(new_score):
		super.set_score(new_score)
		score = new_score
		
		if score.target > 0:
			current_progress_bar = $ProgressBar
			$ProgressFromCenter.visible = false
			
			$VBoxContainer/Name.text = score.name
			$VBoxContainer/MaxValue.text = str(score.target)
			$VBoxContainer/Unit.text = score.unit
			$ProgressBar.min_value = 0.0
			$ProgressBar.max_value = score.target
			
			if score.contributors[0].color_code:
				# TODO: Godot 4.0 implements a vertical ProgressBar
				if $ProgressBar is ProgressBar:
					# Get current stylebox of the progress, duplicate so it only affects this node
					# and only override the background color so it fits the rest of the theme
					var new_stylebox = $ProgressBar.get_stylebox("fg").duplicate()
					# For many themes, a texture could be used which does not have a color
					# in no styleboxflat is used, create one checked our own
					if "bg_color" in new_stylebox:
						new_stylebox.bg_color = score.contributors[0].color_code
						$ProgressBar.add_theme_stylebox_override("fg", new_stylebox)
					else: 
						new_stylebox = StyleBoxFlat.new()
						new_stylebox.bg_color = score.contributors[0].color_code
						$ProgressBar.add_theme_stylebox_override("fg", new_stylebox)
				elif $ProgressBar is TextureProgressBar:
					$ProgressBar.tint_progress = score.contributors[0].color_code
		else:
			current_progress_bar = $ProgressFromCenter
			$VBoxContainer/Name.text = score.name
			$ProgressBar.visible = false
			$VBoxContainer/ValueSeparator.visible = false
			$VBoxContainer/MaxValue.visible = false
			$VBoxContainer/CurrentValue.visible = false
			$VBoxContainer/Unit.visible = false
	
	
		_update_data(score.value)
		score.value_changed.connect(_update_data)


func _update_data(new_value):
	$VBoxContainer/CurrentValue.text = str(round(new_value))
	current_progress_bar.value = new_value
