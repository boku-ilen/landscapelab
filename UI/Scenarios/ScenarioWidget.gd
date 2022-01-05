extends VBoxContainer


var scenario: Scenario setget set_scenario


func _ready():
	connect("gui_input", self, "_on_clicked")


func _on_clicked(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			scenario.activate()


func set_scenario(new_scenario):
	scenario = new_scenario
	$HBoxContainer/Label.text = scenario.name
