extends HBoxContainer
class_name DrawLayerDropdownEntry

func _init(label, callback) -> void:
	var select_button = TableButton.new()
	select_button.icon = preload("res://Resources/Icons/LabTable/score_circle.svg")
	select_button.theme_type_variation = "FlatButton"
	select_button.pressed.connect(callback)
	add_child(select_button)
	
	var name_label = Label.new()
	name_label.text = label
	add_child(name_label)
