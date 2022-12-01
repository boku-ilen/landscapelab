extends Configurator


var geopackage
var external_layers = preload("res://Layers/ExternalLayerComposition.gd").new()

const LOG_MODULE := "LAYERCONFIGURATION"

signal geodata_invalid
signal loading_finished


func _ready():
	category = "geodata"
	load_gpkg(get_setting("gpkg-path"))
	loading_finished.emit()


# Gets called from main_ui
func check_default():
	category = "geodata"
	if(not validate_gpkg(get_setting("gpkg-path"))):
		emit_signal("geodata_invalid")


func load_gpkg(geopackage_path: String):
	if(validate_gpkg(geopackage_path)):
		digest_gpkg(geopackage_path)
	else:
		emit_signal("geodata_invalid")
	
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


# Digests the information provided by the geopackage
func digest_gpkg(geopackage_path: String):
	geopackage = Geodot.get_dataset(geopackage_path)
	
	var logstring = "\n"
	
	var features = geopackage.get_feature_layers()
	logstring += "Vector layers in GeoPackage:\n"
	
	for feature in features:
		logstring += "- " + feature.resource_name + "\n"
	
	var rasters = geopackage.get_raster_layers()
	logstring += "Raster layers in GeoPackage:\n"
	
	for raster in rasters:
		logstring += "- " + raster.resource_name + "\n"
	
	logstring += "\n"
	
	logger.info(logstring, LOG_MODULE)

	logger.info("Opening geopackage as DB ...", LOG_MODULE)
	var db = SQLite.new()
	db.path = geopackage_path
	# FIXME: What's the new one? db.verbose_mode = OS.is_debug_build()
	db.open_db()
	
	# Load vegetation tables outside of the GPKG
	logger.info("Loading Vegetation tables from GPKG ...", LOG_MODULE)
	Vegetation.load_data_from_gpkg(db)
	
	# Load configuration for each layer as specified in GPKG
	logger.info("Starting to load layers ...", LOG_MODULE)
	# Duplication is necessary (SQLite plugin otherwise overwrites with the next query
	var layer_configs: Array = db.select_rows("LL_layer_configuration", "", ["*"]).duplicate()
	
	if layer_configs.is_empty():
		logger.error("No layer configuration found in the geopackage.", LOG_MODULE)
	
	# Load all geo_layers necessary for the configuration
	get_geolayers(db, geopackage)
	
	for layer_config in layer_configs:
		var layer_composition: LayerComposition
		
		var geo_layers_config = geo_layers_config_for_LL_layer(db, layer_config.id)
		
		# Call the corresponding function using the render-type as string
		layer_composition = call(
			# e.g. load_realistic_terrain_layer(db, layer_config, geo_layers_config)
			"load_%s_layer_composition" % LayerComposition.RenderType.keys()[layer_config.render_type].to_lower(),
			db, layer_config, geo_layers_config
		)
		
		if layer_composition:
			logger.info(
				"Added %s-layer-composition: %s" % [LayerComposition.RenderType.keys()[layer_composition.render_type], layer_composition.name],
				LOG_MODULE
			)
			Layers.add_layer_composition(layer_composition)
	
#	var raster = RasterLayer.new()
#	raster.geo_raster_layer = Layers.geo_layers["rasters"]["basemap"].clone()
#	var test = Layer.new()
#	test.render_type = Layer.RenderType.TWODIMENSIONAL
#	test.render_info = Layer.TwoDimensionalInfo.new()
#	test.render_info.texture_layer = raster
#	test.name = "map"
#	Layers.add_layer(test)
	
	# Loading Scenarios
	logger.info("Starting to load scenarios ...", LOG_MODULE)
	var scenario_configs: Array = db.select_rows("LL_scenarios", "", ["*"]).duplicate()
	for scenario_config in scenario_configs:
		var scenario = Scenario.new()
		scenario.name = scenario_config.name
		
		var layer_ids = db.select_rows(
			"LL_layer_to_scenario", 
			"scenario_id = %d" % [scenario_config.id], 
			["layer_id"] 
		).duplicate()
		
		for id in layer_ids:
			var entry = db.select_rows(
				"LL_layer_configuration", 
				"id = %d" % [id.layer_id], 
				["name"] 
			).duplicate()
			
			if entry.is_empty():
				logger.error(
					"Tried to find a non-existing layer with id %d for scenario %s" 
					% [id.layer_id, scenario.name],
					LOG_MODULE
				)
				continue
			
			var layer_name = entry[0].name
			scenario.add_visible_layer_name(layer_name)
			#FIXME: Hotfix
			scenario.add_visible_layer_name("map")
		
		Scenarios.add_scenario(scenario)
	
	db.close_db()
	logger.info("Closing geopackage as DB ...", LOG_MODULE)
 

# Load all used geo-layers as defined by configuration
func get_geolayers(db, gpkg):
	var raster_layers = gpkg.get_raster_layers()
	var feature_layers = gpkg.get_feature_layers()
	
	# Load which external data sources concern which LL-layers
	var externals_config = db.select_rows(
		"LL_externalgeolayer_to_layer", "", ["*"]
	).duplicate()
	
	for raster in raster_layers:
		Layers.add_geo_layer(raster)
	
	for feature in feature_layers:
		Layers.add_geo_layer(feature)
	
	for external_config in externals_config:
		var layer = external_layers.external_to_geolayer_from_type(db, external_config)
		var layer_name = external_config.geolayer_path.get_basename()
		layer_name = layer_name.substr(layer_name.rfind("/") + 1)
		#Layers.add_geo_layer(layer, layer is RasterLayerComposition)


# Find the connections of the primitive geolayers to a a specific LL layer
func geo_layers_config_for_LL_layer(db, LL_layer_id):
	# Load necessary raster geolayers from gpkg for the current LL layer
	var rasters_config = db.select_rows(
		"LL_georasterlayer_to_layer", 
		"layer_id = %d" % [LL_layer_id], 
		["geolayer_name, geo_layer_type"] 
	).duplicate()
	
	# Load necessary feature geolayers from gpkg for the current LL layer
	var features_config = db.select_rows(
		"LL_geofeaturelayer_to_layer", 
		"layer_id = %d" % [LL_layer_id], 
		["geolayer_name, ll_reference"] 
	).duplicate()
	
	# Load external feature data sources for the current LL layer
	var external_feature_config = db.select_rows(
		"LL_external_geofeaturelayer_to_layer",
		"layer_id = %d" % [LL_layer_id], 
		["geolayer_path, ll_reference"]
	).duplicate()
	
	# Load external raster data sources for the current LL layer
	var external_raster_config = db.select_rows(
		"LL_external_georasterlayer_to_layer",
		"layer_id = %d" % [LL_layer_id], 
		["geolayer_path, geo_layer_type"]
	).duplicate()
	
	var externals_config = external_feature_config + external_raster_config
	
	# Convert paths in the external config to file-name without extension
	for conf in externals_config:
		var layer_name = conf.geolayer_path.get_basename()
		layer_name = layer_name.substr(layer_name.rfind("/") + 1)
		conf.erase("geolayer_path")
		conf["geolayer_name"] = layer_name
	
	return { "rasters": rasters_config + external_raster_config,
			"features": features_config + external_feature_config }


# Get the corresponding geolayer for the LL layer by a given type
# e.g. a basic-terrain consists of height and texture 
# => find dhm (digital height model) by type HEIGHT_LAYER, find ortho by type TEXTURE:LAYER
func get_georasterlayer_by_type(db, type: String, candidates: Array) -> GeoRasterLayer:
	var result = db.select_rows(
		"LL_geo_layer_type", 
		"name = '%s'" % [type], 
		["id"]
	)
	
	if result.is_empty():
		logger.error("Could not find layer-type %s" % [type], LOG_MODULE)
		return null
	
	var id = result[0].id
	
	for layer in candidates: 
		if layer and layer.geo_layer_type == id:
			return Layers.geo_layers["rasters"][layer.geolayer_name].clone()
	return null


# Get the corresponding geolayer for the LL layer by a string
# e.g. ll_reference in db = "objects" => filter after this keyword
func get_geofeaturelayer_by_name(db, lname: String, candidates: Array) -> GeoFeatureLayer:
	for layer in candidates: 
		if layer.ll_reference == lname:
			return Layers.geo_layers["features"][layer.geolayer_name]
	return null


func get_extension_by_key(db, key: String, layer_id) -> String:
	var value = db.select_rows(
		"LL_layer_configuration_extention", 
		"key = '%s' and layer_id = %d" % [key, layer_id], 
		["value"] 
	)
	
	if value.is_empty():
		logger.error("No extension with key %s." % [key], LOG_MODULE)
		return ""
	
	return value[0].value


func load_realistic_terrain_layer_composition(db, layer_config, geo_layers_config) -> LayerComposition:
	var terrain_layer = LayerComposition.new()
	terrain_layer.render_type = LayerComposition.RenderType.REALISTIC_TERRAIN
	terrain_layer.render_info = LayerComposition.RealisticTerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	terrain_layer.render_info.texture_layer = get_georasterlayer_by_type(
		db, "TEXTURE_LAYER", geo_layers_config.rasters)
	terrain_layer.render_info.landuse_layer = get_georasterlayer_by_type(
		db, "LANDUSE_LAYER", geo_layers_config.rasters)
	terrain_layer.render_info.surface_height_layer = get_georasterlayer_by_type(
		db, "SURFACE_HEIGHT_LAYER", geo_layers_config.rasters)
	terrain_layer.name = layer_config.name
	
	return terrain_layer


func load_basic_terrain_layer_composition(db, layer_config, geo_layers_config) -> LayerComposition:
	var terrain_layer = LayerComposition.new()
	terrain_layer.render_type = LayerComposition.RenderType.BASIC_TERRAIN
	terrain_layer.render_info = LayerComposition.BasicTerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	terrain_layer.render_info.texture_layer = get_georasterlayer_by_type(
		db, "TEXTURE_LAYER", geo_layers_config.rasters)
	terrain_layer.name = layer_config.name
	
	return terrain_layer


func load_vegetation_layer_composition(db, layer_config, geo_layers_config) -> LayerComposition:
	var vegetation_layer = LayerComposition.new()
	vegetation_layer.render_type = LayerComposition.RenderType.NONE
	vegetation_layer.render_info = LayerComposition.RenderInfo.new()
#	vegetation_layer.render_type = LayerComposition.RenderType.VEGETATION
#	vegetation_layer.render_info = LayerComposition.VegetationRenderInfo.new()
#	var render_ifno = vegetation_layer.render_info
#	vegetation_layer.render_info.height_layer = get_georasterlayer_by_type(
#		db, "HEIGHT_LAYER", geo_layers_config.rasters)
#	vegetation_layer.render_info.landuse_layer = get_georasterlayer_by_type(
#		db, "LANDUSE_LAYER", geo_layers_config.rasters)
#	vegetation_layer.name = layer_config.name
	
	return vegetation_layer


func load_object_layer_composition(db, layer_config, geo_layers_config, extended_as = null) -> LayerComposition:
	if get_extension_by_key(db, "extends_as", layer_config.id) == "WindTurbineRenderInfo":
		# If it is extended as Winturbine we recursively call this function again
		# without extension such that it creates the standard object-layer procedure
		if extended_as == null:
			return load_windmills(db, layer_config, geo_layers_config)

	var object_layer = LayerComposition.new()
	object_layer.render_type = LayerComposition.RenderType.OBJECT
	
	if not extended_as:
		object_layer.render_info = LayerComposition.ObjectRenderInfo.new()
	else:
		object_layer.render_info = extended_as
	
	object_layer.render_info.geo_feature_layer = get_geofeaturelayer_by_name(
		db, "objects", geo_layers_config.features)
	var file_path_object_scene = get_extension_by_key(db, "object", layer_config.id)
	var object_scene
	if file_path_object_scene.ends_with(".tscn"):
		object_scene = load(file_path_object_scene)
	elif file_path_object_scene.ends_with(".obj"):
		# Load the material and mesh
		var material_path = file_path_object_scene.replace(".obj", ".mtl")
		var mesh = BoxMesh.new() # FIXME: ObjParse.parse_obj(file_path_object_scene, material_path)
		
		# Put the resulting mesh into a node
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		
		# Pack the node into a scene
		object_scene = PackedScene.new()
		object_scene.pack(mesh_instance)
	else:
		logger.error("Not a valid format for object-layer!", LOG_MODULE)
		return LayerComposition.new()
		
	object_layer.render_info.object = object_scene
	object_layer.render_info.ground_height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	# FIXME: should come from geopackage -> no hardcoding
	object_layer.ui_info.name_attribute = "Name"
	object_layer.name = layer_config.name
	
	
	return object_layer


func load_windmills(db, layer_config, geo_layers_config) -> LayerComposition:
	var windmill_layer = load_object_layer_composition(
		db, layer_config, geo_layers_config, LayerComposition.WindTurbineRenderInfo.new())
	windmill_layer.render_info.height_attribute_name = get_extension_by_key(
		db, "height_attribute_name", layer_config.id)
	windmill_layer.render_info.diameter_attribute_name = get_extension_by_key(
		db, "diameter_attribute_name", layer_config.id)
	
	return windmill_layer


func load_polygon_layer_composition(db, layer_config, geo_layers_config, extended_as = null) -> LayerComposition:
	if get_extension_by_key(db, "extends_as", layer_config.id) == "BuildingRenderInfo":
		if extended_as == null:
			return load_buildings(db, layer_config, geo_layers_config)
	
	var polygon_layer = LayerComposition.new()
	polygon_layer.render_type = LayerComposition.RenderType.POLYGON
	
	if not extended_as:
		polygon_layer.render_info = LayerComposition.PolygonRenderInfo.new()
	else:
		polygon_layer.render_info = extended_as
	
	polygon_layer.render_info.geo_feature_layer = get_geofeaturelayer_by_name(
		db, "polygons", geo_layers_config.features)
	polygon_layer.render_info.height_attribute_name = get_extension_by_key(
		db, "height_attribute_name", layer_config.id)
	polygon_layer.render_info.ground_height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	polygon_layer.name = layer_config.name
	
	return polygon_layer


func load_buildings(db, layer_config,geo_layers_config) -> LayerComposition:
	var building_layer = load_polygon_layer_composition(db, layer_config, geo_layers_config, LayerComposition.BuildingRenderInfo.new())
	building_layer.render_info.height_stdev_attribute_name  = get_extension_by_key(
		db, "height_stdev_attribute_name", layer_config.id)
	building_layer.render_info.slope_attribute_name  = get_extension_by_key(
		db, "slope_attribute_name", layer_config.id)
	building_layer.render_info.red_attribute_name = get_extension_by_key(
		db, "red_attribute_name", layer_config.id)
	building_layer.render_info.green_attribute_name = get_extension_by_key(
		db, "green_attribute_name", layer_config.id)
	building_layer.render_info.blue_attribute_name = get_extension_by_key(
		db, "blue_attribute_name", layer_config.id)
	
	return building_layer


func load_path_layer_composition(db, layer_config, geo_layers_config) -> LayerComposition:
	var path_layer = LayerComposition.new()
	
	path_layer.render_type = LayerComposition.RenderType.PATH
	path_layer.render_info = LayerComposition.PathRenderInfo.new()
	path_layer.render_info.geo_feature_layer = get_geofeaturelayer_by_name(
		db, "paths", geo_layers_config.features)
	path_layer.render_info.line_visualization = load(get_extension_by_key(
		db, "line_visualization", layer_config.id))
	path_layer.render_info.ground_height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	path_layer.name = layer_config.name
	
	return path_layer


# Loads a JSON containing paths to Objects in this format:
# {"object_name_1": "res://path/to/object1.tscn", "object_name_2": "path/to/object2.tscn"}
func load_object_JSON(json_string: String) -> Dictionary:
	var test_json_conv = JSON.new()
	var error = test_json_conv.parse(json_string)
	var json = test_json_conv.get_data()
	var loaded_json = {}
	
	if error != OK:
		logger.error(
			"Could not parse JSON - try to validate your JSON entries in the package.",
			LOG_MODULE
		)
		return loaded_json
		
	for entry in json:
		loaded_json[entry] = load(json[entry])
	
	return loaded_json


func load_connected_object_layer_composition(db, layer_config, geo_layers_config) -> LayerComposition:
	var co_layer = LayerComposition.new()
	co_layer.render_type = LayerComposition.RenderType.CONNECTED_OBJECT
	co_layer.render_info = LayerComposition.ConnectedObjectInfo.new()
	co_layer.render_info.geo_feature_layer = get_geofeaturelayer_by_name(
		db, "objects", geo_layers_config.features)
	co_layer.render_info.selector_attribute_name = get_extension_by_key(
		db, "selector_attribute_name", layer_config.id)
	# FIXME: There might be more appealing ways than storing a json as varchar in the db ...
	# https://imgur.com/9ZJkPvV
	co_layer.render_info.connectors = load_object_JSON(get_extension_by_key(
		db, "connectors", layer_config.id))
	co_layer.render_info.connections = load_object_JSON(get_extension_by_key(
		db, "connections", layer_config.id))
	co_layer.render_info.fallback_connector = load(get_extension_by_key(
		db, "fallback_connector", layer_config.id))
	co_layer.render_info.fallback_connection = load(get_extension_by_key(
		db, "fallback_connection", layer_config.id))
	co_layer.render_info.ground_height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	co_layer.name = layer_config.name
	
	return co_layer


func load_twodimensional_layer_composition(db, layer_config, geo_layers_config) -> LayerComposition:
	var layer_2d = LayerComposition.new()
	layer_2d.render_type = LayerComposition.RenderType.TWODIMENSIONAL
	layer_2d.render_info = LayerComposition.TwoDimensionalInfo.new()
	layer_2d.render_info.texture_layer = get_georasterlayer_by_type(
		db, "TEXTURE_LAYER", geo_layers_config.rasters)
	layer_2d.name = layer_config.name
	
	return layer_2d
