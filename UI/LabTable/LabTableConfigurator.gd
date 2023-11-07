extends Configurator

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
	
	# Only load game modes if layers could be loaded successfully
	if _load_layers(path, table_config):
		_load_game_modes(path, table_config)


func _load_layers(path: String, table_config: Dictionary) -> bool:
	# Table config requires at least a basic map
	if not "Map" in table_config:
		logger.error("No map was defined in config " + path)
		return false
	
	var path_to_map := LLFileAccess.get_rel_or_abs_path(path, table_config["Map"]["path"])
	var map := Geodot.get_raster_layer(path_to_map)
	Layers.add_geo_layer(map)
	map_added.emit(map.get_file_info()["name"])
	
	# Table config might load other (pre-existing) layers
	for key in table_config["Layers"].keys():
		var layer_conf = table_config["Layers"][key]
		new_layer.emit(layer_conf["layer_name"], layer_conf["icon"], layer_conf["icon_scale"], layer_conf["z_index"])
	
	logger.info("LabTable has been setup")
	return true


func _load_game_modes(path: String, table_config: Dictionary) -> void:
	# Game modes config is not strictly necessary
	if not "GameModes" in table_config:
		logger.info("No game modes were defined in config " + path)
		return
	
	var game_modes: Dictionary = table_config["GameModes"]
	for key in game_modes:
		var game_mode_serialized = game_modes[key]
		
		var game_mode = GameMode.new()
		game_mode.extent = game_mode_serialized["Extent"]
		
		var game_object_collections = game_mode["GameObjectCollections"]
		var attribute_mappings = game_mode["AttributeMappings"]
		var scores = game_mode["Scores"]
		
		_deserialize_object_colletion(game_mode, game_object_collections)
		_deserialize_mappings(game_mode, attribute_mappings)
		_deserialize_scores(game_mode, scores)


# TODO: similarly to layercomposition an own class for deserialization could be created
# TODO: this would enhance readability
func _deserialize_object_colletion(game_mode: GameMode, game_object_collections: Dictionary):
	for collection_name in game_object_collections:
		var collection = game_object_collections[collection_name]
		var layer_name = collection["LayerName"]
		var layer: RefCounted = Layers.get_geo_layer_by_name(layer_name)
		
		var collection_object: GameObjectCollection
		if layer is GeoFeatureLayer:
			collection_object = \
				game_mode.add_game_object_collection_for_feature_layer(collection_name, layer)
		else:
			# TODO: how to handle in case of GeoRasterLayer?
			pass


var type_to_construction_func = {
	"ImplicitVectorGameObjectAttribute": func(_name, data):
		return ImplicitVectorGameObjectAttribute.new(
			_name,
			Layers.get_geo_layer_by_name(data["LayerName"]),
			data["Attribute"]
		),
	"ImplicitRasterGameObjectAttribute": func(_name, data):
		return ImplicitRasterGameObjectAttribute.new(
			_name,
			Layers.get_geo_layer_by_name(data["LayerName"])
		),
	"StaticAttribute": func(_name, data):
		return StaticAttribute.new(
			_name,
			data["value"]
		)
	# TODO: implement all possible attributes
}
func _deserialize_mappings(game_mode: GameMode,
							attribute_mappings: Dictionary) -> void:
	for mapping_name in attribute_mappings:
		var mapping = attribute_mappings[mapping_name]
		var attribute: GameObjectAttribute = \
			type_to_construction_func[mapping["type"]].call(mapping_name, mapping["data"])
		
		for collection_name in mapping["for"]:
			var collection_object = game_mode.game_object_collections[collection_name]
			collection_object.add_attribute_mapping(attribute)


func _deserialize_scores(game_mode: GameMode, scores: Dictionary):
	for score_name in scores: 
		# TODO: will there be other game-scores than updating ones?
		# Create new score and add metadata
		var score = UpdatingGameScore.new()
		score.name = score_name
		var metadata = scores[score_name]
		score.target = metadata["target"]
		score.display_mode = metadata["display_mode"]
		# Might not be set for all display_modes
		score.icon_subject = metadata["icon_subject"] if "icon_subject" in metadata else null
		score.icon_descriptor = metadata["icon_descriptor"] if "icon_descriptor" in metadata else null
		
		# Add all possible contributors
		var contributors = scores["Contributors"]
		for contributor in contributors:
			var collection: GameObjectCollection = \
				game_mode.game_object_collections[contributor["collection_name"]]
			score.add_contributor(collection, contributor["mapping_name"], contributor["weight"])
