extends LayerRenderer


var renderers

var weather_manager: WeatherManager setget set_weather_manager


func _ready():
	renderers = Vegetation.get_renderers()
	add_child(renderers)


func set_weather_manager(new_weather_manager):
	weather_manager = new_weather_manager

	weather_manager.connect("wind_speed_changed", self, "_on_wind_speed_changed")
	_on_wind_speed_changed(weather_manager.wind_speed)


func _on_wind_speed_changed(new_wind_speed):
	for renderer in renderers.get_children():
		renderer.apply_wind_speed(new_wind_speed)


# Called when the node enters the scene tree for the first time.
func load_new_data():
	for renderer in renderers.get_children():
		renderer.update_textures(layer.render_info.height_layer, layer.render_info.landuse_layer,
				center[0], center[1])


func apply_new_data():
	for renderer in renderers.get_children():
		renderer.apply_data()


func get_debug_info() -> String:
	var total_emitted_particles = 0
	var active_renderers = 0
	var total_renderers = 0

	if get_child_count() > 0:
		for renderer in get_child(0).get_children():
			if renderer.visible:
				total_emitted_particles += renderer.rows * renderer.rows
				active_renderers += 1

			total_renderers += 1

	return "{0} of {1} renderers active.\n{2} plants emitted.".format([
		active_renderers,
		total_renderers,
		total_emitted_particles
	])
