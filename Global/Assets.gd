extends Node

#
# Centralized access to all information regarding assets and asset types.
#


var _types_assets: Dictionary = {}
var _assets: Dictionary = {}

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
	# TODO: we want to get rid of this server connection. This kind of setting should come
	# TODO: from the game logic or the geo data
	
	return # FIXME: Phasing out the server
	
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


# Returns all assets in a dictionary indexed by their ID.
func get_assets():
	if _assets.size() == 0:
		logger.info("get_assets() was called, but there are no assets!")
	
	return _assets


# Returns any asset by its ID or null if the asset does not exist.
func get_asset(id):
	id = String(id)
	
	if not _assets.has(id):
		logger.error("Asset with invalid ID %d was requested, returning null. Why was this requested?" % [id])
		return null
	
	return _assets[id]


# Returns a dictionary which contains all asset types, with each asset type containing
#  all its assets.
func get_asset_types_with_assets():
	if _types_assets.size() == 0:
		logger.info("get_asset_types() was called, but there are no assets!")
	
	return _types_assets


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


# Returns an instance of the scene of the asset with the given ID.
func get_asset_instance(id):
	# TODO: In the future, this function could unify dynamic and static assets by either instancing a local scene,
	#  or loading it from a DSCN file from somewhere else, e.g. if a 'path' field is set.
	var path = get_asset_scene_path(id)
	
	if path:
		if not Directory.new().file_exists(path):
			logger.error("The asset of ID %d should be at path %s, but it isn't! Check the naming of the path." \
			% [id, path])
			return null
		
		return load(path).instance()
