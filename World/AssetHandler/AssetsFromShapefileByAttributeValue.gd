extends AbstractAssetsFromShapefile

export(String) var attribute_name
export(Dictionary) var attribute_values_to_assets
export(PackedScene) var default_asset

var pos_manager: PositionManager


func _create_asset_for_geopoint(geopoint):
	var geopoint_value = geopoint.get_attribute(attribute_name)
	var asset_to_spawn = default_asset
	
	for attribute_value in attribute_values_to_assets.keys():
		if attribute_value == geopoint_value:
			asset_to_spawn = attribute_values_to_assets[attribute_value]
	
	if asset_to_spawn:
		var instance = asset_to_spawn.instance()
		instance.transform.origin = geopoint.get_offset_vector3(pos_manager.x, 0, -pos_manager.z)
		
		return instance
	else:
		return null
