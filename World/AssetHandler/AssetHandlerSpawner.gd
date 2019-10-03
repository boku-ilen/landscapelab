extends Spatial

#
# Spawns asset handlers for all dynamic assets as its children.
#

export(PackedScene) var asset_handler_scene


func _ready():
	var assets = Assets.get_assets()
	
	# For each asset, add a handler
	for asset_id in assets:
		var handler = asset_handler_scene.instance()
		
		handler.asset_id = asset_id
		handler.asset_scene = load(Assets.get_asset_scene_path(asset_id))
		
		if handler.asset_scene == null:
			logger.warning("Asset handler for asset ID %s has no valid scene!" % [asset_id])
			continue
		
		add_child(handler)
		
		logger.debug("Added asset handler for asset with ID %s" % [asset_id])
