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
	var base_path = get_setting("config-path")
	for definition_name in table_config["LayerDefinitions"].keys():
		var attributes_config = table_config["LayerDefinitions"][definition_name]["attributes"]
		var type = table_config["LayerDefinitions"][definition_name]["type"]
		match type:
			"Raster": type = LayerDefinition.TYPE.RASTER
			"Feature": type = LayerDefinition.TYPE.FEATURE
			_: logger.error(
				"LayerDefinition %s: wrong type in config (expected <Raster/Feature>, got %s)" %
				[definition_name, type])
		
		var layer_definition = LayerDefinitionSerializer.deserialize(
			base_path,
			definition_name,
			type,
			attributes_config)
			
		Layers.add_layer_definition(layer_definition)
	
	logger.info("LabTable has been setup")



	
