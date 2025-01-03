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
	var map_definition = LayerDefinition.new(map)

	Layers.add_layer_definition(map_definition)
	
	var crs_from = table_config["Map"]["crs_from"]
	map_added.emit(map.get_file_info()["name"], crs_from)
	
	# Table config might load other (pre-existing) layers
	for key in table_config["Layers"].keys():
		# Emit args
		var layer_conf = table_config["Layers"][key]
		new_layer.emit(layer_conf)
	
	# FIXME: proper deserialization/seralization options
	for key in table_config["LayerDefinitions"].keys():
		var layer_conf = table_config["LayerDefinitions"][key]
		var geo_layer = Geodot.get_raster_layer(layer_conf["path"])
		
		var min = layer_conf["min_val"]
		var max = layer_conf["max_val"]
		var values = util.rangef(min, max, (max - min) / 16)
		
		var layer_def = LayerDefinition.new(geo_layer)
		layer_def.name = key
		
		if "color_ramp" in layer_conf:
			var color_ramp = Colors.color_ramps[layer_conf["color_ramp"]]
			layer_def.render_info.colors = color_ramp
			
		layer_def.render_info.values = values
		layer_def.render_info.no_data = layer_conf["no_data"]
		layer_def.z_index = layer_conf["z_index"]
		
		Layers.add_layer_definition(layer_def)
	
	logger.info("LabTable has been setup")
