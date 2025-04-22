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
	
	# TODO: Should this be moved somewhere else to allow other projections than 3857? 
	get_parent().geo_transform = GeoTransform.new()
	get_parent().geo_transform.set_transform(3857, config["Meta"]["crs"])
	
	_load_layers(path, table_config)


func _load_layers(path: String, table_config: Dictionary):
	# FIXME: proper deserialization/seralization options
	var base_path = get_setting("config-path")
	for key in table_config["LayerDefinitions"].keys():
		var layer_conf = table_config["LayerDefinitions"][key]
		
		# Pre-existing layer composition which strictly needs to use the same data background
		var geo_layer: RefCounted
		if "layer_name" in layer_conf:
			if "geo_feature_layer" in Layers.layer_compositions[layer_conf["layer_name"]].render_info:
				geo_layer = Layers.layer_compositions[layer_conf["layer_name"]].render_info.geo_feature_layer
			else:
				assert(false, "Invalid layer!")
		else:
			var splits = LLFileAccess.split_dataset_string(base_path, layer_conf["path"])
			geo_layer = LLFileAccess.get_layer_from_splits(splits, true)
		
		var layer_def = LayerDefinition.new(geo_layer, layer_conf["z_index"])
		layer_def.name = key
		
		if "color_ramp" in layer_conf:
			layer_def.render_info.gradient = ColorRamps.gradients[layer_conf["color_ramp"]]
			layer_def.render_info.min_val = layer_conf["min_val"]
			layer_def.render_info.max_val = layer_conf["max_val"]
		
		if "icon" in layer_conf:
			layer_def.render_info.marker = load(layer_conf["icon"])
			layer_def.render_info.marker_scale = layer_conf["icon_scale"] if "icon_scale" in layer_conf else 0.1
		
		if "no_data" in layer_conf:
			layer_def.render_info.no_data = Color(layer_conf["no_data"][0], layer_conf["no_data"][1], layer_conf["no_data"][2])
		
		if "config" in layer_def.render_info:
			layer_def.render_info.config = layer_conf
			
		Layers.add_layer_definition(layer_def)
	
	logger.info("LabTable has been setup")



	
