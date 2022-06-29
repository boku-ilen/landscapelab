extends VBoxContainer


var weather_manager: WeatherManager


func _ready():
	$Visibility/HSlider.connect("value_changed", self, "_on_visibility_changed")
	$Clouds/HSlider.connect("value_changed", self, "_on_cloudiness_changed")
	$WindSpeed/HSlider.connect("value_changed", self, "_on_wind_speed_changed")
	$WindDirection/HSlider.connect("value_changed", self, "_on_wind_direction_changed")
	$Unshaded/CheckBox.connect("toggled", self, "_on_unshaded_changed")
	$Rain/CheckBox.connect("toggled", self, "_on_rain_enabled")
	$RainDensity/HSlider.connect("value_changed", self, "_on_rain_density_changed")
	$RainDrop/HSlider.connect("value_changed", self, "_on_rain_drop_changed")


func _on_visibility_changed(value):
	weather_manager.set_visibility(value)


func _on_cloudiness_changed(value):
	weather_manager.set_cloudiness(value)


func _on_wind_speed_changed(value):
	weather_manager.set_wind_speed(value)


func _on_wind_direction_changed(value):
	weather_manager.set_wind_direction(value)


func _on_unshaded_changed(value):
	weather_manager.set_is_unshaded(value)


func _on_rain_enabled(value):
	weather_manager.set_rain_enabled(value)


func _on_rain_density_changed(value):
	weather_manager.set_rain_density(value)


func _on_rain_drop_changed(value):
	weather_manager.set_rain_drop_size(value)
