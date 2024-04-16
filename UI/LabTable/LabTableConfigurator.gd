extends Configurator


@export var table_communicator: Node

var has_loaded = false

signal new_layer(layer_name: String, z_index: int)
signal map_added(layer_name: String)


func _ready():
	category = "geodata"


func load_table_config() -> void:
	var path = get_setting("config-path")
	
	var ll_file_access = LLFileAccess.open(path)
	if ll_file_access == null or not "TableSettings" in ll_file_access.json_object.data:
		logger.error("Could not load table config at " + path)
		return
	
	var table_config: Dictionary = ll_file_access.json_object.data["TableSettings"]
	_load_layers(path, table_config)


func _load_layers(path: String, table_config: Dictionary):
	# Table config requires at least a basic map
	if not "Map" in table_config:
		logger.error("No map was defined in config " + path)
	
	var path_to_map := LLFileAccess.get_rel_or_abs_path(path, table_config["Map"]["path"])
	var map := Geodot.get_raster_layer(path_to_map)
	Layers.add_geo_layer(map)
	
	var crs_from = table_config["Map"]["crs_from"]
	map_added.emit(map.get_file_info()["name"], crs_from)
	
	# Table config might load other (pre-existing) layers
	for key in table_config["Layers"].keys():
		# Emit args
		var layer_conf = table_config["Layers"][key]
		
		new_layer.emit(
			layer_conf["layer_name"],
			layer_conf["icon"]  if "icon" in layer_conf else null,
			layer_conf["icon_scale"] if "icon_scale" in layer_conf else null, 
			layer_conf["min_zoom"] if "min_zoom" in layer_conf else 0.0, 
			layer_conf["z_index"]  if "z_index" in layer_conf else null
		)
	
	logger.info("LabTable has been setup")
