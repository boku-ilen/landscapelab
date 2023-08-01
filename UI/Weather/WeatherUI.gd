extends VBoxContainer


var weather_manager: WeatherManager

func _ready():
	$Visibility/HSlider.value_changed.connect(_on_visibility_changed)
	$Clouds/HSlider.value_changed.connect(_on_cloudiness_changed)
	$WindSpeed/HSlider.value_changed.connect(_on_wind_speed_changed)
	$WindDirection/HSlider.value_changed.connect(_on_wind_direction_changed)
	$Rain/CheckBox.toggled.connect(_on_rain_enabled)
	$RainDensity/HSlider.value_changed.connect(_on_rain_density_changed)
	$RainDropX/HSlider.value_changed.connect(_on_rain_drop_changed)
	$RainDropY/HSlider.value_changed.connect(_on_rain_drop_changed)


func _on_visibility_changed(value):
	weather_manager.visibility = value


func _on_cloudiness_changed(value):
	weather_manager.cloudiness = value


func _on_wind_speed_changed(value):
	weather_manager.wind_speed = value


func _on_wind_direction_changed(value):
	weather_manager.wind_direction = value


func _on_rain_enabled(value):
	weather_manager.rain_enabled = value


func _on_rain_density_changed(value):
	weather_manager.rain_density = value


func _on_rain_drop_changed(value):
	var rain_scale = Vector2($RainDropX/SpinBox.value, $RainDropY/SpinBox.value)
	weather_manager.rain_drop_size = rain_scale
