extends PanelContainer

#
# This scene is handling the update of the energy values using a regular server request.
#

onready var requester = get_node("RegularServerRequest")
onready var progress_bar = get_node("Control/ProgressBar")
# Load the labels so we can update them regularly with the requested energy contributions
onready var energy_value = get_node("Energy/EnergySum/EnergyValue")
onready var target_energy = get_node("Energy/EnergySum/TargetEnergy")
onready var assets_amount = get_node("Energy/Amount/AssetsAmount")


func _ready():
	# Make the the interval for the assets request in intervals of 2 seconds
	requester.interval = 2 
	requester.set_request("/energy/contribution/" + String(Session.scenario_id) + "/all.json")
	requester.connect("new_response", self, "_on_new_response", [], CONNECT_DEFERRED)
	
	progress_bar.max_value = Session.get_current_scenario()["energy_requirement_total"]
	
	# Change the value for the target_energy according to the current scenario
	target_energy.text = String(Session.get_current_scenario()["energy_requirement_total"])


func _on_new_response(response):
	var asset_details = response
	
	progress_bar.value = float(asset_details["total_energy_contribution"])
	
	if not asset_details == null:
		energy_value.text = String(int(round(asset_details["total_energy_contribution"])))
		assets_amount.text = String(asset_details["number_of_assets"])