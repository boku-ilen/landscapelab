extends Configurator

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

var center := Vector3.ZERO setget set_center
var geopackage
var external_layers = preload("res://Layers/ExternalLayer.gd").new()

const LOG_MODULE := "LAYERCONFIGURATION"

signal geodata_invalid
signal center_changed(x, y)


func set_center(c: Vector3):
	center = c
	emit_signal("center_changed", center.x, center.z)


func _ready():
	set_category("geodata")
	load_gpkg(get_setting("gpkg-path"))


# Gets called from main_ui
func check_default():
	set_category("geodata")
	if(not validate_gpkg(get_setting("gpkg-path"))):
		emit_signal("geodata_invalid")


func load_gpkg(geopackage_path: String):
	if(validate_gpkg(geopackage_path)):
		digest_gpkg(geopackage_path)
	else:
		emit_signal("geodata_invalid")
	
	# FIXME: Game Engine Testing
	var game_mode = GameMode.new()
	
	var wka = game_mode.add_game_object_collection_for_feature_layer("WKA", Layers.geo_layers["features"]["windmills"])
	game_mode.game_object_collections["WKA"].add_implicit_attribute_mapping("MW", Layers.geo_layers["rasters"]["windturbine_potentials"])
	game_mode.game_object_collections["WKA"].icon_name = "windmill_icon"
	game_mode.game_object_collections["WKA"].desired_shape = "SQUARE_BRICK"
	game_mode.game_object_collections["WKA"].desired_color = "BLUE_BRICK"
	
	var wka_condition = GreaterThanRasterCreationCondition.new("WKA Potential Condition", Layers.geo_layers["rasters"]["windturbine_potentials"], 0.0)
	wka.add_creation_condition(wka_condition)
	
	var pv_small = game_mode.add_game_object_collection_for_feature_layer("PV klein", Layers.geo_layers["features"]["pv_small"])
	game_mode.game_object_collections["PV klein"].add_implicit_attribute_mapping("MW", Layers.geo_layers["rasters"]["new_pv_potentials"])
	game_mode.game_object_collections["PV klein"].icon_name = "pv_icon"
	game_mode.game_object_collections["PV klein"].desired_shape = "SQUARE_BRICK"
	game_mode.game_object_collections["PV klein"].desired_color = "RED_BRICK"
	
	var pv_large = game_mode.add_game_object_collection_for_feature_layer("PV groß", Layers.geo_layers["features"]["pv_large"])
	game_mode.game_object_collections["PV groß"].add_implicit_attribute_mapping("MW", Layers.geo_layers["rasters"]["new_pv_potentials"])
	game_mode.game_object_collections["PV groß"].icon_name = "pv_icon"
	game_mode.game_object_collections["PV groß"].desired_shape = "RECTANGLE_BRICK"
	game_mode.game_object_collections["PV groß"].desired_color = "RED_BRICK"
	
	var pv_condition = GreaterThanRasterCreationCondition.new("PV Potential Condition", Layers.geo_layers["rasters"]["new_pv_potentials"], 0.0)
	pv_small.add_creation_condition(pv_condition)
	pv_large.add_creation_condition(pv_condition)

	game_mode.set_extent(569000.0, 380000.0, 599000.0, 410000.0)

	var score = GameScore.new()
	score.name = "Strom PV"
	score.add_contributor(game_mode.game_object_collections["PV groß"], "MW", 30.0)
	score.add_contributor(game_mode.game_object_collections["PV klein"], "MW", 10.0)
	score.target = 69726.0

	var score2 = GameScore.new()
	score2.name = "Strom WKA"
	score2.add_contributor(game_mode.game_object_collections["WKA"], "MW")
	score2.target = 222667.0

	game_mode.add_score(score2)
	game_mode.add_score(score)

	# Add player game object collection
	var player_game_object_collection = PlayerGameObjectCollection.new("Players", get_parent().get_node("FirstPersonPC"))
	game_mode.add_game_object_collection(player_game_object_collection)
	player_game_object_collection.icon_name = "player_position"
	player_game_object_collection.desired_shape = "SQUARE_BRICK"
	player_game_object_collection.desired_color = "GREEN_BRICK"

	GameSystem.current_game_mode = game_mode


func validate_gpkg(geopackage_path: String):
	if geopackage_path.empty():
		logger.error("User Geopackage path not set! Please set it in user://configuration.ini", LOG_MODULE)
		return false
	
	var file2Check = File.new()
	if !file2Check.file_exists(geopackage_path):
		logger.error(
			"Path to geodataset \"%s\" does not exist, could not load any data!" % [geopackage_path],
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
	
	var rasters = geopackage.get_raster_layers()
	logstring += "Raster layers in GeoPackage:\n"
	
	for raster in rasters:
		logstring += "- " + raster.resource_name + "\n"
	logstring += "\n"
	
	var features = geopackage.get_feature_layers()
	logstring += "Vector layers in GeoPackage:\n"
	
	for feature in features:
		logstring += "- " + feature.resource_name + "\n"
	
	logger.info(logstring, LOG_MODULE)

	logger.info("Opening geopackage as DB ...", LOG_MODULE)
	var db = SQLite.new()
	db.path = geopackage_path
	db.verbose_mode = OS.is_debug_build()
	db.open_db()
	
	# Load vegetation tables outside of the GPKG
	logger.info("Loading Vegetation tables from GPKG ...", LOG_MODULE)
	Vegetation.load_data_from_gpkg(db)
	
	# Load configuration for each layer as specified in GPKG
	logger.info("Starting to load layers ...", LOG_MODULE)
	# Duplication is necessary (SQLite plugin otherwise overwrites with the next query
	var layer_configs: Array = db.select_rows("LL_layer_configuration", "", ["*"]).duplicate()
	
	if layer_configs.empty():
		logger.error("No layer configuration found in the geopackage.", LOG_MODULE)
	
	# Load all geo_layers necessary for the configuration
	Layers.geo_layers = get_geolayers(db, geopackage)
	
	for layer_config in layer_configs:
		var layer: Layer
		
		var geo_layers_config = geo_layers_config_for_LL_layer(db, layer_config.id)
		
		# Call the corresponding function using the render-type as string
		layer = call(
			# e.g. load_realistic_terrain_layer(db, layer_config, geo_layers_config)
			"load_%s_layer" % Layer.RenderType.keys()[layer_config.render_type].to_lower(),
			db, layer_config, geo_layers_config
		)
		
		if layer:
			logger.info(
				"Added %s-layer: %s" % [Layer.RenderType.keys()[layer.render_type], layer.name],
				LOG_MODULE
			)
			Layers.add_layer(layer)
	
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
			
			if entry.empty():
				logger.error(
					"Tried to find a non-existing layer with id %d for scenario %s" 
					% [id.layer_id, scenario.name],
					LOG_MODULE
				)
				continue
			
			var layer_name = entry[0].name
			scenario.add_visible_layer_name(layer_name)
		
		Scenarios.add_scenario(scenario)
	
	db.close_db()
	logger.info("Closing geopackage as DB ...", LOG_MODULE)
	
	set_center(get_avg_center())
 

# Load all used geo-layers as defined by configuration
func get_geolayers(db, gpkg):
	var raster_layers = gpkg.get_raster_layers()
	var feature_layers = gpkg.get_feature_layers()
	
	# Load which external data sources concern which LL-layers
	var externals_config = db.select_rows(
		"LL_externalgeolayer_to_layer", "", ["*"]
	).duplicate()
	
	var rasters = {}
	var features = {}
	for raster in raster_layers:
		rasters[raster.resource_name] = raster
	
	for feature in feature_layers:
		features[feature.resource_name] = feature
	
	for external_config in externals_config:
		var layer = external_layers.external_to_geolayer_from_type(db, external_config)
		var layer_name = external_config.geolayer_path.get_basename()
		layer_name = layer_name.substr(layer_name.rfind("/") + 1)
		if layer is RasterLayer:
			rasters[layer_name] = layer
		else:
			features[layer_name] = layer
	
	return { "rasters": rasters, "features": features }


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
func get_georasterlayer_by_type(db, type: String, candidates: Array) -> Layer:
	var result = db.select_rows(
		"LL_geo_layer_type", 
		"name = '%s'" % [type], 
		["id"]
	)
	
	if result.empty():
		logger.error("Could not find layer-type %s" % [type], LOG_MODULE)
		return null
	
	var id = result[0].id
	
	for layer in candidates: 
		if layer and layer.geo_layer_type == id:
			var raster = RasterLayer.new()
			raster.geo_raster_layer = Layers.geo_layers["rasters"][layer.geolayer_name].clone()
			return raster
	return null


# Get the corresponding geolayer for the LL layer by a given type
# e.g. a basic-terrain consists of height and texture 
# => find dhm (digital height model) by type HEIGHT_LAYER, find ortho by type TEXTURE:LAYER
func get_geofeaturelayer_by_name(db, lname: String, candidates: Array) -> Layer:
	for layer in candidates: 
		if layer.ll_reference == lname:
			var feature = FeatureLayer.new()
			feature.geo_feature_layer = Layers.geo_layers["features"][layer.geolayer_name]
			return feature
	return null


func get_extension_by_key(db, key: String, layer_id) -> String:
	var value = db.select_rows(
		"LL_layer_configuration_extention", 
		"key = '%s' and layer_id = %d" % [key, layer_id], 
		["value"] 
	)
	
	if value.empty():
		logger.error("No extension with key %s." % [key], LOG_MODULE)
		return ""
	
	return value[0].value


func load_realistic_terrain_layer(db, layer_config, geo_layers_config) -> Layer:
	var terrain_layer = Layer.new()
	terrain_layer.render_type = Layer.RenderType.REALISTIC_TERRAIN
	terrain_layer.render_info = Layer.RealisticTerrainRenderInfo.new()
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


func load_basic_terrain_layer(db, layer_config, geo_layers_config) -> Layer:
	var terrain_layer = Layer.new()
	terrain_layer.render_type = Layer.RenderType.BASIC_TERRAIN
	terrain_layer.render_info = Layer.BasicTerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	terrain_layer.render_info.texture_layer = get_georasterlayer_by_type(
		db, "TEXTURE_LAYER", geo_layers_config.rasters)
	terrain_layer.name = layer_config.name
	
	return terrain_layer


func load_vegetation_layer(db, layer_config, geo_layers_config) -> Layer:
	var vegetation_layer = Layer.new()
	vegetation_layer.render_type = Layer.RenderType.VEGETATION
	vegetation_layer.render_info = Layer.VegetationRenderInfo.new()
	vegetation_layer.render_info.height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	vegetation_layer.render_info.landuse_layer = get_georasterlayer_by_type(
		db, "LANDUSE_LAYER", geo_layers_config.rasters)
	vegetation_layer.name = layer_config.name
	
	return vegetation_layer


func load_object_layer(db, layer_config, geo_layers_config, extended_as: Layer.ObjectRenderInfo = null) -> Layer:
	if get_extension_by_key(db, "extends_as", layer_config.id) == "WindTurbineRenderInfo":
		# If it is extended as Winturbine we recursively call this function again
		# without extension such that it creates the standard object-layer procedure
		if extended_as == null:
			return load_windmills(db, layer_config, geo_layers_config)

	var object_layer = FeatureLayer.new()
	object_layer.geo_feature_layer = get_geofeaturelayer_by_name(
		db, "objects", geo_layers_config.features)
	object_layer.render_type = Layer.RenderType.OBJECT
	
	if not extended_as:
		object_layer.render_info = Layer.ObjectRenderInfo.new()
	else:
		object_layer.render_info = extended_as
	
	var file_path_object_scene = get_extension_by_key(db, "object", layer_config.id)
	var object_scene
	if file_path_object_scene.ends_with(".tscn"):
		object_scene = load(file_path_object_scene)
	elif file_path_object_scene.ends_with(".obj"):
		# Load the material and mesh
		var material_path = file_path_object_scene.replace(".obj", ".mtl")
		var mesh = ObjParse.parse_obj(file_path_object_scene, material_path)
		
		# Put the resulting mesh into a node
		var mesh_instance = MeshInstance.new()
		mesh_instance.mesh = mesh
		
		# Pack the node into a scene
		object_scene = PackedScene.new()
		object_scene.pack(mesh_instance)
	else:
		logger.error("Not a valid format for object-layer!", LOG_MODULE)
		return FeatureLayer.new()
		
	object_layer.render_info.object = object_scene
	object_layer.render_info.ground_height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	object_layer.ui_info.name_attribute = "Beschreib"
	object_layer.name = layer_config.name
	
	
	return object_layer


func load_windmills(db, layer_config, geo_layers_config) -> Layer:
	var windmill_layer = load_object_layer(
		db, layer_config, geo_layers_config, Layer.WindTurbineRenderInfo.new())
	windmill_layer.render_info.height_attribute_name = get_extension_by_key(
		db, "height_attribute_name", layer_config.id)
	windmill_layer.render_info.diameter_attribute_name = get_extension_by_key(
		db, "diameter_attribute_name", layer_config.id)
	
	return windmill_layer


func load_polygon_layer(db, layer_config, geo_layers_config, extended_as: Layer.PolygonRenderInfo = null) -> Layer:
	if get_extension_by_key(db, "extends_as", layer_config.id) == "BuildingRenderInfo":
		if extended_as == null:
			return load_buildings(db, layer_config, geo_layers_config)
	
	var polygon_layer = FeatureLayer.new()
	polygon_layer.geo_feature_layer = get_geofeaturelayer_by_name(
		db, "polygons", geo_layers_config.features)
	polygon_layer.render_type = Layer.RenderType.POLYGON
	
	if not extended_as:
		polygon_layer.render_info = Layer.PolygonRenderInfo.new()
	else:
		polygon_layer.render_info = extended_as
	
	polygon_layer.render_info.height_attribute_name = get_extension_by_key(
		db, "height_attribute_name", layer_config.id)
	polygon_layer.render_info.ground_height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	polygon_layer.name = layer_config.name
	
	return polygon_layer


func load_buildings(db, layer_config,geo_layers_config) -> Layer:
	var building_layer = load_polygon_layer(db, layer_config, geo_layers_config, Layer.BuildingRenderInfo.new())
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


func load_path_layer(db, layer_config, geo_layers_config) -> Layer:
	var path_layer = FeatureLayer.new()
	path_layer.geo_feature_layer = get_geofeaturelayer_by_name(
		db, "paths", geo_layers_config.features)
	path_layer.render_type = Layer.RenderType.PATH
	path_layer.render_info = Layer.PathRenderInfo.new()
	path_layer.render_info.line_visualization = get_extension_by_key(
		db, "line_visualization", layer_config.id)
	path_layer.render_info.ground_height_layer = get_georasterlayer_by_type(
		db, "HEIGHT_LAYER", geo_layers_config.rasters)
	path_layer.name = layer_config.name
	
	return path_layer


# Loads a JSON containing paths to Objects in this format:
# {"object_name_1": "res://path/to/object1.tscn", "object_name_2": "path/to/object2.tscn"}
func load_object_JSON(json_string: String) -> Dictionary:
	var json = JSON.parse(json_string)
	var loaded_json = {}
	
	if json.error != OK:
		logger.error(
			"Could not parse JSON - try to validate your JSON entries in the package.",
			LOG_MODULE
		)
		return loaded_json
		
	for entry in json.result:
		loaded_json[entry] = load(json.result[entry])
	
	return loaded_json


func load_connected_object_layer(db, layer_config, geo_layers_config) -> Layer:
	var co_layer = FeatureLayer.new()
	co_layer.geo_feature_layer = get_geofeaturelayer_by_name(
		db, "objects", geo_layers_config.features)
	co_layer.render_type = Layer.RenderType.CONNECTED_OBJECT
	co_layer.render_info = Layer.ConnectedObjectInfo.new()
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


func get_avg_center():
	var center_avg := Vector3.ZERO
	var count := 0
	for layer in Layers.layers:
		for geolayer in Layers.layers[layer].render_info.get_geolayers():
			center_avg += geolayer.get_center()
			count += 1
	
	return center_avg / count
