extends Node

#
# Provides access to the server's scenario data, as well as starting sessions
# for a given scenario.
#

var session_id : int = -1  # start with an invalid session_id
var scenario_id : int

var scenarios: Array = []
var current_scenario


func _ready():
	_load_scenarios()


# Loads all available scenarios into the 'scenarios' variable.
func _load_scenarios():
	var raw_scenarios = GeodataPaths.get_raw("scenarios")
	
	for raw_scenario in raw_scenarios:
		scenarios.append(get_scenario_from_geodata(raw_scenario))

	if scenarios.size() == 0:
		logger.error("Could not get any valid scenarios")
		ErrorPrompt.show("ERROR", "Could not get any valid scenarios! Check the geodata.json and the referenced data")
		return false


# Returns all available (previously loaded) scenarios
func get_scenarios():
	return scenarios


# Returns a specific scenario by its ID
# Fields: name, locations, bounding_polygon, energy_requirement_total,
#  energy_requirement_summer, energy_requirement_winter, default_wind_direction
func get_scenario(scenario_id):
	# Since this is a string-indiced dictionary, make sure to convert the id to a string
	return scenarios[scenario_id]


# Returns the current scenario or null if it's not set
func get_current_scenario():
	return current_scenario


# Sets the world offset to the starting position in that scenario.
func set_start_offset_for_scenario(scen):
	current_scenario = scen
	
	# Get starting location
	var start_loc = scen.locations.front().get_vector3()

	var world_offset_x = -start_loc.x
	var world_offset_z = -start_loc.z
	
	Offset.set_offset(world_offset_x, world_offset_z)


# we want to get a new session id from the server thus ending the old session
func start_session(scenario_id):
	# TODO: a session is only required for recording so the session should now be handled
	# TODO: by the client alone. If we really plan a multi'player' option we may need to
	# TODO: make sure uniqueness by using the connection_id or something like that
	self.session_id = 7020 # FIXME: Increment somehow - maybe save last used session_id


func get_scenario_from_geodata(raw_scenario):
	var scenario = Scenario.new()

	scenario.name = raw_scenario.name
	
	var location = raw_scenario.locations
	var path = GeodataPaths.get_base().plus_file(location.name) + "." + location.type
	
	# TODO: We need all points and this is a bit of a hacky way to get them - should
	#  probably be added to Geodot
	scenario.locations = Geodot.get_points_near_position(path, 0, 0, 10000000000, 100)
	
	return scenario


class Scenario:
	var name
	var locations
