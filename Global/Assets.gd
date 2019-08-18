extends Node


var _types_assets = {}
var _assets = {}

var url = "/assetpos/get_all_editable_assettypes.json"

# The top directory of assets. After this come asset type folders, and afterwards asset scenes.
# Example of a full path with asset type "Wind Turbine" and asset name "Generic Wind Turbine":
#  res://Assets/WindTurbine/GenericWindTurbine.tscn (Spaces are removed, but capitalization is preserved!)
var asset_path_prefix = "res://Assets/"


func _ready():
	# Load information of all assets
	# The response is structured like this:
	# [asset_type_id]
	#   [... asset type fields]
	#   "assets"
	#     [asset_id]
	#       [... asset fields]
	var result = ServerConnection.get_json(url)
	
	if not result:
		logger.error("Couldn't get editable assettypes from the server - this means there will be no dynamic assets!")
		return
	
	_types_assets = result
	
	# For ease of access, we load the individual assets of each type into another dictionary
	for asset_type_id in _types_assets:
		if _types_assets[asset_type_id]["assets"] and _types_assets[asset_type_id]["assets"].size() > 0:
			for asset_id in _types_assets[asset_type_id]["assets"]:
				_assets[asset_id] = _types_assets[asset_type_id]["assets"][asset_id]
				
				# Also save the asset type ID of this asset so we can map them both ways
				_assets[asset_id]["type_id"] = asset_type_id
	
	logger.info("Found %d asset types and a total of %d assets" % [_types_assets.size(), _assets.size()])


# Returns any asset by its ID or null if the asset does not exist.
func get_asset(id):
	id = String(id)
	
	if not _assets.has(id):
		logger.error("Asset with invalid ID %d was requested, returning null. Why was this requested?" % [id])
		return null
	
	return _assets[id]


# Returns any asset type by its ID or null if the asset type does not exist.
func get_asset_type(id):
	id = String(id)
	
	if not _types_assets.has(id):
		logger.error("Asset type with invalid ID %d was requested, returning null. Why was this requested?" % [id])
		return null
	
	return _types_assets[id]


# Returns the path to the scene of an asset by its ID.
func get_asset_scene_path(id):
	var asset = get_asset(id)
	
	if asset:
		var asset_type = get_asset_type(asset["type_id"])
		
		# Build the path by concatenating prefix, type name and asset name and removing spaces
		return (asset_path_prefix + asset_type["name"] + "/" + asset["name"] + ".tscn").replace(" ", "")
