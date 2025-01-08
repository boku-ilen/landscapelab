extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var map_raster = Geodot.get_raster_layer("/home/landscapelab/Data/LandscapeLab/Portugal/MAP_Viana-do-Castelo.mbtiles")
	var map_layer = LayerDefinition.new(map_raster)
	var wind_raster = Geodot.get_raster_layer("/home/landscapelab/Data/LandscapeLab/Portugal/Wind.tif")
	var wind_layer = LayerDefinition.new(wind_raster)
	
	wind_layer.render_info.gradient = ColorRamps.wind_speed
	wind_layer.render_info.max_val = 11.
	wind_layer.render_info.min_val = 0.
	wind_layer.render_info.no_data = 0.
	
	Layers.add_layer_definition(map_layer)
	Layers.add_layer_definition(wind_layer)
	
	var bar = ColorRamps.create_smybology(wind_layer.render_info.gradient)
	bar.size = Vector2(50, 500)
	add_child(bar)
	
	$Button.pressed.connect(func(): 
		wind_layer.z_index *= -1
	)
