extends Configurator


var geopackage
var external_layers = preload("res://Layers/ExternalLayerComposition.gd").new()

const LOG_MODULE := "LAYERCONFIGURATION"

signal geodata_invalid
signal loading_finished


func _ready():
	category = "geodata"
	load_ll_json("/home/landscapelab/Data/wolkersdorf.ll")
	loading_finished.emit()


func load_ll_json(path: String):
	var json_object := JSON.new()
	
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		logger.error("Error opening LL project file at " + path, category)
	
	var error = json_object.parse(file.get_as_text())
	
	if error != OK:
		logger.error("Error parsing LL project at " + path + ": "
				+ json_object.get_error_message() + " at line "
				+ str(json_object.get_error_line()), category)
	
	var ll_project = json_object.data
	
	var db_cache = {}
	
	for composition_name in ll_project["LayerCompositions"].keys():
		var composition_data = ll_project["LayerCompositions"][composition_name]
		var type = composition_data["type"]
		
		var layer_composition = LayerComposition.new()
		
		layer_composition.name = composition_name
		layer_composition.render_info = layer_composition.RENDER_INFOS[type].new()
		
		if composition_data.has("raster_layers"):
			for attribute_name in composition_data["raster_layers"].keys():
				var full_path = composition_data["raster_layers"][attribute_name].split(":")
				var file_name = path.get_base_dir().path_join(full_path[0])
				var layer_name = full_path[1]
				
				if not file_name in db_cache:
					db_cache[file_name] = Geodot.get_dataset(file_name)
				
				var db = db_cache[file_name]
				var layer = db.get_raster_layer(layer_name)
				
				layer_composition.render_info.set(attribute_name, layer)
		
		if composition_data.has("feature_layers"):
			for attribute_name in composition_data["feature_layers"].keys():
				var full_path = composition_data["feature_layers"][attribute_name].split(":")
				var file_name = path.get_base_dir().path_join(full_path[0])
				var layer_name = full_path[1]
				
				if not file_name in db_cache:
					db_cache[file_name] = Geodot.get_dataset(file_name)
				
				var db = db_cache[file_name]
				var layer = db.get_feature_layer(layer_name)
				
				layer_composition.render_info.set(attribute_name, layer)
		
		if composition_data.has("attributes"):
			for attribute_name in composition_data["attributes"].keys():
				var value = composition_data["attributes"][attribute_name]
				layer_composition.render_info.set(attribute_name, value)
		
		Layers.add_layer_composition(layer_composition)

	
#	define_probing_game_mode(
#		623950,
#		493950,
#		648950,
#		513950)
	
#	# Wolkersdorf
#	define_pa3c3_game_mode(
#		623950,
#		493950,
#		648950,
#		513950,
#		-2,
#		-1,
#		4843000,
#		56100000
#	)
#
	# StStefan
#	define_pa3c3_game_mode(
#		513210,
#		366760,
#		538210,
#		391760,
#		-3,
#		-1,
#		2938000
#	)


func define_probing_game_mode(extent_x_min,
		extent_y_min,
		extent_x_max,
		extent_y_max):
	var game_mode = GameMode.new()
	game_mode.extent = [extent_x_min, extent_y_min, extent_x_max, extent_y_max]
	
	var acceptable = game_mode.add_game_object_collection_for_feature_layer("Vorstellbar", Layers.geo_layers["features"]["acceptable"])
	var unacceptable = game_mode.add_game_object_collection_for_feature_layer("Nicht vorstellbar", Layers.geo_layers["features"]["unacceptable"])
	
	acceptable.icon_name = "yes_icon"
	acceptable.desired_shape = "SQUARE_BRICK"
	acceptable.desired_color = "GREEN_BRICK"
	
	unacceptable.icon_name = "no_icon"
	unacceptable.desired_shape = "SQUARE_BRICK"
	unacceptable.desired_color = "RED_BRICK"
	
	# TODO: Do we want a score, e.g. more acceptable than unacceptable?
	
	GameSystem.current_game_mode = game_mode


func define_pa3c3_game_mode(
		extent_x_min,
		extent_y_min,
		extent_x_max,
		extent_y_max,
		food_minus_fh,
		food_minus_bf,
		power_target,
		power_target2
	):
	var game_mode = GameMode.new()
	
	game_mode.extent = [extent_x_min, extent_y_min, extent_x_max, extent_y_max]
	
	var apv_fh_1 = game_mode.add_game_object_collection_for_feature_layer("APV Fraunhofer 1ha", Layers.geo_layers["features"]["apv_fh_1"])
	var apv_fh_3 = game_mode.add_game_object_collection_for_feature_layer("APV Fraunhofer 3ha", Layers.geo_layers["features"]["apv_fh_3"])
	
	var apv_bf_1 = game_mode.add_game_object_collection_for_feature_layer("APV Bifacial 1ha", Layers.geo_layers["features"]["apv_bf_1"])
	var apv_bf_3 = game_mode.add_game_object_collection_for_feature_layer("APV Bifacial 3ha", Layers.geo_layers["features"]["apv_bf_3"])
	
	# Add player game object collection
	var player_game_object_collection = PlayerGameObjectCollection.new("Players", get_parent().get_node("FirstPersonPC"))
	game_mode.add_game_object_collection(player_game_object_collection)
	player_game_object_collection.icon_name = "player_position"
	player_game_object_collection.desired_shape = "SQUARE_BRICK"
	player_game_object_collection.desired_color = "GREEN_BRICK"

	var apv_creation_condition = VectorExistsCreationCondition.new("APV auf Feld", Layers.geo_layers["features"]["fields"])
	apv_fh_1.add_creation_condition(apv_creation_condition)
	apv_fh_3.add_creation_condition(apv_creation_condition)
	apv_bf_1.add_creation_condition(apv_creation_condition)
	apv_bf_3.add_creation_condition(apv_creation_condition)
	
	var field_profit_attribute_fh = ImplicitVectorGameObjectAttribute.new(
			"Profitdifferenz LW",
			Layers.geo_layers["features"]["fields"],
			"PRF_DIFF_F"
	)
	apv_fh_1.add_attribute_mapping(field_profit_attribute_fh)
	apv_fh_3.add_attribute_mapping(field_profit_attribute_fh)
	
	var field_profit_attribute_bf = ImplicitVectorGameObjectAttribute.new(
			"Profitdifferenz LW",
			Layers.geo_layers["features"]["fields"],
			"PRF_DIFF_B"
	)
	apv_bf_1.add_attribute_mapping(field_profit_attribute_bf)
	apv_bf_3.add_attribute_mapping(field_profit_attribute_bf)
	
	var power_generation_fh = ImplicitVectorGameObjectAttribute.new(
			"Stromerzeugung kWh",
			Layers.geo_layers["features"]["fields"],
			"FH_2041_AV"
	)
	apv_fh_1.add_attribute_mapping(power_generation_fh)
	apv_fh_3.add_attribute_mapping(power_generation_fh)
	
	var power_generation_bf = ImplicitVectorGameObjectAttribute.new(
			"Stromerzeugung kWh",
			Layers.geo_layers["features"]["fields"],
			"BF_2041_AV"
	)
	apv_bf_1.add_attribute_mapping(power_generation_bf)
	apv_bf_3.add_attribute_mapping(power_generation_bf)
	
	apv_fh_1.add_attribute_mapping(StaticAttribute.new("Kosten", -47308.8))
	apv_fh_3.add_attribute_mapping(StaticAttribute.new("Kosten", -47308.8))
	
	apv_bf_1.add_attribute_mapping(StaticAttribute.new("Kosten", -20044.5))
	apv_bf_3.add_attribute_mapping(StaticAttribute.new("Kosten", -20044.5))

	apv_fh_1.add_attribute_mapping(StaticAttribute.new("Ernaehrte Personen", food_minus_fh))
	apv_fh_3.add_attribute_mapping(StaticAttribute.new("Ernaehrte Personen", food_minus_fh))
	
	apv_bf_1.add_attribute_mapping(StaticAttribute.new("Ernaehrte Personen", food_minus_bf))
	apv_bf_3.add_attribute_mapping(StaticAttribute.new("Ernaehrte Personen", food_minus_bf))
	
	apv_fh_1.icon_name = "pv_icon"
	apv_fh_1.desired_shape = "SQUARE_BRICK"
	apv_fh_1.desired_color = "BLUE_BRICK"
	
	apv_fh_3.icon_name = "pv_icon"
	apv_fh_3.desired_shape = "RECTANGLE_BRICK"
	apv_fh_3.desired_color = "BLUE_BRICK"
	
	apv_bf_1.icon_name = "pv_icon"
	apv_bf_1.desired_shape = "SQUARE_BRICK"
	apv_bf_1.desired_color = "RED_BRICK"
	
	apv_bf_3.icon_name = "pv_icon"
	apv_bf_3.desired_shape = "RECTANGLE_BRICK"
	apv_bf_3.desired_color = "RED_BRICK"
	
	var profit_lw_score = UpdatingGameScore.new()
	profit_lw_score.name = "Deckungsbeitrag"
	profit_lw_score.add_contributor(apv_fh_1, "Profitdifferenz LW")
	profit_lw_score.add_contributor(apv_fh_3, "Profitdifferenz LW", 3.0)
	profit_lw_score.add_contributor(apv_bf_1, "Profitdifferenz LW")
	profit_lw_score.add_contributor(apv_bf_3, "Profitdifferenz LW", 3.0)
	profit_lw_score.target = 0.0
	profit_lw_score.display_mode = GameScore.DisplayMode.ICONTEXT
	profit_lw_score.icon_subject = "euro"
	profit_lw_score.icon_descriptor = "grass"
	
	game_mode.add_score(profit_lw_score)
	
	var profit_power_score = UpdatingGameScore.new()
	profit_power_score.name = "Profit Strom"
	profit_power_score.add_contributor(apv_fh_1, "Stromerzeugung kWh", 0.07)
	profit_power_score.add_contributor(apv_fh_3, "Stromerzeugung kWh", 0.07 * 3.0)
	profit_power_score.add_contributor(apv_fh_1, "Kosten")
	profit_power_score.add_contributor(apv_fh_3, "Kosten", 3.0)
	profit_power_score.add_contributor(apv_bf_1, "Stromerzeugung kWh", 0.07)
	profit_power_score.add_contributor(apv_bf_3, "Stromerzeugung kWh", 0.07 * 3.0)
	profit_power_score.add_contributor(apv_bf_1, "Kosten")
	profit_power_score.add_contributor(apv_bf_3, "Kosten", 3.0)
	profit_power_score.target = 0.0
	profit_power_score.display_mode = GameScore.DisplayMode.ICONTEXT
	profit_power_score.icon_subject = "euro"
	profit_power_score.icon_descriptor = "energy"
	
	game_mode.add_score(profit_power_score)
	
	var profit_score = UpdatingGameScore.new()
	profit_score.name = "Profit"
	profit_score.add_contributor(apv_fh_1, "Profitdifferenz LW")
	profit_score.add_contributor(apv_fh_3, "Profitdifferenz LW", 3.0)
	profit_score.add_contributor(apv_bf_1, "Profitdifferenz LW")
	profit_score.add_contributor(apv_bf_3, "Profitdifferenz LW", 3.0)
	profit_score.add_contributor(apv_fh_1, "Stromerzeugung kWh", 0.07, Color.ALICE_BLUE, 0.03, 0.09)
	profit_score.add_contributor(apv_fh_3, "Stromerzeugung kWh", 0.07 * 3.0)
	profit_score.add_contributor(apv_fh_1, "Kosten")
	profit_score.add_contributor(apv_fh_3, "Kosten", 3.0)
	profit_score.add_contributor(apv_bf_1, "Stromerzeugung kWh", 0.07, Color.ALICE_BLUE, 0.03, 0.09)
	profit_score.add_contributor(apv_bf_3, "Stromerzeugung kWh", 0.07 * 3.0)
	profit_score.add_contributor(apv_bf_1, "Kosten")
	profit_score.add_contributor(apv_bf_3, "Kosten", 3.0)
	profit_score.target = 0.0
	profit_score.display_mode = GameScore.DisplayMode.ICONTEXT
	profit_score.icon_subject = "euro"
	profit_score.icon_descriptor = "sum"
	
	game_mode.add_score(profit_score)
	
	var power_score = UpdatingGameScore.new()
	power_score.name = "Stromerzeugung kWh 2030"
	power_score.add_contributor(apv_fh_1, "Stromerzeugung kWh")
	power_score.add_contributor(apv_fh_3, "Stromerzeugung kWh", 3.0)
	power_score.add_contributor(apv_bf_1, "Stromerzeugung kWh")
	power_score.add_contributor(apv_bf_3, "Stromerzeugung kWh", 3.0)
	power_score.target = power_target
	power_score.display_mode = GameScore.DisplayMode.PROGRESSBAR
	
	var power_score2 = UpdatingGameScore.new()
	power_score2.name = "Stromerzeugung kWh 2050"
	power_score2.add_contributor(apv_fh_1, "Stromerzeugung kWh")
	power_score2.add_contributor(apv_fh_3, "Stromerzeugung kWh", 3.0)
	power_score2.add_contributor(apv_bf_1, "Stromerzeugung kWh")
	power_score2.add_contributor(apv_bf_3, "Stromerzeugung kWh", 3.0)
	power_score2.target = power_target2
	power_score2.display_mode = GameScore.DisplayMode.PROGRESSBAR
	
	game_mode.add_score(power_score)
	game_mode.add_score(power_score2)
	
	var food_score = UpdatingGameScore.new()
	food_score.name = "Ernährte Personen"
	food_score.add_contributor(apv_fh_1, "Ernaehrte Personen")
	food_score.add_contributor(apv_fh_3, "Ernaehrte Personen", 3.0)
	food_score.add_contributor(apv_bf_1, "Ernaehrte Personen")
	food_score.add_contributor(apv_bf_3, "Ernaehrte Personen", 3.0)
	food_score.target = 0.0
	food_score.display_mode = GameScore.DisplayMode.ICONTEXT
	food_score.icon_descriptor = "grass"
	food_score.icon_subject = "person"
	
	game_mode.add_score(food_score)
	
	var power_score_households = UpdatingGameScore.new()
	power_score_households.name = "Versorgte Haushalte"
	power_score_households.add_contributor(apv_fh_1, "Stromerzeugung kWh", 1.0 / 4500.0)
	power_score_households.add_contributor(apv_fh_3, "Stromerzeugung kWh", 1.0 / 4500.0 * 3.0)
	power_score_households.add_contributor(apv_bf_1, "Stromerzeugung kWh", 1.0 / 4500.0)
	power_score_households.add_contributor(apv_bf_3, "Stromerzeugung kWh", 1.0 / 4500.0 * 3.0)
	power_score_households.target = 0.0
	power_score_households.display_mode = GameScore.DisplayMode.ICONTEXT
	power_score_households.icon_descriptor = "energy"
	power_score_households.icon_subject = "household"
	
	game_mode.add_score(power_score_households)
	
	GameSystem.current_game_mode = game_mode


func validate_gpkg(geopackage_path: String):
	if geopackage_path.is_empty():
		logger.error("User Geopackage path not set! Please set it in user://configuration.ini", LOG_MODULE)
		return false
	
	if not FileAccess.file_exists(geopackage_path):
		logger.error(
			"Path3D to geodataset \"%s\" does not exist, could not load any data!" % [geopackage_path],
			LOG_MODULE
		)
		return false
	
	geopackage = Geodot.get_dataset(geopackage_path)
	if !geopackage.is_valid():
		logger.error("Geodataset is not valid, could not load any data!", LOG_MODULE)
		return false
	
	return true
