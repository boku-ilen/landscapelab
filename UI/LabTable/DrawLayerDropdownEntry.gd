extends PanelContainer
class_name DrawLayerDropdownEntry

func _init(label, callback) -> void:
	theme = preload("res://UI/Theme/LightThemeTable.tres")
	theme_type_variation = "MenuPanel"
	var own_horizontal_container = HBoxContainer.new()
	add_child(own_horizontal_container)
	var select_button = TableButton.new()
	select_button.icon = preload("res://Resources/Icons/LabTable/score_circle.svg")
	select_button.theme_type_variation = "FlatButton"
	select_button.pressed.connect(callback)
	own_horizontal_container.add_child(select_button)
	
	var name_label = Label.new()
	name_label.text = label
	own_horizontal_container.add_child(name_label)
