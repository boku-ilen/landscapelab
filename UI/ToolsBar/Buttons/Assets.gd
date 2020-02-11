extends ToolsButton

#
# This module is for creating new assets in the map.
# These assets are loaded from the server.
# TODO: An area on where they can be put should be shown.
#


var assets_json
# the provided space to load the ui-elements (lists) into
onready var label = get_node("List/Label")
onready var items = get_node("List/ItemList")

# to set the id of the item in the item spawner
var item_id = null


# change the toggle based on the UI signals
func _ready():
	connect("toggled", self, "_on_toggled")
	GlobalSignal.connect("sync_moving_assets", self, "_setpressedfalse")
	GlobalSignal.connect("stop_sync_moving_assets", self, "_setpressedfalse")
	GlobalSignal.connect("changed_item_to_spawn", self, "set_asset_id")
	_load_assets()


# if the status is changed to pressed emit the controller signal
func _on_toggled(button_pressed):
	if is_pressed():
		GlobalSignal.emit_signal("input_controller")


func _load_assets():
	# Load all possible assets from the server 
	# Url: assetpos/get_all_editable_assettypes.json
	assets_json = Assets.get_asset_types_with_assets()
	
	label.text = tr("ASSETS")
	
	var index = 0
	for asset_type_id in assets_json:
		var assets = assets_json[asset_type_id]["assets"]
		
		for asset_id in assets:
			var icon: Texture
			if asset_type_id == "2":
				icon = load("res://Resources/Images/UI/MapIcons/windmill_icon.png")
			elif asset_type_id == "3":
				icon = load("res://Resources/Images/UI/MapIcons/pv_icon.png")
			
			items.add_item(assets[asset_id]["name"], icon)
			
			# The ID in the list is not necessarily the same as the id in the json-file thus we have to
			# set the asset id in the metadata
			items.set_item_metadata(index, asset_id)
			
			index += 1 


func set_asset_id(id):
	item_id = items.get_item_metadata(id)
	# fires a signal which is caught in the itemSpawner
	GlobalSignal.emit_signal("changed_asset_id", int(item_id))
