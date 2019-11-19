extends VBoxContainer

#
# This script loads asset_types and their according energy into the gui.
# Via the RegulareServerRequest the values are updated periodically
#


var assets_list

# The dictionaries hold the the values for a type so they can be changed easily with an update
var type_energy_dict : Dictionary
var type_energy_target_dict : Dictionary
var type_amount_dict : Dictionary
var type_requester_dict : Dictionary
var type_progress_bar_dict : Dictionary

# Stores the most recent values for each type returned by the RegularServerRequester
var requested_target_energy_dict : Dictionary

# Uninstanced requester scene
onready var requester = preload("res://Util/RegularServerRequest.tscn")
# Load all possible assets from the server 
# Url: assetpos/get_all_editable_assettypes.json
onready var assets = Assets.get_asset_types_with_assets()

func _ready():
	# Init the dictionaries size for thread-safety
	_init_dict()
	_setup()
	
	_create_regular_requests()


# For each asset create a new regular request for getting the current contribution
func _create_regular_requests():
	for asset_type in assets:
		var asset_type_name = assets[asset_type]["name"]
		var asset_type_requester = requester.instance()
		add_child(asset_type_requester)
		
		asset_type_requester.set_request("/energy/contribution/%s/%s.json" % [String(Session.scenario_id), asset_type])
		asset_type_requester.connect("new_response", self, "_update_values", [asset_type_name], CONNECT_DEFERRED)
		# Make the the interval for the assets request in intervals of 2 seconds
		asset_type_requester.interval = 2
		asset_type_requester.start()
		
		# Save the specific regular requester in a dict to easily access is later
		type_requester_dict[asset_type_name] = asset_type_requester


# This gets called every time a new response comes from one of the requesters
func _update_values(response, asset_type_name):
	if not response:
		logger.warning("Invalid server response for %s" % [asset_type_name])
		return
	
	# TODO: Add translation file's value
	var energy_level = String(int(round(response["total_energy_contribution"])))
	var energy_target = String(requested_target_energy_dict[asset_type_name])
	var placed_amount = String(response["number_of_assets"])
	
	type_energy_dict[asset_type_name].text = energy_level
	type_energy_target_dict[asset_type_name].text = energy_target
	type_amount_dict[asset_type_name].text = placed_amount
	
	type_progress_bar_dict[asset_type_name].max_value = float(requested_target_energy_dict[asset_type_name])
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
	var response = ServerConnection.get_json("/energy/target/%s/%s.json" % [String(Session.scenario_id), asset_information[1]])
	requested_target_energy_dict[asset_information[0]] = response["energy_target"]


func _init_dict():
	for asset_type_id in assets:
		var asset_type_name = assets[asset_type_id]["name"]
		requested_target_energy_dict[asset_type_name] = "loading ..."


func _setup_type_details(asset_type_details, asset_type_name):
	# Set the values for the details in an own label so they can be manipulated easily later
	var asset_type_amount = assets_list.get_node("Details/AmountHBox/TypeAmount")
	var asset_type_energy = assets_list.get_node("Details/ValueHBox/TypeValue")
	var asset_type_target_energy = assets_list.get_node("Details/ValueHBox/TargetValue")
	
	# Set the value into the dictionary so they can easily be accessed later and updated
	type_amount_dict[asset_type_name] = asset_type_amount
	type_energy_dict[asset_type_name] = asset_type_energy
	type_energy_target_dict[asset_type_name] = asset_type_target_energy
