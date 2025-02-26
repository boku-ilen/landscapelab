extends Configurator

var has_loaded = false
var path


func _ready():
	category = "geodata"


func load_game_mode_config() -> void:
	path = get_setting("config-path")
	
	var ll_file_access = LLFileAccess.open(path)
	if ll_file_access == null or not "GameModes" in ll_file_access.json_object.data:
		logger.info("Could not load game-mode config at " + path)
		return
	
	var game_modes_config: Dictionary = ll_file_access.json_object.data["GameModes"]
	_load_game_modes(path, game_modes_config)


func _load_game_modes(path: String, game_modes: Dictionary) -> void:
	for key in game_modes:
		var game_mode = game_modes[key]
		
		var game_mode_object = GameMode.new()
		
		if "Extent" in game_mode:
			game_mode_object.extent = game_mode["Extent"]
		
		var game_object_collections = game_mode["GameObjectCollections"]
		_deserialize_object_colletion(game_mode_object, game_object_collections)
		
		if "AttributeMappings" in game_mode:
			var attribute_mappings = game_mode["AttributeMappings"]
			_deserialize_mappings(game_mode_object, attribute_mappings)
		
		if "Scores" in game_mode:
			var scores = game_mode["Scores"]
			_deserialize_scores(game_mode_object, scores)
		
		if "CreationConditions" in game_mode:
			var conditions = game_mode["CreationConditions"]
			_deserialize_creation_conditions(game_mode_object, conditions)
		
		if "Tokens" in game_mode:
			var tokens = game_mode["Tokens"]
			_deserialize_tokens(game_mode_object, tokens)
		
		GameSystem.game_modes.append(game_mode_object)
	
	GameSystem.activate_next_game_mode()


# TODO: similarly to layercomposition an own class for deserialization could be created
# TODO: this would enhance readability
func _deserialize_object_colletion(game_mode: GameMode, game_object_collections: Dictionary):
	for collection_name in game_object_collections:
		var collection = game_object_collections[collection_name]
		var layer_name = collection["layer_name"]
		
		var layer
		
		if "geo_feature_layer" in Layers.layer_compositions[layer_name].render_info:
			layer = Layers.layer_compositions[layer_name].render_info.geo_feature_layer
		else:
			assert(false, "Invalid layer!")
		
		var collection_object: GameObjectCollection
		
		var type = collection["type"] if "type" in collection else "GeoGameObjectCollection"
		
		if type == "GeoGameObjectCollection":
			collection_object = game_mode.add_game_object_collection_for_feature_layer(
				collection_name, layer
			)
		elif type == "GameObjectClusterCollection":
			var location_layer = LayerCompositionSerializer.get_feature_layer_from_string(
				collection["location_layer"],
				path
			)
			var instance_goc = game_mode.game_object_collections[collection["goc"]]
			
			collection_object = game_mode.add_cluster_game_object_collection(
				collection_name,
				layer,
				location_layer,
				instance_goc
			)
			
			if "min_cluster_size" in collection: collection_object.min_cluster_size = collection["min_cluster_size"]
			if "max_cluster_size" in collection: collection_object.max_cluster_size = collection["max_cluster_size"]
			if "default_cluster_size" in collection: collection_object.default_cluster_size = collection["default_cluster_size"]


var mapping_type_to_construction_func = {
	"ImplicitVectorGameObjectAttribute": func(_name, data):
		var splits = LLFileAccess.split_dataset_string(path, data["layer_name"])
		var layer = LLFileAccess.get_layer_from_splits(splits, false)
		return ImplicitVectorGameObjectAttribute.new(
			_name,
			layer,
			data["attribute"]
		),
	"ImplicitRasterGameObjectAttribute": func(_name, data):
		var splits = LLFileAccess.split_dataset_string(path, data["layer_name"])
		var layer = LLFileAccess.get_layer_from_splits(splits, true)
		return ImplicitRasterGameObjectAttribute.new(
			_name,
			layer
		),
	"StaticAttribute": func(_name, data):
		return StaticAttribute.new(
			_name,
			data["value"]
		),
	"ExplicitGameObjectAttribute": func(_name, data):
		return ExplicitGameObjectAttribute.new(_name, data["attribute"]),
	"ClassGameObjectAttribute": func(_name, data):
		return ClassGameObjectAttribute.new(_name, data["class_to_attributes"]),
	"CalculatedGameObjectAttribute": func(_name, data):
		return CalculatedGameObjectAttribute.new(_name, data["formula"])
	# TODO: implement all possible attributes
}
func _deserialize_mappings(game_mode: GameMode,
							attribute_mappings: Dictionary) -> void:
	for mapping_name in attribute_mappings:
		var mapping = attribute_mappings[mapping_name]
		
		# Search for the appropriate construction function in the dict above
		var attribute: GameObjectAttribute = \
			mapping_type_to_construction_func[mapping["type"]].call(mapping_name, mapping["data"])
		
		# Add mapping for all required collections
		for collection_name in mapping["for_collections"]:
			var collection_object = game_mode.game_object_collections[collection_name]
			collection_object.add_attribute_mapping(attribute)
		
		if "reflections" in mapping:
			deserialize_reflective(attribute, mapping["reflections"])


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
		score.icon_subject = metadata["icon_subject"] if "icon_subject" in metadata else ""
		score.icon_descriptor = metadata["icon_descriptor"] if "icon_descriptor" in metadata else ""
		
		# Add all possible contributors
		var contributors = scores[score_name]["contributors"]
		for contributor in contributors:
			var collection: GameObjectCollection = \
				game_mode.game_object_collections[contributor["collection_name"]]
			
			# Argument arary for add_contributor
			var args = [
				# Have to be set
				collection, contributor["mapping_name"],
				# Optional
				contributor["weight"] if "weight" in contributor else 1.0,
				Color(contributor["color"]) if "color" in contributor else Color.GRAY,
				contributor["min_weight"] if "min_weight" in contributor else null,
				contributor["max_weight"] if "max_weight" in contributor else null
			]
			
			score.add_contributor.callv(args)
		
		game_mode.add_score(score)


var condition_type_to_construction_func = {
	"VectorAttributeCreationCondition": func(_name, data):
		var splits = LLFileAccess.split_dataset_string(path, data["layer_name"])
		var layer = LLFileAccess.get_layer_from_splits(splits, false)
		return VectorAttributeCreationCondition.new(
			_name,
			layer,
			data["attribute_name"],
			data["attribute_comparator"],
			data["default_return"]
		),
	"GreaterThanRasterCreationCondition": func(_name, data):
		var splits = LLFileAccess.split_dataset_string(path, data["layer_name"])
		var layer = LLFileAccess.get_layer_from_splits(splits, true)
		return GreaterThanRasterCreationCondition.new(
			_name,
			layer,
			data["greater_than_comparator"]
		),
	"VectorExistsCreationCondition": func(_name, data):
		var splits = LLFileAccess.split_dataset_string(path, data["layer_name"])
		var layer = LLFileAccess.get_layer_from_splits(splits, false)
		return VectorExistsCreationCondition.new(
			_name,
			layer
		)
	# TODO: implement all possible attributes
}
func _deserialize_creation_conditions(game_mode: GameMode, conditions: Dictionary):
	for condition_name in conditions:
		var condition = conditions[condition_name]
		var condition_object: CreationCondition \
			= condition_type_to_construction_func[condition["type"]].call(condition_name, condition["data"])
		
		for collection_name in condition["for_collections"]:
			var collection_object = game_mode.game_object_collections[collection_name]
			collection_object.add_creation_condition(condition_object)

func _deserialize_tokens(game_mode: GameMode, tokens: Dictionary):
	game_mode.token_to_game_object_collection = tokens
