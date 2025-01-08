extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var map_raster = Geodot.get_raster_layer("/data/geodata/LandscapeLab/Wienerwald/MAP_Biosphaerenpark-Wienerwald.mbtiles")
	var map_layer = LayerDefinition.new(map_raster)
	var wind_raster = Geodot.get_raster_layer("/data/geodata/LandscapeLab/Wienerwald/Wind.tif")
	var wind_layer = LayerDefinition.new(wind_raster)
	var colors = Colors.color_ramps["Viridis"] as Array[Color]
	
	var values = util.rangef(0, 25, 25/16)
	wind_layer.render_info.colors = colors
	wind_layer.render_info.values = values
	wind_layer.render_info.no_data = 0.
	
	Layers.add_layer_definition(map_layer)
	Layers.add_layer_definition(wind_layer)
	wind_layer.z_index = 1
	
	$Button.pressed.connect(func(): 
		wind_layer.z_index *= -1
	)
