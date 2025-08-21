extends Configurator


@export var table_communicator: Node
@export var renderers: Node2D
@export var game_ui: Control

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
	_load_game_ui(path, table_config)
	
	logger.info("LabTable has been setup")


func _load_layers(path: String, table_config: Dictionary):
	var base_path = get_setting("config-path")
	for definition_name in table_config["LayerDefinitions"].keys():
		
		var layer_definition = LayerDefinitionSerializer.deserialize(
			base_path,
			definition_name,
			table_config["LayerDefinitions"][definition_name])
		
		if layer_definition is LayerDefinition:
			Layers.add_layer_definition(layer_definition)


func _load_game_ui(path: String, table_config: Dictionary):
	var base_path = get_setting("config-path")
	for goc_name in table_config["GameUI"].keys():
		# Find game mode that contains the goc
		var relevant_game_mode = GameSystem.game_modes.filter(func(game_mode: GameMode): 
			return goc_name in game_mode.game_object_collections
		)[0]
		var goc = relevant_game_mode.game_object_collections[goc_name]
		
		var ui_element: Control
		if goc is ToggleGameObjectCollection:
			ui_element = preload("res://UI/LabTable/TableToggleButton.tscn").instantiate() as Button
			ui_element.name = goc_name
			game_ui.add_child(ui_element)
			
			# Check if goc is in the current game mode otherwise hide and connect to signal
			var is_relevant_game_mode = func():
				ui_element.visible = GameSystem.current_game_mode == relevant_game_mode
			is_relevant_game_mode.call()
			GameSystem.game_mode_changed.connect(is_relevant_game_mode)
			
			# Check if it is already active and connect to signal
			ui_element.set_pressed(goc.active)
			ui_element.toggled.connect(goc.toggle)
		
		# Finally deserialize properties
		Serialization.deserialize(
			table_config["GameUI"][goc_name]["attributes"],
			ui_element,
			base_path,
			AbstractLayerSerializer._lookup_deserialization.bind(AbstractLayerSerializer)
		)
