extends "res://UI/GameSystem/AbstractScoreUI.gd"


var score: GameScore setget set_score

var icon_folder = Settings.get_setting("gui", "icon_folder", "ModernLandscapeLab")


func set_score(new_score):
	.set_score(new_score)
	score = new_score
	
	$VBox/HBox/Name.text = score.name
	$TextureDescriptor.texture = load(
		"res://Resources/Icons".plus_file(icon_folder).plus_file(score.icon_descriptor) + ".svg")
	$TextureSubject.texture = load(
		"res://Resources/Icons".plus_file(icon_folder).plus_file(score.icon_subject) + ".svg")
	_update_data(score.value)
	score.connect("value_changed", self, "_update_data")


func _update_data(value):
	$VBox/Value.text = str(round(score.value))
