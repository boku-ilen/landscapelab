extends Configurator


var geodataset


func _ready():
	set_category("geodata")
	add_test_data()


# Adds static test data; will be removed as soon as we have a valid GeoPackage.
func add_test_data():
	var geopackage_path = get_setting("gpkg-path")
	
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
	
	# Realistic Terrain layer
	var terrain_layer = Layer.new()
	terrain_layer.render_type = Layer.RenderType.REALISTIC_TERRAIN
	terrain_layer.render_info = Layer.RealisticTerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = height_layer.clone()
	terrain_layer.render_info.texture_layer = ortho_layer.clone()
	terrain_layer.render_info.landuse_layer = landuse_layer.clone()
	terrain_layer.render_info.surface_height_layer = surface_height_layer.clone()
	terrain_layer.name = "Realistic Terrain"
	
#	# Basic Terrain layer
#	var terrain_layer = Layer.new()
#	terrain_layer.render_type = Layer.RenderType.BASIC_TERRAIN
#	terrain_layer.render_info = Layer.BasicTerrainRenderInfo.new()
#	terrain_layer.render_info.height_layer = height_layer.clone()
#	terrain_layer.render_info.texture_layer = ortho_layer.clone()
#	terrain_layer.name = "Basic Terrain"
	
	# Building layer
	var building_layer = FeatureLayer.new()
	building_layer.geo_feature_layer = geopackage.get_feature_layer("building_footprints")
	building_layer.render_type = Layer.RenderType.POLYGON
	building_layer.render_info = Layer.PolygonRenderInfo.new()
	building_layer.render_info.height_attribute_name = "_mean"
	building_layer.render_info.ground_height_layer = height_layer.clone()
	building_layer.name = "Buildings"

	# Vegetation
	var vegetation_layer = Layer.new()
	vegetation_layer.name = "Vegetation"
	vegetation_layer.render_type = Layer.RenderType.VEGETATION
	vegetation_layer.render_info = Layer.VegetationRenderInfo.new()
	vegetation_layer.render_info.height_layer = height_layer.clone()
	vegetation_layer.render_info.landuse_layer = landuse_layer.clone()
	
#	# Test Point Data
#	var windmill_layer = FeatureLayer.new()
#	var windmill_dataset = Geodot.get_dataset("C:\\boku\\geodata\\test_data\\ooe_point_test.shp")
#	windmill_layer.geo_feature_layer = windmill_dataset.get_feature_layer("ooe_point_test")
#	windmill_layer.render_type = Layer.RenderType.OBJECT
#	windmill_layer.render_info = Layer.ObjectRenderInfo.new()
#	windmill_layer.render_info.object = preload("res://Objects/WindTurbine/GenericWindTurbine.tscn")
#	windmill_layer.render_info.ground_height_layer = height_layer.clone()
#	windmill_layer.name = "Windmills"
	
#	# Test Line Data
#	var street_layer = FeatureLayer.new()
#	var street_dataset = Geodot.get_dataset("C:\\boku\\geodata\\test_data\\ooe_line_test.shp")
#	street_layer.geo_feature_layer = street_dataset.get_feature_layer("ooe_line_test")
#	street_layer.render_type = Layer.RenderType.PATH
#	street_layer.render_info = Layer.PathRenderInfo.new()
#	street_layer.render_info.line_visualization = load("res://Resources/Profiles/Water.tscn")
#	street_layer.render_info.ground_height_layer = height_layer.clone()
#	street_layer.name = "Streets"
	
	# Add the layers
#	Layers.add_layer(windmill_layer)
#	Layers.add_layer(street_layer)
	Layers.add_layer(height_layer)
	Layers.add_layer(ortho_layer)
	Layers.add_layer(surface_height_layer)
	Layers.add_layer(landuse_layer)
	Layers.add_layer(terrain_layer)
	Layers.add_layer(building_layer)
	Layers.add_layer(vegetation_layer)
