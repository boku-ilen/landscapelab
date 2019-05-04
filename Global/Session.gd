extends Node

var session_id : int
var scenario_id : int

var scenario_url = "/location/scenario/list.json"
var session_url = "/location/start_session/%s"  # Fill with scenario ID
var scenarios


func _ready():
	load_scenarios()


func load_scenarios():
	"""Loads all available scenarios from the server into the 'scenarios' variable."""
	var scenario_result = ServerConnection.get_json(scenario_url)

	if not scenario_result or scenario_result.has("Error"):
		logger.error("Could not load the scenarios from the server")
		ErrorPrompt.show("ERROR", "Could not fetch scenarios from server - is the server up and connected?")
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
	"""Sets the world offset to the starting position in that scenario."""
	
	# store the current active scenario
	var scen = get_scenario(scenario_id)
	self.scenario_id = scenario_id
	
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


# we want to get a new session id from the server thus ending the old session
func start_session(scenario_id):
	
	# try to get a new session id for this scenario
	var session = ServerConnection.get_json(session_url % [scenario_id])
	
	if not session or session.has("Error"):
		logger.warning("Could not fetch a new session id from %s" % session_url)
		ErrorPrompt.show("WARNING", "Could not start a new session")
		
	# sets the new session id
	self.session_id = session.session  
