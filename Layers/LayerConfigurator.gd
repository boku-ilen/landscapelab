extends Configurator


var geodataset


func _ready():
	# TODO: Open the geodataset, iterate over layers, etc
	# set_category("TODO")
	# var layers = get_setting("TODO", null)
	
	add_test_data()


# Adds static test data; will be removed as soon as we have a valid GeoPackage.
func add_test_data():
	var geopackage = Geodot.get_dataset("GPKG:/home/karl/Downloads/LL_base.gpkg")

	# Heightmap
	var height_layer = RasterLayer.new()
	height_layer.geo_raster_layer = geopackage.get_raster_layer("dhm")
	
	# Orthophoto
	var ortho_layer = RasterLayer.new()
	ortho_layer.geo_raster_layer = geopackage.get_raster_layer("ortho")
	
	# Terrain layer
	var terrain_layer = Layer.new()
	terrain_layer.render_type = Layer.RenderType.TERRAIN
	terrain_layer.render_info = Layer.TerrainRenderInfo.new()
	terrain_layer.render_info.height_layer = height_layer
	terrain_layer.render_info.texture_layer = ortho_layer
	
	# Add the layers
	Layers.add_layer(height_layer)
	Layers.add_layer(ortho_layer)
	Layers.add_layer(terrain_layer)
