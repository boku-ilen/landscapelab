extends "res://World/AssetHandler/AbstractAssetHandler.gd"


#
# Implementation of an Asset Handler for moving assets such as windmills.
#


export(bool) var only_lego_active = true
export(int) var asset_id


func _ready():
	# Use the update interval from the settings
	update_interval = Settings.get_setting("assets", "moving-update-interval")
	
	# When only_lego_active is true, the asset handler only becomes active
	#  when sync_moving_assets is emitted, otherwise it's inactive because then we
	#  work with local input instead.
	if only_lego_active:
		_active = false
		GlobalSignal.connect("stop_sync_moving_assets", self, "_set_inactive")
		GlobalSignal.connect("sync_moving_assets", self, "_set_active")
	else:
		_active = true


# Abstract function which returns the result (a list of assets) of the specific request being implemented.
func _get_server_result():
	var player_pos = PlayerInfo.get_true_player_position()
	var result = ServerConnection.get_json("/assetpos/get_near/by_asset/%s/%d.0/%d.0.json"
	 % [asset_id, -player_pos[0], player_pos[2]], false)
	
	if result and result.has("assets"):
		return result["assets"]
	else:
		return null


# Abstract function for getting the position of one asset in the result.
# Must be implemented for moving assets because different server responses have different formats of their data.
func _get_asset_position_from_response(asset_id):
	return [_result[asset_id]["position"][0], _result[asset_id]["position"][1]]

 
# Abstract function which instances the asset with the given asset_id.
func _spawn_asset(instance_id):
	var pos = _get_engine_position_for_asset(instance_id)
	
	# Our request should only return nearby assets, but this is a failsafe to prevent #78 from causing crashes if
	#  for some reason, we get assets which are very far away.
	if pos.length() < 30000:
		var new_instance = asset_scene.instance()
		
		new_instance.name = String(instance_id)
		new_instance.global_transform.origin = pos
	
		add_child(new_instance)
		
		GlobalSignal.emit_signal("asset_spawned")
		
		return true
	else:
		logger.warning("Got AssetPosition with ID %d which is very far away, it won't be instanced!" % [instance_id])


# This function handles the delete of an asset and emits the signal so the ui can be updated
func _handle_deleted_asset():
	GlobalSignal.emit_signal("asset_removed")