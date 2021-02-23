extends Configurator


export(String) var geopackage_path

var geodataset


func _ready():
	# TODO: Open the geodataset, iterate over layers, etc
	# set_category("TODO")
	# var layers = get_setting("TODO", null)
	
	add_test_data()


# Adds static test data; will be removed as soon as we have a valid GeoPackage.
func add_test_data():
	var geopackage = Geodot.get_dataset(geopackage_path)
	
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
	
	# Terrain layer
	var terrain_layer = Layer.new()
	terrain_layer.render_type = Layer.RenderType.TERRAIN
	terrain_layer.render_info = Layer.TerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = height_layer.clone()
	terrain_layer.render_info.texture_layer = ortho_layer.clone()
	terrain_layer.name = "Terrain"
	
	# Building layer
	var building_layer = FeatureLayer.new()
	building_layer.geo_feature_layer = geopackage.get_feature_layer("building_footprints")
	building_layer.render_type = Layer.RenderType.POLYGON
	building_layer.render_info = Layer.PolygonRenderInfo.new()
	building_layer.render_info.height_attribute_name = "_mean"
	building_layer.render_info.ground_height_layer = height_layer.clone()
	building_layer.name = "Buildings"
	
#	# Land use
#	var landuse_layer = RasterLayer.new()
#	landuse_layer.geo_raster_layer = geopackage.get_raster_layer("landuse")
#	landuse_layer.name = "Land Use"
#
#	# Vegetation
#	var vegetation_layer = Layer.new()
#	vegetation_layer.render_type = Layer.RenderType.VEGETATION
#	vegetation_layer.render_info = Layer.VegetationRenderInfo.new()
#	vegetation_layer.render_info.min_plant_size = 0.0
#	vegetation_layer.render_info.max_plant_size = 50.0
#	vegetation_layer.render_info.extent = 1000.0
#	vegetation_layer.render_info.density = 10.0
#	vegetation_layer.render_info.height_layer = height_layer
#	vegetation_layer.render_info.landuse_layer = landuse_layer
#
#	var test_layer = Layer.new()
#	test_layer.render_type = Layer.RenderType.NONE
#	test_layer.is_scored = true
#	test_layer.name = "Test layer"
#
#	# Test Point Data
#	var windmill_layer = FeatureLayer.new()
#	var windmill_dataset = Geodot.get_dataset("C:\\boku\\geodata\\test_data\\ooe_point_test.shp")
#	windmill_layer.geo_feature_layer = windmill_dataset.get_feature_layer("ooe_point_test")
#	windmill_layer.render_type = Layer.RenderType.OBJECT
#	windmill_layer.render_info = Layer.ObjectRenderInfo.new()
#	windmill_layer.render_info.object = preload("res://Objects/WindTurbine/GenericWindTurbine.tscn")
#	windmill_layer.render_info.ground_height_layer = height_layer.clone()
#	windmill_layer.name = "Windmills"
	
	# Add the layers
	Layers.add_layer(height_layer)
	Layers.add_layer(ortho_layer)
	Layers.add_layer(terrain_layer)
#	Layers.add_layer(test_layer)
	Layers.add_layer(building_layer)
#	Layers.add_layer(landuse_layer)
#	Layers.add_layer(vegetation_layer)
#	Layers.add_layer(windmill_layer)

