extends Node


var scenarios = []

signal new_scenario(scenario)


func add_scenario(scenario: Scenario):
	scenarios.append(scenario)
	emit_signal("new_scenario", scenario)
