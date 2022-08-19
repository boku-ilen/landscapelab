extends HBoxContainer


var score: GameScore setget set_score

var icon_folder = Settings.get_setting("gui", "icon_folder", "ModernLandscapeLab")


func set_score(new_score):
	score = new_score
	
	$VBox/HBox/Name.text = score.name
	$TextureRect.texture = load(
		"res://Resources/Icons".plus_file(icon_folder).plus_file(score.icon_name) + ".svg")
	_update_data(score.value)
	score.connect("value_changed", self, "_update_data")


func _update_data(value):
	$VBox/Value.text = str(score.value)
