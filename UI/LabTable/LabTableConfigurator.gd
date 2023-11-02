extends Configurator

var has_loaded = false

signal new_layer(layer_name: String, z_index: int)
signal map_added(layer_name: String)


func _ready():
	category = "geodata"


func load_table_config():
	var path = get_setting("config-path")
	
	var ll_file_access = LLFileAccess.open(path)
	if ll_file_access == null or not "TableSettings" in ll_file_access.json_object.data:
		logger.error("Could not load config at " + path)
		return
	
	var table_config: Dictionary = ll_file_access.json_object.data["TableSettings"]
	
	# Table config requires at least a basic map
	var path_to_map := LLFileAccess.get_rel_or_abs_path(path, table_config["Map"]["path"])
	var map := Geodot.get_raster_layer(path_to_map)
	Layers.add_geo_layer(map)
	map_added.emit(map.get_file_info()["name"])
	
	# And can load other (pre-existing) layers
	for key in table_config["Layers"].keys():
		var layer_conf = table_config["Layers"][key]
		new_layer.emit(layer_conf["layer_name"], layer_conf["z_index"])
	
	logger.info("LabTable has been setup")
