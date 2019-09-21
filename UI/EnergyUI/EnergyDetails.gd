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
var type_progress_bar_dict : Dictionary


onready var requester = preload("res://Util/RegularServerRequest.tscn")


func _ready():
	# Load all possible assets from the server 
	# Url: assetpos/get_all_editable_assettypes.json
	assets = Assets.get_asset_types_with_assets()
	# Init the dictionaries size for thread-safety
	_init_dict()
	
	_setup()
	
	_create_regular_requests()


func _create_regular_requests():
	for asset_type in assets:
		var asset_type_name = assets[asset_type]["name"]
		var asset_type_requester = requester.instance()
		add_child(asset_type_requester)
		
		asset_type_requester.set_request("/energy/contribution/" + String(Session.scenario_id) + "/" + asset_type + ".json")
		asset_type_requester.connect("new_response", self, "_update_values", [asset_type_name], CONNECT_DEFERRED)
		# Make the the interval for the assets request in intervals of 2 seconds
		asset_type_requester.interval = 2
		asset_type_requester.start()
		
		# Save the specific regular requester in a dict to easily access is later
		type_requester_dict[asset_type_name] = asset_type_requester


# This gets called every time a new response comes from one of the requesters
func _update_values(response, asset_type_name):
		# TODO: Add translation file's value
		var energy_level = String(int(round(response["total_energy_contribution"])))
		var energy_target = String(type_target_energy_dict[asset_type_name])
		var placed_amount = String(response["number_of_assets"])
		
		type_energy_dict[asset_type_name].text = "Energieproduktion: " +  energy_level + " MWh/a von " +  energy_target + " MWh/a" 
		type_amount_dict[asset_type_name].text = "Anzahl:  " + placed_amount
		
		type_progress_bar_dict[asset_type_name].max_value = float(type_target_energy_dict[asset_type_name])
		type_progress_bar_dict[asset_type_name].value = float(response["total_energy_contribution"])


func _setup():
	for asset_type in assets:
		assets_list = load("res://UI/EnergyUI/AssetsList.tscn").instance()
		
		var asset_type_label = assets_list.get_node("HBoxContainer/AssetType")
		var asset_type_image = assets_list.get_node("HBoxContainer/Image")
		var asset_type_details = assets_list.get_node("Details")
		var progress_bar = assets_list.get_node("ProgressBar")
		
		var asset_type_name = assets[asset_type]["name"]
		
		# Store the target energy value for the type in a dictionary
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_request_type_target_value", [asset_type_name, asset_type]), 95.0)
		
		var icon : Texture
		if asset_type_name == "Wind Turbine":
			# TODO: rename the icons for easy dynamic loading
			# TODO: use translation file for names
			icon = load("res://Resources/Images/UI/MapIcons/windmill_icon.png")
			asset_type_label.text = "Windräder"
		elif asset_type_name == "Photovoltaic Plant":
			icon = load("res://Resources/Images/UI/MapIcons/pv_icon.png")
			asset_type_label.text = "PV Freiflächenanlagen"
		
		asset_type_image.set_texture(icon)
		
		type_progress_bar_dict[asset_type_name] = progress_bar
		
		_setup_type_details(asset_type_details, asset_type_name)
		
		add_child(assets_list)


# The first object in the array has to be a string of the name of the type, the second one needs to be the id 
func _request_type_target_value(asset_information : Array):
	var response = ServerConnection.get_json("/energy/target/" + String(Session.scenario_id) + "/" + asset_information[1] + ".json")
	type_target_energy_dict[asset_information[0]] = response["energy_target"]


func _init_dict():
	for asset_type_id in assets:
		var asset_type_name = assets[asset_type_id]["name"]
		type_target_energy_dict[asset_type_name] = "loading ..."


func _setup_type_details(asset_type_details, asset_type_name):
	# Set the values for the details in an own label so they can be manipulated easily later
	var asset_type_amount = Label.new()
	var asset_type_energy = Label.new()
	
	# Set the value into the dictionary so they can easily be accessed later and updated
	type_amount_dict[asset_type_name] = asset_type_amount
	type_energy_dict[asset_type_name] = asset_type_energy
	
	asset_type_details.add_child(asset_type_amount)
	asset_type_details.add_child(asset_type_energy)