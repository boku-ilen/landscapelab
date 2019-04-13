extends Node

var id : int
var scenario

var scenario_url = "/location/scenario/list.json"
var session_url = "/location/start_session/%s"  # Fill with scenario ID
var scenarios


func _ready():
	load_scenarios()


# Loads all available scenarios from the server into the 'scenarios' variable 
func load_scenarios():
	var scenario_result = ServerConnection.get_json(scenario_url)

	if not scenario_result or scenario_result.has("Error"):
		ErrorPrompt.show("Cannot load areas")
		return false
	
	scenarios = scenario_result
	
	
# Returns all available (previously loaded) scenarios
func get_scenarios():
	return scenarios
	
	
func get_scenario(scenario_id):
	return scenarios[scenario_id]
	
	
func load_scenario(scenario_id):
	_start_session(scenario_id)

	# TODO: Replace with real coordinates
	var world_offset_x = -1765982
	var world_offset_z = 6159002
	
	Offset.set_offset(world_offset_x, world_offset_z)


func _start_session(scenario_id):
	var session = ServerConnection.get_json(session_url % [scenario_id])
	
	if not session or session.has("Error"):
		ErrorPrompt.show("Cannot start session")
		
	id = session.session