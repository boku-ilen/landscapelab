extends Node

var id : int
var scenario

var scenario_url = "/location/areas/"

# Returns all scenarios available on the server
func get_scenarios():
	var scenarios = ServerConnection.get_json(scenario_url)

	if scenarios.has("Error"):
		ErrorPrompt.show("Cannot load areas", scenarios["Error"])
		return false
	
	return scenarios["Areas"]

# Set the scenario variable to the scenario corresponding to the passed area
func load_scenario(area):
	logger.info("loading area %s" % area)
	
	var scen = ServerConnection.get_json("/location/areas/?filename=%s" % area)
	
	if scen.has("Error"):
		ErrorPrompt.show("could not load %s" % area, scen["Error"])
		return false
		
	set_scenario(scen)

func set_scenario(sc):
	scenario = sc
	
func get_scenario():
	return scenario