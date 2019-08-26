extends VBoxContainer

var assets
var assets_list
var instanced_assets
var type_energy_dict : Dictionary
var type_amount_dict : Dictionary


func _ready():
	_setup()
	_update()


func _update():
	for asset_type in assets:
		var asset_type_name = assets[asset_type]["name"]
		var asset_type_details = ServerConnection.get_json("/assetpos/energy_contribution/" + asset_type + ".json")
		
		var asset_type_energy = asset_type_details["total_energy_contribution"]
		var asset_type_amount = asset_type_details["number_of_assets"]
		
		type_energy_dict[asset_type_name].text = String(asset_type_energy)
		type_amount_dict[asset_type_name].text = String(asset_type_amount)


func _setup():	
	# Load all possible assets from the server
	assets = Assets.get_asset_types_with_assets()
	
	for asset_type in assets:
		assets_list = load("res://UI/EnergyUI/AssetsList.tscn").instance()
		
		var asset_type_label = assets_list.get_node("AssetType")
		var asset_type_image = assets_list.get_node("Image")
		var asset_type_details = assets_list.get_node("Details")
		
		var asset_type_name = assets[asset_type]["name"]
		
		#if asset_type_name == "Wind Turbine":
		#	asset_type_image.texture = load("res://Resources/Images/UI/MapIcons/windmill_icon.png")
			
		asset_type_label.text = asset_type_name + "s"
		
		_setup_type_details(asset_type_details, asset_type_name)
		
		self.add_child(assets_list)


func _setup_type_details(asset_type_details, asset_type_name):
	# Set the values for the details in an own label so they can be manipulated easily later
	var amount_container = HBoxContainer.new()
	var energy_container = HBoxContainer.new()
	var asset_type_amount = Label.new()
	var asset_type_amount_label = Label.new()
	var asset_type_energy = Label.new()
	var asset_type_energy_label = Label.new()
	
	asset_type_amount_label.text = "Placed amount: "
	asset_type_energy_label.text = "Current energy value: "
	# These values will get changed with _update() function
	asset_type_amount.text = "0"
	asset_type_energy.text = "0"
	
	# Set the value into the dictionary so they can easily be accessed later and updated
	type_amount_dict[asset_type_name] = asset_type_amount
	type_energy_dict[asset_type_name] = asset_type_energy
	
	amount_container.add_child(asset_type_amount_label)
	amount_container.add_child(asset_type_amount)
	energy_container.add_child(asset_type_energy_label)
	energy_container.add_child(asset_type_energy)
	
	asset_type_details.add_child(amount_container)
	asset_type_details.add_child(energy_container)