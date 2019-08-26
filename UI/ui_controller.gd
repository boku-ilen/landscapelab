extends TextureButton

#
# This module is for creating new assets in the map.
# These assets are loaded from the server.
# TODO: An area on where they can be put should be shown.
#

var assets
# the provided space to load the ui-elements (lists) into
var list_container
# includes a heading and an ItemList-node in which the types are stored (e.g. wind turbines, photovoltaic)
var asset_types_list_view = load("res://UI/EditableAssets/AssetTypeList.tscn").instance()
# stores the assets for a given type
var assets_list_view
# to differentiate between pv/windmill, etc
var item_type_name
# to set the id of the item in the item spawner
var item_id = null


# change the toggle based on the UI signals
func _ready():
	
	list_container = get_child(0)
	
	# initialize the input scene invisible
	for child in get_children():
		child.visible = false	
	
	GlobalSignal.connect("sync_moving_assets", self, "_setpressedfalse")
	GlobalSignal.connect("stop_sync_moving_assets", self, "_setpressedfalse")
	GlobalSignal.connect("changed_item_to_spawn", self, "set_item_id")
	GlobalSignal.connect("selected_asset_type", self, "load_assets_for_type")
	load_asset_types()


# if the status is changed to pressed emit the controller signal
func _toggled(button_pressed) -> void:
	if self.is_pressed():
		GlobalSignal.emit_signal("input_controller")
		for child in get_children():
			child.visible = true
	else:
		_setpressedfalse()


# if we set the pressed status to false also hide the editing menu
func _setpressedfalse():

	set_pressed(false)
	
	for child in get_children():
		child.visible = false


# load the assets and create the ui element
func load_asset_types():
	assets = Assets.get_asset_types_with_assets()
		
	# needed to write metadata into given index
	var index = 0
	
	for asset_type in assets:
		var heading = asset_types_list_view.get_child(0)
		var type_list = asset_types_list_view.get_child(1)
		heading.text = "Types:"

		# get asset type name and according texture to add to list
		var asset_type_name = assets[asset_type]["name"]
		var texture
		
		# TODO: rename the icons or json file so we can load the images nicely
		if asset_type_name == "Wind Turbine":
			texture = load("res://Resources/Images/UI/MapIcons/windmill_icon.png")
			
		type_list.add_item(asset_type_name, texture)
		# we will need this for the next layer of the list, to properly load the specific assets out of the json
		type_list.set_item_metadata(index, asset_type)
		index += 1
		
	list_container.add_child(asset_types_list_view)


func set_item_id(id):
	# id 0 is the back button, we once again load the types
	if id == 0:
		# removes the items list
		clear_list_container()
		list_container.add_child(asset_types_list_view)
	else:
		item_id = assets_list_view.get_child(1).get_item_metadata(id)
		# fires a signal which is caught in the itemSpawner
		GlobalSignal.emit_signal("changed_asset_id", int(item_id))


func load_assets_for_type(id):
	assets_list_view = load("res://UI/EditableAssets/AssetItemList.tscn").instance()
	
	# removes the types list
	clear_list_container()
	
	# get the metadata for the entry to get according data from json
	var asset_type_json_tag = asset_types_list_view.get_child(1).get_item_metadata(id)
	var asset_type_name = asset_types_list_view.get_child(1).get_item_text(id)
	
	var heading = assets_list_view.get_child(0)
	var asset_list = assets_list_view.get_child(1)
	heading.text = asset_type_name
	
	# add a back button with id 0
	asset_list.add_item("back")
	
	var index = 1
	# create an ItemList entry for every specific asset of the type
	for specific_asset in assets[asset_type_json_tag]["assets"]:
		var text = assets[asset_type_json_tag]["assets"][specific_asset]["name"]
		asset_list.add_item(text)
		# The ID in the list is not necessarily the same as the id in the json-file thus we have to
		# set the asset id in the metadata
		asset_list.set_item_metadata(index, specific_asset)
		
		index += 1
	
	list_container.add_child(assets_list_view)


func clear_list_container():
	for list in list_container.get_children():
		list_container.remove_child(list)