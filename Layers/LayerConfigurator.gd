extends Configurator


var geodataset


func _ready():
	# TODO: Open the geodataset, iterate over layers, etc
	# set_category("TODO")
	# var layers = get_setting("TODO", null)
	
	add_test_data()


# Adds static test data; will be removed as soon as we have a valid GeoPackage.
func add_test_data():
	var heightmap_data_path = "/media/karl/loda1/geodata/wien/test_dhm.tif"
	var ortho_data_path = "/media/karl/loda1/geodata/wien/test_ortho.jpg"

	# Heightmap
	var height_layer = RasterLayer.new()
	height_layer.geo_raster_layer = Geodot.get_dataset(heightmap_data_path).get_raster_layer("")
	
	# Orthophoto
	var ortho_layer = RasterLayer.new()
	ortho_layer.geo_raster_layer = Geodot.get_dataset(ortho_data_path).get_raster_layer("")
	
	# Terrain layer
	var terrain_layer = Layer.new()
	terrain_layer.is_rendered = true
	terrain_layer.fields["texture"] = ortho_layer
	terrain_layer.fields["heights"] = height_layer
	terrain_layer.fields["render_as"] = "terrain"
	
	# Add the layers
	Layers.add_layer(height_layer)
	Layers.add_layer(ortho_layer)
	Layers.add_layer(terrain_layer)
