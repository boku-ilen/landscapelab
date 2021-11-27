extends Configurator


var geodataset
var center


func _ready():
	set_category("geodata")
	add_test_data()


# Adds static test data; will be removed as soon as we have a valid GeoPackage.
func add_test_data():
	var geopackage_path = get_setting("gpkg-path")
	
	# TODO: Load the GeoPackage automatically
#	base_path = OS.get_executable_path().get_base_dir()
#	var base_dir = Directory.new()
#	base_dir.open(base_path)
#	base_dir.list_dir_begin()
#	while true:
#		var file = base_dir.get_next()
#		if file == "":
#			break
#		elif file.begins_with("LL_") and (file.ends_with(".gpkg") or file.ends_with(".gpkgx")):
#			geopackage = base_path + "/" + file
#			break
#	base_dir.list_dir_end()
#
#	# if we could not find a geopackage we can not continue
#	if geopackage == "":
#		logger.error("Could not find a valid geopackage! It has to be in the format of LL_<name>.gpkg[x]")
#		#get_tree().quit()
	
	if geopackage_path.empty():
		logger.error("User Geopackage path not set! Please set it in user://configuration.ini")
		return
	
	var file2Check = File.new()
	if !file2Check.file_exists(geopackage_path):
		logger.error("Path to geodataset \"%s\" does not exist, could not load any data!" % [geopackage_path])
		return
	
	var geopackage = Geodot.get_dataset(geopackage_path)
	if !geopackage.is_valid():
		logger.error("Geodataset is not valid, could not load any data!")
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
	
	logger.info(logstring)


	# Heightmap
	var height_layer = RasterLayer.new()
	height_layer.geo_raster_layer = geopackage.get_raster_layer("dhm")
	height_layer.name = "DHM"
	
	# Orthophoto
	var ortho_layer = RasterLayer.new()
	ortho_layer.geo_raster_layer = geopackage.get_raster_layer("ortho")
	ortho_layer.name = "Ortho"
	
	# Land use
	var landuse_layer = RasterLayer.new()
	landuse_layer.geo_raster_layer = geopackage.get_raster_layer("landuse")
	landuse_layer.name = "Land Use"
	
	# Surface Heightmap
	var surface_height_layer = RasterLayer.new()
	surface_height_layer.geo_raster_layer = geopackage.get_raster_layer("ndom")
	surface_height_layer.name = "nDSM"
	
	# Topomap
	var topomap_layer = RasterLayer.new()
	topomap_layer.geo_raster_layer = geopackage.get_raster_layer("map")
	topomap_layer.name = "Map"
	
#	# Precipitation
#	var precipitation_layer = RasterLayer.new()
#	precipitation_layer.geo_raster_layer = Geodot.get_raster_layer("C:\\boku\\geodata\\Niederschlag\\ooe\\Niederschlagssumme_Jahresmittel_1981_2010.tif")
#	precipitation_layer.name = "Precipitation"
	
	# Realistic Terrain layer
	var terrain_layer = Layer.new()
	terrain_layer.render_type = Layer.RenderType.REALISTIC_TERRAIN
	terrain_layer.render_info = Layer.RealisticTerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = height_layer.clone()
	terrain_layer.render_info.texture_layer = ortho_layer.clone()
	terrain_layer.render_info.landuse_layer = landuse_layer.clone()
	terrain_layer.render_info.surface_height_layer = surface_height_layer.clone()
	terrain_layer.name = "Realistic Terrain"
	
	# Minimap Terrain layer
	var map_layer = Layer.new()
	map_layer.render_type = Layer.RenderType.BASIC_TERRAIN
	map_layer.render_info = Layer.BasicTerrainRenderInfo.new()
	map_layer.render_info.height_layer = height_layer.clone()
	map_layer.render_info.texture_layer = topomap_layer.clone()
	map_layer.name = "Map"
	
	# TODO: Consider using the average center of all layers?
	center = height_layer.get_center()
	
#	# Basic Terrain layer
#	var bterrain_layer = Layer.new()
#	bterrain_layer.render_type = Layer.RenderType.BASIC_TERRAIN
#	bterrain_layer.render_info = Layer.BasicTerrainRenderInfo.new()
#	bterrain_layer.render_info.height_layer = height_layer.clone()
#	bterrain_layer.render_info.texture_layer = ortho_layer.clone()
#	bterrain_layer.name = "Basic Terrain"
#
#	# Data Shaded Terrain layer
#	var data_terrain_layer = Layer.new()
#	data_terrain_layer.render_type = Layer.RenderType.BASIC_TERRAIN
#	data_terrain_layer.render_info = Layer.BasicTerrainRenderInfo.new()
#	data_terrain_layer.render_info.height_layer = height_layer.clone()
#	data_terrain_layer.render_info.texture_layer = precipitation_layer.clone()
#	data_terrain_layer.render_info.is_color_shaded = true
#	data_terrain_layer.render_info.max_color = Color(0.8, 0, 0)
#	data_terrain_layer.render_info.min_color = Color(0, 0.8, 0)
#	data_terrain_layer.render_info.alpha = 1.0
#	data_terrain_layer.name = "Data shaded Terrain"
#
	# Building layer
	var building_layer = FeatureLayer.new()
	building_layer.geo_feature_layer = geopackage.get_feature_layer("buildings")
	building_layer.render_type = Layer.RenderType.POLYGON
	building_layer.render_info = Layer.BuildingRenderInfo.new()
	building_layer.render_info.height_attribute_name = "ndom_mean"
	building_layer.render_info.height_stdev_attribute_name = "ndom_stdev"
	building_layer.render_info.slope_attribute_name = "slope_mean"
	building_layer.render_info.red_attribute_name = "r_median"
	building_layer.render_info.green_attribute_name = "g_median"
	building_layer.render_info.blue_attribute_name = "b_median"
	building_layer.render_info.ground_height_layer = height_layer.clone()
	building_layer.name = "Buildings"

	# Vegetation
	var vegetation_layer = Layer.new()
	vegetation_layer.name = "Vegetation"
	vegetation_layer.render_type = Layer.RenderType.VEGETATION
	vegetation_layer.render_info = Layer.VegetationRenderInfo.new()
	vegetation_layer.render_info.height_layer = height_layer.clone()
	vegetation_layer.render_info.landuse_layer = landuse_layer.clone()
	
	# FIXME: Rare crash caused by GeoPackage (SQLite Feature fetching causes DB error), that's why
	# we load these vector features like this for now
	var data_prefix = "C:/boku/geodata/"
	
	# Test Point Data
	var windmills_repower = get_windmill_layer(
		data_prefix + "WKA_koordinaten_LAMB/WKA_NeuWei_Repower.shp",
		"WKA_NeuWei_Repower",
		"WKA Repowering",
		height_layer)
	
	var windmills_repower_large = get_windmill_layer(
		data_prefix + "WKA_koordinaten_LAMB/WKA_NeuWei_Repower_Large.shp",
		"WKA_NeuWei_Repower_Large",
		"WKA Repowering alle groß",
		height_layer)
	
	var windmills_repower_surrounding1 = get_windmill_layer(
		data_prefix + "WKA_koordinaten_LAMB/WKA_Umgebung_Repower.shp",
		"WKA_Umgebung_Repower",
		"WKA Repowering Umgebung Repower",
		height_layer)
	
	var windmills_repower_surrounding2 = get_windmill_layer(
		data_prefix + "WKA_koordinaten_LAMB/WKA_Umgebung_bleibt.shp",
		"WKA_Umgebung_bleibt",
		"WKA Repowering Umgebung Bleibt",
		height_layer)
	
	var windmills_old = get_windmill_layer(
		data_prefix + "WKA_koordinaten_LAMB/WKA_NeuWei_Bestand.shp",
		"WKA_NeuWei_Bestand",
		"WKA Bestand",
		height_layer)
	
	var windmills_old_surrounding = get_windmill_layer(
		data_prefix + "WKA_koordinaten_LAMB/WKA_Umgebung_2020.shp",
		"WKA_Umgebung_2020",
		"WKA Bestand Umgebung",
		height_layer)

	var poi = FeatureLayer.new()
	var poi_dataset = Geodot.get_dataset(data_prefix + "Aussichtspunkte/Aussichtspunkte_AL.shp")
	poi.geo_feature_layer = poi_dataset.get_feature_layer("Aussichtspunkte_AL")
	poi.render_type = Layer.RenderType.OBJECT
	poi.render_info = Layer.ObjectRenderInfo.new()
	poi.render_info.object = preload("res://Objects/Util/Marker.tscn")
	poi.render_info.ground_height_layer = height_layer.clone()
	poi.ui_info.name_attribute = "Beschreib"
	poi.name = "Aussichtspunkte"
	
#	# Test Line Data
#	var water_layer = FeatureLayer.new()
#	var water_dataset = Geodot.get_dataset("C:\\boku\\geodata\\test_data\\ooe\\water_ooe.shp")
#	water_layer.geo_feature_layer = water_dataset.get_feature_layer("water_ooe")
#	water_layer.render_type = Layer.RenderType.PATH
#	water_layer.render_info = Layer.PathRenderInfo.new()
#	water_layer.render_info.line_visualization = load("res://Resources/Profiles/Water.tscn")
#	water_layer.render_info.ground_height_layer = height_layer.clone()
#	water_layer.name = "River"
#
#	# Test Line Data
#	var street_layer = FeatureLayer.new()
#	var street_dataset = Geodot.get_dataset("C:\\boku\\geodata\\test_data\\ooe\\ooe_line_test.shp")
#	street_layer.geo_feature_layer = street_dataset.get_feature_layer("ooe_line_test")
#	street_layer.render_type = Layer.RenderType.PATH
#	street_layer.render_info = Layer.PathRenderInfo.new()
#	street_layer.render_info.line_visualization = load("res://Resources/Profiles/Water.tscn")
#	street_layer.render_info.ground_height_layer = height_layer.clone()
#	street_layer.name = "Streets"

	# Test Line Data
	var ppole_layer = FeatureLayer.new()
	ppole_layer.geo_feature_layer = geopackage.get_feature_layer("power_lines")
	ppole_layer.render_type = Layer.RenderType.CONNECTED_OBJECT
	ppole_layer.render_info = Layer.ConnectedObjectInfo.new()
	ppole_layer.render_info.selector_attribute_name = "power"
	ppole_layer.render_info.connectors = {
		"minor_line": load("res://Objects/Power/LowVoltagePowerPole.tscn"),
		"line": load("res://Objects/Power/HighVoltagePowerLine.tscn")
	}
	ppole_layer.render_info.fallback_connector = load("res://Objects/Power/LowVoltagePowerPole.tscn")
	ppole_layer.render_info.fallback_connection = load("res://Objects/Connection/MetalSteelCable.tscn")
	ppole_layer.render_info.ground_height_layer = height_layer.clone()
	ppole_layer.name = "Power poles"

	# Add the layers
#	Layers.add_layer(precipitation_layer)
#	Layers.add_layer(data_terrain_layer)
#	Layers.add_layer(bterrain_layer)
	Layers.add_layer(windmills_repower)
	Layers.add_layer(windmills_repower_large)
	Layers.add_layer(windmills_repower_surrounding1)
	Layers.add_layer(windmills_repower_surrounding2)
	Layers.add_layer(windmills_old)
	Layers.add_layer(windmills_old_surrounding)
	Layers.add_layer(poi)
#	Layers.add_layer(water_layer)
#	Layers.add_layer(ppole_layer)
#	Layers.add_layer(street_layer)
	Layers.add_layer(height_layer)
	Layers.add_layer(ortho_layer)
	Layers.add_layer(surface_height_layer)
	Layers.add_layer(landuse_layer)
	Layers.add_layer(terrain_layer)
	Layers.add_layer(building_layer)
	Layers.add_layer(vegetation_layer)
	Layers.add_layer(topomap_layer)
	Layers.add_layer(map_layer)
	
	var scenario1 = Scenario.new()
	scenario1.name = "Repowering"
	scenario1.add_visible_layer_name(windmills_repower.name)
	scenario1.add_visible_layer_name(windmills_repower_surrounding1.name)
	scenario1.add_visible_layer_name(windmills_repower_surrounding2.name)
	scenario1.add_visible_layer_name(terrain_layer.name)
	scenario1.add_visible_layer_name(building_layer.name)
	scenario1.add_visible_layer_name(vegetation_layer.name)
	
	var scenario2 = Scenario.new()
	scenario2.name = "Bestand"
	scenario2.add_visible_layer_name(windmills_old.name)
	scenario2.add_visible_layer_name(windmills_old_surrounding.name)
	scenario2.add_visible_layer_name(terrain_layer.name)
	scenario2.add_visible_layer_name(building_layer.name)
	scenario2.add_visible_layer_name(vegetation_layer.name)
	
	var scenario3 = Scenario.new()
	scenario3.name = "Repowering alle Groß"
	scenario3.add_visible_layer_name(windmills_repower_large.name)
	scenario3.add_visible_layer_name(windmills_repower_surrounding1.name)
	scenario3.add_visible_layer_name(windmills_repower_surrounding2.name)
	scenario3.add_visible_layer_name(terrain_layer.name)
	scenario3.add_visible_layer_name(building_layer.name)
	scenario3.add_visible_layer_name(vegetation_layer.name)
	
	var scenario4 = Scenario.new()
	scenario4.name = "Karte"
	scenario4.add_visible_layer_name(map_layer.name)
	
	Scenarios.add_scenario(scenario1)
	Scenarios.add_scenario(scenario2)
	Scenarios.add_scenario(scenario3)
	Scenarios.add_scenario(scenario4)
	
	scenario2.activate()


func get_windmill_layer(path, geo_layer_name, readable_layer_name, height_layer):
	# Test Point Data
	var windmill_layer = FeatureLayer.new()
	var dataset = Geodot.get_dataset(path)
	windmill_layer.geo_feature_layer = dataset.get_feature_layer(geo_layer_name)
	windmill_layer.render_type = Layer.RenderType.OBJECT
	windmill_layer.render_info = Layer.WindTurbineRenderInfo.new()
	windmill_layer.render_info.object = preload("res://Objects/WindTurbine/GenericWindTurbine.tscn")
	windmill_layer.render_info.ground_height_layer = height_layer.clone()
	windmill_layer.render_info.height_attribute_name = "Nabenhoehe"
	windmill_layer.render_info.diameter_attribute_name = "Rotordurch"
	windmill_layer.name = readable_layer_name
	
	return windmill_layer
