extends VBoxContainer

var assets
var assets_list
var instanced_assets


func _ready():
	_setup()
	_update()


func _update():
	instanced_assets = Assets.get_assets()
	print(instanced_assets)


func _setup():	
	# Load all possible assets from the server
	assets = Assets.get_asset_types_with_assets()
	
	for asset_type in assets:
		assets_list = load("res://UI/EnergyUI/AssetsList.tscn").instance()
		
		var asset_type_label = assets_list.get_node("AssetType")
		var asset_type_image = assets_list.get_node("Image")
		var assets_container = assets_list.get_node("AssetsContainer")
		
		var asset_type_name = assets[asset_type]["name"]
		
		#if asset_type_name == "Wind Turbine":
		#	asset_type_image.texture = load("res://Resources/Images/UI/MapIcons/windmill_icon.png")
			
		asset_type_label.text = asset_type_name + "s"
		
		_setup_specific_assets(assets_container, assets[asset_type]["assets"])
		
		self.add_child(assets_list)


func _setup_specific_assets(assets_container, specific_assets):
	for asset in specific_assets:
		var container = HBoxContainer.new()
		var asset_name = Label.new()
		var asset_amount = Label.new()
		var asset_energy = Label.new()
		
		asset_name.text = specific_assets[asset]["name"]
		asset_amount.text = "0"
		asset_energy.text = "0"
		
		container.add_child(asset_name)
		container.add_child(asset_amount)
		
		assets_container.add_child(container)
		assets_container.add_child(asset_energy)