extends PanelContainer
class_name DrawLayerDropdownEntry

func _init(label, callback) -> void:
	add_theme_stylebox_override("panel", preload("res://UI/LabTable/Style/PopupPanel.tres"))
	var own_horizontal_container = HBoxContainer.new()
	own_horizontal_container.add_theme_constant_override("separation", 8)
	add_child(own_horizontal_container)
	var select_button = TableButton.new()
	select_button.icon = preload("res://Resources/Icons/LabTable/circle_lid_select.svg")
	select_button.theme_type_variation = "FlatButton"
	select_button.pressed.connect(callback)
	own_horizontal_container.add_child(select_button)
	
	var name_label = Label.new()
	name_label.text = label
	own_horizontal_container.add_child(name_label)
