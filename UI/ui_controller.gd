extends TextureButton

#
# This module is for creating new assets in the map.
# These assets are loaded from the server.
# TODO: An area on where they can be put should be shown.
#

var assets
var dict
# has a different set of asset_type_elements which include the title of the assettypes (e.g. wind turbines, pv plants)
var asset_type_list
# includes an ItemList-node in which all the subtypes are stored (e.g. vestas wind  turbine)
var asset_type_element


# change the toggle based on the UI signals
func _ready():
	
	asset_type_list = get_child(0)
	
	# initialize the input scene invisible
	for child in get_children():
		child.visible = false	
	
	GlobalSignal.connect("input_lego", self, "_setpressedfalse")
	GlobalSignal.connect("input_disabled", self, "_setpressedfalse")
	load_assets()


# if the status is changed to pressed emit the controller signal
func _toggled(button_pressed) -> void:
	if self.is_pressed():
		GlobalSignal.emit_signal("input_controller")
		for child in get_children():
			child.visible = true
	else:
		GlobalSignal.emit_signal("input_disabled")


# if we set the pressed status to false also hide the editing menu
func _setpressedfalse():

	self.set_pressed(false)
	
	for child in get_children():
		child.visible = false

# load the assets and create the ui element
func load_assets():
	assets = ServerConnection.get_json("/assetpos/get_all_editable_assettypes.json")
	
	for asset_type in assets:
		# create new list element instance
		asset_type_element = load("res://UI/EditableAssets/ListElement.tscn").instance()
		
		# set the title of the current chosen type of asset
		var asset_type_name = assets[asset_type]["name"]
		var asset_type_node = asset_type_element.get_child(0)
		asset_type_node.text = asset_type_name
		asset_type_element.add_child(asset_type_node)
		
		asset_type_list.add_spacer(false)
		
		var subtyp_item_list = asset_type_element.get_child(1)
		
		# create a ItemList entry for every specific asset of the type
		# TODO: rename the icons or json file so we can load the images nicely
		for specific_asset in assets[asset_type]["assets"]:
			var texture
			var text
			if assets[asset_type]["name"] == "wind turbine":
				texture = load("res://Resources/Images/UI/MapIcons/windmill_icon.png")
			else:
				texture = load("res://Resources/Images/UI/MapIcons/pv_icon_dummy.png")
			
			text = assets[asset_type]["assets"][specific_asset]["name"]
			subtyp_item_list.add_item(text, texture)
			
		asset_type_list.add_child(asset_type_element)