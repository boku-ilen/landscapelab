extends VBoxContainer

#
# This script loads asset_types and their according energy into the gui
#

var assets
var assets_list
# The dictionaries hold the the values for a type so they can be changed easily with an update
var type_energy_dict : Dictionary
var type_target_energy_dict : Dictionary
var type_amount_dict : Dictionary
var type_requester_dict : Dictionary

onready var requester = preload("res://Util/RegularServerRequest.tscn")


func _ready():
	# Load all possible assets from the server 
	# Url: assetpos/get_all_editable_assettypes.json
	assets = Assets.get_asset_types_with_assets()
	_setup()
	
	_create_regular_requests()


func _create_regular_requests():
	for asset_type in assets:
		var asset_type_name = assets[asset_type]["name"]
		var asset_type_requester = requester.instance()
		add_child(asset_type_requester)
		
		asset_type_requester.set_request("/energy/contribution/" + String(Session.scenario_id) + "/" + asset_type + ".json")
		asset_type_requester.connect("new_response", self, "_update_values")
		# Make the the interval for the assets request in intervals of 2 seconds
		asset_type_requester.interval = 2 
		
		# Save the specific regular requester in a dict to easily access is later
		type_requester_dict[asset_type_name] = asset_type_requester


func _update_values(response):
	var res = response 
	for asset_type in assets:
		var asset_type_name = assets[asset_type]["name"]
		type_energy_dict[asset_type_name].text = "Current energy value: " + type_requester_dict[asset_type_name].get_latest_response()["total_energy_contribution"] + " MW / " + String(type_target_energy_dict[asset_type_name]) + " MW" 
		type_amount_dict[asset_type_name].text = "Placed amount: " + type_requester_dict[asset_type_name].get_latest_response()["number_of_assets"]


func _setup():
	for asset_type in assets:
		assets_list = load("res://UI/EnergyUI/AssetsList.tscn").instance()
		
		var asset_type_label = assets_list.get_node("AssetType")
		var asset_type_image = assets_list.get_node("Image")
		var asset_type_details = assets_list.get_node("Details")
		
		var asset_type_name = assets[asset_type]["name"]
		
		# Store the target energy value for the type in a dictionary
		type_target_energy_dict[asset_type_name] = assets[asset_type]["energy_target"]
		
		#if asset_type_name == "Wind Turbine":
		#	asset_type_image.texture = load("res://Resources/Images/UI/MapIcons/windmill_icon.png")
			
		asset_type_label.text = asset_type_name + "s"
		
		_setup_type_details(asset_type_details, asset_type_name)
		
		add_child(assets_list)


func _setup_type_details(asset_type_details, asset_type_name):
	# Set the values for the details in an own label so they can be manipulated easily later
	var asset_type_amount = Label.new()
	var asset_type_energy = Label.new()
	
	# Set the value into the dictionary so they can easily be accessed later and updated
	type_amount_dict[asset_type_name] = asset_type_amount
	type_energy_dict[asset_type_name] = asset_type_energy
	
	asset_type_details.add_child(asset_type_amount)
	asset_type_details.add_child(asset_type_energy)