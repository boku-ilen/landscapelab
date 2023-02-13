extends "res://UI/GameSystem/AbstractScoreUI.gd"


var score: GameScore :
	get:
		return score
	set(new_score):
		super.set_score(new_score)
		score = new_score
		
		$VBox/HBox/Name.text = score.name
		$VBox/HBox2/TextureDescriptor.texture = load(
			"res://Resources/Icons".path_join(icon_folder).path_join(score.icon_descriptor) + ".svg")
		$VBox/HBox2/TextureSubject.texture = load(
			"res://Resources/Icons".path_join(icon_folder).path_join(score.icon_subject) + ".svg")
		_update_data(score.value)
		score.connect("value_changed",Callable(self,"_update_data"))

var icon_folder = Settings.get_setting("gui", "icon-folder", "ModernLandscapeLab")


func _update_data(value):
	$VBox/HBox2/Value.text = str(round(score.value))
