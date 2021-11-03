extends LayerRenderer


var renderers

var weather_manager: WeatherManager setget set_weather_manager


func set_weather_manager(new_weather_manager):
	weather_manager = new_weather_manager
	
	weather_manager.connect("wind_speed_changed", self, "_on_wind_speed_changed")


func _on_wind_speed_changed(new_wind_speed):
	for renderer in renderers.get_children():
		renderer.apply_wind_speed(new_wind_speed)


# Called when the node enters the scene tree for the first time.
func load_new_data():
	renderers = Vegetation.get_renderers()
	
	for renderer in renderers.get_children():
		renderer.update_textures(layer.render_info.height_layer, layer.render_info.landuse_layer,
				center[0], center[1])


func apply_new_data():
	for child in get_children():
		child.queue_free()
	
	for renderer in renderers.get_children():
		renderer.apply_data()
	
	add_child(renderers)
