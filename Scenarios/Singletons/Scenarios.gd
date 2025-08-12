extends Node


var scenarios = []
var was_loaded: bool = false

signal new_scenario(scenario)


func add_scenario(scenario: Scenario):
	scenarios.append(scenario)
	new_scenario.emit(scenario)
