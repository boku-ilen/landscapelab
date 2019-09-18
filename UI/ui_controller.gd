extends TextureButton

#
# This module is for creating new assets in the map.
# These assets are loaded from the server.
# TODO: An area on where they can be put should be shown.
#

var assets_json
# the provided space to load the ui-elements (lists) into
onready var list_container = get_node("EditableAssetTypeList")
var assets_list_view = load("res://UI/EditableAssets/AssetTypeList.tscn").instance()
# to differentiate between pv/windmill, etc
var item_type_name
# to set the id of the item in the item spawner
var item_id = null


# change the toggle based on the UI signals
func _ready():
	
	# initialize the input scene invisible
	for child in get_children():
		child.visible = false
	
	GlobalSignal.connect("sync_moving_assets", self, "_setpressedfalse")
	GlobalSignal.connect("stop_sync_moving_assets", self, "_setpressedfalse")
	GlobalSignal.connect("changed_item_to_spawn", self, "set_item_id")
	_load_assets()


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


func _load_assets():
	# Load all possible assets from the server 
	# Url: assetpos/get_all_editable_assettypes.json
	assets_json = Assets.get_asset_types_with_assets()
	
	var index = 0
	for asset_type_id in assets_json:
		
		assets_list_view.get_node("AssetType").text = "Assets:"
		
		var list = assets_list_view.get_node("ItemList")
		var assets = assets_json[asset_type_id]["assets"]
		
		for asset_id in assets:
			var icon : Texture
			if asset_type_id == "2":
				icon = load("res://Resources/Images/UI/MapIcons/windmill_icon.png")
			elif asset_type_id == "3":
				icon = load("res://Resources/Images/UI/MapIcons/pv_icon.png")
			
			list.add_item(assets[asset_id]["name"], icon)
			
			# The ID in the list is not necessarily the same as the id in the json-file thus we have to
			# set the asset id in the metadata
			list.set_item_metadata(index, asset_id)
			
			index += 1 
		
	list_container.add_child(assets_list_view)


func set_item_id(id):
	item_id = assets_list_view.get_node("ItemList").get_item_metadata(id)
	# fires a signal which is caught in the itemSpawner
	GlobalSignal.emit_signal("changed_asset_id", int(item_id))