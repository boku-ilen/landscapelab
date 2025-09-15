extends RefCounted
class_name LLFileAccess

var json_object := JSON.new()
var path: String
var file_access: FileAccess


# Split dataset string into (absolute directory path, layer name, access)
static func split_dataset_string(base_path: String, dataset_str: String):
	# E.g. ./LL.gpkg:ortho?w
	# => ["./LL.gpkg", "ortho?w"], ["ortho", "w"]
	var split_step = dataset_str.split(":")
	var split_step2 = split_step[1].split("?") if split_step.size() > 1 else [""]
	# => ["./LL.gpkg", "ortho", "w"]
	var splits = { 
		"file_name": split_step[0], 
		"layer_name": split_step2[0],
		"write_access": true if split_step2.size() > 1 and split_step2[1] == "w" else false
	}
	
	splits["file_name"] = LLFileAccess.get_rel_or_abs_path(
		base_path,
		splits["file_name"])
	
	return splits


static func get_layer_from_splits(splits: Dictionary, is_raster:=true):
	if splits["layer_name"] == "":
		return Geodot.get_raster_layer(splits["file_name"], splits["write_access"])
	
	var geo_ds = Geodot.get_dataset(
		splits["file_name"], splits["write_access"])
	
	if is_raster:
		return geo_ds.get_raster_layer(splits["layer_name"])
	
	return geo_ds.get_feature_layer(splits["layer_name"])


static func get_rel_or_abs_path(base_path: String, file_path: String) -> String:
	if file_path.begins_with("./"):
		return base_path.get_base_dir().path_join(file_path)
	else:
		return file_path


static func open(init_path: String) -> LLFileAccess:
	logger.info("Loading LL project file from " + init_path + "...")
	var file
	if FileAccess.file_exists(init_path):
		file = FileAccess.open(init_path, FileAccess.READ_WRITE)
	else:
		file = FileAccess.open(init_path, FileAccess.WRITE_READ)
	
	var ll_file_access = LLFileAccess.new()
	ll_file_access.path = init_path
	ll_file_access.file_access = file
	
	if file == null:
		logger.error("Error opening LL project file at " + init_path)
		return null
	
	var error = ll_file_access.json_object.parse(file.get_as_text())
	
	if error != OK:
		logger.error("Error parsing LL project at " + init_path + ": "
				+ ll_file_access.json_object.get_error_message() + " at line "
				+ str(ll_file_access.json_object.get_error_line()))
	
	return ll_file_access


func save():
	var ll_config = {
		"LayerCompositions": {},
		"Scenarios":  {},
		"Vegetation": {}
	}
	
	# FIXME: After the first layercomposition has been serialized, 
	# FIXME: the other ones will not have a valid layer.get_dataset().resource_path
	for layer_composition in Layers.layer_compositions.values():
		var serialized: Dictionary = LayerCompositionSerializer.serialize(layer_composition)
		ll_config["LayerCompositions"].merge(serialized)
	
	for scenario in Scenarios.scenarios:
		ll_config.Scenarios.merge({
			scenario.name: {
				"layers": scenario.visible_layer_names
			}
		})
	
	# FIXME: unmake hardcode
	ll_config["Vegetation"] = Vegetation.paths
	
	var json_string = JSON.stringify(ll_config)
	file_access.store_line(json_string)
	var error = json_object.parse(json_string)
	
	if error != OK:
		logger.error("Error parsing LL project at : "
			+ json_object.get_error_message() + " at line "
			+ str(json_object.get_error_line()))


func apply(vegetation: Node, layers: Node, scenarios: Node, game_system: Node, override=false):
	if override: 
		logger.warn("Trying to override vegetation, layers and scenarios. This could lead to errors!")
	
	for node in [vegetation, layers, scenarios, game_system]:
		if node.was_loaded: 
			logger.info("%s has been loaded already, skipping..." % node)
	
	if not layers.was_loaded or override:
		apply_meta(layers)
	if not vegetation.was_loaded or override:
		apply_vegetation(vegetation)
	if not layers.was_loaded or override:
		apply_layers(layers)
	if not scenarios.was_loaded or override:
		apply_scenarios(scenarios)


func apply_meta(layers: Node):
	var ll_project = json_object.data
	 
	if "Meta" in ll_project:
		if "crs" in ll_project["Meta"]: layers.crs = ll_project["Meta"]["crs"]


func apply_vegetation(vegetation: Node):
	var ll_project = json_object.data
	
	# Load vegetation if in config
	if ll_project.has("Vegetation"):
		logger.info("Loading vegetation...")
		vegetation.load_data_from_csv(
			get_rel_or_abs_path(path, ll_project["Vegetation"]["Plants"]),
			get_rel_or_abs_path(path, ll_project["Vegetation"]["Groups"]),
			get_rel_or_abs_path(path, ll_project["Vegetation"]["Densities"]),
			get_rel_or_abs_path(path, ll_project["Vegetation"]["Textures"])
		)
		# Apply HCY shift
		if "HCYShift" in ll_project["Vegetation"]:
			var hcy_shift_vector = Vector3(
				ll_project["Vegetation"]["HCYShift"][0],
				ll_project["Vegetation"]["HCYShift"][1],
				ll_project["Vegetation"]["HCYShift"][2]
			)
			RenderingServer.global_shader_parameter_set("HCY_SHIFT", hcy_shift_vector)
			vegetation.hcy_shift_changed.emit(hcy_shift_vector)
		
		logger.info("Done loading vegetation!")
		vegetation.was_loaded = true


func apply_layers(layers: Node):
	var ll_project = json_object.data
	
	for composition_name in ll_project["LayerCompositions"].keys():
		logger.info("Loading layer composition " + composition_name + "...")
		
		var composition_data = ll_project["LayerCompositions"][composition_name]
		
		var layer_composition = LayerCompositionSerializer.deserialize(
			path, 
			composition_name, 
			composition_data)
		
		# TODO: layer-compositions and layer-groups may appear under the same section
		# in some cases, the returned value of the deserialization thus is not of class
		# LayerComposition, refer to https://github.com/boku-ilen/landscapelab/issues/362
		if layer_composition == null or not layer_composition is LayerComposition:
			continue
		
		layers.add_layer_composition(layer_composition)
		layers.recalculate_center()
	
	if "LayerCompositionConnections" in ll_project:
		for connection_name in ll_project["LayerCompositionConnections"].keys():
			logger.info("Loading layer composition connection" + connection_name + "...")
			
			var connection_data = ll_project["LayerCompositionConnections"][connection_name]
			var layer_comp_connection = LayerCompositionConnectionSerializer.deserialize(
				connection_data["type"],
				connection_data["source"],
				connection_data["target"]
			)
	
	logger.info("Done loading layer-compositions!")
	layers.was_loaded = true


func apply_scenarios(scenarios: Node):
	var ll_project = json_object.data
	
	# Load scenarios if in config
	if ll_project.has("Scenarios"):
		logger.info("Loading scenarios...")
		for scenario_name in ll_project["Scenarios"].keys():
			var scenario = Scenario.new()
			scenario.name = scenario_name
			
			for layer_name in ll_project["Scenarios"][scenario_name]["layers"]:
				scenario.add_visible_layer_name(layer_name)
			
			scenarios.add_scenario(scenario)
		
		logger.info("Done loading scenarios!")
		scenarios.was_loaded = true


func apply_game(game_system: Node, layers: Node):
	var ll_project = json_object.data
	
	# Load scenarios if in config
	if ll_project.has("GameModes"):
		logger.info("Loading game modes...")
		for game_mode_name in ll_project["GameModes"].keys():
			var game_mode = GameMode.new()
			game_mode.name = game_mode_name
			
			for game_object_collection_name in ll_project["GameModes"][game_mode_name]["GameObjectCollections"]:
				var lc_name = ll_project["GameModes"][game_mode_name]["GameObjectCollections"][game_object_collection_name]
				var layer = layers.layer_compositions[lc_name].render_info.geo_feature_layer
				
				game_mode.add_game_object_collection_for_feature_layer(
					game_object_collection_name,
					layer
				)
			
			# FIXME: Another way to set this, this only works for 1 game mode
			game_system.current_game_mode = game_mode
		
		logger.info("Done loading game logic!")


# Convert dictionary of [String, String] to [String, Geolayer]
func convert_dict_to_geolayers(dict: Dictionary) -> Dictionary:
	var converted = {}
	for key in dict.keys():
		var path = dict[key]
		
		var splits = split_dataset_string(Settings.get_setting("geodata", "config-path"), path)
		var layer = get_layer_from_splits(splits, false)
		
		converted[key] = layer
	
	return converted
