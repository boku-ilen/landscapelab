extends Resource


var external_types = ["shp", "json", "tif", "wmts"]

const path_prefix := "user://Geodata"
const LOG_MODULE := "EXTERNAL_LAYER"


func external_to_geolayer_from_type(db, config: Dictionary):
	var type = config.geolayer_path.get_extension().to_lower()
	
	var path
	if config.geolayer_path.is_rel_path():
		path = ProjectSettings.globalize_path(path_prefix.plus_file(config.geolayer_path))
	elif config.geolayer_path.is_abs_path():
		path = config.geolayer_path
	else:
		logger.error("Invalid path \"%s\" in external layer configuration" % config.geolayer_path, LOG_MODULE)
		return
	
	if not type in external_types:
		logger.error(
			"""Unexpected file-extension \"%s\" for external layer.
				Supported types: %s""" % [type, external_types], LOG_MODULE)
		return
		
	return call("geolayer_from_%s" % type, path, config)


func geolayer_from_shp(path, config):
	var ds = Geodot.get_dataset(path)
	return ds.get_feature_layer(config.additional_info)


func geolayer_from_tif(path, config):
	return Geodot.get_raster_layer(path)


func geolayer_from_json(path, config):
	return Geodot.get_dataset(path)


func geolayer_from_wmts(url, config):
	return Geodot.get_raster_layer(url)
