extends Node

var id : int
var scenario

var scenario_url = "/location/scenario/list.json"
var session_url = "/location/start_session/%s"  # Fill with scenario ID
var scenarios


func _ready():
	load_scenarios()


func load_scenarios():
	"""Loads all available scenarios from the server into the 'scenarios' variable."""
	var scenario_result = ServerConnection.get_json(scenario_url)

	if not scenario_result or scenario_result.has("Error"):
		ErrorPrompt.show("Could not fetch scenarios from server")
		return false
	
	scenarios = scenario_result
	
	
func get_scenarios():
	"""Returns all available (previously loaded) scenarios"""
	return scenarios
	

func get_scenario(scenario_id):
	"""Returns a specific scenario by its ID
	Fields: name, locations, bounding_polygon"""
	return scenarios[scenario_id]


func load_scenario(scenario_id):
	"""Starts a new session for the scenario with the given ID.
	Sets the world offset to the starting position in that scenario."""
	
	_start_session(scenario_id)

	var scen = get_scenario(scenario_id)
	
	# Get starting location (usually first element in dictionary)
	var start_loc
	for loc in scen.locations:
		if scen.locations[loc].starting_location == true:
			start_loc = scen.locations[loc].location
			break

	# if we found a starting location set the offset accordingly
	if start_loc:
		var world_offset_x = -start_loc[0]
		var world_offset_z = start_loc[1]
		
		Offset.set_offset(world_offset_x, world_offset_z)
	else:
		logger.error("Could not initialize starting location")
		# FIXME: what to do? is it possible to start at a random or calculated starting location based on the bounding polygon geometry


func _start_session(scenario_id):
	var session = ServerConnection.get_json(session_url % [scenario_id])
	
	if not session or session.has("Error"):
		ErrorPrompt.show("Cannot start session")
		
	id = session.session