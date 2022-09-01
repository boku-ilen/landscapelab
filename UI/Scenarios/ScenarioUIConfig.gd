extends Configurator


var scenario_widget = preload("res://UI/Scenarios/ScenarioWidget.tscn")

onready var widget_root = get_node("../ScrollContainer/Scenarios")


func _ready():
	for scenario in Scenarios.scenarios:
		_on_new_scenario(scenario)
	
	Scenarios.connect("new_scenario", self, "_on_new_scenario")


func _on_new_scenario(scenario):
	var widget = scenario_widget.instance()
	widget.scenario = scenario
	
	widget_root.add_child(widget)
	widget.connect("focus_entered", self, "set_selected_widget", [widget])


func set_selected_widget(widget: Control):
	for child in widget_root.get_children():
		child.selected = false
	widget.selected = true
