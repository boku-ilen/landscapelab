extends Configurator


@export var table_communicator: Node
@export var renderers: Node2D

var has_loaded = false


func _ready():
	category = "geodata"


func load_table_config() -> void:
	var path = get_setting("config-path")
	
	var ll_file_access = LLFileAccess.open(path)
	if ll_file_access == null or not "TableSettings" in ll_file_access.json_object.data:
		logger.error("Could not load table config at " + path)
		return
	
	var config: Dictionary = ll_file_access.json_object.data
	renderers.crs_from = config["Meta"]["crs"]
	var table_config: Dictionary = config["TableSettings"]
	
	_load_layers(path, table_config)


func _load_layers(path: String, table_config: Dictionary):
	# FIXME: proper deserialization/seralization options
	
	for key in table_config["LayerDefinitions"].keys():
		var layer_conf = table_config["LayerDefinitions"][key]
		
		# Pre-existing layer composition which strictly needs to use the same data background
		var geo_layer: RefCounted
		if "from_composition_name" in layer_conf:
			geo_layer = Layers.layer_compositions[layer_conf["from_composition_name"]].render_info.geo_feature_layer
		else:
			geo_layer = Geodot.get_raster_layer(layer_conf["path"])
		
		var t = geo_layer.get_epsg_code()
		
		var layer_def = LayerDefinition.new(geo_layer, layer_conf["z_index"])
		layer_def.name = key
		
		if "color_ramp" in layer_conf:
			layer_def.render_info.gradient = ColorRamps.gradients[layer_conf["color_ramp"]]
			layer_def.render_info.min_val = layer_conf["min_val"]
			layer_def.render_info.max_val = layer_conf["max_val"]
		
		if "marker" in layer_conf:
			layer_def.render_info.marker = load(layer_conf["marker"])
			layer_def.render_info.marker_scale = layer_conf["marker_scale"] if "marker_scale" in layer_conf else 0.1
		
		if "no_data" in layer_conf:
			layer_def.render_info.no_data = layer_conf["no_data"]
		
		if "config" in layer_def.render_info:
			layer_def.render_info.config = layer_conf
			
		Layers.add_layer_definition(layer_def)
	
	logger.info("LabTable has been setup")



	
