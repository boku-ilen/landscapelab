extends Configurator

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

var geodataset
var center := Vector3.ZERO
var geopackage

const LOG_MODULE := "LAYERCONFIGURATION"


func _ready():
	set_category("geodata")
	digest_geopackage()


# Digests the information provided by the geopackage
func digest_geopackage():
	var geopackage_path = get_setting("gpkg-path")

	if geopackage_path.empty():
		logger.error("User Geopackage path not set! Please set it in user://configuration.ini", LOG_MODULE)
		return

	var file2Check = File.new()
	if !file2Check.file_exists(geopackage_path):
		logger.error(
			"Path to geodataset \"%s\" does not exist, could not load any data!" % [geopackage_path],
			LOG_MODULE
		)
		return
	
	geopackage = Geodot.get_dataset(geopackage_path)
	if !geopackage.is_valid():
		logger.error("Geodataset is not valid, could not load any data!", LOG_MODULE)
		return
	
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
	
	for layer_config in layer_configs:
		var layer: Layer
		
		var raster_layers = db.select_rows(
			"LL_georasterlayer_to_layer", 
			"layer_id = %d" % [layer_config.id], 
			["*"] 
		).duplicate()
		
		var feature_layers = db.select_rows(
			"LL_geofeaturelayer_to_layer", 
			"layer_id = %d" % [layer_config.id], 
			["*"] 
		).duplicate()
		
		match layer_config.render_type:
			Layer.RenderType.REALISTIC_TERRAIN:
				layer = load_realistic_terrain(db, layer_config, raster_layers)
			
			Layer.RenderType.BASIC_TERRAIN:
				layer = load_basic_terrain(db, layer_config, raster_layers)
			
			Layer.RenderType.OBJECT:
				match get_extension_by_key(db, "extends_as", layer_config.id):
					"WindTurbineRenderInfo":
						layer = load_windmills(db, layer_config, feature_layers, raster_layers)
					_: 
						layer = load_object_layer(db, layer_config, feature_layers, raster_layers)
			
			Layer.RenderType.PATH:
				# FIXME: allow different path-types per layer
				layer = load_path_layer(db, layer_config, feature_layers, raster_layers)
			
			Layer.RenderType.CONNECTED_OBJECT:
				layer = load_connected_object_layer(db, layer_config, feature_layers, raster_layers)
			
			Layer.RenderType.POLYGON:
				match get_extension_by_key(db, "extends_as", layer_config.id):
					"BuildingRenderInfo":
						layer = load_buildings(db, layer_config, feature_layers, raster_layers)
					_:
						layer = load_polygon_layer(db, layer_config, feature_layers, raster_layers)
			
			Layer.RenderType.VEGETATION:
				# FIXME: write the vegetation csvs into the geopackage
				layer = load_vegetation_layer(db, layer_config, raster_layers)
		
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

	center = get_avg_center()


func get_geolayer_name_by_type(db, type: String, candidates: Array, is_raster := true) -> Layer:
	var type_dict = db.select_rows(
		"LL_geo_layer_type", 
		"name = '%s'" % [type], 
		["id"] 
	)
	
	if type_dict.empty():
		logger.error("Could not find layer-type %s" % [type], LOG_MODULE)
		return null
	
	for layer in candidates: 
		if layer.geo_layer_type == type_dict[0].id:
			if is_raster:
				var raster = RasterLayer.new()
				raster.geo_raster_layer = geopackage.get_raster_layer(layer.geolayer_name)
				return raster
			else: 
				var feature = FeatureLayer.new()
				feature.geo_feature_layer = geopackage.get_feature_layer(layer.geolayer_name)
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


func load_realistic_terrain(db, layer_config, raster_layers) -> Layer:
	var terrain_layer = Layer.new()
	terrain_layer.render_type = Layer.RenderType.REALISTIC_TERRAIN
	terrain_layer.render_info = Layer.RealisticTerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = get_geolayer_name_by_type(db, "HEIGHT_LAYER", raster_layers)
	terrain_layer.render_info.texture_layer = get_geolayer_name_by_type(db, "TEXTURE_LAYER", raster_layers)
	terrain_layer.render_info.landuse_layer = get_geolayer_name_by_type(db, "LANDUSE_LAYER", raster_layers)
	terrain_layer.render_info.surface_height_layer = get_geolayer_name_by_type(db, "SURFACE_HEIGHT_LAYER", raster_layers)
	terrain_layer.name = layer_config.name
	
	return terrain_layer


func load_basic_terrain(db, layer_config, raster_layers) -> Layer:
	var terrain_layer = Layer.new()
	terrain_layer.render_type = Layer.RenderType.BASIC_TERRAIN
	terrain_layer.render_info = Layer.BasicTerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = get_geolayer_name_by_type(db, "HEIGHT_LAYER", raster_layers)
	terrain_layer.render_info.texture_layer = get_geolayer_name_by_type(db, "TEXTURE_LAYER", raster_layers)
	terrain_layer.name = layer_config.name
	
	return terrain_layer


func load_vegetation_layer(db, layer_config, raster_layers) -> Layer:
	var vegetation_layer = Layer.new()
	vegetation_layer.render_type = Layer.RenderType.VEGETATION
	vegetation_layer.render_info = Layer.VegetationRenderInfo.new()
	vegetation_layer.render_info.height_layer = get_geolayer_name_by_type(db, "HEIGHT_LAYER", raster_layers)
	vegetation_layer.render_info.landuse_layer = get_geolayer_name_by_type(db, "LANDUSE_LAYER", raster_layers)
	vegetation_layer.name = layer_config.name
	
	return vegetation_layer


func load_object_layer(db, layer_config, feature_layers, raster_layers, extended_as: Layer.ObjectRenderInfo = null) -> Layer:
	var object_layer = FeatureLayer.new()
	object_layer.geo_feature_layer = get_geolayer_name_by_type(db, "FEATURE_LAYER", feature_layers, false)
	object_layer.render_type = Layer.RenderType.OBJECT
	
	if not extended_as:
		object_layer.render_info = Layer.ObjectRenderInfo.new()
	else:
		object_layer.render_info = extended_as
	
	object_layer.render_info.object = load(get_extension_by_key(db, "object", layer_config.id))
	object_layer.render_info.ground_height_layer = get_geolayer_name_by_type(db, "HEIGHT_LAYER", raster_layers)
	object_layer.ui_info.name_attribute = "Beschreib"
	object_layer.name = layer_config.name
	
	return object_layer


func load_windmills(db, layer_config, feature_layers, raster_layers) -> Layer:
	var windmill_layer = load_object_layer(db, layer_config, feature_layers, raster_layers, Layer.WindTurbineRenderInfo.new())
	windmill_layer.render_info.height_attribute_name = get_extension_by_key(db, "height_attribute_name", layer_config.id)
	windmill_layer.render_info.diameter_attribute_name = get_extension_by_key(db, "diameter_attribute_name", layer_config.id)
	
	return windmill_layer


func load_polygon_layer(db, layer_config, feature_layers, raster_layers, extended_as: Layer.PolygonRenderInfo = null) -> Layer:
	var polygon_layer = FeatureLayer.new()
	polygon_layer.geo_feature_layer = get_geolayer_name_by_type(db, "FEATURE_LAYER", feature_layers, false)
	polygon_layer.render_type = Layer.RenderType.POLYGON
	
	if not extended_as:
		polygon_layer.render_info = Layer.PolygonRenderInfo.new()
	else:
		polygon_layer.render_info = extended_as
	
	polygon_layer.render_info.height_attribute_name = get_extension_by_key(db, "height_attribute_name", layer_config.id)
	polygon_layer.render_info.ground_height_layer = get_geolayer_name_by_type(db, "HEIGHT_LAYER", raster_layers)
	polygon_layer.name = layer_config.name
	
	return polygon_layer


func load_buildings(db, layer_config, feature_layers, raster_layers) -> Layer:
	var building_layer = load_polygon_layer(db, layer_config, feature_layers, raster_layers, Layer.BuildingRenderInfo.new())
	building_layer.render_info.height_stdev_attribute_name  = get_extension_by_key(db, "height_stdev_attribute_name", layer_config.id)
	building_layer.render_info.slope_attribute_name  = get_extension_by_key(db, "slope_attribute_name", layer_config.id)
	building_layer.render_info.red_attribute_name = get_extension_by_key(db, "red_attribute_name", layer_config.id)
	building_layer.render_info.green_attribute_name = get_extension_by_key(db, "green_attribute_name", layer_config.id)
	building_layer.render_info.blue_attribute_name = get_extension_by_key(db, "blue_attribute_name", layer_config.id)
	
	return building_layer


func load_path_layer(db, layer_config, feature_layers, raster_layers) -> Layer:
	var path_layer = FeatureLayer.new()
	path_layer.geo_feature_layer = get_geolayer_name_by_type(db, "FEATURE_LAYER", feature_layers, false)
	path_layer.render_type = Layer.RenderType.PATH
	path_layer.render_info = Layer.PathRenderInfo.new()
	path_layer.render_info.line_visualization = get_extension_by_key(db, "line_visualization", layer_config.id)
	path_layer.render_info.ground_height_layer = get_geolayer_name_by_type(db, "HEIGHT_LAYER", raster_layers)
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


func load_connected_object_layer(db, layer_config, feature_layers, raster_layers) -> Layer:
	var co_layer = FeatureLayer.new()
	co_layer.geo_feature_layer = get_geolayer_name_by_type(db, "FEATURE_LAYER", feature_layers, false)
	co_layer.render_type = Layer.RenderType.CONNECTED_OBJECT
	co_layer.render_info = Layer.ConnectedObjectInfo.new()
	co_layer.render_info.selector_attribute_name = get_extension_by_key(db, "selector_attribute_name", layer_config.id)
	# FIXME: There might be more appealing ways than storing a json as varchar in the db ...
	# https://imgur.com/9ZJkPvV
	co_layer.render_info.connectors = load_object_JSON(get_extension_by_key(db, "connectors", layer_config.id))
	co_layer.render_info.connections = load_object_JSON(get_extension_by_key(db, "connections", layer_config.id))
	co_layer.render_info.fallback_connector = load(get_extension_by_key(db, "fallback_connector", layer_config.id))
	co_layer.render_info.fallback_connection = load(get_extension_by_key(db, "fallback_connection", layer_config.id))
	co_layer.render_info.ground_height_layer = get_geolayer_name_by_type(db, "HEIGHT_LAYER", raster_layers)
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
